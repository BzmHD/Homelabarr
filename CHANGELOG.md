# Changelog

All notable changes to **Homelabarr** are documented in this file.

Homelabarr is a fork of [CometTools/LunaSea](https://github.com/CometTools/LunaSea) licensed under **GPL-3.0**.

---

## [v1.2.2] — 2026-11-25

### Added & Improved
- **Add Screen Search Toggle:** Added a dedicated, visible **"Start Search for Missing"** toggle switch tile (`LunaSwitch`) directly in the Add Details list alongside **"Monitor"** for both **Radarr** and **Sonarr**.
- **Linked Monitored & Search Behavior:**
  - Toggling **Monitored** to **OFF** automatically switches **Start Search** to **OFF** (preventing orphaned searches on unmonitored titles).
  - Toggling **Monitored** to **ON** automatically switches **Start Search** to **ON**.
  - **Start Search** can still be toggled independently at any time directly on the screen before adding.
- **Default Auto-Search on Add:** Set `ADD_MOVIE_SEARCH_FOR_MISSING` and `ADD_SERIES_SEARCH_FOR_MISSING` defaults to `true` across the application database tables, ensuring new additions trigger immediate indexer searches instead of remaining monitored and waiting for periodic RSS syncs.

---

## [v1.2.1] — 2026-11-24

### Fixed & Hardened
- **Global Search Stability:** Fixed `GlobalKey<ScaffoldState>` recreation inside `build()`, added HTTP timeouts & status-code validation on all Radarr/Sonarr/Readarr/Overseerr actions, guarded empty root-folder/quality-profile lists, added request sequence tracking to drop stale overlapping searches, and added per-item in-flight guards to prevent duplicate taps.
- **Backup & Restore Safety:** Added confirmation dialog before overwriting settings, automatic `Provider` state reset (`Radarr`, `Sonarr`, `Lidarr`, `NZBGet`, `SABnzbd`, `Tautulli`) immediately after restore, timestamped (`HHmmss`) filenames, and automatic temp-file cleanup after sharing.
- **Dashboard Live Status Resilience:** Wrapped refresh in `try/finally` so polling can never wedge, and enforced a 5-second timeout on torrent client polls so offline containers cannot stall the Dashboard.
- **Torrent Clients:** Added in-memory session cookie caching for qBittorrent (`SID`) and Deluge (`_session_id`) with automatic `401`/`403` refresh (preventing IP bans), fixed client-switching race conditions, disposed the Add Torrent `TextEditingController`, and added `context.mounted` guards before opening picker sheets.
- **Unified Prowlarr Config & Overseerr Deduplication:** Eliminated duplicate Prowlarr config state and added in-flight guards on Overseerr Request/Approve/Decline/Delete actions.
- **Android Permanent Release Signing:** Signed `Homelabarr-v1.2.1-android.apk` with a dedicated permanent release keystore for clean in-place upgrades going forward.

---

## [v1.2.0] — 2026-11-24

### Added
- **Readarr Module (eBooks & Audiobooks):**
  - **Library**, **Missing** (+ **Search All Missing Books**), and **Add Book** tabs.
  - Format badges on every book showing what Readarr is looking for (e.g., `eBook (EPUB)` vs. `Spoken (MP3, M4B, FLAC)`).
  - Tap any book to switch between **eBook** and **Audiobook (Spoken)** quality profiles, toggle Monitored, run **Auto Search**, **Interactive Release Search**, or **Direct Prowlarr Search**.
  - Format picker sheet when adding new books.
- **Live Dashboard Status & Unified "Now Downloading" Strip:**
  - Real-time status badges on every Dashboard tile across all 4 layouts (`Online`, `Offline`, live download speed, queued/pending/missing/wanted counts) with pull-to-refresh.
  - Combined **Now Downloading** bar at the top of the Dashboard with live aggregate speed and 1-tap Pause/Resume.
- **Global "Search Everything":**
  - Top-bar search icon on the Dashboard querying **Radarr**, **Sonarr**, **Readarr**, **Overseerr**, and **Prowlarr** simultaneously with source filter chips and 1-tap Add, Request, or Download.
- **Full Backup & Restore:**
  - Export/share a single `.json` backup (or copy to clipboard) covering all connected apps, Theme, and Dashboard Layout — and restore from file or clipboard in seconds.
- **Android Build (`Homelabarr-v1.2.0-android.apk`):**
  - Native Android release APK (`com.homelabarr.app`, Android 7.0+) with custom Homelabarr launcher icons and direct install support.

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
