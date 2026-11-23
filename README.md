# Homelabarr

> **Fork Notice:** Homelabarr is an independent, community-maintained fork of **[LunaSea](https://github.com/CometTools/LunaSea)** by [Jagandeep Brar (CometTools)](https://github.com/CometTools), redistributed under the **GNU General Public License v3.0 (GPL-3.0)**. All credit for the core application architecture and base `*arr` integrations goes to the original LunaSea project.

**Homelabarr** is an all-in-one, self-hosted iOS app for managing your media server stack (`*arr` apps, Usenet & Torrent downloaders, indexers, requests, and subtitles) — with zero telemetry, zero cloud accounts, and full local control.

> See [CHANGELOG.md](CHANGELOG.md) for full version history.

---

## Supported Apps

| Category | Apps Included |
| --- | --- |
| **Media Managers (`*arr`)** | **Radarr** (Movies), **Sonarr** (TV Shows), **Lidarr** (Music), **Bazarr** (Subtitles) |
| **Indexers & Search** | **Prowlarr** (Inline + Standalone), Newznab Search |
| **Usenet Downloaders (NZB)** | **NZBGet**, **SABnzbd** |
| **Torrent Clients (Docker / WebUI)** | **qBittorrent**, **Transmission**, **Deluge** |
| **Requests & Monitoring** | **Overseerr / Jellyseerr**, **Tautulli** (Plex Stats), External Modules, Wake on LAN |

---

## Key Features

### 1. Native Prowlarr Interactive Search
- **Built Directly into Radarr & Sonarr:** Search Prowlarr right inside any movie or episode's release screen — no switching apps.
- **Automatic Quality Profile Checks:** Every release is checked against that title's active Radarr/Sonarr Quality Profile. Matching releases are sorted to the top, while mismatched releases are clearly flagged in red with the exact reason.
- **Live Blocklist Warnings:** Automatically cross-checks your Radarr/Sonarr blocklist so previously failed or rejected releases are highlighted before you download them.
- **Smart Release Age:** Releases posted less than 24 hours ago show exact hours (`h`) and minutes (`m`) instead of `0d`.
- **Smart 1-Tap Download Dispatch:**
  - **NZB releases** go straight to **NZBGet** or **SABnzbd** (with a quick picker if you use both).
  - **Torrent releases** go straight to **qBittorrent**, **Transmission**, or **Deluge**.

### 2. Full Torrent & Usenet Downloader Control
- **qBittorrent, Transmission & Deluge:** Monitor live download/upload speeds and progress bars, pause or resume torrents, remove torrents (with optional file deletion), and paste magnet links or `.torrent` URLs directly from your iPhone.
- **NZBGet & SABnzbd:** Full queue, speed, history, and 1-tap send support.

### 3. Overseerr / Jellyseerr, Standalone Prowlarr & Bazarr
- **Overseerr / Jellyseerr:** Browse **Trending** movies and TV shows, search and submit new requests, and **Approve, Decline, or Delete** pending requests in one tap.
- **Standalone Prowlarr:** Run global searches across all your indexers with category filters (*All, Movies, TV, Music, Books*), view indexer health warnings, and **Test** any indexer directly.
- **Bazarr:** View movies and episodes missing subtitles, trigger 1-tap per-item searches, or tap **Search All Missing** to scan your whole wanted list.

### 4. Customizable Dashboard Layouts
Tap the layout button in the Dashboard top bar to switch instantly between 4 visual styles:
- **Stacked Tiles** — Classic full-width cards with descriptions
- **2-Column Grid** — Modern side-by-side cards with icon badges
- **3-Column Compact Grid** — App-launcher style compact icon tiles
- **Grouped by Usage** — Organized into *Media Managers*, *Indexers & Search*, *Downloaders*, *Requests & Monitoring*, and *System & Tools*

### 5. 4 Live Themes & Matching Native iOS App Icons
Switch themes anytime in **Settings** or during onboarding — the entire UI, drawer header, and **iPhone Home Screen app icon** update together:
- **Forest Sage** *(Default)* — Deep charcoal & muted forest sage greens
- **Midnight Ocean** — Cool midnight navy & slate ocean blues
- **Obsidian Gold** — Rich obsidian dark & warm brushed gold
- **Crimson Noir** — Deep noir & refined crimson accents

### 6. Usage-Grouped First-Time Setup & Unified Configuration
- **Guided Setup Walkthrough:** Walks you through your stack by category (*Media Managers*, *Indexers*, *Usenet*, *Torrents*, *Requests & Monitoring*) with **Skip** on every step and **Skip All**.
- **Instant Dashboard & Side Bar Sync:** Turning any app on in **Settings → Configuration** (or during setup) immediately adds it to both your Dashboard and pull-out Side Bar.

---

## Installation (iOS 15+)

Homelabarr is distributed as an unsigned `.ipa` for sideloading.

### Option 1: SideStore *(Recommended — Auto-Refreshes Over Wi-Fi)*
1. Install [SideStore](https://sidestore.io) on your iPhone.
2. Add this repository's source URL in SideStore:
   ```
   https://raw.githubusercontent.com/BzmHD/Homelabarr/main/altstore-source.json
   ```
   *(Or download `Homelabarr-v1.1.0-unsigned.ipa` directly from [Releases](../../releases) and import it into SideStore.)*
3. SideStore automatically refreshes the 7-day signature over Wi-Fi without needing a computer.

### Option 2: AltStore / Sideloadly
1. Download `Homelabarr-v1.1.0-unsigned.ipa` from the [Releases](../../releases) page.
2. Install via [AltStore](https://altstore.io) or [Sideloadly](https://sideloadly.io) using your Apple ID.

### Option 3: Build from Source (Xcode)
Requires **Flutter 3.29.3** (Dart 3.7.2), **CocoaPods**, and **Xcode**.

```bash
git clone https://github.com/BzmHD/Homelabarr.git
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

## Attribution & License

Homelabarr is a fork of **[CometTools/LunaSea](https://github.com/CometTools/LunaSea)** (originally created by Jagandeep Brar / CometTools) and is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

- **Upstream Repository:** https://github.com/CometTools/LunaSea
- **License:** [LICENSE](LICENSE) (GPL-3.0)
