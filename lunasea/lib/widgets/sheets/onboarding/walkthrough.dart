import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/lidarr.dart';
import 'package:lunasea/modules/nzbget.dart';
import 'package:lunasea/modules/radarr.dart';
import 'package:lunasea/modules/sabnzbd.dart';
import 'package:lunasea/modules/sonarr.dart';
import 'package:lunasea/modules/tautulli.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/sheet.dart';
import 'package:lunasea/widgets/ui/homelabarr_themes.dart';

class HomelabarrWalkthrough {
  static const String _doneKey = 'HOMELABARR_ONBOARDING_DONE_V1';

  static bool get isCompleted => LunaBox.lunasea.read(_doneKey) == true;

  static Future<void> markCompleted() async {
    await LunaBox.lunasea.update(_doneKey, true);
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    if (isCompleted) return;
    await show(context);
  }

  static Future<void> show(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _WalkthroughPage(),
      ),
    );
  }
}

class _WalkthroughPage extends StatefulWidget {
  const _WalkthroughPage();

  @override
  State<_WalkthroughPage> createState() => _WalkthroughPageState();
}

class _WalkthroughPageState extends State<_WalkthroughPage> {
  int _step = 0;
  static const int _totalSteps = 8;

  // Media Managers (*arr)
  late bool _sonarrEnabled;
  late TextEditingController _sonarrHost;
  late TextEditingController _sonarrKey;

  late bool _radarrEnabled;
  late TextEditingController _radarrHost;
  late TextEditingController _radarrKey;

  late bool _lidarrEnabled;
  late TextEditingController _lidarrHost;
  late TextEditingController _lidarrKey;

  late bool _bazarrEnabled;
  late TextEditingController _bazarrHost;
  late TextEditingController _bazarrKey;

  // Indexers & Search
  late bool _prowlarrEnabled;
  late TextEditingController _prowlarrHost;
  late TextEditingController _prowlarrKey;

  // Usenet Downloaders (NZB)
  late bool _nzbgetEnabled;
  late TextEditingController _nzbgetHost;
  late TextEditingController _nzbgetUser;
  late TextEditingController _nzbgetPass;

  late bool _sabEnabled;
  late TextEditingController _sabHost;
  late TextEditingController _sabKey;

  // Torrent Downloaders
  late bool _qbitEnabled;
  late TextEditingController _qbitHost;
  late TextEditingController _qbitUser;
  late TextEditingController _qbitPass;
  late TextEditingController _qbitCat;

  late bool _transEnabled;
  late TextEditingController _transHost;
  late TextEditingController _transUser;
  late TextEditingController _transPass;

  late bool _delugeEnabled;
  late TextEditingController _delugeHost;
  late TextEditingController _delugePass;

  // Requests & Monitoring
  late bool _overseerrEnabled;
  late TextEditingController _overseerrHost;
  late TextEditingController _overseerrKey;

  late bool _tautulliEnabled;
  late TextEditingController _tautulliHost;
  late TextEditingController _tautulliKey;

  @override
  void initState() {
    super.initState();
    final p = LunaProfile.current;

    _sonarrEnabled = p.sonarrEnabled;
    _sonarrHost = TextEditingController(text: p.sonarrHost);
    _sonarrKey = TextEditingController(text: p.sonarrKey);

    _radarrEnabled = p.radarrEnabled;
    _radarrHost = TextEditingController(text: p.radarrHost);
    _radarrKey = TextEditingController(text: p.radarrKey);

    _lidarrEnabled = p.lidarrEnabled;
    _lidarrHost = TextEditingController(text: p.lidarrHost);
    _lidarrKey = TextEditingController(text: p.lidarrKey);

    _bazarrEnabled = HomelabarrDevConfig.bazarrEnabled;
    _bazarrHost = TextEditingController(text: HomelabarrDevConfig.bazarrHost);
    _bazarrKey = TextEditingController(text: HomelabarrDevConfig.bazarrApiKey);

    _prowlarrEnabled = HomelabarrDevConfig.prowlarrEnabled;
    _prowlarrHost = TextEditingController(text: ProwlarrConfig.host);
    _prowlarrKey = TextEditingController(text: ProwlarrConfig.apiKey);

    _nzbgetEnabled = p.nzbgetEnabled;
    _nzbgetHost = TextEditingController(text: p.nzbgetHost);
    _nzbgetUser = TextEditingController(text: p.nzbgetUser);
    _nzbgetPass = TextEditingController(text: p.nzbgetPass);

    _sabEnabled = p.sabnzbdEnabled;
    _sabHost = TextEditingController(text: p.sabnzbdHost);
    _sabKey = TextEditingController(text: p.sabnzbdKey);

    _qbitEnabled = HomelabarrDevConfig.qbitEnabled;
    _qbitHost = TextEditingController(text: HomelabarrDevConfig.qbitHost);
    _qbitUser = TextEditingController(text: HomelabarrDevConfig.qbitUser);
    _qbitPass = TextEditingController(text: HomelabarrDevConfig.qbitPass);
    _qbitCat = TextEditingController(text: HomelabarrDevConfig.qbitCategory);

    _transEnabled = HomelabarrDevConfig.transEnabled;
    _transHost = TextEditingController(text: HomelabarrDevConfig.transHost);
    _transUser = TextEditingController(text: HomelabarrDevConfig.transUser);
    _transPass = TextEditingController(text: HomelabarrDevConfig.transPass);

    _delugeEnabled = HomelabarrDevConfig.delugeEnabled;
    _delugeHost = TextEditingController(text: HomelabarrDevConfig.delugeHost);
    _delugePass = TextEditingController(text: HomelabarrDevConfig.delugePass);

    _overseerrEnabled = HomelabarrDevConfig.overseerrEnabled;
    _overseerrHost = TextEditingController(text: HomelabarrDevConfig.overseerrHost);
    _overseerrKey = TextEditingController(text: HomelabarrDevConfig.overseerrApiKey);

    _tautulliEnabled = p.tautulliEnabled;
    _tautulliHost = TextEditingController(text: p.tautulliHost);
    _tautulliKey = TextEditingController(text: p.tautulliKey);
  }

  @override
  void dispose() {
    for (final c in [
      _sonarrHost, _sonarrKey,
      _radarrHost, _radarrKey,
      _lidarrHost, _lidarrKey,
      _bazarrHost, _bazarrKey,
      _prowlarrHost, _prowlarrKey,
      _nzbgetHost, _nzbgetUser, _nzbgetPass,
      _sabHost, _sabKey,
      _qbitHost, _qbitUser, _qbitPass, _qbitCat,
      _transHost, _transUser, _transPass,
      _delugeHost, _delugePass,
      _overseerrHost, _overseerrKey,
      _tautulliHost, _tautulliKey,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveCurrentStep() async {
    final key = LunaSeaDatabase.ENABLED_PROFILE.read();
    final p = LunaBox.profiles.read(key) ?? LunaProfile();

    if (_step == 2) {
      // Media Managers (*arr)
      p.sonarrEnabled = _sonarrEnabled;
      p.sonarrHost = _sonarrHost.text.trim();
      p.sonarrKey = _sonarrKey.text.trim();

      p.radarrEnabled = _radarrEnabled;
      p.radarrHost = _radarrHost.text.trim();
      p.radarrKey = _radarrKey.text.trim();

      p.lidarrEnabled = _lidarrEnabled;
      p.lidarrHost = _lidarrHost.text.trim();
      p.lidarrKey = _lidarrKey.text.trim();

      await LunaBox.profiles.update(key, p);

      HomelabarrDevConfig.bazarrEnabled = _bazarrEnabled;
      HomelabarrDevConfig.bazarrHost = _bazarrHost.text.trim();
      HomelabarrDevConfig.bazarrApiKey = _bazarrKey.text.trim();

      if (mounted) {
        context.read<SonarrState>().reset();
        context.read<RadarrState>().reset();
        context.read<LidarrState>().reset();
      }
    } else if (_step == 3) {
      // Indexers & Search
      HomelabarrDevConfig.prowlarrEnabled = _prowlarrEnabled;
      ProwlarrConfig.host = _prowlarrHost.text.trim();
      ProwlarrConfig.apiKey = _prowlarrKey.text.trim();
      HomelabarrDevConfig.prowlarrHost = _prowlarrHost.text.trim();
      HomelabarrDevConfig.prowlarrApiKey = _prowlarrKey.text.trim();
    } else if (_step == 4) {
      // Usenet Downloaders (NZB)
      p.nzbgetEnabled = _nzbgetEnabled;
      p.nzbgetHost = _nzbgetHost.text.trim();
      p.nzbgetUser = _nzbgetUser.text.trim();
      p.nzbgetPass = _nzbgetPass.text.trim();

      p.sabnzbdEnabled = _sabEnabled;
      p.sabnzbdHost = _sabHost.text.trim();
      p.sabnzbdKey = _sabKey.text.trim();

      await LunaBox.profiles.update(key, p);
      HomelabarrDevConfig.notify();
      if (mounted) {
        context.read<NZBGetState>().reset();
        context.read<SABnzbdState>().reset();
      }
    } else if (_step == 5) {
      // Torrent Downloaders
      HomelabarrDevConfig.qbitEnabled = _qbitEnabled;
      HomelabarrDevConfig.qbitHost = _qbitHost.text.trim();
      HomelabarrDevConfig.qbitUser = _qbitUser.text.trim();
      HomelabarrDevConfig.qbitPass = _qbitPass.text;
      HomelabarrDevConfig.qbitCategory = _qbitCat.text.trim();

      HomelabarrDevConfig.transEnabled = _transEnabled;
      HomelabarrDevConfig.transHost = _transHost.text.trim();
      HomelabarrDevConfig.transUser = _transUser.text.trim();
      HomelabarrDevConfig.transPass = _transPass.text;

      HomelabarrDevConfig.delugeEnabled = _delugeEnabled;
      HomelabarrDevConfig.delugeHost = _delugeHost.text.trim();
      HomelabarrDevConfig.delugePass = _delugePass.text;
    } else if (_step == 6) {
      // Requests & Monitoring
      HomelabarrDevConfig.overseerrEnabled = _overseerrEnabled;
      HomelabarrDevConfig.overseerrHost = _overseerrHost.text.trim();
      HomelabarrDevConfig.overseerrApiKey = _overseerrKey.text.trim();

      p.tautulliEnabled = _tautulliEnabled;
      p.tautulliHost = _tautulliHost.text.trim();
      p.tautulliKey = _tautulliKey.text.trim();
      await LunaBox.profiles.update(key, p);
      HomelabarrDevConfig.notify();
      if (mounted) {
        context.read<TautulliState>().reset();
      }
    }
  }

  Future<void> _next({bool save = true}) async {
    if (save) await _saveCurrentStep();
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    await HomelabarrWalkthrough.markCompleted();
    HomelabarrDevConfig.notify();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: LunaColours.white, fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          labelStyle: const TextStyle(color: LunaColours.grey, fontSize: 12.5),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: LunaColours.blueGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: LunaColours.blueGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: HomelabarrTheme.current.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _groupHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: HomelabarrTheme.current.accent, size: 40),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: HomelabarrTheme.current.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            color: HomelabarrTheme.current.grey,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _appToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required List<Widget> fields,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LunaColours.secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? HomelabarrTheme.current.accent.withValues(alpha: 0.65) : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              icon,
              color: enabled ? HomelabarrTheme.current.accent : LunaColours.grey,
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: LunaColours.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: LunaColours.grey, fontSize: 12),
            ),
            activeColor: HomelabarrTheme.current.accent,
            value: enabled,
            onChanged: onToggle,
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(children: fields),
            ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                LunaAssets.brandingLogo,
                width: 112,
                height: 112,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Homelabarr',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: LunaColours.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Let\'s set up your stack by category — Media Managers, Indexers, Usenet & Torrent Downloaders, and Request/Monitoring apps.\n\nToggle on only the apps you use. Anything you enable is added right to your Dashboard and Side Bar.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: LunaColours.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupHeader(
              icon: Icons.palette_rounded,
              title: 'Theme & App Icon',
              subtitle: 'Pick your color palette and matching iPhone Home Screen icon. You can switch anytime in Settings.',
            ),
            const HomelabarrThemePicker(),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupHeader(
              icon: Icons.video_library_rounded,
              title: 'Media Managers (*arr)',
              subtitle: 'Turn on the library managers you run for TV, Movies, Music, and Subtitles.',
            ),
            _appToggleCard(
              title: 'Sonarr',
              subtitle: 'TV shows, calendar & episode search',
              icon: Icons.tv_rounded,
              enabled: _sonarrEnabled,
              onToggle: (v) => setState(() => _sonarrEnabled = v),
              fields: [
                _field('Sonarr Host URL', _sonarrHost, hint: 'http://192.168.1.x:8989'),
                _field('Sonarr API Key', _sonarrKey),
              ],
            ),
            _appToggleCard(
              title: 'Radarr',
              subtitle: 'Movies, quality profiles & interactive search',
              icon: Icons.movie_rounded,
              enabled: _radarrEnabled,
              onToggle: (v) => setState(() => _radarrEnabled = v),
              fields: [
                _field('Radarr Host URL', _radarrHost, hint: 'http://192.168.1.x:7878'),
                _field('Radarr API Key', _radarrKey),
              ],
            ),
            _appToggleCard(
              title: 'Lidarr',
              subtitle: 'Music library & albums',
              icon: Icons.music_note_rounded,
              enabled: _lidarrEnabled,
              onToggle: (v) => setState(() => _lidarrEnabled = v),
              fields: [
                _field('Lidarr Host URL', _lidarrHost, hint: 'http://192.168.1.x:8686'),
                _field('Lidarr API Key', _lidarrKey),
              ],
            ),
            _appToggleCard(
              title: 'Bazarr',
              subtitle: 'Wanted subtitles & 1-tap subtitle search',
              icon: Icons.subtitles_rounded,
              enabled: _bazarrEnabled,
              onToggle: (v) => setState(() => _bazarrEnabled = v),
              fields: [
                _field('Bazarr Host URL', _bazarrHost, hint: 'http://192.168.1.x:6767'),
                _field('Bazarr API Key', _bazarrKey),
              ],
            ),
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupHeader(
              icon: Icons.travel_explore_rounded,
              title: 'Indexers & Search',
              subtitle: 'Connect Prowlarr for inline Radarr/Sonarr search, quality profile & blocklist checks, and global indexer search.',
            ),
            _appToggleCard(
              title: 'Prowlarr',
              subtitle: 'Indexer manager & direct interactive search',
              icon: Icons.travel_explore_rounded,
              enabled: _prowlarrEnabled,
              onToggle: (v) => setState(() => _prowlarrEnabled = v),
              fields: [
                _field('Prowlarr Host URL', _prowlarrHost, hint: 'http://192.168.1.x:9696'),
                _field('Prowlarr API Key', _prowlarrKey),
              ],
            ),
          ],
        );

      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupHeader(
              icon: Icons.cloud_download_rounded,
              title: 'Usenet Downloaders (NZB)',
              subtitle: 'Enable NZBGet and/or SABnzbd to monitor queues and 1-tap send NZBs from Prowlarr.',
            ),
            _appToggleCard(
              title: 'NZBGet',
              subtitle: 'Usenet download queue & history',
              icon: Icons.download_rounded,
              enabled: _nzbgetEnabled,
              onToggle: (v) => setState(() => _nzbgetEnabled = v),
              fields: [
                _field('NZBGet Host URL', _nzbgetHost, hint: 'http://192.168.1.x:6789'),
                _field('Username', _nzbgetUser),
                _field('Password', _nzbgetPass, obscure: true),
              ],
            ),
            _appToggleCard(
              title: 'SABnzbd',
              subtitle: 'Usenet downloader with Prowlarr picker support',
              icon: Icons.cloud_download_rounded,
              enabled: _sabEnabled,
              onToggle: (v) => setState(() => _sabEnabled = v),
              fields: [
                _field('SABnzbd Host URL', _sabHost, hint: 'http://192.168.1.x:8080'),
                _field('SABnzbd API Key', _sabKey),
              ],
            ),
          ],
        );

      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupHeader(
              icon: Icons.downloading_rounded,
              title: 'Torrent Downloaders',
              subtitle: 'Turn on any Docker / WebUI torrent clients you run. Enabled clients appear on your Dashboard, Side Bar, and Prowlarr torrent picker.',
            ),
            _appToggleCard(
              title: 'qBittorrent',
              subtitle: 'WebUI API v2 • queue, pause/resume, magnets',
              icon: Icons.downloading_rounded,
              enabled: _qbitEnabled,
              onToggle: (v) => setState(() => _qbitEnabled = v),
              fields: [
                _field('qBittorrent Host URL', _qbitHost, hint: 'http://192.168.1.x:8080'),
                _field('Username', _qbitUser),
                _field('Password', _qbitPass, obscure: true),
                _field('Default Category (optional)', _qbitCat, hint: 'radarr / tv-sonarr'),
              ],
            ),
            _appToggleCard(
              title: 'Transmission',
              subtitle: 'RPC API • queue, start/stop, add torrents',
              icon: Icons.swap_vert_circle_rounded,
              enabled: _transEnabled,
              onToggle: (v) => setState(() => _transEnabled = v),
              fields: [
                _field('Transmission Host URL', _transHost, hint: 'http://192.168.1.x:9091'),
                _field('Username (optional)', _transUser),
                _field('Password (optional)', _transPass, obscure: true),
              ],
            ),
            _appToggleCard(
              title: 'Deluge',
              subtitle: 'WebUI JSON-RPC • queue & magnet support',
              icon: Icons.water_drop_rounded,
              enabled: _delugeEnabled,
              onToggle: (v) => setState(() => _delugeEnabled = v),
              fields: [
                _field('Deluge Host URL', _delugeHost, hint: 'http://192.168.1.x:8112'),
                _field('WebUI Password', _delugePass, obscure: true),
              ],
            ),
          ],
        );

      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupHeader(
              icon: Icons.movie_filter_rounded,
              title: 'Requests & Monitoring',
              subtitle: 'Add media request management and Plex streaming stats to your dashboard.',
            ),
            _appToggleCard(
              title: 'Overseerr / Jellyseerr',
              subtitle: 'Discover trending titles, submit & approve requests',
              icon: Icons.movie_filter_rounded,
              enabled: _overseerrEnabled,
              onToggle: (v) => setState(() => _overseerrEnabled = v),
              fields: [
                _field('Overseerr Host URL', _overseerrHost, hint: 'http://192.168.1.x:5055'),
                _field('API Key', _overseerrKey),
              ],
            ),
            _appToggleCard(
              title: 'Tautulli',
              subtitle: 'Plex activity, streams & watch history',
              icon: Icons.analytics_rounded,
              enabled: _tautulliEnabled,
              onToggle: (v) => setState(() => _tautulliEnabled = v),
              fields: [
                _field('Tautulli Host URL', _tautulliHost, hint: 'http://192.168.1.x:8181'),
                _field('API Key', _tautulliKey),
              ],
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.check_circle_rounded, color: HomelabarrTheme.current.accent, size: 64),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Homelabarr is Ready',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LunaColours.white),
              ),
            ),
            const SizedBox(height: 16),
            _summaryGroup('Media Managers', [
              if (_sonarrEnabled) 'Sonarr',
              if (_radarrEnabled) 'Radarr',
              if (_lidarrEnabled) 'Lidarr',
              if (_bazarrEnabled) 'Bazarr',
            ]),
            _summaryGroup('Indexers & Search', [
              if (_prowlarrEnabled) 'Prowlarr',
            ]),
            _summaryGroup('Usenet Downloaders', [
              if (_nzbgetEnabled) 'NZBGet',
              if (_sabEnabled) 'SABnzbd',
            ]),
            _summaryGroup('Torrent Downloaders', [
              if (_qbitEnabled) 'qBittorrent',
              if (_transEnabled) 'Transmission',
              if (_delugeEnabled) 'Deluge',
            ]),
            _summaryGroup('Requests & Monitoring', [
              if (_overseerrEnabled) 'Overseerr',
              if (_tautulliEnabled) 'Tautulli',
            ]),
          ],
        );
    }
  }

  Widget _summaryGroup(String groupName, List<String> enabledApps) {
    final active = enabledApps.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LunaColours.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            groupName,
            style: const TextStyle(color: LunaColours.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              active ? enabledApps.join(', ') : 'Skipped',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: active ? HomelabarrTheme.current.accent : LunaColours.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / _totalSteps;
    return Scaffold(
      backgroundColor: LunaColours.primary,
      appBar: AppBar(
        backgroundColor: LunaColours.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LunaColours.white, size: 20),
                onPressed: () => setState(() => _step--),
              )
            : null,
        title: Text(
          'Step ${_step + 1} of $_totalSteps',
          style: const TextStyle(color: LunaColours.grey, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_step < _totalSteps - 1)
            TextButton(
              onPressed: _finish,
              child: const Text(
                'Skip All',
                style: TextStyle(color: LunaColours.grey, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: LunaColours.secondary,
                  valueColor: AlwaysStoppedAnimation<Color>(HomelabarrTheme.current.accent),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepBody(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                children: [
                  if (_step > 0 && _step < _totalSteps - 1)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LunaColours.grey,
                          side: const BorderSide(color: LunaColours.blueGrey),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _next(save: false),
                        child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (_step > 0 && _step < _totalSteps - 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HomelabarrTheme.current.accent,
                        foregroundColor: LunaColours.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _next(save: true),
                      child: Text(
                        _step == 0
                            ? 'Get Started'
                            : (_step == _totalSteps - 1 ? 'Start Using Homelabarr' : 'Save & Continue'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
