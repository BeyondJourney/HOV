using System.Text.Json;

namespace HouseOfVacation.Seo;

/// <summary>
/// Loads the old -> new URL map and flattens it so every lookup returns the
/// FINAL destination. This is what guarantees "no redirect chains": if the map
/// contains A -> B and B -> C, the service rewrites it to A -> C at startup.
/// </summary>
public sealed class RedirectMapService
{
    private readonly Dictionary<string, string> _map;
    private readonly ILogger<RedirectMapService> _log;

    public RedirectMapService(IWebHostEnvironment env, ILogger<RedirectMapService> log)
    {
        _log = log;
        var path = Path.Combine(env.ContentRootPath, "App_Data", "redirect-map.json");
        _map = Load(path);
        _map = Flatten(_map);
    }

    private Dictionary<string, string> Load(string path)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        if (!File.Exists(path))
        {
            _log.LogWarning("Redirect map not found at {Path}. No 1:1 redirects loaded.", path);
            return result;
        }

        var entries = JsonSerializer.Deserialize<List<RedirectEntry>>(File.ReadAllText(path))
                      ?? new List<RedirectEntry>();

        foreach (var e in entries)
        {
            if (string.IsNullOrWhiteSpace(e.From) || string.IsNullOrWhiteSpace(e.To))
                continue;

            var from = Normalize(e.From);
            var to = e.To.Trim();

            // A rule that points at itself would loop forever.
            if (string.Equals(from, Normalize(to), StringComparison.OrdinalIgnoreCase))
            {
                _log.LogWarning("Skipping self-referencing redirect: {From}", from);
                continue;
            }

            result[from] = to;
        }

        _log.LogInformation("Loaded {Count} redirect rules.", result.Count);
        return result;
    }

    /// <summary>
    /// Collapses multi-hop chains into single hops and drops any cycles.
    /// </summary>
    private Dictionary<string, string> Flatten(Dictionary<string, string> source)
    {
        var flat = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        foreach (var (from, to) in source)
        {
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { from };
            var target = to;
            var hops = 0;

            // Follow the chain to its end (bounded, so a cycle cannot hang startup).
            while (source.TryGetValue(Normalize(target), out var next) && hops++ < 10)
            {
                if (!seen.Add(Normalize(target)))
                {
                    _log.LogError("Redirect cycle detected starting at {From}. Rule dropped.", from);
                    target = null;
                    break;
                }
                target = next;
            }

            if (target is null) continue;

            if (hops > 0)
                _log.LogInformation("Collapsed chain: {From} -> {To} ({Hops} hops removed)", from, target, hops);

            flat[from] = target;
        }

        return flat;
    }

    /// <summary>Returns the final destination for a path, or null if none.</summary>
    public bool TryResolve(string path, out string destination)
        => _map.TryGetValue(Normalize(path), out destination!);

    /// <summary>Lowercase + guaranteed leading and trailing slash.</summary>
    public static string Normalize(string path)
    {
        if (string.IsNullOrWhiteSpace(path)) return "/";

        path = path.Trim().ToLowerInvariant();
        if (!path.StartsWith('/')) path = "/" + path;

        // Leave files alone - only page URLs get a trailing slash.
        var last = path.LastIndexOf('/');
        var hasExtension = path.LastIndexOf('.') > last;

        if (!hasExtension && !path.EndsWith('/')) path += "/";

        return path;
    }

    public int Count => _map.Count;

    private sealed record RedirectEntry(string From, string To);
}
