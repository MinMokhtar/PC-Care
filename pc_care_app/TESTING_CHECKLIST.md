# PC Care App — Full Feature Testing Checklist

End-to-end testing checklist for FYP demo readiness. Verify each item works
before showcase day.

---

## Setup (one-time per machine)

- [ ] PC companion `.exe` running (GUI window visible)
- [ ] PC network category = **Private** (`Get-NetConnectionProfile`)
- [ ] PC Windows Firewall allows app (Private profile)
- [ ] PC no other monitoring tools running (HWiNFO, MSI Afterburner, RGB
  software, standalone LibreHardwareMonitor) — kernel driver is single-tenant
- [ ] Phone + PC on the same network (WiFi or wired+WiFi both pointing to
  same router/hotspot)
- [ ] Phone has PC Care app installed + launched

---

## Pairing & Connection

- [ ] Connect screen — tap big Connect circle
- [ ] Scan finds your PC within ~3-5 seconds, shows hostname + IP
- [ ] Tap PC → PIN dialog appears with "Pair with [hostname]" title
- [ ] Enter the 6-digit PIN from PC GUI → tap Verify & Connect
- [ ] Lands on Home screen with green Online indicator
- [ ] PC GUI Connected Devices count = 1, shows your phone's name + IP,
  green active dot

---

## Temperature Monitor

- [ ] Tap Temperature card on Home → opens Temperature screen
- [ ] Overall temperature arc + chart visible
- [ ] CPU shows real temp (~30-50°C idle)
- [ ] GPU shows real temp (~30-50°C idle)
- [ ] Motherboard shows real temp
- [ ] Storage (SSD) shows real temp
- [ ] Values update every 3 seconds
- [ ] Chart line builds out smoothly over ~30 seconds
- [ ] Status pills (Cool/Warm/Hot) match temps

---

## Storage Manager

- [ ] Tap Storage card on Home → opens Storage screen
- [ ] All real drives visible (C: + others)
- [ ] Drive donut shows realistic used %
- [ ] Tap donut → highlights with blue border + breakdown updates
- [ ] Category breakdown (Apps/System/Media/Documents/Cache/Other) shows
  proportional sizes
- [ ] C: drive has Cache Files category, secondary drive(s) don't

---

## PC Power Screen

- [ ] Tap My PC big card on Home → opens PC Power screen
- [ ] Status card shows PC name + Online green dot
- [ ] Wake button greyed out (PC is currently online)
- [ ] Other 3 buttons (Sleep/Restart/Shutdown) enabled
- [ ] Sleep test:
  - [ ] Tap Sleep → confirm dialog → tap Sleep
  - [ ] PC enters sleep mode within 5 sec
  - [ ] Wake PC manually (keyboard/mouse) → app reconnects automatically
- [ ] Restart test (do once, then restart `.exe` on PC after reboot):
  - [ ] Tap Restart → confirm → "Restart command sent"
  - [ ] PC reboots within ~5-10 sec
  - [ ] After reboot, re-launch `.exe` on PC
  - [ ] Phone reconnects automatically

---

## Quick Actions (Home screen)

- [ ] Tap Clear Cache → confirm → snackbar "Deleted X files (Y MB)"
- [ ] Tap Defrag / Optimize Disk → confirm → snackbar "Defrag started in
  background"
- [ ] (Optional verification) Open Optimize Drives on PC to confirm it ran

---

## Wake-on-LAN (the WOW moment)

- [ ] Tap Shutdown on PC Power screen → confirm → PC shuts down
- [ ] Phone home shows Offline within ~5 sec (red dot)
- [ ] Wake button now enabled (green)
- [ ] Tap Wake → snackbar "Wake packet sent to XX:XX:XX:XX:XX:XX"
- [ ] PC boots within ~30-60 sec
- [ ] After Windows loads, manually start `.exe` (or it auto-starts if Task
  Scheduler set up)
- [ ] Phone reconnects automatically

---

## Guides Feature (works without PC)

- [ ] AR Mode — open Guides → AR Mode → pick task → camera opens → detects
  components live
- [ ] Video Guide — open Guides → Video Guide → pick task → real YouTube
  videos load
- [ ] Search bar works (type query → submit → results update)
- [ ] Filter by duration (Short/Medium/Long) works
- [ ] Sort by Relevance/Most Viewed/Newest/Highest Rated works
- [ ] Tap a video → opens in YouTube app

---

## Upgrade Planner (works without PC)

- [ ] Open Upgrade Planner → no specs message OR existing specs card
- [ ] Tap Spec Entry → fill in PC components → Save
- [ ] Back to planner — see Upgrade List with compat badge
- [ ] Pick an upgrade for any category → saves
- [ ] Review Plan button appears with ≥1 selection
- [ ] Tap Review Plan → side-by-side Current vs Upgrade comparison
- [ ] Compat banner color changes if PSU is too low

---

## Reminders (works without PC)

- [ ] Settings → Reminders → see 6 default presets (Clear Cache, Defrag, etc.)
- [ ] Toggle one ON → set time to 1-2 minutes from now
- [ ] Wait → notification fires on phone
- [ ] Edit a reminder (title / frequency / time) — saves correctly
- [ ] Add custom reminder works
- [ ] Delete reminder works

---

## Settings

- [ ] Dark Mode toggle locked ON ("Light mode coming soon" subtitle)
- [ ] Notifications master toggle works
- [ ] Reminders chevron → opens reminder management
- [ ] Disconnect from PC tile shows current host
- [ ] About App → shows version dialog

---

## Security — Connected Devices (PC GUI side)

- [ ] Phone shows in Connected Devices with model code name
- [ ] Rename button → dialog opens → type custom name (e.g. "Mokhtar's
  Poco F6") → Save
- [ ] Custom name shows bold + original underneath as subtitle
- [ ] Restart `.exe` → custom name persists (saved to `device_names.txt`)
- [ ] Activity Log updates as phone polls (every 3-5 sec entries appear)

---

## Security — Revoke flows

- [ ] PC kicks phone: Tap ✕ Disconnect on PC GUI → confirm → phone bounces
  back to Connect screen with red snackbar "Disconnected by PC owner"
- [ ] Try to re-pair after revoke: scan + enter same PIN → dialog shows
  "This phone was disconnected by the PC owner. Ask them to regenerate the
  PIN to allow it again."
- [ ] Regenerate PIN: Tap 🔄 Regenerate on PC GUI → confirm → new PIN
  displayed → revoked list cleared → re-pair with new PIN works
- [ ] Phone leaves: Settings → Disconnect from PC → phone clears credentials
  → PC GUI device list immediately removes the entry (count goes to 0)

---

## PC GUI — Other

- [ ] Copy PIN button copies to clipboard → text briefly shows "✓ Copied"
  then reverts
- [ ] Sidebar nav: Home / Settings / About work (clicking switches the right
  panel)
- [ ] Minimize to tray: Click X → window hides, balloon tip appears, tray
  icon stays in system tray
- [ ] Restore from tray: Double-click tray icon → window comes back
- [ ] Quit from tray: Right-click tray icon → Quit → app fully exits

---

## Sanity check

- [ ] Phone Home stat cards (Temperature + Storage) show real values when
  PC is on
- [ ] Phone stat cards show `--` + "Offline" when PC is off
- [ ] Online/Offline indicator on My PC card flips correctly within ~5 sec
  of state changes
