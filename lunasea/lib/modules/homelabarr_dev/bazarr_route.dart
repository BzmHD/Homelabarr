import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_settings_route.dart';

class BazarrRoute extends StatefulWidget {
  const BazarrRoute({Key? key}) : super(key: key);

  @override
  State<BazarrRoute> createState() => _BazarrRouteState();
}

class _BazarrRouteState extends State<BazarrRoute> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _wantedMovies = [];
  List<Map<String, dynamic>> _wantedEpisodes = [];

  static const _timeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    HomelabarrDevConfig.revision.addListener(_onConfigChanged);
    if (_isConfigured) _load();
  }

  @override
  void dispose() {
    HomelabarrDevConfig.revision.removeListener(_onConfigChanged);
    _tabController.dispose();
    super.dispose();
  }

  bool get _isConfigured =>
      HomelabarrDevConfig.bazarrEnabled &&
      HomelabarrDevConfig.bazarrHost.isNotEmpty &&
      HomelabarrDevConfig.bazarrApiKey.isNotEmpty;

  void _onConfigChanged() {
    if (!mounted) return;
    setState(() {});
    if (_isConfigured) _load();
  }

  String get _base => HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.bazarrHost);
  Map<String, String> get _headers => {'X-API-KEY': HomelabarrDevConfig.bazarrApiKey};

  Future<void> _load() async {
    if (!_isConfigured) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final movRes = await http
          .get(Uri.parse('$_base/api/movies/wanted?start=0&length=40'), headers: _headers)
          .timeout(_timeout);
      final epRes = await http
          .get(Uri.parse('$_base/api/episodes/wanted?start=0&length=40'), headers: _headers)
          .timeout(_timeout);
      if (movRes.statusCode != 200 && epRes.statusCode != 200) {
        throw Exception('Bazarr HTTP ${movRes.statusCode}');
      }
      final movies = movRes.statusCode == 200
          ? ((json.decode(movRes.body) as Map<String, dynamic>)['data'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final eps = epRes.statusCode == 200
          ? ((json.decode(epRes.body) as Map<String, dynamic>)['data'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _wantedMovies = movies;
          _wantedEpisodes = eps;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _searchMovieSubs(Map<String, dynamic> movie) async {
    final radarrId = movie['radarrId'];
    final missing = (movie['missing_subtitles'] as List<dynamic>? ?? []);
    final lang = missing.isNotEmpty ? (missing.first['code2'] ?? 'en') : 'en';
    try {
      final uri = Uri.parse('$_base/api/movies/subtitles').replace(queryParameters: {
        'radarrid': '$radarrId',
        'language': '$lang',
        'hi': 'false',
        'forced': 'false',
      });
      final res = await http.patch(uri, headers: _headers).timeout(const Duration(seconds: 25));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showLunaSuccessSnackBar(title: 'Subtitle Search Sent', message: (movie['title'] ?? 'Movie').toString());
        _load();
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Subtitle Search Failed', message: e.toString());
    }
  }

  Future<void> _searchEpisodeSubs(Map<String, dynamic> ep) async {
    final seriesId = ep['sonarrSeriesId'];
    final epId = ep['sonarrEpisodeId'];
    final missing = (ep['missing_subtitles'] as List<dynamic>? ?? []);
    final lang = missing.isNotEmpty ? (missing.first['code2'] ?? 'en') : 'en';
    try {
      final uri = Uri.parse('$_base/api/episodes/subtitles').replace(queryParameters: {
        'seriesid': '$seriesId',
        'episodeid': '$epId',
        'language': '$lang',
        'hi': 'false',
        'forced': 'false',
      });
      final res = await http.patch(uri, headers: _headers).timeout(const Duration(seconds: 25));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showLunaSuccessSnackBar(
          title: 'Subtitle Search Sent',
          message: '${ep['seriesTitle'] ?? ''} ${ep['episode_number'] ?? ''}',
        );
        _load();
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Subtitle Search Failed', message: e.toString());
    }
  }

  bool _searchingAll = false;

  Future<void> _searchAllMissing({required bool movies, required bool episodes}) async {
    if (_searchingAll || !_isConfigured) return;
    setState(() => _searchingAll = true);
    try {
      final tasks = <String>[
        if (movies) 'wanted_search_missing_subtitles_movies',
        if (episodes) 'wanted_search_missing_subtitles_series',
      ];
      int triggered = 0;
      for (final taskId in tasks) {
        final res = await http
            .post(
              Uri.parse('$_base/api/system/tasks'),
              headers: {
                ..._headers,
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: {'taskid': taskId},
            )
            .timeout(_timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          triggered++;
        }
      }
      if (triggered > 0) {
        showLunaSuccessSnackBar(
          title: 'Searching All Missing Subtitles',
          message: movies && episodes
              ? 'Triggered Bazarr search for all missing movies & episodes.'
              : (movies
                  ? 'Triggered Bazarr search for all missing movies.'
                  : 'Triggered Bazarr search for all missing episodes.'),
        );
      } else {
        throw Exception('Bazarr did not accept the search task');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Search All Failed', message: e.toString());
    } finally {
      if (mounted) setState(() => _searchingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const LunaDrawer(page: 'bazarr'),
      appBar: LunaAppBar(
        title: 'Bazarr',
        useDrawer: true,
        actions: [
          if (_isConfigured)
            LunaIconButton(
              icon: Icons.manage_search_rounded,
              onPressed: _searchingAll
                  ? null
                  : () => _searchAllMissing(movies: true, episodes: true),
            ),
          LunaIconButton(
            icon: Icons.tune_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HomelabarrDevSettingsRoute()),
            ),
          ),
        ],
      ),
      body: !_isConfigured
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.subtitles_rounded, size: 56, color: LunaColours.accent),
                    const SizedBox(height: 14),
                    const Text(
                      'Bazarr Not Configured',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect Bazarr to see movies and episodes missing subtitles and trigger 1-tap subtitle searches.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    LunaButton.text(
                      text: 'Configure Bazarr',
                      icon: Icons.settings_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HomelabarrDevSettingsRoute()),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  color: Theme.of(context).primaryColor,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: LunaColours.accent,
                    labelColor: LunaColours.accent,
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(text: 'Movies (${_wantedMovies.length})'),
                      Tab(text: 'Episodes (${_wantedEpisodes.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading && _wantedMovies.isEmpty && _wantedEpisodes.isEmpty
                      ? const Center(child: LunaLoader())
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_error!, style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 12),
                                    LunaButton.text(text: 'Retry', icon: Icons.refresh_rounded, onTap: _load),
                                  ],
                                ),
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: [_moviesList(), _episodesList()],
                            ),
                ),
              ],
            ),
    );
  }

  Widget _searchAllButton({required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: LunaColours.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _searchingAll ? null : onTap,
          icon: _searchingAll
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.manage_search_rounded, size: 18),
          label: Text(
            _searchingAll ? 'Triggering Search...' : label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
        ),
      ),
    );
  }

  Widget _moviesList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _wantedMovies.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No missing movie subtitles', style: TextStyle(color: Colors.white60))),
              ],
            )
          : Column(
              children: [
                _searchAllButton(
                  label: 'Search All Missing Movies (${_wantedMovies.length})',
                  onTap: () => _searchAllMissing(movies: true, episodes: false),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: _wantedMovies.length,
                    itemBuilder: (_, idx) {
                      final m = _wantedMovies[idx];
                      final langs = (m['missing_subtitles'] as List<dynamic>? ?? [])
                          .map((s) => (s['name'] ?? s['code2'] ?? '').toString())
                          .join(', ');
                      return Card(
                        color: Theme.of(context).primaryColor,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text((m['title'] ?? 'Movie').toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('Missing: $langs', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          trailing: IconButton(
                            icon: Icon(Icons.search_rounded, color: LunaColours.accent),
                            onPressed: () => _searchMovieSubs(m),
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

  Widget _episodesList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _wantedEpisodes.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No missing episode subtitles', style: TextStyle(color: Colors.white60))),
              ],
            )
          : Column(
              children: [
                _searchAllButton(
                  label: 'Search All Missing Episodes (${_wantedEpisodes.length})',
                  onTap: () => _searchAllMissing(movies: false, episodes: true),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: _wantedEpisodes.length,
                    itemBuilder: (_, idx) {
                      final e = _wantedEpisodes[idx];
                      final langs = (e['missing_subtitles'] as List<dynamic>? ?? [])
                          .map((s) => (s['name'] ?? s['code2'] ?? '').toString())
                          .join(', ');
                      return Card(
                        color: Theme.of(context).primaryColor,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(
                            '${e['seriesTitle'] ?? 'Series'} • ${e['episode_number'] ?? ''}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${e['episodeTitle'] ?? ''}\nMissing: $langs',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: Icon(Icons.search_rounded, color: LunaColours.accent),
                            onPressed: () => _searchEpisodeSubs(e),
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
