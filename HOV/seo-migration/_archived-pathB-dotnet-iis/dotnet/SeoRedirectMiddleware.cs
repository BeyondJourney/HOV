using Microsoft.Extensions.Options;

namespace HouseOfVacation.Seo;

public sealed class SeoOptions
{
    public string CanonicalHost { get; set; } = "houseofvacation.com";
    public bool ForceHttps { get; set; } = true;
    public bool ForceLowercase { get; set; } = true;
    public bool ForceTrailingSlash { get; set; } = true;

    /// <summary>Query keys stripped on sight (the old ?no-cache= trap).</summary>
    public string[] JunkQueryKeys { get; set; } = { "no-cache", "attachment_id" };

    /// <summary>Paths never touched by normalisation.</summary>
    public string[] SkipPrefixes { get; set; } =
        { "/wp-content/uploads/", "/.well-known/", "/assets/", "/css/", "/js/" };
}

/// <summary>
/// Computes the canonical form of a request ONCE, then issues a single 301.
/// Host, scheme, case, trailing slash and the redirect map are all evaluated
/// before redirecting, so a request that is wrong in four ways still costs
/// exactly one hop. This is the main advantage over doing it in .htaccess.
/// </summary>
public sealed class SeoRedirectMiddleware
{
    private readonly RequestDelegate _next;
    private readonly RedirectMapService _map;
    private readonly SeoOptions _opt;
    private readonly ILogger<SeoRedirectMiddleware> _log;

    public SeoRedirectMiddleware(
        RequestDelegate next,
        RedirectMapService map,
        IOptions<SeoOptions> opt,
        ILogger<SeoRedirectMiddleware> log)
    {
        _next = next;
        _map = map;
        _opt = opt.Value;
        _log = log;
    }

    public async Task InvokeAsync(HttpContext ctx)
    {
        var req = ctx.Request;
        var path = req.Path.HasValue ? req.Path.Value! : "/";

        // Static assets and the ACME challenge pass straight through.
        foreach (var prefix in _opt.SkipPrefixes)
        {
            if (path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                await _next(ctx);
                return;
            }
        }

        var changed = false;

        // ---- 1. Scheme -------------------------------------------------
        // X-Forwarded-Proto is honoured so this works behind a CDN or a
        // shared-hosting reverse proxy without looping.
        var scheme = req.Headers.TryGetValue("X-Forwarded-Proto", out var xfp)
            ? xfp.ToString().Split(',')[0].Trim()
            : req.Scheme;

        if (_opt.ForceHttps && !scheme.Equals("https", StringComparison.OrdinalIgnoreCase))
        {
            scheme = "https";
            changed = true;
        }

        // ---- 2. Host ---------------------------------------------------
        var host = req.Host.Host;
        if (!host.Equals(_opt.CanonicalHost, StringComparison.OrdinalIgnoreCase))
        {
            // Only rewrite www -> apex. An unknown host is left alone so a
            // staging domain does not get bounced to production.
            if (host.Equals("www." + _opt.CanonicalHost, StringComparison.OrdinalIgnoreCase))
            {
                host = _opt.CanonicalHost;
                changed = true;
            }
        }

        // ---- 3. Query string cleanup ----------------------------------
        var query = req.QueryString;
        if (query.HasValue)
        {
            var kept = req.Query
                .Where(kv => !_opt.JunkQueryKeys.Contains(kv.Key, StringComparer.OrdinalIgnoreCase))
                .ToList();

            if (kept.Count != req.Query.Count)
            {
                query = kept.Count == 0
                    ? QueryString.Empty
                    : QueryString.Create(kept.Select(kv =>
                        new KeyValuePair<string, string?>(kv.Key, kv.Value.ToString())));
                changed = true;
            }
        }

        // ---- 4. Case ---------------------------------------------------
        if (_opt.ForceLowercase && path.Any(char.IsUpper))
        {
            path = path.ToLowerInvariant();
            changed = true;
        }

        // ---- 5. Trailing slash ----------------------------------------
        if (_opt.ForceTrailingSlash && !path.EndsWith('/'))
        {
            var lastSlash = path.LastIndexOf('/');
            var hasExtension = path.LastIndexOf('.') > lastSlash;
            if (!hasExtension)
            {
                path += "/";
                changed = true;
            }
        }

        // ---- 6. Explicit redirect map (already chain-flattened) --------
        if (_map.TryResolve(path, out var mapped))
        {
            _log.LogInformation("REDIRECT_MAP {From} -> {To} (ref: {Referer})",
                path, mapped, req.Headers.Referer.ToString());

            path = mapped;
            query = QueryString.Empty;   // do not carry old params to a new page
            changed = true;
        }

        // ---- 7. One 301, containing every correction -------------------
        if (changed)
        {
            var target = $"{scheme}://{host}{path}{query}";
            ctx.Response.Headers["X-Redirect-Reason"] = "seo-canonical";
            ctx.Response.Redirect(target, permanent: true);   // 301, never 302
            return;
        }

        await _next(ctx);
    }
}

public static class SeoRedirectExtensions
{
    public static IServiceCollection AddSeoRedirects(
        this IServiceCollection services, IConfiguration config)
    {
        services.Configure<SeoOptions>(config.GetSection("Seo"));
        services.AddSingleton<RedirectMapService>();
        return services;
    }

    public static IApplicationBuilder UseSeoRedirects(this IApplicationBuilder app)
        => app.UseMiddleware<SeoRedirectMiddleware>();
}
