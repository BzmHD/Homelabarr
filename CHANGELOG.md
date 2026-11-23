# Changelog

All notable changes to **Homelabarr** are documented in this file.

Homelabarr is a fork of [CometTools/LunaSea](https://github.com/CometTools/LunaSea) licensed under **GPL-3.0**.

---

## [v1.1.0] — 2026-11-23

### Added
- **Torrent Clients (Docker / WebUI):**
  - **qBittorrent** (WebUI API v2) — live queue, download/upload speeds, progress bars, pause/resume, remove (with optional file deletion), add magnet/URL, default category, and Test Connection.
  - **Transmission** (RPC API with automatic `X-Transmission-Session-Id` handshake & Basic Auth) — live queue, speeds, start/stop, remove, add magnet/URL, and Test Connection.
  - **Deluge** (WebUI JSON-RPC) — live queue, speeds, pause/resume, remove, add magnet/URL, and Test Connection.
- **Multi-Downloader Prowlarr Dispatch:**
  - Prowlarr Interactive Search (inside Radarr & Sonarr) and Standalone Prowlarr now detect Usenet vs. Torrent releases automatically.
  - **Usenet (NZB):** Sends directly to **NZBGet** or **SABnzbd** (with a quick picker when both are enabled).
  - **Torrents:** Sends directly to your enabled torrent client(s) (**qBittorrent**, **Transmission**, or **Deluge**).
- **Overseerr / Jellyseerr Module:**
  - **Requests** tab with 1-tap **Approve**, **Decline**, and **Delete** actions.
  - **Search** tab to find movies & TV shows and submit 1-tap requests.
  - **Trending** discovery feed with status badges.
- **Standalone Prowlarr Module:**
  - **Global Search** across all Prowlarr indexers with category filter chips (*All*, *Movies*, *TV*, *Music*, *Books*) and smart release age formatting.
  - **Indexers** tab displaying protocol, priority, enabled state, health warnings, and 1-tap **Test** per indexer.
- **Bazarr Module:**
  - **Wanted Movies** & **Wanted Episodes** tabs listing missing subtitle languages with 1-tap per-item subtitle search.
  - **Search All Missing** buttons (both per-tab and in the top AppBar to trigger Movies + Episodes together).
- **4 Live Dashboard Layouts:**
  - Tap the layout switcher icon in the Dashboard top bar to swap between **Stacked Tiles**, **2-Column Grid**, **3-Column Compact Grid**, and **Grouped by Usage** (persisted across restarts).
- **Usage-Grouped Setup Walkthrough:**
  - Rebuilt onboarding organized by usage: *Media Managers (`*arr`)*, *Indexers & Search*, *Usenet Downloaders (NZB)*, *Torrent Downloaders*, and *Requests & Monitoring*, with inline enable toggles and **Skip** on every step.

### Changed
- **Unified Settings → Configuration & Side Bar:** Merged Bazarr, Deluge, Overseerr, Prowlarr, qBittorrent, and Transmission directly into the main alphabetical **Settings → Configuration** page and unified pull-out Side Bar.
- **Instant Dashboard & Side Bar Sync:** Toggling any app on or off immediately updates both the Dashboard and the Side Bar in real time.

### Fixed
- Fixed a navigation stack issue where switching between newly added modules and the **Dashboard** from the Side Bar could replace the router root and crash.

---

## [v1.0.0] — 2026-11-23

### Added
- Initial blank-slate public release of **Homelabarr** (fork of [CometTools/LunaSea](https://github.com/CometTools/LunaSea)).
- **Inline Prowlarr Interactive Search** inside Radarr & Sonarr release screens with live **Quality Profile** verification, live **Blocklist** checking, automatic sorting of matching releases to the top, and 1-tap send to NZBGet.
- **Smart Release Age Formatting:** Shows precise hours (`h`) and minutes (`m`) for releases under 24 hours instead of `0d`.
- **4 Live Themes & Matching Native iOS Alternate App Icons:** *Forest Sage*, *Midnight Ocean*, *Obsidian Gold*, and *Crimson Noir* with custom H + mini server rack icons.
- **Guided First-Time Setup Walkthrough** with Skip on every step and Skip All.
- **iOS 26+ Support** including native `UIScene` lifecycle adoption.
