using System.Diagnostics;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using LibreHardwareMonitor.Hardware;
using PcCareCompanion;

// ----- Boot hardware sensor monitor -----
var computer = new Computer
{
    IsCpuEnabled = true,
    IsGpuEnabled = true,
    IsMotherboardEnabled = true,
    IsStorageEnabled = true,
};
computer.Open();
var sensorLock = new object();

// ----- Initialize persistent state (PIN + revoked list) -----
var dataDir = Path.Combine(
    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
    "PcCareCompanion");
Directory.CreateDirectory(dataDir);

AppState.PinFile = Path.Combine(dataDir, "pin.txt");
if (File.Exists(AppState.PinFile))
{
    AppState.SetPin(File.ReadAllText(AppState.PinFile).Trim(), persist: false);
}
else
{
    AppState.SetPin(new Random().Next(100000, 999999).ToString(), persist: true);
}

AppState.RevokedFile = Path.Combine(dataDir, "revoked.txt");
if (File.Exists(AppState.RevokedFile))
{
    AppState.Revoked = new HashSet<string>(
        File.ReadAllLines(AppState.RevokedFile)
            .Select(l => l.Trim())
            .Where(l => l.Length > 0));
}

AppState.CustomNamesFile = Path.Combine(dataDir, "device_names.txt");
AppState.LoadCustomNames();

// ----- Identity (hostname / IP / MAC) -----
AppState.Hostname = Environment.MachineName;
AppState.LocalIp = GetLocalIp();
AppState.MacAddress = GetMacAddress();

static string GetLocalIp()
{
    try
    {
        var host = Dns.GetHostEntry(Dns.GetHostName());
        foreach (var addr in host.AddressList)
        {
            if (addr.AddressFamily == AddressFamily.InterNetwork &&
                !IPAddress.IsLoopback(addr))
            {
                return addr.ToString();
            }
        }
    }
    catch { /* ignore */ }
    return "127.0.0.1";
}

static string GetMacAddress()
{
    try
    {
        var nic = NetworkInterface.GetAllNetworkInterfaces()
            .FirstOrDefault(n =>
                n.OperationalStatus == OperationalStatus.Up &&
                n.NetworkInterfaceType != NetworkInterfaceType.Loopback &&
                n.NetworkInterfaceType != NetworkInterfaceType.Tunnel);
        if (nic == null) return "";
        var bytes = nic.GetPhysicalAddress().GetAddressBytes();
        return string.Join(":", bytes.Select(b => b.ToString("X2")));
    }
    catch { return ""; }
}

// ----- Build the HTTP server -----
var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders(); // we have a GUI activity log instead
var app = builder.Build();

// Auth middleware + device tracking + revocation check + activity logging.
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/api"))
    {
        var headerPin = context.Request.Headers["X-Pin"].ToString();
        if (headerPin != AppState.Pin)
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Invalid or missing PIN");
            return;
        }

        var deviceId = context.Request.Headers["X-Device-Id"].ToString();
        var deviceName = context.Request.Headers["X-Device-Name"].ToString();

        if (!string.IsNullOrWhiteSpace(deviceId))
        {
            if (AppState.IsRevoked(deviceId))
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                context.Response.Headers["X-Revoked"] = "1";
                return;
            }

            var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
            if (ip.StartsWith("::ffff:")) ip = ip.Substring(7);
            AppState.TrackDevice(deviceId, deviceName, ip);

            var label = string.IsNullOrWhiteSpace(deviceName) ? "Unknown" : deviceName;
            AppState.LogActivity(label, context.Request.Method, context.Request.Path);
        }
    }
    await next();
});

// Health check + identify — used for online detection AND subnet scan.
app.MapGet("/", () => Results.Ok(new
{
    app = "PC Care Companion",
    hostname = AppState.Hostname,
    mac = AppState.MacAddress,
    version = "1.0",
}));

app.MapGet("/api/storage", () =>
{
    var drives = DriveInfo.GetDrives()
        .Where(d => d.IsReady && d.DriveType == DriveType.Fixed)
        .Select(d => new
        {
            letter = d.Name.TrimEnd('\\'),
            name = string.IsNullOrWhiteSpace(d.VolumeLabel) ? "Local Disk" : d.VolumeLabel,
            totalGB = Math.Round(d.TotalSize / 1024.0 / 1024.0 / 1024.0, 1),
            freeGB = Math.Round(d.AvailableFreeSpace / 1024.0 / 1024.0 / 1024.0, 1),
        })
        .ToList();
    return Results.Ok(new { drives });
});

app.MapGet("/api/temps", () =>
{
    int? cpu = null, gpu = null, mobo = null, storage = null;

    lock (sensorLock)
    {
        void Walk(IHardware hw, HardwareType root)
        {
            hw.Update();
            foreach (var s in hw.Sensors)
            {
                if (s.SensorType != SensorType.Temperature || !s.Value.HasValue)
                    continue;
                var t = (int)Math.Round(s.Value.Value);
                if (t == 0) continue;
                switch (root)
                {
                    case HardwareType.Cpu:
                        if (s.Name.Contains("Package") ||
                            s.Name.Contains("Tdie") ||
                            s.Name.Contains("Tctl"))
                        {
                            cpu = t;
                        }
                        else if (cpu == null || t > cpu)
                        {
                            cpu = t;
                        }
                        break;
                    case HardwareType.GpuNvidia:
                    case HardwareType.GpuAmd:
                    case HardwareType.GpuIntel:
                        gpu ??= t;
                        break;
                    case HardwareType.Motherboard:
                        mobo ??= t;
                        break;
                    case HardwareType.Storage:
                        storage ??= t;
                        break;
                }
            }
            foreach (var sub in hw.SubHardware) Walk(sub, root);
        }

        foreach (var hw in computer.Hardware) Walk(hw, hw.HardwareType);
    }

    return Results.Ok(new { cpu, gpu, motherboard = mobo, storage });
});

app.MapPost("/api/power/shutdown", () =>
{
    Process.Start(new ProcessStartInfo
    {
        FileName = "shutdown",
        Arguments = "/s /t 5",
        CreateNoWindow = true,
        UseShellExecute = false,
    });
    return Results.Ok(new { ok = true, message = "Shutdown in 5 seconds" });
});

app.MapPost("/api/power/restart", () =>
{
    Process.Start(new ProcessStartInfo
    {
        FileName = "shutdown",
        Arguments = "/r /t 5",
        CreateNoWindow = true,
        UseShellExecute = false,
    });
    return Results.Ok(new { ok = true, message = "Restart in 5 seconds" });
});

app.MapPost("/api/power/sleep", () =>
{
    Process.Start(new ProcessStartInfo
    {
        FileName = "rundll32.exe",
        Arguments = "powrprof.dll,SetSuspendState 0,1,0",
        CreateNoWindow = true,
        UseShellExecute = false,
    });
    return Results.Ok(new { ok = true, message = "Going to sleep" });
});

app.MapPost("/api/power/cancel", () =>
{
    Process.Start(new ProcessStartInfo
    {
        FileName = "shutdown",
        Arguments = "/a",
        CreateNoWindow = true,
        UseShellExecute = false,
    });
    return Results.Ok(new { ok = true, message = "Cancelled" });
});

app.MapPost("/api/actions/clear-cache", () =>
{
    long bytesFreed = 0;
    int filesDeleted = 0;
    var temp = Path.GetTempPath();

    try
    {
        foreach (var path in Directory.EnumerateFiles(temp))
        {
            try
            {
                var info = new FileInfo(path);
                var size = info.Length;
                info.Delete();
                bytesFreed += size;
                filesDeleted++;
            }
            catch { /* locked / in use / no perms — skip */ }
        }
    }
    catch { /* dir missing or unreadable */ }

    var mbFreed = Math.Round(bytesFreed / 1024.0 / 1024.0, 2);
    return Results.Ok(new
    {
        ok = true,
        filesDeleted,
        bytesFreed,
        mbFreed,
        message = $"Deleted {filesDeleted} files ({mbFreed} MB)",
    });
});

app.MapPost("/api/actions/defrag", () =>
{
    Process.Start(new ProcessStartInfo
    {
        FileName = "defrag",
        Arguments = "C: /O",
        CreateNoWindow = true,
        UseShellExecute = false,
    });
    return Results.Ok(new
    {
        ok = true,
        message = "Defrag / Optimize started in background",
    });
});

app.MapGet("/api/devices", () =>
{
    var snapshot = AppState.SnapshotDevices();
    var now = DateTime.UtcNow;
    var list = snapshot.Select(d => new
    {
        id = d.Id,
        name = d.DisplayName,
        reportedName = d.ReportedName,
        customName = d.CustomName,
        ip = d.Ip,
        firstSeen = d.FirstSeen,
        lastSeen = d.LastSeen,
        secondsSinceLastSeen = (int)(now - d.LastSeen).TotalSeconds,
        active = (now - d.LastSeen).TotalSeconds < 30,
    }).ToList();
    return Results.Ok(new { devices = list });
});

app.MapPost("/api/devices/{id}/revoke", (string id) =>
{
    AppState.RevokeDevice(id);
    return Results.Ok(new { ok = true, revokedId = id });
});

// Sets a custom display name for a device. Sending an empty/missing name
// clears the override so it falls back to whatever the phone reports.
app.MapPost("/api/devices/{id}/rename", async (string id, HttpContext ctx) =>
{
    using var reader = new StreamReader(ctx.Request.Body);
    var body = await reader.ReadToEndAsync();
    AppState.RenameDevice(id, body);
    return Results.Ok(new { ok = true });
});

app.MapPost("/api/devices/regenerate-pin", () =>
{
    AppState.RegeneratePin();
    return Results.Ok(new { ok = true, newPin = AppState.Pin });
});

// Called by phone-side Disconnect button so the PC GUI also removes the
// device entry (otherwise it would just go stale showing "Last seen X").
// Does NOT add to revoked list — the user chose to leave; they can re-pair.
app.MapPost("/api/devices/me/forget", (HttpContext ctx) =>
{
    var deviceId = ctx.Request.Headers["X-Device-Id"].ToString();
    if (string.IsNullOrWhiteSpace(deviceId))
    {
        return Results.BadRequest(new { ok = false, error = "Missing X-Device-Id" });
    }
    AppState.ForgetDevice(deviceId);
    return Results.Ok(new { ok = true });
});

// ----- Start web server in the background, then show GUI -----
var serverTask = app.RunAsync($"http://0.0.0.0:{AppState.Port}");

ApplicationConfiguration.Initialize();
Application.Run(new MainForm());

// When the form closes, gracefully shut down the web server.
try { await app.StopAsync(TimeSpan.FromSeconds(2)); } catch { /* ignore */ }
computer.Close();
