# Homelabarr

> **Fork Notice:** Homelabarr is an independent fork of **[LunaSea](https://github.com/CometTools/LunaSea)** by [Jagandeep Brar (CometTools)](https://github.com/CometTools), licensed under **GPL-3.0**.

**Homelabarr** is an all-in-one, self-hosted **iOS & Android** app for managing your `*arr` stack, Usenet & Torrent downloaders, indexers, requests, and subtitles — completely local with zero telemetry.

> See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## Supported Platforms

| Platform | Minimum Version | Install Method |
| --- | --- | --- |
| **Android** | **Android 7.0+ (API 24+)** *(targeted to Android 15 / API 35)* | Direct `.apk` install — **no 7-day re-signing required** |
| **iOS** | **iOS 26+** | Sideload unsigned `.ipa` via SideStore, AltStore, Sideloadly, or Xcode |

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

- **Cross-Platform (iOS 26+ & Android 7.0+):** Identical feature set across both platforms — direct APK install on Android (no re-signing) and SideStore auto-refresh support on iOS.
- **Inline Prowlarr Search:** Search Prowlarr directly inside Radarr & Sonarr with live Quality Profile checks, Blocklist warnings, smart hours/minutes release ages, and 1-tap send to NZBGet, SABnzbd, or your torrent client.
- **Torrent & Usenet Control:** Manage queues, speeds, pause/resume, delete, and add magnets/URLs across **qBittorrent**, **Transmission**, **Deluge**, **NZBGet**, and **SABnzbd**.
- **Readarr (eBooks & Audiobooks):** Browse library, see target format badges (`eBook` vs `Spoken`), switch formats per author, search missing books, run interactive or direct Prowlarr searches, and pick format when adding new books.
- **Overseerr, Prowlarr & Bazarr Built In:** Approve/decline/submit requests in Overseerr, run global indexer searches & tests in Prowlarr, and trigger **Search All Missing** subtitles in Bazarr.
- **Live Dashboard Status & Now Downloading:** Real-time online/speed/missing/pending badges on every Dashboard tile + a top **Now Downloading** strip with 1-tap Pause/Resume.
- **Global "Search Everything":** One Dashboard search bar querying Radarr, Sonarr, Readarr, Overseerr & Prowlarr simultaneously with 1-tap Add, Request, or Download.
- **4 Dashboard Layouts & 4 Live Themes:** Switch live between **Stacked Tiles**, **2-Column Grid**, **3-Column Compact Grid**, and **Grouped by Usage**, plus 4 themes (**Forest Sage**, **Midnight Ocean**, **Obsidian Gold**, **Crimson Noir**) with matching native Home Screen app icons on iOS.
- **Guided Setup & Full JSON Backup/Restore:** Usage-grouped First-Time Setup Walkthrough with Skip on every step, instant Dashboard/Side Bar sync, and 1-file `.json` backup/restore across iOS and Android devices.

---

## Installation

### Android (Android 7.0+ / API 24+) — Direct APK *(No Re-Signing Needed)*
1. Download `Homelabarr-v1.2.0-android.apk` from the [Releases](../../releases) page on your Android device.
2. Tap the downloaded `.apk` to install (allow **Install unknown apps** if prompted).

### iOS (iOS 26+)

Homelabarr for iOS is distributed as an unsigned `.ipa` for sideloading.

#### Option 1: SideStore *(Recommended — Auto-Refreshes Over Wi-Fi)*
1. Install [SideStore](https://sidestore.io) on your iPhone.
2. Add this repository's source URL in SideStore:
   ```
   https://raw.githubusercontent.com/nachocheese1100/Homelabarr/main/altstore-source.json
   ```
   *(Or download `Homelabarr-v1.2.0-unsigned.ipa` directly from [Releases](../../releases) and import it into SideStore.)*
3. SideStore automatically refreshes the 7-day signature over Wi-Fi without needing a computer.

#### Option 2: AltStore / Sideloadly
1. Download `Homelabarr-v1.2.0-unsigned.ipa` from the [Releases](../../releases) page.
2. Install via [AltStore](https://altstore.io) or [Sideloadly](https://sideloadly.io) using your Apple ID.

#### Option 3: Build from Source (Xcode / Android SDK)
Requires **Flutter 3.29.3** (Dart 3.7.2).

```bash
git clone https://github.com/nachocheese1100/Homelabarr.git
cd Homelabarr/lunasea
flutter pub get
# Android:
flutter build apk --release
# iOS:
cd ios && pod install && cd .. && open ios/Runner.xcworkspace
```

---

## Privacy & Blank-Slate Guarantee
- **Zero telemetry, zero accounts, zero cloud dependencies.** All server URLs, API keys, and preferences are stored locally on your device.
- Ships completely blank — no pre-filled hosts, keys, or personal data.

---

## AI-Assisted Development Disclosure
Custom features, themes, icons, and documentation added on top of upstream LunaSea were developed with AI assistance using **Google Antigravity** (powered by **Google Gemini**), and reviewed and tested directly on hardware.

---

## Attribution & License

Homelabarr is a fork of **[CometTools/LunaSea](https://github.com/CometTools/LunaSea)** (originally created by Jagandeep Brar / CometTools) and is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

- **Upstream Repository:** https://github.com/CometTools/LunaSea
- **License:** [LICENSE](LICENSE) (GPL-3.0)
