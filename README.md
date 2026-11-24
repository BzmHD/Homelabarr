# Homelabarr

> **Fork Notice:** Homelabarr is an independent fork of **[LunaSea](https://github.com/CometTools/LunaSea)** by [Jagandeep Brar (CometTools)](https://github.com/CometTools), licensed under **GPL-3.0**.

**Homelabarr** is an all-in-one, self-hosted **iOS (26+) & Android (7.0+)** app for managing your `*arr` stack, Usenet & Torrent downloaders, indexers, requests, and subtitles — completely local with zero telemetry.

> See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## Supported Apps

| Category | Apps Included |
| --- | --- |
| **Media Managers (`*arr`)** | **Radarr** (Movies), **Sonarr** (TV Shows), **Lidarr** (Music), **Readarr** (eBooks & Audiobooks), **Bazarr** (Subtitles) |
| **Indexers & Search** | **Prowlarr** (Inline + Standalone), Newznab Search |
| **Usenet Downloaders (NZB)** | **NZBGet**, **SABnzbd** |
| **Torrent Clients (Docker / WebUI)** | **qBittorrent**, **Transmission**, **Deluge** |
| **Requests & Monitoring** | **Overseerr / Jellyseerr**, **Tautulli** (Plex Stats), External Modules, Wake on LAN |

---

## Features

- **Inline Prowlarr Search:** Search Prowlarr directly inside Radarr & Sonarr with live Quality Profile checks, Blocklist warnings, smart hours/minutes release ages, and 1-tap send to NZBGet, SABnzbd, or your torrent client.
- **Torrent & Usenet Control:** Manage queues, speeds, pause/resume, delete, and add magnets/URLs across **qBittorrent**, **Transmission**, **Deluge**, **NZBGet**, and **SABnzbd**.
- **Overseerr, Prowlarr & Bazarr Built In:** Approve/decline/submit requests in Overseerr, run global indexer searches & tests in Prowlarr, and trigger **Search All Missing** subtitles in Bazarr.
- **Readarr (eBooks & Audiobooks):** Browse library, see target format badges (`eBook` vs `Spoken`), switch formats per author, search missing books, run interactive or direct Prowlarr searches, and choose format when adding new books.
- **Live Dashboard Status & Now Downloading:** Real-time online/speed/missing/pending badges on every Dashboard tile (across all 4 layouts) + a top **Now Downloading** strip with 1-tap Pause/Resume.
- **Global "Search Everything":** One Dashboard search bar querying Radarr, Sonarr, Readarr, Overseerr & Prowlarr simultaneously with 1-tap Add, Request, or Download.
- **Full JSON Backup & Restore:** Export/share or import all connected apps, credentials, theme, and Dashboard layout in one `.json` file.
- **4 Dashboard Layouts:** Switch live between **Stacked Tiles**, **2-Column Grid**, **3-Column Compact Grid**, and **Grouped by Usage**.
- **4 Themes & Matching iOS Icons:** Live theme switching (**Forest Sage**, **Midnight Ocean**, **Obsidian Gold**, **Crimson Noir**) with matching Home Screen app icons.
- **Guided Setup & Instant Sync:** Usage-grouped First-Time Setup Walkthrough with Skip on every step; enabling any app adds it immediately to your Dashboard and Side Bar.

---

## Installation

### Android (Android 7.0+) — Direct APK *(No Re-Signing Needed)*
1. Download `Homelabarr-v1.2.0-android.apk` from the [Releases](../../releases) page on your Android device.
2. Tap the downloaded `.apk` to install (allow **Install unknown apps** if prompted).

### iOS (iOS 26+)

Homelabarr for iOS is distributed as an unsigned `.ipa` for sideloading.

### Option 1: SideStore *(Recommended — Auto-Refreshes Over Wi-Fi)*
1. Install [SideStore](https://sidestore.io) on your iPhone.
2. Add this repository's source URL in SideStore:
   ```
   https://raw.githubusercontent.com/nachocheese1100/Homelabarr/main/altstore-source.json
   ```
   *(Or download `Homelabarr-v1.2.0-unsigned.ipa` directly from [Releases](../../releases) and import it into SideStore.)*
3. SideStore automatically refreshes the 7-day signature over Wi-Fi without needing a computer.

### Option 2: AltStore / Sideloadly
1. Download `Homelabarr-v1.2.0-unsigned.ipa` from the [Releases](../../releases) page.
2. Install via [AltStore](https://altstore.io) or [Sideloadly](https://sideloadly.io) using your Apple ID.

### Option 3: Build from Source (Xcode)
Requires **Flutter 3.29.3** (Dart 3.7.2), **CocoaPods**, and **Xcode**.

```bash
git clone https://github.com/nachocheese1100/Homelabarr.git
cd Homelabarr/lunasea
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode:
1. Select the `Runner` target → **Signing & Capabilities**.
2. Choose your Apple Developer Team and set a unique Bundle Identifier (e.g., `com.yourname.homelabarr`).
3. Connect your iPhone and click **Run** (or run `flutter run --release`).

---

## Privacy & Blank-Slate Guarantee
- **Zero telemetry, zero accounts, zero cloud dependencies.** All server URLs, API keys, and preferences are stored locally on your device.
- Ships completely blank — no pre-filled hosts, keys, or personal data.

---

## AI-Assisted Development Disclosure
Custom features, themes, icons, and documentation added on top of upstream LunaSea were developed with AI assistance using **Google Antigravity** (powered by **Google Gemini**), and reviewed and tested directly on iOS hardware.

---

## Attribution & License

Homelabarr is a fork of **[CometTools/LunaSea](https://github.com/CometTools/LunaSea)** (originally created by Jagandeep Brar / CometTools) and is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

- **Upstream Repository:** https://github.com/CometTools/LunaSea
- **License:** [LICENSE](LICENSE) (GPL-3.0)
