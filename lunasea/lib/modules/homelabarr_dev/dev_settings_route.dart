import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/download_clients_api.dart';

class HomelabarrDevSettingsRoute extends StatefulWidget {
  final String? filterApp;

  const HomelabarrDevSettingsRoute({Key? key, this.filterApp}) : super(key: key);

  @override
  State<HomelabarrDevSettingsRoute> createState() => _HomelabarrDevSettingsRouteState();
}

class _HomelabarrDevSettingsRouteState extends State<HomelabarrDevSettingsRoute> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // qBittorrent
  bool _qbitEnabled = HomelabarrDevConfig.qbitEnabled;
  final _qbitHost = TextEditingController(text: HomelabarrDevConfig.qbitHost);
  final _qbitUser = TextEditingController(text: HomelabarrDevConfig.qbitUser);
  final _qbitPass = TextEditingController(text: HomelabarrDevConfig.qbitPass);
  final _qbitCat = TextEditingController(text: HomelabarrDevConfig.qbitCategory);

  // Transmission
  bool _transEnabled = HomelabarrDevConfig.transEnabled;
  final _transHost = TextEditingController(text: HomelabarrDevConfig.transHost);
  final _transUser = TextEditingController(text: HomelabarrDevConfig.transUser);
  final _transPass = TextEditingController(text: HomelabarrDevConfig.transPass);

  // Deluge
  bool _delugeEnabled = HomelabarrDevConfig.delugeEnabled;
  final _delugeHost = TextEditingController(text: HomelabarrDevConfig.delugeHost);
  final _delugePass = TextEditingController(text: HomelabarrDevConfig.delugePass);

  // SABnzbd (writes directly to active LunaProfile)
  late bool _sabEnabled;
  late TextEditingController _sabHost;
  late TextEditingController _sabKey;

  // Overseerr / Jellyseerr
  bool _overseerrEnabled = HomelabarrDevConfig.overseerrEnabled;
  final _overseerrHost = TextEditingController(text: HomelabarrDevConfig.overseerrHost);
  final _overseerrKey = TextEditingController(text: HomelabarrDevConfig.overseerrApiKey);

  // Prowlarr
  bool _prowlarrEnabled = HomelabarrDevConfig.prowlarrEnabled;
  final _prowlarrHost = TextEditingController(text: HomelabarrDevConfig.prowlarrHost);
  final _prowlarrKey = TextEditingController(text: HomelabarrDevConfig.prowlarrApiKey);

  // Bazarr
  bool _bazarrEnabled = HomelabarrDevConfig.bazarrEnabled;
  final _bazarrHost = TextEditingController(text: HomelabarrDevConfig.bazarrHost);
  final _bazarrKey = TextEditingController(text: HomelabarrDevConfig.bazarrApiKey);

  // Readarr
  bool _readarrEnabled = HomelabarrDevConfig.readarrEnabled;
  final _readarrHost = TextEditingController(text: HomelabarrDevConfig.readarrHost);
  final _readarrKey = TextEditingController(text: HomelabarrDevConfig.readarrApiKey);

  @override
  void initState() {
    super.initState();
    final p = LunaProfile.current;
    _sabEnabled = p.sabnzbdEnabled;
    _sabHost = TextEditingController(text: p.sabnzbdHost);
    _sabKey = TextEditingController(text: p.sabnzbdKey);
  }

  @override
  void dispose() {
    for (final c in [
      _qbitHost, _qbitUser, _qbitPass, _qbitCat,
      _transHost, _transUser, _transPass,
      _delugeHost, _delugePass,
      _sabHost, _sabKey,
      _overseerrHost, _overseerrKey,
      _prowlarrHost, _prowlarrKey,
      _bazarrHost, _bazarrKey,
      _readarrHost, _readarrKey,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveAll({bool silent = false}) {
    HomelabarrDevConfig.qbitEnabled = _qbitEnabled;
    HomelabarrDevConfig.qbitHost = _qbitHost.text;
    HomelabarrDevConfig.qbitUser = _qbitUser.text;
    HomelabarrDevConfig.qbitPass = _qbitPass.text;
    HomelabarrDevConfig.qbitCategory = _qbitCat.text;

    HomelabarrDevConfig.transEnabled = _transEnabled;
    HomelabarrDevConfig.transHost = _transHost.text;
    HomelabarrDevConfig.transUser = _transUser.text;
    HomelabarrDevConfig.transPass = _transPass.text;

    HomelabarrDevConfig.delugeEnabled = _delugeEnabled;
    HomelabarrDevConfig.delugeHost = _delugeHost.text;
    HomelabarrDevConfig.delugePass = _delugePass.text;

    final p = LunaProfile.current;
    p.sabnzbdEnabled = _sabEnabled;
    p.sabnzbdHost = _sabHost.text.trim();
    p.sabnzbdKey = _sabKey.text.trim();
    p.save();

    HomelabarrDevConfig.overseerrEnabled = _overseerrEnabled;
    HomelabarrDevConfig.overseerrHost = _overseerrHost.text;
    HomelabarrDevConfig.overseerrApiKey = _overseerrKey.text;

    HomelabarrDevConfig.prowlarrEnabled = _prowlarrEnabled;
    HomelabarrDevConfig.prowlarrHost = _prowlarrHost.text;
    HomelabarrDevConfig.prowlarrApiKey = _prowlarrKey.text;

    HomelabarrDevConfig.bazarrEnabled = _bazarrEnabled;
    HomelabarrDevConfig.bazarrHost = _bazarrHost.text;
    HomelabarrDevConfig.bazarrApiKey = _bazarrKey.text;

    HomelabarrDevConfig.readarrEnabled = _readarrEnabled;
    HomelabarrDevConfig.readarrHost = _readarrHost.text;
    HomelabarrDevConfig.readarrApiKey = _readarrKey.text;

    if (!silent) {
      showLunaSuccessSnackBar(
        title: 'Saved',
        message: 'Downloaders & Apps configuration updated.',
      );
    }
  }

  Future<void> _runTest(String name, Future<String> Function() testFn) async {
    _saveAll(silent: true);
    try {
      final msg = await testFn();
      showLunaSuccessSnackBar(title: '$name Connected', message: msg);
    } catch (e) {
      showLunaErrorSnackBar(title: '$name Test Failed', message: e.toString());
    }
  }

  Future<String> _testSab() async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(_sabHost.text);
    if (base.isEmpty || _sabKey.text.trim().isEmpty) throw Exception('Enter Host & API Key');
    final res = await http
        .get(Uri.parse('$base/api?mode=version&apikey=${Uri.encodeQueryComponent(_sabKey.text.trim())}&output=json'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final d = json.decode(res.body) as Map<String, dynamic>;
    return 'SABnzbd ${d['version'] ?? 'OK'}';
  }

  Future<String> _testOverseerr() async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(_overseerrHost.text);
    if (base.isEmpty || _overseerrKey.text.trim().isEmpty) throw Exception('Enter Host & API Key');
    final res = await http.get(
      Uri.parse('$base/api/v1/status'),
      headers: {'X-Api-Key': _overseerrKey.text.trim()},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final d = json.decode(res.body) as Map<String, dynamic>;
    return 'Version ${d['version'] ?? 'OK'}';
  }

  Future<String> _testProwlarr() async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(_prowlarrHost.text);
    if (base.isEmpty || _prowlarrKey.text.trim().isEmpty) throw Exception('Enter Host & API Key');
    final res = await http.get(
      Uri.parse('$base/api/v1/system/status'),
      headers: {'X-Api-Key': _prowlarrKey.text.trim()},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final d = json.decode(res.body) as Map<String, dynamic>;
    return 'Prowlarr ${d['version'] ?? 'OK'}';
  }

  Future<String> _testBazarr() async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(_bazarrHost.text);
    if (base.isEmpty || _bazarrKey.text.trim().isEmpty) throw Exception('Enter Host & API Key');
    final res = await http.get(
      Uri.parse('$base/api/system/status'),
      headers: {'X-API-KEY': _bazarrKey.text.trim()},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final d = json.decode(res.body) as Map<String, dynamic>;
    final inner = d['data'] as Map<String, dynamic>?;
    return 'Bazarr ${inner?['bazarr_version'] ?? 'OK'}';
  }

  Future<String> _testReadarr() async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(_readarrHost.text);
    if (base.isEmpty || _readarrKey.text.trim().isEmpty) throw Exception('Enter Host & API Key');
    final res = await http.get(
      Uri.parse('$base/api/v1/system/status'),
      headers: {'X-Api-Key': _readarrKey.text.trim()},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final d = json.decode(res.body) as Map<String, dynamic>;
    return 'Readarr ${d['version'] ?? 'OK'}';
  }

  bool _show(String id) => widget.filterApp == null || widget.filterApp == id;

  String get _pageTitle {
    switch (widget.filterApp) {
      case 'qbit':
        return 'qBittorrent';
      case 'transmission':
        return 'Transmission';
      case 'deluge':
        return 'Deluge';
      case 'overseerr':
        return 'Overseerr';
      case 'prowlarr':
        return 'Prowlarr';
      case 'bazarr':
        return 'Bazarr';
      case 'readarr':
        return 'Readarr';
      default:
        return 'Configuration';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = widget.filterApp != null;
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: LunaAppBar(
        title: _pageTitle,
        actions: [
          TextButton(
            onPressed: _saveAll,
            child: Text(
              'Save',
              style: TextStyle(color: LunaColours.accent, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 32),
        children: [
          if (!isSingle) _sectionHeader('TORRENT CLIENTS (DOCKER / WEBUI)'),
          if (_show('qbit'))
            _serviceCard(
              title: 'qBittorrent',
              subtitle: 'WebUI API v2 • e.g. http://192.168.1.x:8080',
              icon: Icons.downloading_rounded,
              enabled: _qbitEnabled,
              initiallyExpanded: isSingle,
              onToggle: (v) {
                setState(() => _qbitEnabled = v);
                HomelabarrDevConfig.qbitEnabled = v;
              },
              onTest: () => _runTest('qBittorrent', DownloadClientsApi.testQBittorrent),
              fields: [
                _field(_qbitHost, 'Host URL', 'http://192.168.1.x:8080'),
                _field(_qbitUser, 'Username', 'admin'),
                _field(_qbitPass, 'Password', '••••••••', obscure: true),
                _field(_qbitCat, 'Default Category (optional)', 'radarr / tv-sonarr'),
              ],
            ),
          if (_show('transmission'))
            _serviceCard(
              title: 'Transmission',
              subtitle: 'RPC API • e.g. http://192.168.1.x:9091',
              icon: Icons.swap_vert_circle_rounded,
              enabled: _transEnabled,
              initiallyExpanded: isSingle,
              onToggle: (v) {
                setState(() => _transEnabled = v);
                HomelabarrDevConfig.transEnabled = v;
              },
              onTest: () => _runTest('Transmission', DownloadClientsApi.testTransmission),
              fields: [
                _field(_transHost, 'Host URL', 'http://192.168.1.x:9091'),
                _field(_transUser, 'Username (optional)', 'transmission'),
                _field(_transPass, 'Password (optional)', '••••••••', obscure: true),
              ],
            ),
          if (_show('deluge'))
            _serviceCard(
              title: 'Deluge',
              subtitle: 'WebUI JSON-RPC • e.g. http://192.168.1.x:8112',
              icon: Icons.water_drop_rounded,
              enabled: _delugeEnabled,
              initiallyExpanded: isSingle,
              onToggle: (v) {
                setState(() => _delugeEnabled = v);
                HomelabarrDevConfig.delugeEnabled = v;
              },
              onTest: () => _runTest('Deluge', DownloadClientsApi.testDeluge),
              fields: [
                _field(_delugeHost, 'Host URL', 'http://192.168.1.x:8112'),
                _field(_delugePass, 'WebUI Password', 'deluge', obscure: true),
              ],
            ),
          if (!isSingle) ...[
            const SizedBox(height: 12),
            _sectionHeader('ADDITIONAL NZB DOWNLOADERS'),
            _serviceCard(
              title: 'SABnzbd',
              subtitle: 'Adds SABnzbd to Drawer & Prowlarr Search picker',
              icon: Icons.cloud_download_rounded,
              enabled: _sabEnabled,
              onToggle: (v) {
                setState(() => _sabEnabled = v);
                final p = LunaProfile.current;
                p.sabnzbdEnabled = v;
                p.save();
                HomelabarrDevConfig.notify();
              },
              onTest: () => _runTest('SABnzbd', _testSab),
              fields: [
                _field(_sabHost, 'Host URL', 'http://192.168.1.x:8080'),
                _field(_sabKey, 'API Key', 'SABnzbd API Key'),
              ],
            ),
            const SizedBox(height: 12),
            _sectionHeader('HOMELAB APPS'),
          ],
          if (_show('overseerr'))
            _serviceCard(
              title: 'Overseerr / Jellyseerr',
              subtitle: 'Discover, request movies/TV, and approve requests',
              icon: Icons.movie_filter_rounded,
              enabled: _overseerrEnabled,
              initiallyExpanded: isSingle,
              onToggle: (v) {
                setState(() => _overseerrEnabled = v);
                HomelabarrDevConfig.overseerrEnabled = v;
              },
              onTest: () => _runTest('Overseerr', _testOverseerr),
              fields: [
                _field(_overseerrHost, 'Host URL', 'http://192.168.1.x:5055'),
                _field(_overseerrKey, 'API Key', 'Settings → General → API Key'),
              ],
            ),
          if (_show('prowlarr'))
            _serviceCard(
              title: 'Prowlarr',
              subtitle: 'Standalone global search & indexer health manager',
              icon: Icons.travel_explore_rounded,
              enabled: _prowlarrEnabled,
              initiallyExpanded: isSingle,
              onToggle: (v) {
                setState(() => _prowlarrEnabled = v);
                HomelabarrDevConfig.prowlarrEnabled = v;
              },
              onTest: () => _runTest('Prowlarr', _testProwlarr),
              fields: [
                _field(_prowlarrHost, 'Host URL', 'http://192.168.1.x:9696'),
                _field(_prowlarrKey, 'API Key', 'Settings → General → API Key'),
              ],
            ),
          if (_show('bazarr'))
            _serviceCard(
              title: 'Bazarr',
              subtitle: 'Wanted subtitles & 1-tap subtitle search',
              icon: Icons.subtitles_rounded,
              enabled: _bazarrEnabled,
              initiallyExpanded: isSingle,
              onToggle: (v) {
                setState(() => _bazarrEnabled = v);
                HomelabarrDevConfig.bazarrEnabled = v;
              },
              onTest: () => _runTest('Bazarr', _testBazarr),
              fields: [
                _field(_bazarrHost, 'Host URL', 'http://192.168.1.x:6767'),
                _field(_bazarrKey, 'API Key', 'Settings → General → API Key'),
              ],
            ),
          if (_show('readarr'))
            _serviceCard(
              title: 'Readarr',
              subtitle: 'eBooks & Audiobooks library, missing books & lookup',
              icon: Icons.menu_book_rounded,
              enabled: _readarrEnabled,
              initiallyExpanded: isSingle,
              onToggle: (v) {
                setState(() => _readarrEnabled = v);
                HomelabarrDevConfig.readarrEnabled = v;
              },
              onTest: () => _runTest('Readarr', _testReadarr),
              fields: [
                _field(_readarrHost, 'Host URL', 'http://192.168.1.x:8787'),
                _field(_readarrKey, 'API Key', 'Settings → General → API Key'),
              ],
            ),
          const SizedBox(height: 16),
          LunaButton.text(
            text: isSingle ? 'Save $_pageTitle Settings' : 'Save All Settings',
            icon: Icons.save_rounded,
            onTap: _saveAll,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Text(
        text,
        style: TextStyle(
          color: LunaColours.accent,
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _serviceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    bool initiallyExpanded = false,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTest,
    required List<Widget> fields,
  }) {
    return Card(
      color: Theme.of(context).primaryColor,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: enabled ? LunaColours.accent : Colors.white38),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: Switch(
          value: enabled,
          activeColor: LunaColours.accent,
          onChanged: onToggle,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          ...fields,
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: LunaColours.accent,
                side: BorderSide(color: LunaColours.accent.withValues(alpha: 0.6)),
              ),
              onPressed: onTest,
              icon: const Icon(Icons.wifi_tethering_rounded, size: 16),
              label: const Text('Test Connection', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 12.5),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
          isDense: true,
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
