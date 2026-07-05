using System.Diagnostics;

namespace PcCareCompanion;

public class MainForm : Form
{
    // ----- Color palette (matches the phone app) -----
    private static readonly Color BgColor = ColorTranslator.FromHtml("#03091F");
    private static readonly Color SidebarBg = ColorTranslator.FromHtml("#06112E");
    private static readonly Color CardBg = ColorTranslator.FromHtml("#11182C");
    private static readonly Color Accent = ColorTranslator.FromHtml("#29ABE2");
    private static readonly Color TextMuted = ColorTranslator.FromHtml("#94A3B8");
    private static readonly Color Divider = ColorTranslator.FromHtml("#2A3550");
    private static readonly Color OnlineGreen = ColorTranslator.FromHtml("#22C55E");
    private static readonly Color OfflineRed = ColorTranslator.FromHtml("#EF4444");

    // ----- Layout state -----
    private Panel _contentHost = null!;
    private Panel _homePage = null!;
    private Panel _settingsPage = null!;
    private Panel _aboutPage = null!;
    private readonly List<SidebarItem> _navItems = new();

    // ----- Live UI controls (Home page) -----
    private Label _pinValue = null!;
    private Label _macValue = null!;
    private Label _ipValue = null!;
    private bool _pinVisible = false;
    private bool _macVisible = false;
    private bool _ipVisible = false;
    private Label _devicesHeading = null!;
    private Panel _devicesList = null!;
    private RichTextBox _activityLog = null!;

    // ----- System tray -----
    private NotifyIcon _tray = null!;
    private bool _reallyQuit = false;

    private readonly System.Windows.Forms.Timer _refreshTimer;

    public MainForm()
    {
        // Window setup
        Text = "PC Care Companion";
        Size = new Size(900, 700);
        MinimumSize = new Size(760, 560);
        BackColor = BgColor;
        ForeColor = Color.White;
        Font = new Font("Segoe UI", 9F);
        FormBorderStyle = FormBorderStyle.Sizable;
        StartPosition = FormStartPosition.CenterScreen;
        Icon = SystemIcons.Application;

        BuildLayout();
        BuildTray();

        // Wire AppState events
        AppState.PinChanged += () => SafeInvoke(UpdatePinDisplay);
        AppState.DevicesChanged += () => SafeInvoke(RebuildDevicesList);
        AppState.ActivityLogged += (entry) => SafeInvoke(() => AppendLogEntry(entry));

        // Tick every 1 sec to update "last seen" times and online dot
        _refreshTimer = new System.Windows.Forms.Timer { Interval = 1000 };
        _refreshTimer.Tick += (_, _) => RebuildDevicesList();
        _refreshTimer.Start();

        // Pre-fill activity log with whatever was already buffered
        foreach (var entry in AppState.SnapshotLog())
        {
            AppendLogEntry(entry);
        }

        // Initial paint
        RebuildDevicesList();
    }

    // ============================================================
    // Layout
    // ============================================================
    private void BuildLayout()
    {
        Controls.Clear();

        _contentHost = new Panel
        {
            Dock = DockStyle.Fill,
            BackColor = BgColor,
            Padding = new Padding(20),
        };

        _homePage = BuildHomePage();
        _settingsPage = BuildSettingsPage();
        _aboutPage = BuildAboutPage();

        _contentHost.Controls.Add(_homePage);
        _contentHost.Controls.Add(_settingsPage);
        _contentHost.Controls.Add(_aboutPage);
        _settingsPage.Visible = false;
        _aboutPage.Visible = false;

        var sidebar = BuildSidebar();

        Controls.Add(_contentHost); // added first so sidebar docks on top
        Controls.Add(sidebar);
    }

    private Panel BuildSidebar()
    {
        var sidebar = new Panel
        {
            Dock = DockStyle.Left,
            Width = 200,
            BackColor = SidebarBg,
            Padding = new Padding(14, 22, 14, 14),
        };

        var logoRow = new Panel
        {
            Dock = DockStyle.Top,
            Height = 80,
            BackColor = SidebarBg,
            Padding = new Padding(8, 4, 8, 4),
        };
        var logoBox = new PictureBox
        {
            Dock = DockStyle.Fill,
            BackColor = SidebarBg,
            SizeMode = PictureBoxSizeMode.Zoom,
        };
        try
        {
            var logoPath = Path.Combine(AppContext.BaseDirectory, "assets", "logo.png");
            if (File.Exists(logoPath)) logoBox.Image = Image.FromFile(logoPath);
        }
        catch { /* fall back to empty box if logo can't be loaded */ }
        logoRow.Controls.Add(logoBox);
        // Docking processes back-to-front (index 0 last), so we add the
        // pieces in REVERSE of the visual top-to-bottom order so they stack
        // correctly: navHost (bottom), spacer (middle), logoRow (top).
        var navHost = new Panel
        {
            Dock = DockStyle.Top,
            Height = 200,
            BackColor = SidebarBg,
        };

        var aboutItem = BuildNavItem("ⓘ", "About", () => Show(_aboutPage));
        var settingsItem = BuildNavItem("⚙", "Settings", () => Show(_settingsPage));
        var homeItem = BuildNavItem("⌂", "Home", () => Show(_homePage));

        // Within navHost too: add in reverse so Home ends up on top.
        navHost.Controls.Add(aboutItem);
        navHost.Controls.Add(settingsItem);
        navHost.Controls.Add(homeItem);

        sidebar.Controls.Add(navHost);
        sidebar.Controls.Add(new Panel { Dock = DockStyle.Top, Height = 24, BackColor = SidebarBg });
        sidebar.Controls.Add(logoRow);

        SetSelected(homeItem);
        return sidebar;
    }

    private SidebarItem BuildNavItem(string glyph, string label, Action onClick)
    {
        var item = new SidebarItem(glyph, label);
        item.Click += (_, _) =>
        {
            SetSelected(item);
            onClick();
        };
        _navItems.Add(item);
        return item;
    }

    private void SetSelected(SidebarItem chosen)
    {
        foreach (var i in _navItems) i.SetSelected(i == chosen);
    }

    private void Show(Panel page)
    {
        _homePage.Visible = page == _homePage;
        _settingsPage.Visible = page == _settingsPage;
        _aboutPage.Visible = page == _aboutPage;
    }

    // ============================================================
    // Home page
    // ============================================================
    private Panel BuildHomePage()
    {
        var page = new Panel
        {
            Dock = DockStyle.Fill,
            BackColor = BgColor,
        };

        var top = BuildPcInfoSection();
        var middle = BuildDevicesSection();
        var bottom = BuildActivityLogSection();

        // Stack vertically: top (auto), middle (fill), bottom (fixed height)
        page.Controls.Add(middle);
        page.Controls.Add(bottom);
        page.Controls.Add(top);

        top.Dock = DockStyle.Top;
        bottom.Dock = DockStyle.Bottom;
        middle.Dock = DockStyle.Fill;

        return page;
    }

    private Panel BuildPcInfoSection()
    {
        var section = NewCard("PC Information");
        section.Height = 220;

        var grid = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 3,
            RowCount = 4,
            BackColor = CardBg,
            Padding = new Padding(0, 8, 0, 8),
        };
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 90));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 48));
        for (int i = 0; i < 4; i++)
            grid.RowStyles.Add(new RowStyle(SizeType.Percent, 25));

        // Row 0: PC Name
        grid.Controls.Add(NewMuted("PC Name"), 0, 0);
        grid.Controls.Add(NewValueLabel(AppState.Hostname, Color.White), 1, 0);

        // Row 1: IP (masked by default, eye toggle to reveal)
        grid.Controls.Add(NewMuted("IP"), 0, 1);
        _ipValue = NewValueLabel(MaskIp(AppState.LocalIp, AppState.Port), Color.White);
        grid.Controls.Add(_ipValue, 1, 1);
        var ipEye = NewEyeButton(() =>
        {
            _ipVisible = !_ipVisible;
            UpdateIpDisplay();
        });
        grid.Controls.Add(ipEye, 2, 1);

        // Row 2: MAC (masked by default, eye toggle to reveal)
        grid.Controls.Add(NewMuted("MAC"), 0, 2);
        _macValue = NewValueLabel(MaskMac(AppState.MacAddress), Color.White);
        grid.Controls.Add(_macValue, 1, 2);
        var macEye = NewEyeButton(() =>
        {
            _macVisible = !_macVisible;
            UpdateMacDisplay();
        });
        grid.Controls.Add(macEye, 2, 2);

        // Row 3: PIN (masked by default) with Copy + Regenerate + eye toggle
        grid.Controls.Add(NewMuted("PIN"), 0, 3);

        var pinPanel = new Panel { Dock = DockStyle.Fill, BackColor = CardBg };
        _pinValue = new Label
        {
            Text = MaskPin(AppState.Pin),
            ForeColor = Accent,
            BackColor = CardBg,
            Font = new Font("Segoe UI", 14F, FontStyle.Bold),
            AutoSize = false,
            Dock = DockStyle.Left,
            Width = 110,
            TextAlign = ContentAlignment.MiddleLeft,
        };
        var copyBtn = NewSmallButton("📋 Copy", (s, _) =>
        {
            var btn = (Button)s!;
            Clipboard.SetText(AppState.Pin);
            btn.Text = "✓ Copied";
            var t = new System.Windows.Forms.Timer { Interval = 1200 };
            t.Tick += (_, _) => { btn.Text = "📋 Copy"; t.Stop(); t.Dispose(); };
            t.Start();
        });
        copyBtn.Dock = DockStyle.Left;
        copyBtn.Margin = new Padding(8, 4, 8, 4);

        var regenBtn = NewSmallButton("🔄 Regenerate", (_, _) =>
        {
            var result = MessageBox.Show(
                "Regenerating the PIN kicks every paired phone. They'll need to re-pair with the new PIN. Continue?",
                "Regenerate PIN?",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);
            if (result == DialogResult.Yes) AppState.RegeneratePin();
        });
        regenBtn.Dock = DockStyle.Left;

        pinPanel.Controls.Add(regenBtn);
        pinPanel.Controls.Add(copyBtn);
        pinPanel.Controls.Add(_pinValue);
        grid.Controls.Add(pinPanel, 1, 3);

        var pinEye = NewEyeButton(() =>
        {
            _pinVisible = !_pinVisible;
            UpdatePinDisplay();
        });
        grid.Controls.Add(pinEye, 2, 3);

        section.Controls.Add(grid);
        return section;
    }

    private Label NewValueLabel(string text, Color color) => new()
    {
        Text = text,
        ForeColor = color,
        BackColor = CardBg,
        Font = new Font("Segoe UI", 10F),
        AutoSize = false,
        Dock = DockStyle.Fill,
        TextAlign = ContentAlignment.MiddleLeft,
    };

    private static string MaskMac(string mac) =>
        string.IsNullOrWhiteSpace(mac) ? "" : "●●:●●:●●:●●:●●:●●";

    private static string MaskPin(string pin) =>
        new string('●', pin.Length);

    private static string MaskIp(string ip, int port) =>
        string.IsNullOrWhiteSpace(ip) ? "" : $"●●●.●●●.●.●●● : {port}";

    private void UpdateMacDisplay() =>
        _macValue.Text = _macVisible ? AppState.MacAddress : MaskMac(AppState.MacAddress);

    private void UpdatePinDisplay() =>
        _pinValue.Text = _pinVisible ? AppState.Pin : MaskPin(AppState.Pin);

    private void UpdateIpDisplay() =>
        _ipValue.Text = _ipVisible
            ? $"{AppState.LocalIp} : {AppState.Port}"
            : MaskIp(AppState.LocalIp, AppState.Port);

    private Button NewEyeButton(Action onClick)
    {
        var btn = new Button
        {
            // Segoe MDL2 Assets: U+E7B3 = RedEye (open). Visible by default
            // since the state starts "hidden" — clicking reveals.
            Text = "",
            BackColor = ColorTranslator.FromHtml("#1E2742"),
            ForeColor = Color.White,
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe MDL2 Assets", 12F),
            Width = 36,
            Height = 28,
            Margin = new Padding(4),
            Padding = new Padding(0),
            Dock = DockStyle.None,
        };
        btn.FlatAppearance.BorderSize = 0;
        btn.Click += (_, _) =>
        {
            onClick();
            // Toggle the icon between RedEye (U+E7B3) and Hide (U+ED1A)
            btn.Text = btn.Text == "" ? "" : "";
        };
        return btn;
    }

    private Label NewMuted(string text) => new()
    {
        Text = text,
        ForeColor = TextMuted,
        BackColor = CardBg,
        Font = new Font("Segoe UI", 9F, FontStyle.Bold),
        AutoSize = false,
        Dock = DockStyle.Fill,
        TextAlign = ContentAlignment.MiddleLeft,
    };

    private Button NewSmallButton(string text, EventHandler onClick)
    {
        var b = new Button
        {
            Text = text,
            BackColor = ColorTranslator.FromHtml("#1E2742"),
            ForeColor = Color.White,
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI", 9F),
            AutoSize = false,
            Height = 28,
            Width = 110,
            Margin = new Padding(4),
            Padding = new Padding(2),
        };
        b.FlatAppearance.BorderSize = 0;
        b.Click += onClick;
        return b;
    }

    // ----- Connected devices -----
    private Panel BuildDevicesSection()
    {
        var section = NewCard("Connected Devices (0)");
        _devicesHeading = (Label)section.Tag!;

        _devicesList = new Panel
        {
            Dock = DockStyle.Fill,
            BackColor = CardBg,
            AutoScroll = true,
        };
        section.Controls.Add(_devicesList);
        return section;
    }

    private void RebuildDevicesList()
    {
        var devices = AppState.SnapshotDevices();
        _devicesHeading.Text = $"Connected Devices ({devices.Count})";
        _devicesList.SuspendLayout();
        _devicesList.Controls.Clear();
        if (devices.Count == 0)
        {
            _devicesList.Controls.Add(new Label
            {
                Text = "  No phones connected yet.",
                ForeColor = TextMuted,
                BackColor = CardBg,
                Font = new Font("Segoe UI", 10F, FontStyle.Italic),
                Dock = DockStyle.Top,
                Height = 40,
                TextAlign = ContentAlignment.MiddleLeft,
            });
        }
        else
        {
            // Stack from bottom to top using DockStyle.Top — add in reverse
            foreach (var d in devices.AsEnumerable().Reverse())
            {
                _devicesList.Controls.Add(BuildDeviceRow(d));
            }
        }
        _devicesList.ResumeLayout();
    }

    private Panel BuildDeviceRow(DeviceEntry d)
    {
        var seconds = (int)(DateTime.UtcNow - d.LastSeen).TotalSeconds;
        var isActive = seconds < 30;
        var row = new Panel
        {
            Dock = DockStyle.Top,
            Height = 60,
            BackColor = ColorTranslator.FromHtml("#1A2238"),
            Margin = new Padding(0, 0, 0, 8),
            Padding = new Padding(12, 8, 12, 8),
        };
        // Spacer below for separation
        var wrap = new Panel
        {
            Dock = DockStyle.Top,
            Height = 70,
            BackColor = CardBg,
        };

        // Phone icon (Segoe MDL2 Assets U+E1C9 = CellPhone) coloured green
        // when the device is actively talking, gray when idle.
        var phoneIcon = new Label
        {
            Text = "",
            Font = new Font("Segoe MDL2 Assets", 22F),
            ForeColor = isActive ? OnlineGreen : ColorTranslator.FromHtml("#475569"),
            BackColor = row.BackColor,
            Width = 44,
            Dock = DockStyle.Left,
            TextAlign = ContentAlignment.MiddleCenter,
        };

        var info = new Panel { Dock = DockStyle.Fill, BackColor = row.BackColor };
        var name = new Label
        {
            Text = d.DisplayName,
            ForeColor = Color.White,
            BackColor = row.BackColor,
            Font = new Font("Segoe UI", 11F, FontStyle.Bold),
            Dock = DockStyle.Top,
            Height = 22,
        };
        var subText = string.IsNullOrEmpty(d.CustomName)
            ? $"{d.Ip}  ·  Last seen {FormatRelative(seconds)}"
            : $"{d.ReportedName}  ·  {d.Ip}  ·  Last seen {FormatRelative(seconds)}";
        var sub = new Label
        {
            Text = subText,
            ForeColor = TextMuted,
            BackColor = row.BackColor,
            Font = new Font("Segoe UI", 9F),
            Dock = DockStyle.Top,
            Height = 18,
        };
        info.Controls.Add(sub);
        info.Controls.Add(name);

        var disconnectBtn = new Button
        {
            Text = "✕ Disconnect",
            BackColor = ColorTranslator.FromHtml("#3F1F23"),
            ForeColor = OfflineRed,
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI", 9F, FontStyle.Bold),
            Width = 110,
            Height = 32,
            Dock = DockStyle.Right,
            Margin = new Padding(4),
        };
        disconnectBtn.FlatAppearance.BorderSize = 0;
        disconnectBtn.Click += (_, _) =>
        {
            var result = MessageBox.Show(
                $"Disconnect \"{d.DisplayName}\"?\n\nThe phone will lose access immediately and bounce back to the Connect screen.",
                "Disconnect Device",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (result == DialogResult.Yes) AppState.RevokeDevice(d.Id);
        };

        var renameBtn = new Button
        {
            Text = "✎ Rename",
            BackColor = ColorTranslator.FromHtml("#1E2742"),
            ForeColor = Color.White,
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI", 9F, FontStyle.Bold),
            Width = 90,
            Height = 32,
            Dock = DockStyle.Right,
            Margin = new Padding(4),
        };
        renameBtn.FlatAppearance.BorderSize = 0;
        renameBtn.Click += (_, _) =>
        {
            var current = d.CustomName ?? d.ReportedName;
            var newName = PromptForName(this, current, d.ReportedName);
            if (newName != null) AppState.RenameDevice(d.Id, newName);
        };

        row.Controls.Add(info);
        row.Controls.Add(disconnectBtn);
        row.Controls.Add(renameBtn);
        row.Controls.Add(phoneIcon);

        wrap.Controls.Add(row);
        return wrap;
    }

    /// <summary>
    /// Shows a small dialog asking for a new device name. Returns:
    ///   - the new name (trimmed) if user clicked Save with content
    ///   - empty string "" if user clicked Save with the field empty (reset)
    ///   - null if user cancelled
    /// </summary>
    private static string? PromptForName(IWin32Window owner, string current, string originalReported)
    {
        using var form = new Form
        {
            Text = "Rename Device",
            Size = new Size(440, 220),
            StartPosition = FormStartPosition.CenterParent,
            FormBorderStyle = FormBorderStyle.FixedDialog,
            MaximizeBox = false,
            MinimizeBox = false,
            BackColor = CardBg,
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 9F),
        };

        var lbl = new Label
        {
            Text = "Friendly name for this device:",
            Location = new Point(20, 18),
            AutoSize = true,
            ForeColor = Color.White,
            BackColor = form.BackColor,
        };
        var hint = new Label
        {
            Text = $"Reported as: {originalReported}\nLeave empty to reset.",
            Location = new Point(20, 100),
            AutoSize = true,
            ForeColor = TextMuted,
            BackColor = form.BackColor,
            Font = new Font("Segoe UI", 9F, FontStyle.Italic),
        };
        var txt = new TextBox
        {
            Text = current,
            Location = new Point(20, 48),
            Width = 380,
            BackColor = ColorTranslator.FromHtml("#1E2742"),
            ForeColor = Color.White,
            BorderStyle = BorderStyle.FixedSingle,
            Font = new Font("Segoe UI", 11F),
        };
        var btnOk = new Button
        {
            Text = "Save",
            Location = new Point(220, 140),
            Width = 90,
            Height = 32,
            BackColor = Accent,
            ForeColor = Color.White,
            FlatStyle = FlatStyle.Flat,
            DialogResult = DialogResult.OK,
        };
        btnOk.FlatAppearance.BorderSize = 0;
        var btnCancel = new Button
        {
            Text = "Cancel",
            Location = new Point(320, 140),
            Width = 90,
            Height = 32,
            BackColor = ColorTranslator.FromHtml("#1E2742"),
            ForeColor = Color.White,
            FlatStyle = FlatStyle.Flat,
            DialogResult = DialogResult.Cancel,
        };
        btnCancel.FlatAppearance.BorderSize = 0;

        form.Controls.Add(lbl);
        form.Controls.Add(txt);
        form.Controls.Add(hint);
        form.Controls.Add(btnOk);
        form.Controls.Add(btnCancel);
        form.AcceptButton = btnOk;
        form.CancelButton = btnCancel;

        var result = form.ShowDialog(owner);
        if (result != DialogResult.OK) return null;
        return txt.Text.Trim();
    }

    private static string FormatRelative(int seconds)
    {
        if (seconds < 5) return "just now";
        if (seconds < 60) return $"{seconds} sec ago";
        var minutes = seconds / 60;
        if (minutes < 60) return $"{minutes} min ago";
        var hours = minutes / 60;
        return $"{hours}h ago";
    }

    // ----- Activity log -----
    private Panel BuildActivityLogSection()
    {
        var section = NewCard("Activity Log");
        section.Height = 200;

        _activityLog = new RichTextBox
        {
            Dock = DockStyle.Fill,
            BackColor = CardBg,
            ForeColor = TextMuted,
            BorderStyle = BorderStyle.None,
            Font = new Font("Consolas", 9F),
            ReadOnly = true,
            ScrollBars = RichTextBoxScrollBars.Vertical,
            DetectUrls = false,
        };
        section.Controls.Add(_activityLog);
        return section;
    }

    private void AppendLogEntry(LogEntry entry)
    {
        if (_activityLog.IsDisposed) return;
        var text = entry.ToString() + Environment.NewLine;
        _activityLog.AppendText(text);
        _activityLog.SelectionStart = _activityLog.Text.Length;
        _activityLog.ScrollToCaret();
    }

    // ============================================================
    // Settings & About pages (lightweight)
    // ============================================================
    private Button _autoStartToggle = null!;

    private Panel BuildSettingsPage()
    {
        var page = new Panel { Dock = DockStyle.Fill, BackColor = BgColor };

        var card = NewCard("Settings");
        card.Dock = DockStyle.Top;
        card.Height = 220;

        var row = new Panel
        {
            Dock = DockStyle.Top,
            Height = 90,
            BackColor = CardBg,
            Padding = new Padding(0, 16, 0, 8),
        };

        _autoStartToggle = new Button
        {
            Text = "OFF",
            Width = 80,
            Height = 36,
            Dock = DockStyle.Right,
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI", 10F, FontStyle.Bold),
            ForeColor = Color.White,
            Margin = new Padding(0, 12, 8, 0),
        };
        _autoStartToggle.FlatAppearance.BorderSize = 0;
        _autoStartToggle.Click += (_, _) => ToggleAutoStart();
        UpdateAutoStartButton();

        var labelPanel = new Panel { Dock = DockStyle.Fill, BackColor = CardBg };
        var title = new Label
        {
            Text = "Auto-start with Windows",
            ForeColor = Color.White,
            BackColor = CardBg,
            Font = new Font("Segoe UI", 11F, FontStyle.Bold),
            Dock = DockStyle.Top,
            Height = 26,
        };
        var sub = new Label
        {
            Text = "Launch PC Care Companion automatically when you log in to Windows.",
            ForeColor = TextMuted,
            BackColor = CardBg,
            Font = new Font("Segoe UI", 9F),
            Dock = DockStyle.Top,
            Height = 20,
        };
        labelPanel.Controls.Add(sub);
        labelPanel.Controls.Add(title);

        row.Controls.Add(labelPanel);
        row.Controls.Add(_autoStartToggle);
        card.Controls.Add(row);
        page.Controls.Add(card);
        return page;
    }

    private void UpdateAutoStartButton()
    {
        var enabled = AutoStartService.IsInstalled();
        _autoStartToggle.Text = enabled ? "ON" : "OFF";
        _autoStartToggle.BackColor = enabled
            ? OnlineGreen
            : ColorTranslator.FromHtml("#475569");
    }

    private void ToggleAutoStart()
    {
        var currentlyEnabled = AutoStartService.IsInstalled();
        if (currentlyEnabled)
        {
            if (AutoStartService.Uninstall(out var err))
            {
                UpdateAutoStartButton();
            }
            else
            {
                MessageBox.Show($"Couldn't disable auto-start:\n{err}",
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        else
        {
            if (AutoStartService.Install(out var err))
            {
                UpdateAutoStartButton();
                MessageBox.Show(
                    "Auto-start enabled. PC Care Companion will launch with admin\n" +
                    "privileges when you log into Windows.",
                    "Auto-start enabled",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            else
            {
                MessageBox.Show($"Couldn't enable auto-start:\n{err}",
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }

    private Panel BuildAboutPage()
    {
        var page = new Panel { Dock = DockStyle.Fill, BackColor = BgColor };
        var card = NewCard("About");
        card.Dock = DockStyle.Top;
        card.Height = 240;
        var info = new Label
        {
            Text = "  PC Care Companion\n" +
                   "  Version 1.0\n\n" +
                   "  Companion app for the PC Care mobile project.\n" +
                   "  Exposes hardware sensors and power controls over\n" +
                   "  the local network via authenticated HTTP.\n\n" +
                   "  Built for FYP.",
            ForeColor = Color.White,
            BackColor = CardBg,
            Dock = DockStyle.Fill,
            Font = new Font("Segoe UI", 10F),
            TextAlign = ContentAlignment.MiddleLeft,
        };
        card.Controls.Add(info);
        page.Controls.Add(card);
        return page;
    }

    // ============================================================
    // Section card helper
    // ============================================================
    private Panel NewCard(string title)
    {
        var card = new Panel
        {
            BackColor = CardBg,
            Padding = new Padding(16, 12, 16, 14),
            Margin = new Padding(0, 0, 0, 12),
        };

        var heading = new Label
        {
            Text = title,
            ForeColor = Color.White,
            BackColor = CardBg,
            Font = new Font("Segoe UI", 11F, FontStyle.Bold),
            Dock = DockStyle.Top,
            Height = 32,
            Padding = new Padding(0, 0, 0, 8),
            TextAlign = ContentAlignment.MiddleLeft,
        };
        // Add the heading first to register it, BUT also stash a closure
        // that ensures it stays on top of any future child controls (callers
        // add their Dock=Fill content after, and WinForms docks last-added
        // FIRST — so we re-add heading at the end via ControlAdded event).
        card.Controls.Add(heading);
        card.Tag = heading;
        card.ControlAdded += (_, _) =>
        {
            // Move heading to the highest z-order so it docks Top first.
            card.Controls.SetChildIndex(heading, card.Controls.Count - 1);
        };
        return card;
    }

    // ============================================================
    // System tray
    // ============================================================
    private void BuildTray()
    {
        _tray = new NotifyIcon
        {
            Icon = SystemIcons.Application,
            Text = "PC Care Companion",
            Visible = true,
        };
        var menu = new ContextMenuStrip();
        menu.Items.Add("Show", null, (_, _) => RestoreWindow());
        menu.Items.Add("Quit", null, (_, _) =>
        {
            _reallyQuit = true;
            _tray.Visible = false;
            Application.Exit();
        });
        _tray.ContextMenuStrip = menu;
        _tray.DoubleClick += (_, _) => RestoreWindow();
    }

    private void RestoreWindow()
    {
        Show();
        WindowState = FormWindowState.Normal;
        BringToFront();
        Activate();
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        // Closing via X minimizes to tray instead of quitting; only "Quit"
        // from tray menu actually exits.
        if (!_reallyQuit && e.CloseReason == CloseReason.UserClosing)
        {
            e.Cancel = true;
            Hide();
            _tray.ShowBalloonTip(2000, "PC Care Companion",
                "Still running in the tray. Right-click the icon to quit.",
                ToolTipIcon.Info);
            return;
        }
        base.OnFormClosing(e);
    }

    // ============================================================
    // Helpers
    // ============================================================
    private void SafeInvoke(Action action)
    {
        if (IsDisposed) return;
        if (InvokeRequired) BeginInvoke(action);
        else action();
    }
}

// ----- Sidebar item -----
internal class SidebarItem : Panel
{
    private static readonly Color HoverBg = ColorTranslator.FromHtml("#0E1B3D");
    private static readonly Color SelectedBg = ColorTranslator.FromHtml("#152348");
    private static readonly Color Accent = ColorTranslator.FromHtml("#29ABE2");

    private readonly Label _glyph;
    private readonly Label _label;
    private bool _selected;

    public SidebarItem(string glyph, string label)
    {
        Dock = DockStyle.Top;
        Height = 44;
        BackColor = ColorTranslator.FromHtml("#06112E");
        Cursor = Cursors.Hand;
        Padding = new Padding(8, 0, 8, 0);

        _glyph = new Label
        {
            Text = glyph,
            ForeColor = Color.White,
            BackColor = BackColor,
            Font = new Font("Segoe UI Symbol", 14F),
            Width = 28,
            Dock = DockStyle.Left,
            TextAlign = ContentAlignment.MiddleCenter,
        };
        _label = new Label
        {
            Text = label,
            ForeColor = Color.White,
            BackColor = BackColor,
            Font = new Font("Segoe UI", 11F, FontStyle.Bold),
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleLeft,
            Padding = new Padding(8, 0, 0, 0),
        };

        Controls.Add(_label);
        Controls.Add(_glyph);

        MouseEnter += (_, _) => { if (!_selected) PaintHover(true); };
        MouseLeave += (_, _) => { if (!_selected) PaintHover(false); };
        foreach (Control c in Controls)
        {
            c.MouseEnter += (_, _) => { if (!_selected) PaintHover(true); };
            c.MouseLeave += (_, _) => { if (!_selected) PaintHover(false); };
            c.Click += (_, e) => OnClick(e);
        }
    }

    private void PaintHover(bool hover)
    {
        BackColor = hover ? HoverBg : ColorTranslator.FromHtml("#06112E");
        _glyph.BackColor = BackColor;
        _label.BackColor = BackColor;
    }

    public void SetSelected(bool selected)
    {
        _selected = selected;
        BackColor = selected ? SelectedBg : ColorTranslator.FromHtml("#06112E");
        _glyph.BackColor = BackColor;
        _label.BackColor = BackColor;
        _glyph.ForeColor = selected ? Accent : Color.White;
        _label.ForeColor = selected ? Accent : Color.White;
    }
}
