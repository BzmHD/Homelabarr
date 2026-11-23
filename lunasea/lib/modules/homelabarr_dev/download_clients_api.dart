import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';

class TorrentItem {
  final String id;
  final String name;
  final String client;
  final String state;
  final double progress; // 0.0 - 1.0
  final int sizeBytes;
  final int dlSpeed;
  final int ulSpeed;
  final int etaSeconds;
  final double ratio;
  final bool isPaused;

  const TorrentItem({
    required this.id,
    required this.name,
    required this.client,
    required this.state,
    required this.progress,
    required this.sizeBytes,
    required this.dlSpeed,
    required this.ulSpeed,
    required this.etaSeconds,
    required this.ratio,
    required this.isPaused,
  });
}

class TorrentClientStats {
  final int dlSpeed;
  final int ulSpeed;
  final List<TorrentItem> items;

  const TorrentClientStats({
    required this.dlSpeed,
    required this.ulSpeed,
    required this.items,
  });
}

/// Unified HTTP API clients for qBittorrent, Transmission, Deluge, NZBGet, and SABnzbd.
class DownloadClientsApi {
  static const _timeout = Duration(seconds: 12);

  // ========================== qBittorrent ==========================
  static Future<String?> _qbitLoginCookie(String base, String user, String pass) async {
    final res = await http
        .post(
          Uri.parse('$base/api/v2/auth/login'),
          body: {'username': user, 'password': pass},
        )
        .timeout(_timeout);
    if (res.statusCode == 200 && res.body.trim().toLowerCase() == 'ok.') {
      final rawCookie = res.headers['set-cookie'];
      if (rawCookie != null) {
        final match = RegExp(r'SID=[^;]+').firstMatch(rawCookie);
        if (match != null) return match.group(0);
      }
      return '';
    }
    throw Exception('qBittorrent login failed (HTTP ${res.statusCode})');
  }

  static Future<String> testQBittorrent() async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.qbitHost);
    if (base.isEmpty) throw Exception('Enter qBittorrent host URL first');
    final cookie = await _qbitLoginCookie(
      base,
      HomelabarrDevConfig.qbitUser,
      HomelabarrDevConfig.qbitPass,
    );
    final res = await http.get(
      Uri.parse('$base/api/v2/app/version'),
      headers: {if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie},
    ).timeout(_timeout);
    if (res.statusCode == 200) return 'Connected to qBittorrent ${res.body.trim()}';
    throw Exception('HTTP ${res.statusCode}');
  }

  static Future<TorrentClientStats> fetchQBittorrent() async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.qbitHost);
    final cookie = await _qbitLoginCookie(
      base,
      HomelabarrDevConfig.qbitUser,
      HomelabarrDevConfig.qbitPass,
    );
    final headers = {if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie};
    final res = await http
        .get(Uri.parse('$base/api/v2/torrents/info?sort=added_on&reverse=true'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final list = json.decode(res.body) as List<dynamic>;
    int totalDl = 0;
    int totalUl = 0;
    final items = list.map((raw) {
      final m = raw as Map<String, dynamic>;
      final dl = (m['dlspeed'] as num?)?.toInt() ?? 0;
      final ul = (m['upspeed'] as num?)?.toInt() ?? 0;
      totalDl += dl;
      totalUl += ul;
      final state = (m['state'] ?? '').toString();
      final paused = state.toLowerCase().contains('paused') || state.toLowerCase().contains('stopped');
      return TorrentItem(
        id: (m['hash'] ?? '').toString(),
        name: (m['name'] ?? 'Unknown').toString(),
        client: 'qBittorrent',
        state: state,
        progress: ((m['progress'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
        sizeBytes: (m['size'] as num?)?.toInt() ?? 0,
        dlSpeed: dl,
        ulSpeed: ul,
        etaSeconds: (m['eta'] as num?)?.toInt() ?? -1,
        ratio: (m['ratio'] as num?)?.toDouble() ?? 0.0,
        isPaused: paused,
      );
    }).toList();
    return TorrentClientStats(dlSpeed: totalDl, ulSpeed: totalUl, items: items);
  }

  static Future<void> qbitAction(String action, String hash, {bool deleteFiles = false}) async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.qbitHost);
    final cookie = await _qbitLoginCookie(
      base,
      HomelabarrDevConfig.qbitUser,
      HomelabarrDevConfig.qbitPass,
    );
    final headers = {if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie};
    // qBittorrent v5 renamed pause/resume to stop/start, fallback cleanly
    String endpoint;
    final body = <String, String>{'hashes': hash};
    if (action == 'pause') {
      endpoint = '/api/v2/torrents/stop';
    } else if (action == 'resume') {
      endpoint = '/api/v2/torrents/start';
    } else {
      endpoint = '/api/v2/torrents/delete';
      body['deleteFiles'] = deleteFiles ? 'true' : 'false';
    }
    var res = await http.post(Uri.parse('$base$endpoint'), headers: headers, body: body).timeout(_timeout);
    if (res.statusCode == 404 && (action == 'pause' || action == 'resume')) {
      final legacy = action == 'pause' ? '/api/v2/torrents/pause' : '/api/v2/torrents/resume';
      res = await http.post(Uri.parse('$base$legacy'), headers: headers, body: body).timeout(_timeout);
    }
    if (res.statusCode != 200) throw Exception('qBittorrent action failed (HTTP ${res.statusCode})');
  }

  static Future<void> addToQBittorrent(String urlOrMagnet, {String? category}) async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.qbitHost);
    final cookie = await _qbitLoginCookie(
      base,
      HomelabarrDevConfig.qbitUser,
      HomelabarrDevConfig.qbitPass,
    );
    final headers = {if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie};
    final cat = (category != null && category.isNotEmpty)
        ? category
        : HomelabarrDevConfig.qbitCategory;
    final body = <String, String>{'urls': urlOrMagnet};
    if (cat.isNotEmpty) body['category'] = cat;
    final res = await http
        .post(Uri.parse('$base/api/v2/torrents/add'), headers: headers, body: body)
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('qBittorrent add failed (HTTP ${res.statusCode})');
  }

  // ========================== Transmission ==========================
  static String _transmissionSessionId = '';

  static Future<Map<String, dynamic>> _transmissionRpc(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.transHost);
    if (base.isEmpty) throw Exception('Enter Transmission host URL first');
    final rpcUrl = base.endsWith('/transmission/rpc') ? base : '$base/transmission/rpc';
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_transmissionSessionId.isNotEmpty) 'X-Transmission-Session-Id': _transmissionSessionId,
    };
    if (HomelabarrDevConfig.transUser.isNotEmpty || HomelabarrDevConfig.transPass.isNotEmpty) {
      final auth = base64Encode(utf8.encode('${HomelabarrDevConfig.transUser}:${HomelabarrDevConfig.transPass}'));
      headers['Authorization'] = 'Basic $auth';
    }
    final payload = json.encode({'method': method, if (arguments != null) 'arguments': arguments});
    var res = await http.post(Uri.parse(rpcUrl), headers: headers, body: payload).timeout(_timeout);
    if (res.statusCode == 409) {
      final sid = res.headers['x-transmission-session-id'] ?? '';
      if (sid.isNotEmpty) {
        _transmissionSessionId = sid;
        headers['X-Transmission-Session-Id'] = sid;
        res = await http.post(Uri.parse(rpcUrl), headers: headers, body: payload).timeout(_timeout);
      }
    }
    if (res.statusCode != 200) throw Exception('Transmission RPC HTTP ${res.statusCode}');
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    if (decoded['result'] != 'success') {
      throw Exception('Transmission error: ${decoded['result']}');
    }
    return (decoded['arguments'] as Map<String, dynamic>?) ?? {};
  }

  static Future<String> testTransmission() async {
    final args = await _transmissionRpc('session-get');
    final ver = args['version']?.toString() ?? 'OK';
    return 'Connected to Transmission $ver';
  }

  static Future<TorrentClientStats> fetchTransmission() async {
    final args = await _transmissionRpc('torrent-get', {
      'fields': [
        'id',
        'name',
        'status',
        'percentDone',
        'totalSize',
        'rateDownload',
        'rateUpload',
        'eta',
        'uploadRatio',
      ],
    });
    final list = (args['torrents'] as List<dynamic>?) ?? [];
    int totalDl = 0;
    int totalUl = 0;
    const statusLabels = {
      0: 'Stopped',
      1: 'Check Wait',
      2: 'Checking',
      3: 'Queued',
      4: 'Downloading',
      5: 'Seed Wait',
      6: 'Seeding',
    };
    final items = list.map((raw) {
      final m = raw as Map<String, dynamic>;
      final dl = (m['rateDownload'] as num?)?.toInt() ?? 0;
      final ul = (m['rateUpload'] as num?)?.toInt() ?? 0;
      final statusCode = (m['status'] as num?)?.toInt() ?? 0;
      totalDl += dl;
      totalUl += ul;
      return TorrentItem(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? 'Unknown').toString(),
        client: 'Transmission',
        state: statusLabels[statusCode] ?? 'Status $statusCode',
        progress: ((m['percentDone'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
        sizeBytes: (m['totalSize'] as num?)?.toInt() ?? 0,
        dlSpeed: dl,
        ulSpeed: ul,
        etaSeconds: (m['eta'] as num?)?.toInt() ?? -1,
        ratio: (m['uploadRatio'] as num?)?.toDouble() ?? 0.0,
        isPaused: statusCode == 0,
      );
    }).toList();
    return TorrentClientStats(dlSpeed: totalDl, ulSpeed: totalUl, items: items);
  }

  static Future<void> transmissionAction(String action, String id, {bool deleteFiles = false}) async {
    final intId = int.tryParse(id);
    final ids = [intId ?? id];
    if (action == 'pause') {
      await _transmissionRpc('torrent-stop', {'ids': ids});
    } else if (action == 'resume') {
      await _transmissionRpc('torrent-start', {'ids': ids});
    } else {
      await _transmissionRpc('torrent-remove', {'ids': ids, 'delete-local-data': deleteFiles});
    }
  }

  static Future<void> addToTransmission(String urlOrMagnet) async {
    await _transmissionRpc('torrent-add', {'filename': urlOrMagnet});
  }

  // ========================== Deluge ==========================
  static Future<String> _delugeLoginCookie(String base, String pass) async {
    final res = await http
        .post(
          Uri.parse('$base/json'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'id': 1, 'method': 'auth.login', 'params': [pass]}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Deluge HTTP ${res.statusCode}');
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    if (decoded['result'] != true) throw Exception('Deluge login rejected');
    final rawCookie = res.headers['set-cookie'] ?? '';
    final match = RegExp(r'_session_id=[^;]+').firstMatch(rawCookie);
    return match?.group(0) ?? '';
  }

  static Future<dynamic> _delugeCall(String method, List<dynamic> params) async {
    final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.delugeHost);
    if (base.isEmpty) throw Exception('Enter Deluge WebUI host URL first');
    final cookie = await _delugeLoginCookie(base, HomelabarrDevConfig.delugePass);
    final res = await http
        .post(
          Uri.parse('$base/json'),
          headers: {
            'Content-Type': 'application/json',
            if (cookie.isNotEmpty) 'Cookie': cookie,
          },
          body: json.encode({'id': 2, 'method': method, 'params': params}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Deluge HTTP ${res.statusCode}');
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    if (decoded['error'] != null) throw Exception('Deluge: ${decoded['error']}');
    return decoded['result'];
  }

  static Future<String> testDeluge() async {
    final ver = await _delugeCall('daemon.info', []);
    return 'Connected to Deluge ${ver ?? "WebUI"}';
  }

  static Future<TorrentClientStats> fetchDeluge() async {
    final result = await _delugeCall('web.update_ui', [
      ['name', 'state', 'progress', 'total_size', 'download_payload_rate', 'upload_payload_rate', 'eta', 'ratio'],
      {},
    ]);
    final map = (result as Map<String, dynamic>?) ?? {};
    final torrents = (map['torrents'] as Map<String, dynamic>?) ?? {};
    int totalDl = 0;
    int totalUl = 0;
    final items = torrents.entries.map((entry) {
      final m = entry.value as Map<String, dynamic>;
      final dl = (m['download_payload_rate'] as num?)?.toInt() ?? 0;
      final ul = (m['upload_payload_rate'] as num?)?.toInt() ?? 0;
      totalDl += dl;
      totalUl += ul;
      final state = (m['state'] ?? '').toString();
      return TorrentItem(
        id: entry.key,
        name: (m['name'] ?? 'Unknown').toString(),
        client: 'Deluge',
        state: state,
        progress: (((m['progress'] as num?)?.toDouble() ?? 0.0) / 100.0).clamp(0.0, 1.0),
        sizeBytes: (m['total_size'] as num?)?.toInt() ?? 0,
        dlSpeed: dl,
        ulSpeed: ul,
        etaSeconds: (m['eta'] as num?)?.toInt() ?? -1,
        ratio: (m['ratio'] as num?)?.toDouble() ?? 0.0,
        isPaused: state.toLowerCase() == 'paused',
      );
    }).toList();
    return TorrentClientStats(dlSpeed: totalDl, ulSpeed: totalUl, items: items);
  }

  static Future<void> delugeAction(String action, String id, {bool deleteFiles = false}) async {
    if (action == 'pause') {
      await _delugeCall('core.pause_torrent', [[id]]);
    } else if (action == 'resume') {
      await _delugeCall('core.resume_torrent', [[id]]);
    } else {
      await _delugeCall('core.remove_torrent', [id, deleteFiles]);
    }
  }

  static Future<void> addToDeluge(String urlOrMagnet) async {
    if (urlOrMagnet.startsWith('magnet:')) {
      await _delugeCall('core.add_torrent_magnet', [urlOrMagnet, {}]);
    } else {
      await _delugeCall('core.add_torrent_url', [urlOrMagnet, {}]);
    }
  }

  // ========================== SABnzbd & NZBGet ==========================
  static Future<void> addToSABnzbd({
    required String url,
    required String title,
    String category = '',
  }) async {
    final profile = LunaProfile.current;
    final base = HomelabarrDevConfig.normalizeBaseUrl(profile.sabnzbdHost);
    if (base.isEmpty || profile.sabnzbdKey.isEmpty) {
      throw Exception('SABnzbd is not configured in your active profile');
    }
    final uri = Uri.parse('$base/api').replace(queryParameters: {
      'mode': 'addurl',
      'name': url,
      'nzbname': title,
      if (category.isNotEmpty) 'cat': category,
      'apikey': profile.sabnzbdKey,
      'output': 'json',
    });
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('SABnzbd HTTP ${res.statusCode}');
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    if (decoded['status'] != true) {
      throw Exception('SABnzbd rejected NZB: ${decoded['error'] ?? res.body}');
    }
  }

  static Future<void> addToNZBGet({
    required String url,
    required String title,
    String category = '',
  }) async {
    final profile = LunaProfile.current;
    final rawHost = profile.nzbgetHost.trim();
    final user = profile.nzbgetUser.trim();
    final pass = profile.nzbgetPass;
    if (rawHost.isEmpty) {
      throw Exception('NZBGet is not configured in your active profile');
    }
    final base = HomelabarrDevConfig.normalizeBaseUrl(rawHost);
    final auth = base64Encode(utf8.encode('$user:$pass'));
    final res = await http
        .post(
          Uri.parse('$base/jsonrpc'),
          headers: {
            'Authorization': 'Basic $auth',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'method': 'append',
            'params': [
              '$title.nzb',
              url,
              category,
              0,
              false,
              false,
              '',
              0,
              'SCORE',
              [],
            ],
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('NZBGet HTTP ${res.statusCode}');
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    final result = decoded['result'];
    if (result == null || result == 0 || result == false) {
      throw Exception('NZBGet rejected release');
    }
  }

  /// Smart multi-downloader dispatcher used by Prowlarr Interactive Search
  /// and the standalone Prowlarr module.
  static Future<void> dispatchRelease({
    required BuildContext context,
    required String title,
    required String downloadUrl,
    required bool isTorrent,
    String category = '',
  }) async {
    if (isTorrent) {
      final clients = HomelabarrDevConfig.configuredTorrentClients;
      if (clients.isEmpty) {
        showLunaErrorSnackBar(
          title: 'No Torrent Client Configured',
          message: 'Enable qBittorrent, Transmission, or Deluge in Downloaders & Apps.',
        );
        return;
      }
      String? chosen = clients.length == 1
          ? clients.first
          : await _pickClient(context, 'Send Torrent To', clients);
      if (chosen == null) return;
      try {
        if (chosen == 'qBittorrent') {
          await addToQBittorrent(downloadUrl, category: category);
        } else if (chosen == 'Transmission') {
          await addToTransmission(downloadUrl);
        } else if (chosen == 'Deluge') {
          await addToDeluge(downloadUrl);
        }
        showLunaSuccessSnackBar(
          title: 'Sent to $chosen',
          message: title,
        );
      } catch (e) {
        showLunaErrorSnackBar(title: '$chosen Failed', message: e.toString());
      }
      return;
    }

    // Usenet release
    final profile = LunaProfile.current;
    final hasNzbget = profile.nzbgetHost.trim().isNotEmpty;
    final hasSab = profile.sabnzbdEnabled && profile.sabnzbdHost.trim().isNotEmpty && profile.sabnzbdKey.trim().isNotEmpty;
    final usenetClients = <String>[
      if (hasNzbget) 'NZBGet',
      if (hasSab) 'SABnzbd',
    ];
    if (usenetClients.isEmpty) {
      showLunaErrorSnackBar(
        title: 'No NZB Downloader Configured',
        message: 'Configure NZBGet or SABnzbd in Settings first.',
      );
      return;
    }
    String? chosen = usenetClients.length == 1
        ? usenetClients.first
        : await _pickClient(context, 'Send NZB To', usenetClients);
    if (chosen == null) return;
    try {
      if (chosen == 'SABnzbd') {
        await addToSABnzbd(url: downloadUrl, title: title, category: category);
      } else {
        await addToNZBGet(url: downloadUrl, title: title, category: category);
      }
      showLunaSuccessSnackBar(
        title: 'Sent to $chosen',
        message: title,
      );
    } catch (e) {
      showLunaErrorSnackBar(title: '$chosen Failed', message: e.toString());
    }
  }

  static Future<String?> _pickClient(
    BuildContext context,
    String title,
    List<String> options,
  ) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (name) => ListTile(
                  leading: Icon(
                    Icons.download_rounded,
                    color: LunaColours.accent,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.of(ctx).pop(name),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
