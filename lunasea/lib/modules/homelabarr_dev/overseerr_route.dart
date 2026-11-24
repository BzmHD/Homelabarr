import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_settings_route.dart';

class OverseerrRoute extends StatefulWidget {
  const OverseerrRoute({Key? key}) : super(key: key);

  @override
  State<OverseerrRoute> createState() => _OverseerrRouteState();
}

class _OverseerrRouteState extends State<OverseerrRoute> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loadingRequests = false;
  bool _loadingTrending = false;
  bool _searching = false;
  final Set<String> _busyKeys = {};
  String? _error;

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _trending = [];
  List<Map<String, dynamic>> _searchResults = [];

  static const _timeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    HomelabarrDevConfig.revision.addListener(_onConfigChanged);
    if (_isConfigured) {
      _loadRequests();
      _loadTrending();
    }
  }

  @override
  void dispose() {
    HomelabarrDevConfig.revision.removeListener(_onConfigChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isConfigured =>
      HomelabarrDevConfig.overseerrEnabled &&
      HomelabarrDevConfig.overseerrHost.isNotEmpty &&
      HomelabarrDevConfig.overseerrApiKey.isNotEmpty;

  void _onConfigChanged() {
    if (!mounted) return;
    setState(() {});
    if (_isConfigured) {
      _loadRequests();
      _loadTrending();
    }
  }

  String get _base => HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.overseerrHost);
  Map<String, String> get _headers => {
        'X-Api-Key': HomelabarrDevConfig.overseerrApiKey,
        'Content-Type': 'application/json',
      };

  Future<void> _loadRequests() async {
    if (!_isConfigured) return;
    setState(() {
      _loadingRequests = true;
      _error = null;
    });
    try {
      final res = await http
          .get(Uri.parse('$_base/api/v1/request?take=40&skip=0&sort=added'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode != 200) throw Exception('Overseerr HTTP ${res.statusCode}');
      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = (data['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _requests = list;
          _loadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingRequests = false;
        });
      }
    }
  }

  Future<void> _loadTrending() async {
    if (!_isConfigured) return;
    setState(() => _loadingTrending = true);
    try {
      final res = await http
          .get(Uri.parse('$_base/api/v1/discover/trending?page=1'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final list = (data['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _trending = list);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingTrending = false);
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty || !_isConfigured) return;
    setState(() => _searching = true);
    try {
      final uri = Uri.parse('$_base/api/v1/search').replace(queryParameters: {'query': q, 'page': '1'});
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = (data['results'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((m) => m['mediaType'] == 'movie' || m['mediaType'] == 'tv')
          .toList();
      if (mounted) setState(() => _searchResults = list);
    } catch (e) {
      showLunaErrorSnackBar(title: 'Search Failed', message: e.toString());
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _requestMedia(Map<String, dynamic> item) async {
    final mediaType = (item['mediaType'] ?? 'movie').toString();
    final id = item['id'];
    final key = 'req:$mediaType:$id';
    if (_busyKeys.contains(key)) return;
    _busyKeys.add(key);
    final title = (item['title'] ?? item['name'] ?? 'Title').toString();
    try {
      final payload = <String, dynamic>{
        'mediaType': mediaType,
        'mediaId': id,
        if (mediaType == 'tv') 'seasons': 'all',
      };
      final res = await http
          .post(Uri.parse('$_base/api/v1/request'), headers: _headers, body: json.encode(payload))
          .timeout(_timeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        showLunaSuccessSnackBar(title: 'Requested!', message: title);
        _loadRequests();
      } else {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Request Failed', message: e.toString());
    } finally {
      _busyKeys.remove(key);
    }
  }

  Future<void> _updateRequest(int requestId, String action) async {
    final key = 'upd:$requestId:$action';
    if (_busyKeys.contains(key)) return;
    _busyKeys.add(key);
    try {
      http.Response res;
      if (action == 'delete') {
        res = await http.delete(Uri.parse('$_base/api/v1/request/$requestId'), headers: _headers).timeout(_timeout);
      } else {
        res = await http.post(Uri.parse('$_base/api/v1/request/$requestId/$action'), headers: _headers).timeout(_timeout);
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showLunaSuccessSnackBar(
          title: action == 'approve'
              ? 'Approved'
              : (action == 'decline' ? 'Declined' : 'Deleted'),
          message: 'Request #$requestId updated',
        );
        _loadRequests();
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Action Failed', message: e.toString());
    } finally {
      _busyKeys.remove(key);
    }
  }

  String _statusLabel(int? status) {
    switch (status) {
      case 1:
        return 'Pending';
      case 2:
        return 'Approved';
      case 3:
        return 'Declined';
      case 4:
        return 'Partial';
      case 5:
        return 'Available';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(int? status) {
    switch (status) {
      case 1:
        return LunaColours.orange;
      case 2:
      case 5:
        return LunaColours.accent;
      case 3:
        return LunaColours.red;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const LunaDrawer(page: 'overseerr'),
      appBar: LunaAppBar(
        title: 'Overseerr',
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
      body: !_isConfigured
          ? _emptyState()
          : Column(
              children: [
                Container(
                  color: Theme.of(context).primaryColor,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: LunaColours.accent,
                    labelColor: LunaColours.accent,
                    unselectedLabelColor: Colors.white60,
                    tabs: const [
                      Tab(text: 'Requests'),
                      Tab(text: 'Search'),
                      Tab(text: 'Trending'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _requestsTab(),
                      _searchTab(),
                      _trendingTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_filter_rounded, size: 56, color: LunaColours.accent),
            const SizedBox(height: 14),
            const Text(
              'Overseerr / Jellyseerr Not Configured',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your Overseerr or Jellyseerr instance to browse trending titles, submit requests, and approve/decline pending requests.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 20),
            LunaButton.text(
              text: 'Configure Overseerr',
              icon: Icons.settings_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HomelabarrDevSettingsRoute()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestsTab() {
    if (_loadingRequests && _requests.isEmpty) {
      return const Center(child: LunaLoader());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              LunaButton.text(text: 'Retry', icon: Icons.refresh_rounded, onTap: _loadRequests),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: _requests.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No requests yet', style: TextStyle(color: Colors.white60))),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: _requests.length,
              itemBuilder: (_, idx) {
                final req = _requests[idx];
                final id = (req['id'] as num?)?.toInt() ?? 0;
                final status = (req['status'] as num?)?.toInt();
                final type = (req['type'] ?? 'media').toString().toUpperCase();
                final media = (req['media'] as Map<String, dynamic>?) ?? {};
                final tmdbId = media['tmdbId'];
                final requestedBy = ((req['requestedBy'] as Map<String, dynamic>?)?['displayName'] ??
                        (req['requestedBy'] as Map<String, dynamic>?)?['email'] ??
                        'User')
                    .toString();
                final isPending = status == 1;
                return Card(
                  color: Theme.of(context).primaryColor,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$type • TMDB #$tmdbId',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Requested by $requestedBy', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isPending) ...[
                              TextButton.icon(
                                onPressed: () => _updateRequest(id, 'approve'),
                                icon: Icon(Icons.check_circle_outline, size: 17, color: LunaColours.accent),
                                label: Text('Approve', style: TextStyle(color: LunaColours.accent, fontSize: 12.5)),
                              ),
                              TextButton.icon(
                                onPressed: () => _updateRequest(id, 'decline'),
                                icon: const Icon(Icons.cancel_outlined, size: 17, color: LunaColours.orange),
                                label: const Text('Decline', style: TextStyle(color: LunaColours.orange, fontSize: 12.5)),
                              ),
                            ],
                            TextButton.icon(
                              onPressed: () => _updateRequest(id, 'delete'),
                              icon: const Icon(Icons.delete_outline, size: 17, color: LunaColours.red),
                              label: const Text('Delete', style: TextStyle(color: LunaColours.red, fontSize: 12.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _searchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search movies & TV shows...',
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
        Expanded(
          child: _searching
              ? const Center(child: LunaLoader())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: _searchResults.length,
                  itemBuilder: (_, idx) => _mediaCard(_searchResults[idx]),
                ),
        ),
      ],
    );
  }

  Widget _trendingTab() {
    if (_loadingTrending && _trending.isEmpty) {
      return const Center(child: LunaLoader());
    }
    return RefreshIndicator(
      onRefresh: _loadTrending,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _trending.length,
        itemBuilder: (_, idx) => _mediaCard(_trending[idx]),
      ),
    );
  }

  Widget _mediaCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? item['name'] ?? 'Untitled').toString();
    final mediaType = (item['mediaType'] ?? 'movie').toString().toUpperCase();
    final date = (item['releaseDate'] ?? item['firstAirDate'] ?? '').toString();
    final year = date.length >= 4 ? date.substring(0, 4) : '';
    final overview = (item['overview'] ?? '').toString();
    final mediaInfo = item['mediaInfo'] as Map<String, dynamic>?;
    final status = (mediaInfo?['status'] as num?)?.toInt();
    final already = status != null && status >= 2;

    return Card(
      color: Theme.of(context).primaryColor,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    year.isNotEmpty ? '$title ($year)' : title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mediaType,
                    style: TextStyle(color: LunaColours.accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  if (overview.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            already
                ? Chip(
                    label: Text(_statusLabel(status), style: const TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: _statusColor(status).withValues(alpha: 0.3),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LunaColours.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _requestMedia(item),
                    child: const Text('Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}
