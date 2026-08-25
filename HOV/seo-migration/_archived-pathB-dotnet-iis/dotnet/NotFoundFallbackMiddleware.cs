using Microsoft.Extensions.Options;

namespace HouseOfVacation.Seo;

public sealed class NotFoundOptions
{
    /// <summary>
    /// TRUE  = 301 every unmatched URL to a guessed page (what was requested).
    /// FALSE = 301 only on a confident slug match, otherwise serve a real 404.
    ///
    /// Google treats a mass redirect-to-homepage as a SOFT 404. Leaving this
    /// false is the SEO-safe default; see README before turning it on.
    /// </summary>
    public bool AlwaysRedirect { get; set; } = false;

    public string FallbackUrl { get; set; } = "/";
    public string NotFoundPage { get; set; } = "/page-not-found/";

    /// <summary>Minimum token overlap (0-1) before a guess counts as confident.</summary>
    public double MatchThreshold { get; set; } = 0.5;
}

/// <summary>
/// Runs LAST. If nothing served the request, try to find the most relevant
/// live page by slug similarity and 301 there. Only falls back to the
/// homepage when configured to.
/// </summary>
public sealed class NotFoundFallbackMiddleware
{
    private readonly RequestDelegate _next;
    private readonly NotFoundOptions _opt;
    private readonly ILogger<NotFoundFallbackMiddleware> _log;

    // The live URL set. Keep in sync with the sitemap.
    private static readonly string[] LivePages =
    {
        "/",
        "/mice-company-in-delhi/",
        "/mice-company-in-noida/",
        "/mice-company-in-gurugram/",
        "/corporate-travel-agency-in-mumbai/",
        "/corporate-travel-agency-in-bangalore/",
        "/corporate-event-planners-in-pune/",
        "/contact-us/",
        "/about-company/",
        "/blog/"
    };

    // Topic hints -> destination. Checked before fuzzy matching so an unknown
    // city or service URL lands somewhere genuinely relevant.
    private static readonly (string[] Keywords, string Target)[] TopicRules =
    {
        (new[] { "delhi", "ncr" },                       "/mice-company-in-delhi/"),
        (new[] { "noida" },                              "/mice-company-in-noida/"),
        (new[] { "gurugram", "gurgaon" },                "/mice-company-in-gurugram/"),
        (new[] { "mumbai", "bombay" },                   "/corporate-travel-agency-in-mumbai/"),
        (new[] { "bangalore", "bengaluru" },             "/corporate-travel-agency-in-bangalore/"),
        (new[] { "pune" },                               "/corporate-event-planners-in-pune/"),
        (new[] { "contact", "enquiry", "quote" },        "/contact-us/"),
        (new[] { "about", "company", "team" },           "/about-company/"),
        (new[] { "blog", "post", "news", "article" },    "/blog/")
    };

    public NotFoundFallbackMiddleware(
        RequestDelegate next,
        IOptions<NotFoundOptions> opt,
        ILogger<NotFoundFallbackMiddleware> log)
    {
        _next = next;
        _opt = opt.Value;
        _log = log;
    }

    public async Task InvokeAsync(HttpContext ctx)
    {
        await _next(ctx);

        // Only act on an unhandled 404 that has not already started writing.
        if (ctx.Response.StatusCode != StatusCodes.Status404NotFound ||
            ctx.Response.HasStarted)
            return;

        var path = ctx.Request.Path.Value ?? "/";
        var referer = ctx.Request.Headers.Referer.ToString();
        var ua = ctx.Request.Headers.UserAgent.ToString();

        // --- Structured 404 log. Feed this into your redirect map weekly. ---
        _log.LogWarning("404_HIT path={Path} referer={Referer} ua={UserAgent} ip={Ip}",
            path, string.IsNullOrEmpty(referer) ? "(direct)" : referer, ua,
            ctx.Connection.RemoteIpAddress?.ToString() ?? "-");

        var guess = FindBestMatch(path);

        if (guess is not null)
        {
            _log.LogInformation("404_RECOVERED {Path} -> {Target}", path, guess);
            ctx.Response.Clear();
            ctx.Response.Redirect(guess, permanent: true);   // 301
            return;
        }

        if (_opt.AlwaysRedirect)
        {
            _log.LogInformation("404_FALLBACK {Path} -> {Target}", path, _opt.FallbackUrl);
            ctx.Response.Clear();
            ctx.Response.Redirect(_opt.FallbackUrl, permanent: true);
            return;
        }

        // SEO-safe default: a real 404 with a helpful branded page.
        _log.LogInformation("404_SERVED {Path}", path);
        ctx.Response.Clear();
        ctx.Response.StatusCode = StatusCodes.Status404NotFound;
        ctx.Request.Path = _opt.NotFoundPage;
        await _next(ctx);
    }

    private string? FindBestMatch(string path)
    {
        var slug = path.Trim('/').ToLowerInvariant();
        if (slug.Length == 0) return null;

        // 1. Exact live page, differing only by case or slash.
        var normalised = RedirectMapService.Normalize(path);
        foreach (var page in LivePages)
            if (page.Equals(normalised, StringComparison.OrdinalIgnoreCase))
                return page;

        var tokens = slug.Split(new[] { '-', '/', '_', '.' },
                                StringSplitOptions.RemoveEmptyEntries);

        // 2. Topic keyword hit (a city or intent word appears in the URL).
        foreach (var (keywords, target) in TopicRules)
            if (tokens.Any(t => keywords.Contains(t)))
                return target;

        // 3. Fuzzy token overlap against live slugs.
        string? best = null;
        double bestScore = 0;

        foreach (var page in LivePages)
        {
            var pageTokens = page.Trim('/')
                                 .Split('-', StringSplitOptions.RemoveEmptyEntries);
            if (pageTokens.Length == 0) continue;

            var shared = tokens.Intersect(pageTokens).Count();
            var score = (double)shared / Math.Max(tokens.Length, pageTokens.Length);

            if (score > bestScore) { bestScore = score; best = page; }
        }

        return bestScore >= _opt.MatchThreshold ? best : null;
    }
}

public static class NotFoundFallbackExtensions
{
    public static IServiceCollection AddNotFoundFallback(
        this IServiceCollection services, IConfiguration config)
    {
        services.Configure<NotFoundOptions>(config.GetSection("NotFound"));
        return services;
    }

    public static IApplicationBuilder UseNotFoundFallback(this IApplicationBuilder app)
        => app.UseMiddleware<NotFoundFallbackMiddleware>();
}
