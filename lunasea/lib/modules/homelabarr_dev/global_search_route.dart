import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/download_clients_api.dart';

class _GlobalResult {
  final String source; // 'Radarr' | 'Sonarr' | 'Readarr' | 'Overseerr' | 'Prowlarr'
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> raw;

  const _GlobalResult({
    required this.source,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.raw,
  });
}

class GlobalSearchRoute extends StatefulWidget {
  const GlobalSearchRoute({super.key});

  @override
  State<GlobalSearchRoute> createState() => _GlobalSearchRouteState();
}

class _GlobalSearchRouteState extends State<GlobalSearchRoute> {
  final TextEditingController _ctrl = TextEditingController();
  bool _searching = false;
  String _selectedFilter = 'All';
  List<_GlobalResult> _results = [];

  static const _timeout = Duration(seconds: 20);
  static const _filters = ['All', 'Radarr', 'Sonarr', 'Readarr', 'Overseerr', 'Prowlarr'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _searchAll(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _results = [];
    });

    final p = LunaProfile.current;
    final found = <_GlobalResult>[];
    final tasks = <Future<void>>[];

    if (p.radarrEnabled && p.radarrHost.trim().isNotEmpty && p.radarrKey.trim().isNotEmpty) {
      tasks.add(_searchRadarr(p.radarrHost, p.radarrKey, q).then(found.addAll));
    }
    if (p.sonarrEnabled && p.sonarrHost.trim().isNotEmpty && p.sonarrKey.trim().isNotEmpty) {
      tasks.add(_searchSonarr(p.sonarrHost, p.sonarrKey, q).then(found.addAll));
    }
    if (HomelabarrDevConfig.readarrEnabled &&
        HomelabarrDevConfig.readarrHost.isNotEmpty &&
        HomelabarrDevConfig.readarrApiKey.isNotEmpty) {
      tasks.add(_searchReadarr(q).then(found.addAll));
    }
    if (HomelabarrDevConfig.overseerrEnabled &&
        HomelabarrDevConfig.overseerrHost.isNotEmpty &&
        HomelabarrDevConfig.overseerrApiKey.isNotEmpty) {
      tasks.add(_searchOverseerr(q).then(found.addAll));
    }
    if (HomelabarrDevConfig.prowlarrHost.isNotEmpty && HomelabarrDevConfig.prowlarrApiKey.isNotEmpty) {
      tasks.add(_searchProwlarr(q).then(found.addAll));
    }

    await Future.wait(tasks);
    if (mounted) {
      setState(() {
        _results = found;
        _searching = false;
      });
    }
  }

  Future<List<_GlobalResult>> _searchRadarr(String host, String key, String q) async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(host);
      final uri = Uri.parse('$base/api/v3/movie/lookup').replace(queryParameters: {'term': q});
      final res = await http.get(uri, headers: {'X-Api-Key': key}).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final list = (json.decode(res.body) as List<dynamic>).take(8).cast<Map<String, dynamic>>();
      return list.map((m) {
        final year = m['year'] ?? '';
        final inLib = ((m['id'] as num?)?.toInt() ?? 0) > 0;
        return _GlobalResult(
          source: 'Radarr',
          title: '${m['title'] ?? 'Movie'}${year != '' ? ' ($year)' : ''}',
          subtitle: inLib ? 'Movie • Already in Radarr' : 'Movie • Tap + to add to Radarr',
          icon: Icons.movie_rounded,
          color: LunaColours.orange,
          raw: m,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_GlobalResult>> _searchSonarr(String host, String key, String q) async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(host);
      final uri = Uri.parse('$base/api/v3/series/lookup').replace(queryParameters: {'term': q});
      final res = await http.get(uri, headers: {'X-Api-Key': key}).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final list = (json.decode(res.body) as List<dynamic>).take(8).cast<Map<String, dynamic>>();
      return list.map((s) {
        final year = s['year'] ?? '';
        final inLib = ((s['id'] as num?)?.toInt() ?? 0) > 0;
        return _GlobalResult(
          source: 'Sonarr',
          title: '${s['title'] ?? 'Series'}${year != '' ? ' ($year)' : ''}',
          subtitle: inLib ? 'TV Show • Already in Sonarr' : 'TV Show • Tap + to add to Sonarr',
          icon: Icons.tv_rounded,
          color: LunaColours.blue,
          raw: s,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_GlobalResult>> _searchReadarr(String q) async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.readarrHost);
      final uri = Uri.parse('$base/api/v1/book/lookup').replace(queryParameters: {'term': q});
      final res = await http.get(uri, headers: {'X-Api-Key': HomelabarrDevConfig.readarrApiKey}).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final list = (json.decode(res.body) as List<dynamic>).take(8).cast<Map<String, dynamic>>();
      return list.map((b) {
        final author = ((b['author'] as Map<String, dynamic>?)?['authorName'] ?? b['authorTitle'] ?? 'Author').toString();
        final inLib = ((b['id'] as num?)?.toInt() ?? 0) > 0;
        return _GlobalResult(
          source: 'Readarr',
          title: (b['title'] ?? 'Book').toString(),
          subtitle: '$author • ${inLib ? "In Readarr" : "Tap + to add"}',
          icon: Icons.menu_book_rounded,
          color: LunaColours.accent,
          raw: b,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_GlobalResult>> _searchOverseerr(String q) async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.overseerrHost);
      final uri = Uri.parse('$base/api/v1/search').replace(queryParameters: {'query': q, 'page': '1'});
      final res = await http.get(uri, headers: {'X-Api-Key': HomelabarrDevConfig.overseerrApiKey}).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final list = ((json.decode(res.body) as Map<String, dynamic>)['results'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((m) => m['mediaType'] == 'movie' || m['mediaType'] == 'tv')
          .take(8);
      return list.map((m) {
        final title = (m['title'] ?? m['name'] ?? 'Title').toString();
        final type = (m['mediaType'] ?? 'media').toString().toUpperCase();
        return _GlobalResult(
          source: 'Overseerr',
          title: title,
          subtitle: 'Overseerr $type • Tap to Request',
          icon: Icons.movie_filter_rounded,
          color: LunaColours.purple,
          raw: m,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_GlobalResult>> _searchProwlarr(String q) async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.prowlarrHost);
      final uri = Uri.parse('$base/api/v1/search?query=${Uri.encodeQueryComponent(q)}&type=search');
      final res = await http.get(uri, headers: {'X-Api-Key': HomelabarrDevConfig.prowlarrApiKey}).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final list = (json.decode(res.body) as List<dynamic>).take(12).cast<Map<String, dynamic>>();
      return list.map((r) {
        final proto = (r['protocol'] ?? 'usenet').toString().toUpperCase();
        final indexer = (r['indexer'] ?? 'Indexer').toString();
        final bytes = (r['size'] as num?)?.toDouble() ?? 0;
        final sizeStr = bytes >= 1024 * 1024 * 1024
            ? '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
            : '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
        return _GlobalResult(
          source: 'Prowlarr',
          title: (r['title'] ?? 'Release').toString(),
          subtitle: '$proto • $indexer • $sizeStr',
          icon: Icons.travel_explore_rounded,
          color: LunaColours.accent,
          raw: r,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _handleAction(_GlobalResult item) async {
    final p = LunaProfile.current;
    try {
      if (item.source == 'Prowlarr') {
        final proto = (item.raw['protocol'] ?? 'usenet').toString().toLowerCase();
        final isTorrent = proto == 'torrent';
        final url = (isTorrent
                ? (item.raw['magnetUrl'] ?? item.raw['downloadUrl'] ?? '')
                : (item.raw['downloadUrl'] ?? ''))
            .toString();
        if (url.isEmpty) throw Exception('No download URL');
        await DownloadClientsApi.dispatchRelease(
          context: context,
          title: item.title,
          downloadUrl: url,
          isTorrent: isTorrent,
        );
        return;
      }

      if (item.source == 'Overseerr') {
        final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.overseerrHost);
        final mediaType = (item.raw['mediaType'] ?? 'movie').toString();
        final res = await http.post(
          Uri.parse('$base/api/v1/request'),
          headers: {'X-Api-Key': HomelabarrDevConfig.overseerrApiKey, 'Content-Type': 'application/json'},
          body: json.encode({
            'mediaType': mediaType,
            'mediaId': item.raw['id'],
            if (mediaType == 'tv') 'seasons': 'all',
          }),
        );
        if (res.statusCode == 200 || res.statusCode == 201) {
          showLunaSuccessSnackBar(title: 'Requested in Overseerr', message: item.title);
        } else {
          throw Exception('HTTP ${res.statusCode}');
        }
        return;
      }

      if (item.source == 'Radarr') {
        final base = HomelabarrDevConfig.normalizeBaseUrl(p.radarrHost);
        final headers = {'X-Api-Key': p.radarrKey, 'Content-Type': 'application/json'};
        final rf = json.decode((await http.get(Uri.parse('$base/api/v3/rootfolder'), headers: headers)).body) as List;
        final qp = json.decode((await http.get(Uri.parse('$base/api/v3/qualityprofile'), headers: headers)).body) as List;
        final payload = Map<String, dynamic>.from(item.raw);
        payload['rootFolderPath'] = (rf.first as Map)['path'];
        payload['qualityProfileId'] = (qp.first as Map)['id'];
        payload['monitored'] = true;
        payload['addOptions'] = {'searchForMovie': true};
        final res = await http.post(Uri.parse('$base/api/v3/movie'), headers: headers, body: json.encode(payload));
        if (res.statusCode == 200 || res.statusCode == 201) {
          showLunaSuccessSnackBar(title: 'Added to Radarr', message: item.title);
        } else {
          throw Exception('HTTP ${res.statusCode}');
        }
        return;
      }

      if (item.source == 'Sonarr') {
        final base = HomelabarrDevConfig.normalizeBaseUrl(p.sonarrHost);
        final headers = {'X-Api-Key': p.sonarrKey, 'Content-Type': 'application/json'};
        final rf = json.decode((await http.get(Uri.parse('$base/api/v3/rootfolder'), headers: headers)).body) as List;
        final qp = json.decode((await http.get(Uri.parse('$base/api/v3/qualityprofile'), headers: headers)).body) as List;
        final payload = Map<String, dynamic>.from(item.raw);
        payload['rootFolderPath'] = (rf.first as Map)['path'];
        payload['qualityProfileId'] = (qp.first as Map)['id'];
        payload['monitored'] = true;
        payload['addOptions'] = {'searchForMissingEpisodes': true};
        final res = await http.post(Uri.parse('$base/api/v3/series'), headers: headers, body: json.encode(payload));
        if (res.statusCode == 200 || res.statusCode == 201) {
          showLunaSuccessSnackBar(title: 'Added to Sonarr', message: item.title);
        } else {
          throw Exception('HTTP ${res.statusCode}');
        }
        return;
      }

      if (item.source == 'Readarr') {
        final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.readarrHost);
        final headers = {'X-Api-Key': HomelabarrDevConfig.readarrApiKey, 'Content-Type': 'application/json'};
        final rf = json.decode((await http.get(Uri.parse('$base/api/v1/rootfolder'), headers: headers)).body) as List;
        final qp = json.decode((await http.get(Uri.parse('$base/api/v1/qualityprofile'), headers: headers)).body) as List;
        final mp = json.decode((await http.get(Uri.parse('$base/api/v1/metadataprofile'), headers: headers)).body) as List;
        final payload = Map<String, dynamic>.from(item.raw);
        final author = Map<String, dynamic>.from((item.raw['author'] as Map<String, dynamic>?) ?? {});
        author['rootFolderPath'] = (rf.first as Map)['path'];
        author['qualityProfileId'] = (qp.first as Map)['id'];
        author['metadataProfileId'] = mp.isNotEmpty ? (mp.first as Map)['id'] : 1;
        author['monitored'] = true;
        author['addOptions'] = {'monitor': 'none', 'searchForMissingBooks': false};
        payload['author'] = author;
        payload['monitored'] = true;
        payload['addOptions'] = {'searchForNewBook': true};
        final res = await http.post(Uri.parse('$base/api/v1/book'), headers: headers, body: json.encode(payload));
        if (res.statusCode == 200 || res.statusCode == 201) {
          showLunaSuccessSnackBar(title: 'Added to Readarr', message: item.title);
        } else {
          throw Exception('HTTP ${res.statusCode}');
        }
      }
    } catch (e) {
      showLunaErrorSnackBar(title: '${item.source} Failed', message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _selectedFilter == 'All'
        ? _results
        : _results.where((r) => r.source == _selectedFilter).toList();

    return LunaScaffold(
      scaffoldKey: GlobalKey<ScaffoldState>(),
      appBar: LunaAppBar(title: 'Search Everything'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search movies, TV, books, requests & indexers...',
                      hintStyle: const TextStyle(color: Colors.white54, fontSize: 13.5),
                      filled: true,
                      fillColor: Theme.of(context).primaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _searchAll,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.arrow_forward_rounded, color: LunaColours.accent),
                  onPressed: () => _searchAll(_ctrl.text),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _filters.map((f) {
                final active = f == _selectedFilter;
                final count = f == 'All'
                    ? _results.length
                    : _results.where((r) => r.source == f).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      count > 0 ? '$f ($count)' : f,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: active,
                    selectedColor: LunaColours.accent,
                    backgroundColor: Theme.of(context).primaryColor,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _searching
                ? const Center(child: LunaLoader())
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          _ctrl.text.trim().isEmpty
                              ? 'Search across Radarr, Sonarr, Readarr, Overseerr & Prowlarr'
                              : 'No matches found',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 13.5),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: visible.length,
                        itemBuilder: (_, idx) {
                          final item = visible[idx];
                          final inLib = ((item.raw['id'] as num?)?.toInt() ?? 0) > 0 &&
                              (item.source == 'Radarr' || item.source == 'Sonarr' || item.source == 'Readarr');
                          return Card(
                            color: Theme.of(context).primaryColor,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: Icon(item.icon, color: item.color),
                              title: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                              subtitle: Text(
                                '${item.source} • ${item.subtitle}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                              ),
                              trailing: inLib
                                  ? Icon(Icons.check_circle_rounded, color: LunaColours.accent, size: 22)
                                  : IconButton(
                                      icon: Icon(
                                        item.source == 'Prowlarr'
                                            ? Icons.download_rounded
                                            : Icons.add_circle_outline_rounded,
                                        color: LunaColours.accent,
                                      ),
                                      onPressed: () => _handleAction(item),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
