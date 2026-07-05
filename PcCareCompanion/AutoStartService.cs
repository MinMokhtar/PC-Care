using System.Diagnostics;

namespace PcCareCompanion;

/// <summary>
/// Manages a Windows Task Scheduler entry that launches the companion app
/// at logon with admin privileges. Uses `schtasks.exe` shipped with Windows
/// (no extra dependencies).
/// </summary>
public static class AutoStartService
{
    public const string TaskName = "PcCareCompanion";

    /// <summary>Returns true if a scheduled task with our name exists.</summary>
    public static bool IsInstalled()
    {
        try
        {
            var p = Process.Start(new ProcessStartInfo
            {
                FileName = "schtasks",
                Arguments = $"/query /tn \"{TaskName}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                UseShellExecute = false,
            });
            p?.WaitForExit();
            return p?.ExitCode == 0;
        }
        catch { return false; }
    }

    /// <summary>
    /// Creates the scheduled task pointing at the currently running .exe.
    /// Trigger: at log on. RunLevel: highest (admin elevation, no UAC prompt).
    /// Returns false if creation fails (e.g. not enough rights, or running
    /// via `dotnet run` instead of the published .exe).
    /// </summary>
    public static bool Install(out string error)
    {
        error = "";
        try
        {
            var exePath = GetExePath();
            if (string.IsNullOrEmpty(exePath) ||
                exePath.EndsWith("dotnet.exe", StringComparison.OrdinalIgnoreCase))
            {
                error = "Auto-start only works for the published .exe, not `dotnet run`.";
                return false;
            }

            var p = Process.Start(new ProcessStartInfo
            {
                FileName = "schtasks",
                // /f overrides existing entry, /rl highest = admin without UAC
                Arguments = $"/create /tn \"{TaskName}\" /tr \"\\\"{exePath}\\\"\" /sc onlogon /rl highest /f",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                UseShellExecute = false,
            });
            p?.WaitForExit();
            if (p?.ExitCode == 0) return true;
            error = $"schtasks failed (exit code {p?.ExitCode}).";
            return false;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }

    public static bool Uninstall(out string error)
    {
        error = "";
        try
        {
            var p = Process.Start(new ProcessStartInfo
            {
                FileName = "schtasks",
                Arguments = $"/delete /tn \"{TaskName}\" /f",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                UseShellExecute = false,
            });
            p?.WaitForExit();
            if (p?.ExitCode == 0) return true;
            error = $"schtasks failed (exit code {p?.ExitCode}).";
            return false;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }

    private static string GetExePath() =>
        Process.GetCurrentProcess().MainModule?.FileName ?? "";
}
