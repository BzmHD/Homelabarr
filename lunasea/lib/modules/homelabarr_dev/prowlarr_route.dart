import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_settings_route.dart';
import 'package:lunasea/modules/homelabarr_dev/download_clients_api.dart';

class ProwlarrModuleRoute extends StatefulWidget {
  const ProwlarrModuleRoute({Key? key}) : super(key: key);

  @override
  State<ProwlarrModuleRoute> createState() => _ProwlarrModuleRouteState();
}

class _ProwlarrModuleRouteState extends State<ProwlarrModuleRoute> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedCat = 'All';
  bool _searching = false;
  bool _loadingIndexers = false;
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _indexers = [];
  List<Map<String, dynamic>> _health = [];

  static const _timeout = Duration(seconds: 15);
  static const _catMap = <String, List<int>>{
    'All': [],
    'Movies': [2000],
    'TV': [5000],
    'Music': [3000],
    'Books': [7000],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    HomelabarrDevConfig.revision.addListener(_onConfigChanged);
    _loadIndexers();
  }

  @override
  void dispose() {
    HomelabarrDevConfig.revision.removeListener(_onConfigChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onConfigChanged() {
    if (mounted) {
      setState(() {});
      _loadIndexers();
    }
  }

  String get _base => HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.prowlarrHost);
  Map<String, String> get _headers => {
        'X-Api-Key': HomelabarrDevConfig.prowlarrApiKey,
        'Content-Type': 'application/json',
      };

  Future<void> _loadIndexers() async {
    if (_base.isEmpty || HomelabarrDevConfig.prowlarrApiKey.isEmpty) return;
    setState(() => _loadingIndexers = true);
    try {
      final idxRes = await http.get(Uri.parse('$_base/api/v1/indexer'), headers: _headers).timeout(_timeout);
      final healthRes = await http.get(Uri.parse('$_base/api/v1/health'), headers: _headers).timeout(_timeout);
      if (mounted) {
        setState(() {
          if (idxRes.statusCode == 200) {
            _indexers = (json.decode(idxRes.body) as List<dynamic>).cast<Map<String, dynamic>>();
          }
          if (healthRes.statusCode == 200) {
            _health = (json.decode(healthRes.body) as List<dynamic>).cast<Map<String, dynamic>>();
          }
          _loadingIndexers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingIndexers = false);
    }
  }

  Future<void> _testIndexer(Map<String, dynamic> indexer) async {
    final name = (indexer['name'] ?? 'Indexer').toString();
    try {
      final res = await http
          .post(Uri.parse('$_base/api/v1/indexer/test'), headers: _headers, body: json.encode(indexer))
          .timeout(const Duration(seconds: 25));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showLunaSuccessSnackBar(title: 'Indexer OK', message: '$name passed health check');
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: '$name Failed', message: e.toString());
    }
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final cats = _catMap[_selectedCat] ?? [];
      final buf = StringBuffer('$_base/api/v1/search?query=${Uri.encodeQueryComponent(q)}&type=search');
      for (final c in cats) {
        buf.write('&categories=$c');
      }
      final res = await http.get(Uri.parse(buf.toString()), headers: _headers).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw Exception('Prowlarr HTTP ${res.statusCode}');
      final list = (json.decode(res.body) as List<dynamic>).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _results = list);
    } catch (e) {
      showLunaErrorSnackBar(title: 'Prowlarr Search Failed', message: e.toString());
    }
    if (mounted) setState(() => _searching = false);
  }

  String _fmtAge(Map<String, dynamic> r) {
    final ageHours = (r['ageHours'] as num?)?.toDouble();
    final ageDays = (r['age'] as num?)?.toInt() ?? 0;
    if (ageHours != null && ageHours < 24) {
      if (ageHours < 1) {
        final mins = (r['ageMinutes'] as num?)?.round() ?? (ageHours * 60).round();
        return '${mins < 1 ? 1 : mins}m';
      }
      return '${ageHours.floor()}h';
    }
    return '${ageDays}d';
  }

  String _fmtSize(num? bytes) {
    if (bytes == null || bytes <= 0) return '—';
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(2)} GB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const LunaDrawer(page: 'prowlarr'),
      appBar: LunaAppBar(
        title: 'Prowlarr',
        useDrawer: true,
        actions: [
          LunaIconButton(
            icon: Icons.tune_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HomelabarrDevSettingsRoute()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: LunaColours.accent,
              labelColor: LunaColours.accent,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Global Search'),
                Tab(text: 'Indexers'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_searchTab(), _indexersTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search all Prowlarr indexers...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Theme.of(context).primaryColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _runSearch,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.arrow_forward_rounded, color: LunaColours.accent),
                onPressed: () => _runSearch(_searchCtrl.text),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _catMap.keys.map((cat) {
              final active = _selectedCat == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat, style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 12)),
                  selected: active,
                  selectedColor: LunaColours.accent,
                  backgroundColor: Theme.of(context).primaryColor,
                  onSelected: (_) => setState(() => _selectedCat = cat),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _searching
              ? const Center(child: LunaLoader())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: _results.length,
                  itemBuilder: (_, idx) {
                    final r = _results[idx];
                    final title = (r['title'] ?? 'Untitled').toString();
                    final indexer = (r['indexer'] ?? 'Indexer').toString();
                    final protocol = (r['protocol'] ?? 'usenet').toString().toLowerCase();
                    final isTorrent = protocol == 'torrent';
                    final dlUrl = (r['magnetUrl'] ?? r['downloadUrl'] ?? '').toString();
                    final seeders = r['seeders'];
                    final sizeStr = _fmtSize(r['size'] as num?);
                    final ageStr = _fmtAge(r);

                    return Card(
                      color: Theme.of(context).primaryColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${isTorrent ? "TORRENT" : "NZB"} • $indexer • $sizeStr • $ageStr${isTorrent && seeders != null ? " • S:$seeders" : ""}',
                            style: TextStyle(
                              color: isTorrent ? LunaColours.blue : Colors.white60,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.download_rounded, color: LunaColours.accent),
                          onPressed: dlUrl.isEmpty
                              ? null
                              : () => DownloadClientsApi.dispatchRelease(
                                    context: context,
                                    title: title,
                                    downloadUrl: dlUrl,
                                    isTorrent: isTorrent,
                                    category: _selectedCat == 'Movies'
                                        ? 'movies'
                                        : (_selectedCat == 'TV' ? 'tv' : ''),
                                  ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _indexersTab() {
    return RefreshIndicator(
      onRefresh: _loadIndexers,
      child: _loadingIndexers && _indexers.isEmpty
          ? const Center(child: LunaLoader())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
              children: [
                if (_health.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LunaColours.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: LunaColours.orange.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Health Warnings',
                          style: TextStyle(color: LunaColours.orange, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        ..._health.map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '• ${h['message'] ?? h['source']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ..._indexers.map((idx) {
                  final name = (idx['name'] ?? 'Indexer').toString();
                  final proto = (idx['protocol'] ?? '').toString().toUpperCase();
                  final enabled = idx['enable'] == true;
                  final priority = idx['priority'] ?? 25;
                  return Card(
                    color: Theme.of(context).primaryColor,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: Icon(
                        proto == 'TORRENT' ? Icons.hub_rounded : Icons.dns_rounded,
                        color: enabled ? LunaColours.accent : Colors.white38,
                      ),
                      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '$proto • Priority $priority • ${enabled ? "Enabled" : "Disabled"}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () => _testIndexer(idx),
                        child: Text('Test', style: TextStyle(color: LunaColours.accent, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
