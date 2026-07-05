# PC Care

**An all-in-one PC maintenance companion — Flutter mobile app + Windows companion.**

Final Year Project by Mokhtar Amin Ahlan · 2026

---

## About

PC Care is designed to make PC maintenance simple for casual users. The mobile app pairs with a Windows companion app to monitor temperatures, plan upgrades, guide hardware repairs via AR, and clean up storage — all from your phone.

## Features

- 📷 **AR Guide** — Point your camera to detect PC components and follow step-by-step maintenance guides
- 🌡️ **Live Temp** — Monitor CPU, GPU, motherboard, and SSD temperatures in real time
- 📋 **Upgrade Plan** — Find compatible hardware upgrades based on your current PC specs
- 💾 **Storage Cleanup** — Free up disk space by clearing junk files with one tap
- 🔔 **Reminders** — Set custom maintenance reminders (dust cleaning, driver updates, defrag, etc.)
- ⚡ **PC Power** — Wake, sleep, restart, or shut down your PC remotely (Wake-on-LAN)

## Project Structure

```
PC-Care/
├── pc_care_app/          → Flutter mobile app (Android)
├── PcCareCompanion/      → Windows companion app (.NET 8)
└── README.md             → You are here
```

## Download

Grab the latest release from the [Releases page](../../releases):

| File | For | Required for |
|------|-----|--------------|
| `PCCare-vX.X.apk` | Android phone | Everything |
| `PcCareCompanion-vX.X.zip` | Windows PC | Connect Mode (real PC data) |

If you just want to try it, install only the APK and use **Demo Mode**.

## Requirements

**Mobile app**
- Android 8.0 or higher
- Camera permission (for AR features)
- ~50 MB storage

**Companion app** (optional — only for Connect Mode)
- Windows 10 or 11
- Admin privileges (for kernel-mode sensor access)
- Same Wi-Fi network as your phone

## How It Works

1. Install the APK on your Android phone
2. (Optional) Install the Windows companion on your PC for real-time data
3. Open the app and choose **Demo Mode** or **Connect Mode**
4. Explore the four features from your phone

## Technology Stack

**Mobile app**
- Flutter (Dart) — cross-platform framework
- YOLOv11 nano (ONNX) — on-device AR object detection
- flutter_local_notifications — scheduled reminders
- YouTube Data API v3 — video tutorial integration

**Windows companion**
- .NET 8 + WinForms — Windows companion app
- ASP.NET Core Minimal API — local HTTP server
- LibreHardwareMonitorLib — CPU/GPU/motherboard/SSD sensors
- Windows System.IO.DriveInfo — storage info

## License

This project is a Final Year Project for academic use. Feel free to explore the code for educational purposes.

---

**Developed by Mokhtar Amin Ahlan**
Final Year Project · 2026
