using System.Collections.Concurrent;

namespace PcCareCompanion;

/// <summary>Tracks one paired phone for the Connected Devices panel.</summary>
public class DeviceEntry
{
    public string Id { get; set; } = "";
    /// <summary>Raw name reported by the phone via X-Device-Name (e.g. "24069PC21G").</summary>
    public string ReportedName { get; set; } = "Unknown Device";
    /// <summary>User-set friendly name from the PC GUI (e.g. "Mokhtar's Phone"). Optional.</summary>
    public string? CustomName { get; set; }
    /// <summary>What gets shown in the GUI — custom name if set, otherwise the reported one.</summary>
    public string DisplayName =>
        !string.IsNullOrWhiteSpace(CustomName) ? CustomName : ReportedName;
    public string Ip { get; set; } = "";
    public DateTime FirstSeen { get; set; }
    public DateTime LastSeen { get; set; }
}

/// <summary>One row in the activity log (shown at the bottom of MainForm).</summary>
public class LogEntry
{
    public DateTime Time { get; init; } = DateTime.Now;
    public string DeviceName { get; init; } = "";
    public string Method { get; init; } = "";
    public string Path { get; init; } = "";
    public override string ToString() =>
        $"{Time:HH:mm:ss}  {DeviceName,-20} {Method,-4} {Path}";
}

/// <summary>
/// Shared application state — populated at startup by the web-server side
/// and read by the WinForms MainForm. Thread-safe.
/// </summary>
public static class AppState
{
    // ----- Identity (set once at startup) -----
    public static string Hostname { get; set; } = "";
    public static string LocalIp { get; set; } = "";
    public static string MacAddress { get; set; } = "";
    public static int Port { get; set; } = 5000;

    // ----- PIN (mutable via Regenerate) -----
    public static string Pin { get; set; } = "";
    public static string PinFile { get; set; } = "";
    public static event Action? PinChanged;

    public static void SetPin(string newPin, bool persist = true)
    {
        Pin = newPin;
        if (persist && !string.IsNullOrEmpty(PinFile))
        {
            try { File.WriteAllText(PinFile, newPin); } catch { /* ignore */ }
        }
        PinChanged?.Invoke();
    }

    public static void RegeneratePin()
    {
        var fresh = new Random().Next(100000, 999999).ToString();
        SetPin(fresh, persist: true);
        lock (DeviceLock)
        {
            Devices.Clear();
            // Regenerating PIN is a hard reset — also clear revoked list
            // so previously-kicked phones can pair again with the new PIN.
            Revoked.Clear();
            try { File.WriteAllText(RevokedFile, ""); } catch { /* ignore */ }
        }
        DevicesChanged?.Invoke();
    }

    // ----- Connected devices + revoke list -----
    public static Dictionary<string, DeviceEntry> Devices { get; } = new();
    public static HashSet<string> Revoked { get; set; } = new();
    public static string RevokedFile { get; set; } = "";
    public static object DeviceLock { get; } = new();
    public static event Action? DevicesChanged;

    public static void TrackDevice(string id, string name, string ip)
    {
        lock (DeviceLock)
        {
            if (!Devices.TryGetValue(id, out var dev))
            {
                dev = new DeviceEntry
                {
                    Id = id,
                    ReportedName = string.IsNullOrWhiteSpace(name) ? "Unknown Device" : name,
                    CustomName = _customNames.TryGetValue(id, out var custom) ? custom : null,
                    Ip = ip,
                    FirstSeen = DateTime.UtcNow,
                };
                Devices[id] = dev;
            }
            dev.LastSeen = DateTime.UtcNow;
            dev.Ip = ip;
            if (!string.IsNullOrWhiteSpace(name)) dev.ReportedName = name;
        }
        DevicesChanged?.Invoke();
    }

    public static bool IsRevoked(string id)
    {
        lock (DeviceLock) return Revoked.Contains(id);
    }

    public static void RevokeDevice(string id)
    {
        lock (DeviceLock)
        {
            Revoked.Add(id);
            Devices.Remove(id);
            try { File.WriteAllLines(RevokedFile, Revoked); } catch { /* ignore */ }
        }
        DevicesChanged?.Invoke();
    }

    /// <summary>
    /// Removes a device from the tracked list WITHOUT revoking it. Used when
    /// the phone explicitly says "forget me" via the Disconnect button.
    /// The phone can re-pair later with the same PIN.
    /// </summary>
    public static void ForgetDevice(string id)
    {
        lock (DeviceLock)
        {
            Devices.Remove(id);
        }
        DevicesChanged?.Invoke();
    }

    public static List<DeviceEntry> SnapshotDevices()
    {
        lock (DeviceLock)
        {
            return Devices.Values.Select(d => new DeviceEntry
            {
                Id = d.Id,
                ReportedName = d.ReportedName,
                CustomName = d.CustomName,
                Ip = d.Ip,
                FirstSeen = d.FirstSeen,
                LastSeen = d.LastSeen,
            }).OrderBy(d => d.DisplayName).ToList();
        }
    }

    // ----- Custom display names (per-device, set by user in GUI) -----
    private static readonly Dictionary<string, string> _customNames = new();
    public static string CustomNamesFile { get; set; } = "";

    /// <summary>Reads custom names from disk into memory. Call once at startup.</summary>
    public static void LoadCustomNames()
    {
        if (string.IsNullOrEmpty(CustomNamesFile) || !File.Exists(CustomNamesFile)) return;
        try
        {
            foreach (var line in File.ReadAllLines(CustomNamesFile))
            {
                var idx = line.IndexOf('|');
                if (idx <= 0) continue;
                var id = line.Substring(0, idx).Trim();
                var name = line.Substring(idx + 1).Trim();
                if (id.Length > 0 && name.Length > 0) _customNames[id] = name;
            }
        }
        catch { /* ignore */ }
    }

    /// <summary>
    /// Sets or clears a user-friendly name for a device. Pass null or empty
    /// to reset back to the phone-reported name. Persists to disk.
    /// </summary>
    public static void RenameDevice(string id, string? newName)
    {
        lock (DeviceLock)
        {
            if (string.IsNullOrWhiteSpace(newName))
            {
                _customNames.Remove(id);
                if (Devices.TryGetValue(id, out var dev)) dev.CustomName = null;
            }
            else
            {
                var trimmed = newName.Trim();
                _customNames[id] = trimmed;
                if (Devices.TryGetValue(id, out var dev)) dev.CustomName = trimmed;
            }
            try
            {
                File.WriteAllLines(CustomNamesFile,
                    _customNames.Select(kv => $"{kv.Key}|{kv.Value}"));
            }
            catch { /* ignore */ }
        }
        DevicesChanged?.Invoke();
    }

    // ----- Activity log (rolling window of recent API calls) -----
    private const int MaxLogEntries = 200;
    private static readonly ConcurrentQueue<LogEntry> _log = new();
    public static event Action<LogEntry>? ActivityLogged;

    public static void LogActivity(string deviceName, string method, string path)
    {
        var entry = new LogEntry
        {
            DeviceName = deviceName,
            Method = method,
            Path = path,
        };
        _log.Enqueue(entry);
        while (_log.Count > MaxLogEntries && _log.TryDequeue(out _)) { }
        ActivityLogged?.Invoke(entry);
    }

    public static List<LogEntry> SnapshotLog()
    {
        return _log.ToList();
    }
}
