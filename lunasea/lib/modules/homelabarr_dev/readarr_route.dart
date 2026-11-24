import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_settings_route.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/sheet.dart';

class _ReadarrQualityProfile {
  final int id;
  final String name;
  final List<String> allowedFormats;
  final bool isAudio;

  const _ReadarrQualityProfile({
    required this.id,
    required this.name,
    required this.allowedFormats,
    required this.isAudio,
  });

  String get formatSummary =>
      allowedFormats.isEmpty ? name : '$name (${allowedFormats.take(3).join(', ')})';
}

class ReadarrRoute extends StatefulWidget {
  const ReadarrRoute({super.key});

  @override
  State<ReadarrRoute> createState() => _ReadarrRouteState();
}

class _ReadarrRouteState extends State<ReadarrRoute> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final TextEditingController _filterCtrl = TextEditingController();
  final TextEditingController _lookupCtrl = TextEditingController();

  bool _loadingLibrary = false;
  bool _loadingMissing = false;
  bool _searchingLookup = false;
  bool _searchingAllMissing = false;
  String? _error;
  String _filterQuery = '';

  List<Map<String, dynamic>> _books = [];
  Map<int, Map<String, dynamic>> _authorsById = {};
  List<_ReadarrQualityProfile> _qualityProfiles = [];
  List<Map<String, dynamic>> _rootFolders = [];
  List<Map<String, dynamic>> _metadataProfiles = [];
  List<Map<String, dynamic>> _missingBooks = [];
  List<Map<String, dynamic>> _lookupResults = [];

  static const _timeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    HomelabarrDevConfig.revision.addListener(_onConfigChanged);
    if (_isConfigured) {
      _loadLibrary();
      _loadMissing();
    }
  }

  @override
  void dispose() {
    HomelabarrDevConfig.revision.removeListener(_onConfigChanged);
    _tabController.dispose();
    _filterCtrl.dispose();
    _lookupCtrl.dispose();
    super.dispose();
  }

  bool get _isConfigured =>
      HomelabarrDevConfig.readarrEnabled &&
      HomelabarrDevConfig.readarrHost.isNotEmpty &&
      HomelabarrDevConfig.readarrApiKey.isNotEmpty;

  void _onConfigChanged() {
    if (!mounted) return;
    setState(() {});
    if (_isConfigured) {
      _loadLibrary();
      _loadMissing();
    }
  }

  String get _base => HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.readarrHost);
  Map<String, String> get _headers => {
        'X-Api-Key': HomelabarrDevConfig.readarrApiKey,
        'Content-Type': 'application/json',
      };

  List<_ReadarrQualityProfile> _parseQualityProfiles(List<dynamic> rawList) {
    return rawList.map((raw) {
      final m = raw as Map<String, dynamic>;
      final id = (m['id'] as num?)?.toInt() ?? 0;
      final name = (m['name'] ?? 'Profile $id').toString();
      final formats = <String>[];
      for (final item in (m['items'] as List<dynamic>? ?? [])) {
        final im = item as Map<String, dynamic>;
        if (im['allowed'] == true) {
          final q = im['quality'] as Map<String, dynamic>?;
          if (q != null && (q['name'] ?? '').toString().isNotEmpty) {
            final qName = q['name'].toString();
            if (!qName.toLowerCase().contains('unknown')) {
              formats.add(qName);
            }
          } else if ((im['name'] ?? '').toString().isNotEmpty) {
            formats.add(im['name'].toString());
          }
        }
      }
      final joined = '$name ${formats.join(' ')}'.toLowerCase();
      final isAudio = joined.contains('spoken') ||
          joined.contains('audio') ||
          joined.contains('mp3') ||
          joined.contains('m4b') ||
          joined.contains('flac');
      return _ReadarrQualityProfile(
        id: id,
        name: name,
        allowedFormats: formats,
        isAudio: isAudio,
      );
    }).toList();
  }

  Future<void> _loadLibrary() async {
    if (!_isConfigured) return;
    setState(() {
      _loadingLibrary = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_base/api/v1/author'), headers: _headers).timeout(_timeout),
        http.get(Uri.parse('$_base/api/v1/book'), headers: _headers).timeout(_timeout),
        http.get(Uri.parse('$_base/api/v1/qualityprofile'), headers: _headers).timeout(_timeout),
        http.get(Uri.parse('$_base/api/v1/rootfolder'), headers: _headers).timeout(_timeout),
        http.get(Uri.parse('$_base/api/v1/metadataprofile'), headers: _headers).timeout(_timeout),
      ]);

      final authorRes = results[0];
      final bookRes = results[1];
      final qpRes = results[2];
      final rfRes = results[3];
      final mpRes = results[4];

      if (bookRes.statusCode != 200) throw Exception('Readarr HTTP ${bookRes.statusCode}');

      final authorMap = <int, Map<String, dynamic>>{};
      if (authorRes.statusCode == 200) {
        for (final a in (json.decode(authorRes.body) as List<dynamic>).cast<Map<String, dynamic>>()) {
          final id = (a['id'] as num?)?.toInt();
          if (id != null) authorMap[id] = a;
        }
      }

      final profiles = qpRes.statusCode == 200
          ? _parseQualityProfiles(json.decode(qpRes.body) as List<dynamic>)
          : <_ReadarrQualityProfile>[];
      final rootFolders = rfRes.statusCode == 200
          ? (json.decode(rfRes.body) as List<dynamic>).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final metaProfiles = mpRes.statusCode == 200
          ? (json.decode(mpRes.body) as List<dynamic>).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

      final books = (json.decode(bookRes.body) as List<dynamic>).cast<Map<String, dynamic>>();
      books.sort((a, b) => (a['title'] ?? '').toString().toLowerCase().compareTo((b['title'] ?? '').toString().toLowerCase()));

      if (mounted) {
        setState(() {
          _authorsById = authorMap;
          _qualityProfiles = profiles;
          _rootFolders = rootFolders;
          _metadataProfiles = metaProfiles;
          _books = books;
          _loadingLibrary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingLibrary = false;
        });
      }
    }
  }

  Future<void> _loadMissing() async {
    if (!_isConfigured) return;
    setState(() => _loadingMissing = true);
    try {
      final res = await http
          .get(
            Uri.parse('$_base/api/v1/wanted/missing?page=1&pageSize=50&sortKey=releaseDate&sortDirection=descending'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final records = (data['records'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _missingBooks = records);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMissing = false);
  }

  _ReadarrQualityProfile? _profileForBook(Map<String, dynamic> book) {
    final authorId = (book['authorId'] as num?)?.toInt();
    final author = authorId != null ? _authorsById[authorId] : (book['author'] as Map<String, dynamic>?);
    final qpId = (author?['qualityProfileId'] as num?)?.toInt();
    if (qpId == null) return null;
    for (final p in _qualityProfiles) {
      if (p.id == qpId) return p;
    }
    return null;
  }

  String _authorForBook(Map<String, dynamic> book) {
    final authorObj = book['author'] as Map<String, dynamic>?;
    if (authorObj != null && (authorObj['authorName'] ?? '').toString().isNotEmpty) {
      return authorObj['authorName'].toString();
    }
    final authorId = (book['authorId'] as num?)?.toInt();
    if (authorId != null && _authorsById.containsKey(authorId)) {
      return (_authorsById[authorId]!['authorName'] ?? 'Unknown Author').toString();
    }
    final title = (book['authorTitle'] ?? '').toString();
    return title.isNotEmpty ? title : 'Unknown Author';
  }

  Future<void> _updateAuthorQualityProfile(int authorId, _ReadarrQualityProfile profile) async {
    final existing = _authorsById[authorId];
    if (existing == null) {
      showLunaErrorSnackBar(title: 'Update Failed', message: 'Author record not loaded yet');
      return;
    }
    final updated = Map<String, dynamic>.from(existing);
    updated['qualityProfileId'] = profile.id;
    try {
      final res = await http
          .put(
            Uri.parse('$_base/api/v1/author/$authorId'),
            headers: _headers,
            body: json.encode(updated),
          )
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final saved = json.decode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() => _authorsById[authorId] = saved);
        }
        showLunaSuccessSnackBar(
          title: 'Format Updated',
          message: '${existing['authorName'] ?? 'Author'} now looking for ${profile.formatSummary}',
        );
      } else {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Format Update Failed', message: e.toString());
    }
  }

  Future<void> _toggleBookMonitored(Map<String, dynamic> book, bool monitored) async {
    final id = (book['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      final res = await http
          .put(
            Uri.parse('$_base/api/v1/book/monitor'),
            headers: _headers,
            body: json.encode({
              'bookIds': [id],
              'monitored': monitored,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        book['monitored'] = monitored;
        if (mounted) setState(() {});
        showLunaSuccessSnackBar(
          title: monitored ? 'Monitored' : 'Unmonitored',
          message: (book['title'] ?? 'Book').toString(),
        );
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Update Failed', message: e.toString());
    }
  }

  Future<void> _searchBook(int bookId, String title) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/command'),
            headers: _headers,
            body: json.encode({
              'name': 'BookSearch',
              'bookIds': [bookId],
            }),
          )
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showLunaSuccessSnackBar(title: 'Search Triggered', message: title);
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Search Failed', message: e.toString());
    }
  }

  Future<void> _searchAllMissing() async {
    if (_searchingAllMissing || !_isConfigured) return;
    setState(() => _searchingAllMissing = true);
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/command'),
            headers: _headers,
            body: json.encode({'name': 'MissingBookSearch'}),
          )
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showLunaSuccessSnackBar(
          title: 'Searching All Missing Books',
          message: 'Readarr started searching for all missing books.',
        );
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Search All Failed', message: e.toString());
    } finally {
      if (mounted) setState(() => _searchingAllMissing = false);
    }
  }

  Future<void> _showInteractiveReleases(int bookId, String title) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _ReadarrReleasesSheet(
        base: _base,
        headers: _headers,
        bookId: bookId,
        bookTitle: title,
      ),
    );
  }

  void _openBookDetailsSheet(Map<String, dynamic> book) {
    final id = (book['id'] as num?)?.toInt() ?? 0;
    final authorId = (book['authorId'] as num?)?.toInt();
    final title = (book['title'] ?? 'Untitled').toString();
    final author = _authorForBook(book);
    final stats = book['statistics'] as Map<String, dynamic>?;
    final fileCount = (stats?['bookFileCount'] as num?)?.toInt() ?? 0;
    final hasFile = fileCount > 0;
    bool monitored = book['monitored'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final currentProfile = _profileForBook(book);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        currentProfile?.isAudio == true ? Icons.headphones_rounded : Icons.menu_book_rounded,
                        color: LunaColours.accent,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '$author • ${hasFile ? "Downloaded ($fileCount file${fileCount == 1 ? '' : 's'})" : "Missing"}',
                              style: TextStyle(
                                color: hasFile ? Colors.white60 : LunaColours.orange,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOOKING FOR FORMAT (QUALITY PROFILE)',
                          style: TextStyle(
                            color: LunaColours.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentProfile != null
                              ? currentProfile.formatSummary
                              : 'No quality profile assigned',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (_qualityProfiles.isNotEmpty && authorId != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _qualityProfiles.map((p) {
                              final selected = currentProfile?.id == p.id;
                              return ChoiceChip(
                                avatar: Icon(
                                  p.isAudio ? Icons.headphones_rounded : Icons.menu_book_rounded,
                                  size: 16,
                                  color: selected ? Colors.white : Colors.white70,
                                ),
                                label: Text(
                                  p.formatSummary,
                                  style: TextStyle(
                                    color: selected ? Colors.white : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                selected: selected,
                                selectedColor: LunaColours.accent,
                                backgroundColor: Theme.of(context).primaryColor,
                                onSelected: (_) async {
                                  if (selected) return;
                                  await _updateAuthorQualityProfile(authorId, p);
                                  setSheetState(() {});
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Note: Readarr sets eBook vs. Audiobook (Spoken) per author.',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Monitored', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    activeColor: LunaColours.accent,
                    value: monitored,
                    onChanged: (v) async {
                      setSheetState(() => monitored = v);
                      await _toggleBookMonitored(book, v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LunaColours.accent,
                            side: BorderSide(color: LunaColours.accent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: id > 0
                              ? () {
                                  Navigator.of(ctx).pop();
                                  _searchBook(id, title);
                                }
                              : null,
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('Auto Search', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LunaColours.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: id > 0
                              ? () {
                                  Navigator.of(ctx).pop();
                                  _showInteractiveReleases(id, title);
                                }
                              : null,
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Interactive Search', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ProwlarrSearchSheet(
                          initialQuery: title,
                          defaultCategory: 'all',
                        ).show();
                      },
                      icon: Icon(Icons.travel_explore_rounded, size: 18, color: LunaColours.accent),
                      label: const Text('Search in Prowlarr (Direct)', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _runLookup(String term) async {
    final q = term.trim();
    if (q.isEmpty || !_isConfigured) return;
    setState(() => _searchingLookup = true);
    try {
      final uri = Uri.parse('$_base/api/v1/book/lookup').replace(queryParameters: {'term': q});
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) throw Exception('Readarr HTTP ${res.statusCode}');
      final list = (json.decode(res.body) as List<dynamic>).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _lookupResults = list);
    } catch (e) {
      showLunaErrorSnackBar(title: 'Lookup Failed', message: e.toString());
    }
    if (mounted) setState(() => _searchingLookup = false);
  }

  Future<void> _promptAndAddBook(Map<String, dynamic> book) async {
    if (_qualityProfiles.isEmpty || _rootFolders.isEmpty) {
      await _loadLibrary();
    }
    if (!mounted) return;
    if (_rootFolders.isEmpty) {
      showLunaErrorSnackBar(title: 'Cannot Add Book', message: 'No Root Folder configured in Readarr');
      return;
    }

    int selectedQpId = _qualityProfiles.isNotEmpty ? _qualityProfiles.first.id : 1;
    String selectedRootPath = (_rootFolders.first['path'] ?? '').toString();
    bool searchNow = true;
    final title = (book['title'] ?? 'Book').toString();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add "$title"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 12),
                Text(
                  'CHOOSE FORMAT (EBOOK OR AUDIOBOOK)',
                  style: TextStyle(color: LunaColours.accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.9),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _qualityProfiles.map((p) {
                    final active = p.id == selectedQpId;
                    return ChoiceChip(
                      avatar: Icon(
                        p.isAudio ? Icons.headphones_rounded : Icons.menu_book_rounded,
                        size: 16,
                        color: active ? Colors.white : Colors.white70,
                      ),
                      label: Text(
                        p.formatSummary,
                        style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      selected: active,
                      selectedColor: LunaColours.accent,
                      backgroundColor: Colors.black26,
                      onSelected: (_) => setS(() => selectedQpId = p.id),
                    );
                  }).toList(),
                ),
                if (_rootFolders.length > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRootPath,
                    dropdownColor: Theme.of(context).primaryColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Root Folder',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    items: _rootFolders
                        .map((rf) => DropdownMenuItem<String>(
                              value: (rf['path'] ?? '').toString(),
                              child: Text('${rf['name'] ?? ''} (${rf['path'] ?? ''})'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setS(() => selectedRootPath = v);
                    },
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Search Immediately', style: TextStyle(color: Colors.white, fontSize: 14)),
                  activeColor: LunaColours.accent,
                  value: searchNow,
                  onChanged: (v) => setS(() => searchNow = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LunaColours.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add to Readarr', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final mpId = _metadataProfiles.isNotEmpty ? _metadataProfiles.first['id'] : 1;
      final payload = Map<String, dynamic>.from(book);
      final author = Map<String, dynamic>.from((book['author'] as Map<String, dynamic>?) ?? {});
      author['qualityProfileId'] = selectedQpId;
      author['metadataProfileId'] = mpId;
      author['rootFolderPath'] = selectedRootPath;
      author['monitored'] = true;
      author['addOptions'] = {'monitor': 'none', 'searchForMissingBooks': false};

      payload['author'] = author;
      payload['monitored'] = true;
      payload['addOptions'] = {'searchForNewBook': searchNow};

      final res = await http
          .post(Uri.parse('$_base/api/v1/book'), headers: _headers, body: json.encode(payload))
          .timeout(_timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final chosenName = _qualityProfiles
            .where((p) => p.id == selectedQpId)
            .map((p) => p.name)
            .firstOrNull ??
            'Readarr';
        showLunaSuccessSnackBar(title: 'Added as $chosenName', message: title);
        _loadLibrary();
        _loadMissing();
      } else {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Add Book Failed', message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const LunaDrawer(page: 'readarr'),
      appBar: LunaAppBar(
        title: 'Readarr',
        useDrawer: true,
        actions: [
          if (_isConfigured)
            LunaIconButton(
              icon: Icons.manage_search_rounded,
              onPressed: _searchingAllMissing ? null : _searchAllMissing,
            ),
          LunaIconButton(
            icon: Icons.tune_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HomelabarrDevSettingsRoute(filterApp: 'readarr')),
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
                    tabs: [
                      Tab(text: 'Library (${_books.length})'),
                      Tab(text: 'Missing (${_missingBooks.length})'),
                      const Tab(text: 'Add Book'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _libraryTab(),
                      _missingTab(),
                      _lookupTab(),
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
            Icon(Icons.menu_book_rounded, size: 56, color: LunaColours.accent),
            const SizedBox(height: 14),
            const Text(
              'Readarr Not Configured',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect Readarr to browse your eBook & Audiobook library, choose formats, search missing books, and add new titles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 20),
            LunaButton.text(
              text: 'Configure Readarr',
              icon: Icons.settings_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HomelabarrDevSettingsRoute(filterApp: 'readarr')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _libraryTab() {
    if (_loadingLibrary && _books.isEmpty) {
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
              LunaButton.text(text: 'Retry', icon: Icons.refresh_rounded, onTap: _loadLibrary),
            ],
          ),
        ),
      );
    }

    final q = _filterQuery.toLowerCase();
    final filtered = q.isEmpty
        ? _books
        : _books.where((b) {
            final t = (b['title'] ?? '').toString().toLowerCase();
            final a = _authorForBook(b).toLowerCase();
            return t.contains(q) || a.contains(q);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _filterCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Filter books or authors...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Theme.of(context).primaryColor,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
            ),
            onChanged: (v) => setState(() => _filterQuery = v.trim()),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLibrary,
            child: filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('No books found', style: TextStyle(color: Colors.white60))),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, idx) => _bookCard(filtered[idx]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _missingTab() {
    if (_loadingMissing && _missingBooks.isEmpty) {
      return const Center(child: LunaLoader());
    }
    return RefreshIndicator(
      onRefresh: _loadMissing,
      child: _missingBooks.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No missing books!', style: TextStyle(color: Colors.white60))),
              ],
            )
          : Column(
              children: [
                Padding(
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
                      onPressed: _searchingAllMissing ? null : _searchAllMissing,
                      icon: const Icon(Icons.manage_search_rounded, size: 18),
                      label: Text(
                        _searchingAllMissing
                            ? 'Triggering Search...'
                            : 'Search All Missing Books (${_missingBooks.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: _missingBooks.length,
                    itemBuilder: (_, idx) => _bookCard(_missingBooks[idx]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _bookCard(Map<String, dynamic> book) {
    final id = (book['id'] as num?)?.toInt() ?? 0;
    final title = (book['title'] ?? 'Untitled').toString();
    final author = _authorForBook(book);
    final releaseDate = (book['releaseDate'] ?? '').toString();
    final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
    final stats = book['statistics'] as Map<String, dynamic>?;
    final fileCount = (stats?['bookFileCount'] as num?)?.toInt() ?? 0;
    final monitored = book['monitored'] == true;
    final hasFile = fileCount > 0;
    final profile = _profileForBook(book);

    return Card(
      color: Theme.of(context).primaryColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openBookDetailsSheet(book),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                profile?.isAudio == true
                    ? Icons.headphones_rounded
                    : (hasFile ? Icons.menu_book_rounded : Icons.book_outlined),
                color: hasFile ? LunaColours.accent : (monitored ? LunaColours.orange : Colors.white38),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      year.isNotEmpty ? '$title ($year)' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$author • ${hasFile ? "Downloaded" : "Missing"}${monitored ? "" : " • Unmonitored"}',
                      style: TextStyle(
                        color: hasFile ? Colors.white60 : LunaColours.orange,
                        fontSize: 12,
                      ),
                    ),
                    if (profile != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (profile.isAudio ? LunaColours.blue : LunaColours.accent).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Looking for: ${profile.formatSummary}',
                          style: TextStyle(
                            color: profile.isAudio ? LunaColours.blue : LunaColours.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.search_rounded, color: LunaColours.accent),
                onPressed: id > 0 ? () => _showInteractiveReleases(id, title) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lookupTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lookupCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search books or authors to add...',
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
                  onSubmitted: _runLookup,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.arrow_forward_rounded, color: LunaColours.accent),
                onPressed: () => _runLookup(_lookupCtrl.text),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchingLookup
              ? const Center(child: LunaLoader())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: _lookupResults.length,
                  itemBuilder: (_, idx) {
                    final item = _lookupResults[idx];
                    final title = (item['title'] ?? 'Untitled').toString();
                    final author = _authorForBook(item);
                    final releaseDate = (item['releaseDate'] ?? '').toString();
                    final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
                    final inLibrary = ((item['id'] as num?)?.toInt() ?? 0) > 0;

                    return Card(
                      color: Theme.of(context).primaryColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          year.isNotEmpty ? '$title ($year)' : title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(author, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        trailing: inLibrary
                            ? Chip(
                                label: const Text('In Library', style: TextStyle(color: Colors.white, fontSize: 11)),
                                backgroundColor: LunaColours.accent.withValues(alpha: 0.3),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LunaColours.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: () => _promptAndAddBook(item),
                                child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ReadarrReleasesSheet extends StatefulWidget {
  final String base;
  final Map<String, String> headers;
  final int bookId;
  final String bookTitle;

  const _ReadarrReleasesSheet({
    required this.base,
    required this.headers,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  State<_ReadarrReleasesSheet> createState() => _ReadarrReleasesSheetState();
}

class _ReadarrReleasesSheetState extends State<_ReadarrReleasesSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _releases = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http
          .get(Uri.parse('${widget.base}/api/v1/release?bookId=${widget.bookId}'), headers: widget.headers)
          .timeout(const Duration(seconds: 35));
      if (res.statusCode != 200) throw Exception('Readarr HTTP ${res.statusCode}');
      final list = (json.decode(res.body) as List<dynamic>).cast<Map<String, dynamic>>();
      // Sort approved releases first
      list.sort((a, b) {
        final aOk = (a['approved'] == true) ? 0 : 1;
        final bOk = (b['approved'] == true) ? 0 : 1;
        return aOk.compareTo(bOk);
      });
      if (mounted) {
        setState(() {
          _releases = list;
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

  Future<void> _grab(Map<String, dynamic> r) async {
    try {
      final res = await http
          .post(
            Uri.parse('${widget.base}/api/v1/release'),
            headers: widget.headers,
            body: json.encode({
              'guid': r['guid'],
              'indexerId': r['indexerId'],
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showLunaSuccessSnackBar(
          title: 'Release Grabbed',
          message: (r['title'] ?? widget.bookTitle).toString(),
        );
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      showLunaErrorSnackBar(title: 'Grab Failed', message: e.toString());
    }
  }

  String _fmtSize(num? bytes) {
    if (bytes == null || bytes <= 0) return '—';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.94,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Releases: ${widget.bookTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: _loading
                ? const Center(child: LunaLoader())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
                    : _releases.isEmpty
                        ? const Center(child: Text('No releases found on indexers', style: TextStyle(color: Colors.white60)))
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                            itemCount: _releases.length,
                            itemBuilder: (_, idx) {
                              final r = _releases[idx];
                              final title = (r['title'] ?? 'Untitled').toString();
                              final indexer = (r['indexer'] ?? 'Indexer').toString();
                              final quality = ((r['quality'] as Map<String, dynamic>?)?['quality'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
                              final approved = r['approved'] == true;
                              final rejections = (r['rejections'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
                              final size = _fmtSize(r['size'] as num?);
                              return Card(
                                color: Colors.black26,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: approved ? LunaColours.accent.withValues(alpha: 0.4) : LunaColours.red.withValues(alpha: 0.4)),
                                ),
                                child: ListTile(
                                  title: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: approved ? Colors.white : LunaColours.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$quality • $size • $indexer${rejections.isNotEmpty ? "\nRejected: ${rejections.first}" : ""}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                                  ),
                                  isThreeLine: rejections.isNotEmpty,
                                  trailing: IconButton(
                                    icon: Icon(Icons.download_rounded, color: approved ? LunaColours.accent : LunaColours.orange),
                                    onPressed: () => _grab(r),
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
