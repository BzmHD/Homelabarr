# Homelabarr

> **Fork Notice:** Homelabarr is an independent, community-maintained fork of **[LunaSea](https://github.com/CometTools/LunaSea)** by [Jagandeep Brar (CometTools)](https://github.com/CometTools), redistributed under the **GNU General Public License v3.0 (GPL-3.0)**. All credit for the core application architecture and `*arr` module integrations goes to the original LunaSea project.

A modern, self-hosted iOS companion app for managing your `*arr` media stack — built on top of [CometTools/LunaSea](https://github.com/CometTools/LunaSea) with native **Prowlarr Interactive Search**, live **Quality Profile & Blocklist** verification, **4 live themes with matching native iOS app icons**, and a guided **First-Time Setup Walkthrough**.

---

## Features

### Native Prowlarr Interactive Search
- **Inline Search inside Radarr & Sonarr:** Trigger Prowlarr directly from any Movie or Episode's Interactive Search screen without switching apps.
- **Live Quality Profile Checking:** Automatically checks every Prowlarr result against the active Radarr/Sonarr Quality Profile for that title. Mismatched releases are flagged in red with an explanation dialog, and matching releases are automatically sorted to the top.
- **Live Blocklist Checking:** Cross-references your Radarr/Sonarr blocklist in real time so previously failed or rejected releases are clearly marked before you download them.
- **Smart Release Age Formatting:** Releases younger than 24 hours display precise age in hours (`h`) and minutes (`m`) instead of `0d`.
- **1-Tap Send to NZBGet:** Send any release straight to NZBGet directly from the expandable release card.

### 4 Live Themes & Matching Native iOS App Icons
Switch themes on the fly in **Settings** (or during First-Time Setup) — the app UI, navigation drawer header, and **iOS Home Screen app icon** all update together:
- **Forest Sage** *(Default)* — Deep charcoal & muted forest sage greens
- **Midnight Ocean** — Cool midnight navy & slate ocean blues
- **Obsidian Gold** — Rich obsidian dark & warm brushed gold
- **Crimson Noir** — Deep noir & refined crimson accents

### Guided First-Time Setup Walkthrough
- Clean **blank-slate** onboarding that walks you through choosing a theme and connecting **Radarr**, **Sonarr**, **Prowlarr**, **NZBGet**, **SABnzbd**, **Lidarr**, **Tautulli**, and more.
- **Skip any step** (or **Skip All**) and configure services later at your own pace.

### Full `*arr` & Homelab Module Support
Includes full support for **Radarr**, **Sonarr**, **Lidarr**, **NZBGet**, **SABnzbd**, **Tautulli**, **Overseerr**, **Prowlarr**, Newznab search, and External Modules.

---

## Installation (iOS)

Homelabarr is distributed as an unsigned `.ipa` for sideloading on iOS 15+.

### Option 1: SideStore *(Recommended — Auto-Refreshes Over Wi-Fi)*
1. Install [SideStore](https://sidestore.io) on your iPhone.
2. Add this repository's `altstore-source.json` URL as a Source in SideStore, **or** download `Homelabarr-v1.0.0-unsigned.ipa` from the [Releases](../../releases) page and import it into SideStore.
3. SideStore automatically refreshes the 7-day signature over Wi-Fi without needing a Mac/PC.

### Option 2: AltStore / Sideloadly
1. Download `Homelabarr-v1.0.0-unsigned.ipa` from the [Releases](../../releases) page.
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
