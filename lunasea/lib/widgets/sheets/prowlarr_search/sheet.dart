import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/extensions/string/string.dart';

class ProwlarrConfig {
  static const String _hostKey = 'HOMELABARR_PROWLARR_HOST';
  static const String _apiKeyKey = 'HOMELABARR_PROWLARR_API_KEY';

  static String get host => (LunaBox.lunasea.read(_hostKey) ?? '').toString();
  static set host(String v) => LunaBox.lunasea.update(_hostKey, v.trim());

  static String get apiKey => (LunaBox.lunasea.read(_apiKeyKey) ?? '').toString();
  static set apiKey(String v) => LunaBox.lunasea.update(_apiKeyKey, v.trim());

  static bool get isConfigured => host.isNotEmpty && apiKey.isNotEmpty;
}

class ProwlarrProfileInfo {
  final String name;
  final Set<String> allowedQualities;

  const ProwlarrProfileInfo({
    required this.name,
    required this.allowedQualities,
  });

  bool get hasRules => allowedQualities.isNotEmpty;
}

class ProwlarrApi {
  static Future<ProwlarrProfileInfo?> fetchQualityProfile({
    required String category,
    required int? qualityProfileId,
  }) async {
    if (qualityProfileId == null || qualityProfileId <= 0) return null;
    try {
      final profile = LunaProfile.current;
      String host = '';
      String apiKey = '';
      if (category == 'movies' && profile.radarrEnabled) {
        host = profile.radarrHost.replaceAll(RegExp(r'/+$'), '');
        apiKey = profile.radarrKey;
      } else if (category == 'tv' && profile.sonarrEnabled) {
        host = profile.sonarrHost.replaceAll(RegExp(r'/+$'), '');
        apiKey = profile.sonarrKey;
      }
      if (host.isEmpty || apiKey.isEmpty) return null;

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'X-Api-Key': apiKey},
      ));
      final resp = await dio.get('$host/api/v3/qualityprofile/$qualityProfileId');
      if (resp.data is! Map) return null;
      final data = resp.data as Map;
      final name = (data['name'] ?? 'Profile #$qualityProfileId').toString();
      final allowed = <String>{};

      void collectItems(dynamic items) {
        if (items is! List) return;
        for (final item in items) {
          if (item is! Map) continue;
          if (item['allowed'] != true) continue;
          final q = item['quality'];
          if (q is Map && q['name'] != null) {
            allowed.add(_normQuality(q['name'].toString()));
          }
          if (item['items'] is List) {
            for (final sub in (item['items'] as List)) {
              if (sub is Map && sub['quality'] is Map && sub['quality']['name'] != null) {
                allowed.add(_normQuality(sub['quality']['name'].toString()));
              }
            }
          }
        }
      }

      collectItems(data['items']);
      return ProwlarrProfileInfo(name: name, allowedQualities: allowed);
    } catch (_) {
      return null;
    }
  }

  static String _normQuality(String q) {
    return q.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static Future<Map<String, String>> fetchBlocklist({
    required String category,
  }) async {
    try {
      final profile = LunaProfile.current;
      String host = '';
      String apiKey = '';
      if (category == 'movies' && profile.radarrEnabled) {
        host = profile.radarrHost.replaceAll(RegExp(r'/+$'), '');
        apiKey = profile.radarrKey;
      } else if (category == 'tv' && profile.sonarrEnabled) {
        host = profile.sonarrHost.replaceAll(RegExp(r'/+$'), '');
        apiKey = profile.sonarrKey;
      }
      if (host.isEmpty || apiKey.isEmpty) return {};

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'X-Api-Key': apiKey},
      ));
      final resp = await dio.get('$host/api/v3/blocklist?pageSize=250');
      final records = (resp.data is Map ? resp.data['records'] : null) as List? ?? [];
      final map = <String, String>{};
      for (final rec in records) {
        if (rec is Map) {
          final st = (rec['sourceTitle'] ?? '').toString().trim().toLowerCase();
          if (st.isNotEmpty) {
            final msg = (rec['message'] ?? '').toString().trim();
            map[st] = msg.isNotEmpty
                ? 'Blocklisted: $msg'
                : 'Release is in ${category == 'movies' ? 'Radarr' : 'Sonarr'} Blocklist';
          }
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> search(
    String query, {
    String category = 'all',
  }) async {
    final q = query.trim();
    if (q.isEmpty || !ProwlarrConfig.isConfigured) return [];
    final host = ProwlarrConfig.host.replaceAll(RegExp(r'/+$'), '');
    final searchType = category == 'movies'
        ? 'movie'
        : category == 'tv'
            ? 'tvsearch'
            : 'search';
    final catParam = category == 'tv'
        ? '&categories=5000'
        : category == 'movies'
            ? '&categories=2000'
            : '';
    final url =
        '$host/api/v1/search?query=${Uri.encodeQueryComponent(q)}&type=$searchType$catParam';
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'X-Api-Key': ProwlarrConfig.apiKey},
    ));
    final resp = await dio.get(url);
    return (resp.data as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((r) => (r['protocol'] ?? '') == 'usenet')
        .toList();
  }

  static String parseQuality(String title) {
    final low = title.toLowerCase();
    String res = '';
    if (low.contains('2160p') || low.contains('4k') || low.contains('uhd')) {
      res = '2160p';
    } else if (low.contains('1080p')) {
      res = '1080p';
    } else if (low.contains('720p')) {
      res = '720p';
    } else if (low.contains('480p') || low.contains('576p')) {
      res = '480p';
    }

    if (RegExp(r'\b(cam|hdcam)\b').hasMatch(low)) return 'CAM';
    if (RegExp(r'\b(ts|hdts|telesync)\b').hasMatch(low)) return 'TELESYNC';

    String src = '';
    if (low.contains('remux')) {
      src = 'Remux';
    } else if (low.contains('bluray') || low.contains('blu-ray') || low.contains('bdrip') || low.contains('brrip')) {
      src = 'Bluray';
    } else if (low.contains('web-dl') || low.contains('webdl')) {
      src = 'WEBDL';
    } else if (low.contains('webrip') || RegExp(r'\bweb\b').hasMatch(low)) {
      src = 'WEBRip';
    } else if (low.contains('hdtv')) {
      src = 'HDTV';
    } else if (low.contains('dvdrip') || low.contains('dvd')) {
      return 'DVD';
    } else if (low.contains('sdtv')) {
      return 'SDTV';
    }

    if (src.isNotEmpty && res.isNotEmpty) return '$src-$res';
    if (res.isNotEmpty) return res;
    if (src.isNotEmpty) return src;
    return 'Unknown';
  }

  static bool matchesQualityProfile(
    String parsedQuality,
    ProwlarrProfileInfo profile,
  ) {
    if (!profile.hasRules) return true;
    if (parsedQuality == 'Unknown') return false;
    final norm = _normQuality(parsedQuality);
    if (profile.allowedQualities.contains(norm)) return true;
    // Handle resolution-only parse (e.g. "1080p") by checking if any allowed quality has that resolution
    if (RegExp(r'^(2160p|1080p|720p|480p)$').hasMatch(norm)) {
      return profile.allowedQualities.any((q) => q.endsWith(norm));
    }
    // Handle WEBRip/WEBDL fallback when title only said "WEB"
    if (norm.startsWith('webrip')) {
      final dlVariant = norm.replaceFirst('webrip', 'webdl');
      if (profile.allowedQualities.contains(dlVariant)) return true;
    }
    return false;
  }

  static List<String> parseTags(String title) {
    final low = title.toLowerCase();
    final tags = <String>[];
    if (low.contains('x265') || low.contains('h265') || low.contains('hevc')) {
      tags.add('x265');
    } else if (low.contains('x264') || low.contains('h264') || low.contains('avc')) {
      tags.add('x264');
    }
    if (low.contains('hdr') || low.contains('dolby.vision') || RegExp(r'\bdv\b').hasMatch(low)) {
      tags.add('HDR/DV');
    }
    if (low.contains('atmos')) {
      tags.add('Atmos');
    } else if (low.contains('ddp5.1') || low.contains('dd+5.1') || low.contains('eac3')) {
      tags.add('DDP5.1');
    }
    return tags;
  }

  static List<String> evaluateRejections(
    Map<String, dynamic> r, {
    required String category,
    Map<String, String> blocklist = const {},
    ProwlarrProfileInfo? qualityProfile,
  }) {
    final reasons = <String>[];
    final title = (r['title'] ?? '').toString();
    final low = title.toLowerCase();
    final sizeBytes = (r['size'] is num) ? (r['size'] as num).toDouble() : 0.0;
    final quality = parseQuality(title);

    // 1. Quality Profile check
    if (qualityProfile != null && qualityProfile.hasRules) {
      if (!matchesQualityProfile(quality, qualityProfile)) {
        reasons.add('$quality is not wanted in quality profile (${qualityProfile.name})');
      }
    }

    // 2. Blocklist match
    final blReason = blocklist[low.trim()];
    if (blReason != null) {
      reasons.add(blReason);
    }

    // 3. Sample / CAM / TS
    if (RegExp(r'\bsample\b').hasMatch(low)) {
      reasons.add('Release appears to be a sample');
    }
    if (RegExp(r'\b(cam|hdcam|ts|hdts|telesync)\b').hasMatch(low)) {
      reasons.add('Low quality CAM/TS release');
    }

    // 4. Movie Remux / Bloated size (> 3.5 GB)
    if (category == 'movies') {
      if (low.contains('remux') && (qualityProfile?.name.toLowerCase().contains('noremux') ?? true)) {
        reasons.add('Remux excluded by quality profile');
      }
      if (sizeBytes > 3.5 * 1024 * 1024 * 1024) {
        reasons.add('Large file size (${formatSize(sizeBytes)}) exceeds preferred 3 GB cap');
      }
    }

    // 5. Foreign-only release without English/Multi
    final hasForeign = RegExp(r'\b(french|vff|truefrench|german|italian|spanish|russian|hindi)\b').hasMatch(low);
    final hasEngOrMulti = RegExp(r'\b(eng|english|multi|dl|dual)\b').hasMatch(low);
    if (hasForeign && !hasEngOrMulti) {
      reasons.add('Non-English release (no ENG/MULTI tag)');
    }

    return reasons;
  }

  static Future<void> grabToNzbget(
    Map<String, dynamic> item, {
    String category = 'all',
  }) async {
    final dlUrl = (item['downloadUrl'] ?? '').toString();
    final title = (item['title'] ?? 'download').toString();
    if (dlUrl.isEmpty) {
      showLunaErrorSnackBar(
        title: 'Download Failed',
        message: 'Release has no download URL',
      );
      return;
    }

    showLunaInfoSnackBar(
      title: 'Sending to NZBGet...',
      message: title,
    );

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ));
      final nzbResp = await dio.get<List<int>>(
        dlUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'User-Agent': 'Sonarr/4.0 (linux)'},
        ),
      );
      final b64 = base64Encode(nzbResp.data ?? []);

      final profile = LunaProfile.current;
      if (!profile.nzbgetEnabled || profile.nzbgetHost.isEmpty) {
        showLunaErrorSnackBar(
          title: 'NZBGet Not Configured',
          message: 'Enable and configure NZBGet in Settings or the Setup Walkthrough first.',
        );
        return;
      }
      final nzbHost = profile.nzbgetHost.replaceAll(RegExp(r'/+$'), '');
      final nzbUser = profile.nzbgetUser;
      final nzbPass = profile.nzbgetPass;
      final auth = 'Basic ${base64Encode(utf8.encode('$nzbUser:$nzbPass'))}';

      final cats = ((item['categories'] as List?) ?? [])
          .map((c) => (c is Map ? c['name'] : c).toString().toLowerCase())
          .join(' ');
      final isMovie = category == 'movies' || cats.contains('movie');
      final nzbCat = isMovie ? 'Movies' : 'Series';
      final nzbName = title.endsWith('.nzb') ? title : '$title.nzb';

      await dio.post(
        '$nzbHost/jsonrpc',
        options: Options(headers: {'Authorization': auth}),
        data: {
          'method': 'append',
          'params': [nzbName, b64, nzbCat, 0, false, false, '', 0, 'SCORE', []],
        },
      );

      showLunaSuccessSnackBar(
        title: 'Sent to NZBGet ($nzbCat)',
        message: title,
      );
    } catch (e) {
      showLunaErrorSnackBar(
        title: 'NZBGet Send Failed',
        error: e,
      );
    }
  }

  static String formatAge(Map<String, dynamic> r) {
    final days = (r['age'] is num) ? (r['age'] as num).toDouble() : 0.0;
    if (days >= 1) return '${days.round()}d';

    double? hours = (r['ageHours'] is num) ? (r['ageHours'] as num).toDouble() : null;
    double? minutes = (r['ageMinutes'] is num) ? (r['ageMinutes'] as num).toDouble() : null;

    if (hours == null && minutes == null && r['publishDate'] is String) {
      final dt = DateTime.tryParse(r['publishDate'] as String);
      if (dt != null) {
        final diff = DateTime.now().toUtc().difference(dt.toUtc());
        if (diff.inDays >= 1) return '${diff.inDays}d';
        if (diff.inHours >= 1) return '${diff.inHours}h';
        return '${diff.inMinutes.clamp(1, 59)}m';
      }
    }

    if (hours != null && hours >= 1) return '${hours.round()}h';
    if (minutes != null && minutes >= 1) return '${minutes.round()}m';
    return '<1m';
  }

  static String formatSize(dynamic sizeVal) {
    final b = (sizeVal is num) ? sizeVal.toDouble() : 0.0;
    if (b <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var v = b;
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(i >= 3 ? 2 : 1)} ${units[i]}';
  }

  static Widget buildReleaseTile(
    Map<String, dynamic> r, {
    String category = 'all',
    Map<String, String> blocklist = const {},
    ProwlarrProfileInfo? qualityProfile,
  }) {
    return ProwlarrReleaseTile(
      release: r,
      category: category,
      blocklist: blocklist,
      qualityProfile: qualityProfile,
    );
  }
}

class ProwlarrReleaseTile extends StatefulWidget {
  final Map<String, dynamic> release;
  final String category;
  final Map<String, String> blocklist;
  final ProwlarrProfileInfo? qualityProfile;

  const ProwlarrReleaseTile({
    super.key,
    required this.release,
    this.category = 'all',
    this.blocklist = const {},
    this.qualityProfile,
  });

  @override
  State<ProwlarrReleaseTile> createState() => _ProwlarrReleaseTileState();
}

class _ProwlarrReleaseTileState extends State<ProwlarrReleaseTile> {
  LunaLoadingState _downloadState = LunaLoadingState.INACTIVE;

  Future<void> _startDownload() async {
    setState(() => _downloadState = LunaLoadingState.ACTIVE);
    await ProwlarrApi.grabToNzbget(widget.release, category: widget.category);
    if (mounted) {
      setState(() => _downloadState = LunaLoadingState.INACTIVE);
    }
  }

  void _showRejections(List<String> reasons) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Warnings / Rejections'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reasons
              .map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $reason'),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startDownload();
            },
            child: const Text('Download Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.release;
    final title = (r['title'] ?? '').toString();
    final indexer = (r['indexer'] ?? 'Usenet').toString();
    final size = ProwlarrApi.formatSize(r['size']);
    final age = ProwlarrApi.formatAge(r);
    final quality = ProwlarrApi.parseQuality(title);
    final tags = ProwlarrApi.parseTags(title);
    final rejections = ProwlarrApi.evaluateRejections(
      r,
      category: widget.category,
      blocklist: widget.blocklist,
      qualityProfile: widget.qualityProfile,
    );
    final isRejected = rejections.isNotEmpty;
    final isBlocklisted = rejections.any((e) => e.toLowerCase().contains('blocklist'));
    final isQualityMismatch = rejections.any((e) => e.toLowerCase().contains('quality profile'));

    return LunaExpandableListTile(
      title: title,
      collapsedSubtitles: [
        TextSpan(
          children: [
            const TextSpan(
              text: 'Prowlarr',
              style: TextStyle(
                color: LunaColours.purple,
                fontWeight: LunaUI.FONT_WEIGHT_BOLD,
              ),
            ),
            TextSpan(text: LunaUI.TEXT_BULLET.pad()),
            TextSpan(text: indexer),
            TextSpan(text: LunaUI.TEXT_BULLET.pad()),
            TextSpan(text: age),
          ],
        ),
        TextSpan(
          children: [
            TextSpan(
              text: quality,
              style: isQualityMismatch
                  ? const TextStyle(
                      color: LunaColours.red,
                      fontWeight: LunaUI.FONT_WEIGHT_BOLD,
                    )
                  : null,
            ),
            TextSpan(text: LunaUI.TEXT_BULLET.pad()),
            TextSpan(text: size),
            if (isBlocklisted) ...[
              TextSpan(text: LunaUI.TEXT_BULLET.pad()),
              const TextSpan(
                text: 'Blocklisted',
                style: TextStyle(
                  color: LunaColours.red,
                  fontWeight: LunaUI.FONT_WEIGHT_BOLD,
                ),
              ),
            ],
          ],
        ),
      ],
      collapsedTrailing: LunaIconButton(
        icon: isRejected ? Icons.report_outlined : Icons.download_rounded,
        color: isRejected ? LunaColours.red : LunaColours.accent,
        onPressed: () =>
            isRejected ? _showRejections(rejections) : _startDownload(),
        onLongPress: _startDownload,
        loadingState: _downloadState,
      ),
      expandedHighlightedNodes: [
        LunaHighlightedNode(
          text: 'Prowlarr',
          backgroundColor: LunaColours.purple,
        ),
        LunaHighlightedNode(
          text: 'Usenet',
          backgroundColor: LunaColours.accent,
        ),
        if (isQualityMismatch)
          LunaHighlightedNode(
            text: 'Wrong Quality',
            backgroundColor: LunaColours.red,
          ),
        if (isBlocklisted)
          LunaHighlightedNode(
            text: 'Blocklisted',
            backgroundColor: LunaColours.red,
          ),
        ...tags.map(
          (t) => LunaHighlightedNode(
            text: t,
            backgroundColor: LunaColours.blueGrey,
          ),
        ),
      ],
      expandedTableContent: [
        LunaTableContent(title: 'age', body: age),
        LunaTableContent(title: 'indexer', body: indexer),
        LunaTableContent(title: 'quality', body: quality),
        if (widget.qualityProfile != null)
          LunaTableContent(title: 'profile', body: widget.qualityProfile!.name),
        LunaTableContent(title: 'size', body: size),
        if (isRejected)
          LunaTableContent(
            title: 'rejections',
            body: rejections.join('\n'),
          ),
      ],
      expandedTableButtons: [
        LunaButton(
          type: LunaButtonType.TEXT,
          text: 'Download',
          icon: Icons.download_rounded,
          onTap: _startDownload,
          loadingState: _downloadState,
        ),
        if (isRejected)
          LunaButton.text(
            text: 'Rejected',
            icon: Icons.report_outlined,
            color: LunaColours.red,
            onTap: () => _showRejections(rejections),
          ),
      ],
    );
  }
}

class ProwlarrSearchSheet extends LunaBottomModalSheet {
  final String initialQuery;
  final String defaultCategory;

  ProwlarrSearchSheet({
    this.initialQuery = '',
    this.defaultCategory = 'all',
  });

  @override
  Future<dynamic> show({
    Widget Function(BuildContext context)? builder,
  }) async {
    return showModal(
      builder: (context) => _ProwlarrSearchPage(
        initialQuery: initialQuery,
        defaultCategory: defaultCategory,
      ),
    );
  }
}

class _ProwlarrSearchPage extends StatefulWidget {
  final String initialQuery;
  final String defaultCategory;

  const _ProwlarrSearchPage({
    required this.initialQuery,
    required this.defaultCategory,
  });

  @override
  State<_ProwlarrSearchPage> createState() => _ProwlarrSearchPageState();
}

class _ProwlarrSearchPageState extends State<_ProwlarrSearchPage> {
  late final TextEditingController _controller;
  late String _category;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];
  Map<String, String> _blocklist = {};

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _category = widget.defaultCategory;
    if (widget.initialQuery.trim().isNotEmpty) {
      _search();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ProwlarrApi.search(q, category: _category),
        ProwlarrApi.fetchBlocklist(category: _category),
      ]);
      if (!mounted) return;
      setState(() {
        _results = results[0] as List<Map<String, dynamic>>;
        _blocklist = results[1] as Map<String, String>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openSettings() {
    final hostCtrl = TextEditingController(text: ProwlarrConfig.host);
    final keyCtrl = TextEditingController(text: ProwlarrConfig.apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prowlarr Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostCtrl,
              decoration: const InputDecoration(labelText: 'Prowlarr Host URL'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(labelText: 'Prowlarr API Key'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ProwlarrConfig.host = hostCtrl.text.trim();
              ProwlarrConfig.apiKey = keyCtrl.text.trim();
              Navigator.of(ctx).pop();
              _search();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: GlobalKey<ScaffoldState>(),
      appBar: LunaAppBar(
        title: 'Prowlarr Search',
        actions: [
          LunaIconButton.appBar(
            icon: Icons.settings_rounded,
            onPressed: _openSettings,
          ),
        ],
      ) as PreferredSizeWidget,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Search Prowlarr...',
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                LunaIconButton(
                  icon: Icons.search_rounded,
                  onPressed: _search,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _catChip('All', 'all'),
                const SizedBox(width: 8),
                _catChip('TV', 'tv'),
                const SizedBox(width: 8),
                _catChip('Movies', 'movies'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LunaLoader()
                : _error != null
                    ? LunaMessage(
                        text: 'Prowlarr Error:\n$_error',
                        buttonText: 'Retry',
                        onTap: _search,
                      )
                    : _results.isEmpty
                        ? LunaMessage(
                            text: 'No Prowlarr releases found',
                            buttonText: 'Search',
                            onTap: _search,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: _results.length,
                            itemBuilder: (context, index) =>
                                ProwlarrApi.buildReleaseTile(
                              _results[index],
                              category: _category,
                              blocklist: _blocklist,
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _catChip(String label, String value) {
    final selected = _category == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _category = value);
        _search();
      },
    );
  }
}
