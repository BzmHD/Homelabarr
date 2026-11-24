import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/download_clients_api.dart';

class ServiceLiveStatus {
  final bool online;
  final String badgeText;
  final Color badgeColor;
  final int activeCount;
  final int dlSpeedBytes;
  final bool isPaused;

  const ServiceLiveStatus({
    required this.online,
    required this.badgeText,
    required this.badgeColor,
    this.activeCount = 0,
    this.dlSpeedBytes = 0,
    this.isPaused = false,
  });
}

class DashboardLiveStatusService {
  static final ValueNotifier<Map<String, ServiceLiveStatus>> statuses =
      ValueNotifier<Map<String, ServiceLiveStatus>>({});
  static final ValueNotifier<bool> refreshing = ValueNotifier<bool>(false);
  static DateTime? _lastFetch;

  static const _timeout = Duration(seconds: 5);

  static String fmtSpeed(int bytesPerSec) {
    if (bytesPerSec <= 0) return '0 B/s';
    final mb = bytesPerSec / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB/s';
    final kb = bytesPerSec / 1024;
    if (kb >= 1) return '${kb.toStringAsFixed(0)} KB/s';
    return '$bytesPerSec B/s';
  }

  static Future<void> refresh({bool force = false}) async {
    if (refreshing.value) return;
    if (!force &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(seconds: 12)) {
      return;
    }
    refreshing.value = true;
    _lastFetch = DateTime.now();

    final p = LunaProfile.current;
    final map = <String, ServiceLiveStatus>{};
    final tasks = <Future<void>>[];

    if (p.nzbgetEnabled && p.nzbgetHost.trim().isNotEmpty) {
      tasks.add(_pollNzbget(p).then((s) {
        if (s != null) map['nzbget'] = s;
      }));
    }
    if (p.sabnzbdEnabled && p.sabnzbdHost.trim().isNotEmpty && p.sabnzbdKey.trim().isNotEmpty) {
      tasks.add(_pollSab(p).then((s) {
        if (s != null) map['sabnzbd'] = s;
      }));
    }
    if (p.radarrEnabled && p.radarrHost.trim().isNotEmpty && p.radarrKey.trim().isNotEmpty) {
      tasks.add(_pollArr(p.radarrHost, p.radarrKey, '/api/v3/queue').then((s) {
        if (s != null) map['radarr'] = s;
      }));
    }
    if (p.sonarrEnabled && p.sonarrHost.trim().isNotEmpty && p.sonarrKey.trim().isNotEmpty) {
      tasks.add(_pollArr(p.sonarrHost, p.sonarrKey, '/api/v3/queue').then((s) {
        if (s != null) map['sonarr'] = s;
      }));
    }
    if (HomelabarrDevConfig.qbitEnabled && HomelabarrDevConfig.qbitHost.isNotEmpty) {
      tasks.add(_pollTorrent('qBittorrent', DownloadClientsApi.fetchQBittorrent).then((s) {
        if (s != null) map['qbittorrent'] = s;
      }));
    }
    if (HomelabarrDevConfig.transEnabled && HomelabarrDevConfig.transHost.isNotEmpty) {
      tasks.add(_pollTorrent('Transmission', DownloadClientsApi.fetchTransmission).then((s) {
        if (s != null) map['transmission'] = s;
      }));
    }
    if (HomelabarrDevConfig.delugeEnabled && HomelabarrDevConfig.delugeHost.isNotEmpty) {
      tasks.add(_pollTorrent('Deluge', DownloadClientsApi.fetchDeluge).then((s) {
        if (s != null) map['deluge'] = s;
      }));
    }
    if (HomelabarrDevConfig.overseerrEnabled &&
        HomelabarrDevConfig.overseerrHost.isNotEmpty &&
        HomelabarrDevConfig.overseerrApiKey.isNotEmpty) {
      tasks.add(_pollOverseerr().then((s) {
        if (s != null) map['overseerr'] = s;
      }));
    }
    if (HomelabarrDevConfig.readarrEnabled &&
        HomelabarrDevConfig.readarrHost.isNotEmpty &&
        HomelabarrDevConfig.readarrApiKey.isNotEmpty) {
      tasks.add(_pollReadarr().then((s) {
        if (s != null) map['readarr'] = s;
      }));
    }
    if (HomelabarrDevConfig.bazarrEnabled &&
        HomelabarrDevConfig.bazarrHost.isNotEmpty &&
        HomelabarrDevConfig.bazarrApiKey.isNotEmpty) {
      tasks.add(_pollBazarr().then((s) {
        if (s != null) map['bazarr'] = s;
      }));
    }
    if (HomelabarrDevConfig.prowlarrEnabled &&
        HomelabarrDevConfig.prowlarrHost.isNotEmpty &&
        HomelabarrDevConfig.prowlarrApiKey.isNotEmpty) {
      tasks.add(_pollProwlarr().then((s) {
        if (s != null) map['prowlarr'] = s;
      }));
    }

    await Future.wait(tasks);
    statuses.value = map;
    refreshing.value = false;
  }

  static Future<ServiceLiveStatus?> _pollNzbget(LunaProfile p) async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(p.nzbgetHost);
      final auth = base64Encode(utf8.encode('${p.nzbgetUser}:${p.nzbgetPass}'));
      final res = await http
          .post(
            Uri.parse('$base/jsonrpc'),
            headers: {'Authorization': 'Basic $auth', 'Content-Type': 'application/json'},
            body: json.encode({'method': 'status', 'params': []}),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) throw Exception();
      final r = (json.decode(res.body) as Map<String, dynamic>)['result'] as Map<String, dynamic>;
      final rate = (r['DownloadRate'] as num?)?.toInt() ?? 0;
      final remMb = (r['RemainingSizeMB'] as num?)?.toInt() ?? 0;
      final paused = r['DownloadPaused'] == true;
      final active = remMb > 0 ? 1 : 0;
      return ServiceLiveStatus(
        online: true,
        badgeText: paused
            ? 'Paused'
            : (rate > 0 ? fmtSpeed(rate) : (remMb > 0 ? '${remMb}MB left' : 'Idle')),
        badgeColor: paused ? LunaColours.orange : (rate > 0 ? LunaColours.accent : Colors.white54),
        activeCount: active,
        dlSpeedBytes: rate,
        isPaused: paused,
      );
    } catch (_) {
      return const ServiceLiveStatus(online: false, badgeText: 'Offline', badgeColor: LunaColours.red);
    }
  }

  static Future<void> toggleNzbgetPause(bool pause) async {
    final p = LunaProfile.current;
    if (p.nzbgetHost.trim().isEmpty) return;
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(p.nzbgetHost);
      final auth = base64Encode(utf8.encode('${p.nzbgetUser}:${p.nzbgetPass}'));
      await http
          .post(
            Uri.parse('$base/jsonrpc'),
            headers: {'Authorization': 'Basic $auth', 'Content-Type': 'application/json'},
            body: json.encode({'method': pause ? 'pausedownload' : 'resumedownload', 'params': []}),
          )
          .timeout(_timeout);
      await refresh(force: true);
    } catch (_) {}
  }

  static Future<ServiceLiveStatus?> _pollSab(LunaProfile p) async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(p.sabnzbdHost);
      final res = await http
          .get(Uri.parse('$base/api?mode=queue&apikey=${Uri.encodeQueryComponent(p.sabnzbdKey)}&output=json'))
          .timeout(_timeout);
      if (res.statusCode != 200) throw Exception();
      final q = (json.decode(res.body) as Map<String, dynamic>)['queue'] as Map<String, dynamic>;
      final kbPerSec = double.tryParse((q['kbpersec'] ?? '0').toString()) ?? 0;
      final bytesPerSec = (kbPerSec * 1024).round();
      final slots = (q['slots'] as List<dynamic>? ?? []).length;
      final paused = q['paused'] == true;
      return ServiceLiveStatus(
        online: true,
        badgeText: paused ? 'Paused' : (bytesPerSec > 0 ? fmtSpeed(bytesPerSec) : 'Idle'),
        badgeColor: paused ? LunaColours.orange : (bytesPerSec > 0 ? LunaColours.accent : Colors.white54),
        activeCount: slots,
        dlSpeedBytes: bytesPerSec,
        isPaused: paused,
      );
    } catch (_) {
      return const ServiceLiveStatus(online: false, badgeText: 'Offline', badgeColor: LunaColours.red);
    }
  }

  static Future<ServiceLiveStatus?> _pollArr(String host, String key, String path) async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(host);
      final res = await http.get(Uri.parse('$base$path?page=1&pageSize=1'), headers: {'X-Api-Key': key}).timeout(_timeout);
      if (res.statusCode != 200) throw Exception();
      final d = json.decode(res.body) as Map<String, dynamic>;
      final total = (d['totalRecords'] as num?)?.toInt() ?? 0;
      return ServiceLiveStatus(
        online: true,
        badgeText: total > 0 ? '$total queued' : 'Online',
        badgeColor: total > 0 ? LunaColours.blue : LunaColours.accent,
        activeCount: total,
      );
    } catch (_) {
      return const ServiceLiveStatus(online: false, badgeText: 'Offline', badgeColor: LunaColours.red);
    }
  }

  static Future<ServiceLiveStatus?> _pollTorrent(
    String name,
    Future<TorrentClientStats> Function() fetchFn,
  ) async {
    try {
      final stats = await fetchFn();
      final active = stats.items.where((t) => !t.isPaused && t.progress < 1.0).length;
      return ServiceLiveStatus(
        online: true,
        badgeText: stats.dlSpeed > 0 ? fmtSpeed(stats.dlSpeed) : '${stats.items.length} active',
        badgeColor: stats.dlSpeed > 0 ? LunaColours.accent : Colors.white54,
        activeCount: active,
        dlSpeedBytes: stats.dlSpeed,
      );
    } catch (_) {
      return const ServiceLiveStatus(online: false, badgeText: 'Offline', badgeColor: LunaColours.red);
    }
  }

  static Future<ServiceLiveStatus?> _pollOverseerr() async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.overseerrHost);
      final res = await http.get(
        Uri.parse('$base/api/v1/request/count'),
        headers: {'X-Api-Key': HomelabarrDevConfig.overseerrApiKey},
      ).timeout(_timeout);
      if (res.statusCode != 200) throw Exception();
      final d = json.decode(res.body) as Map<String, dynamic>;
      final pending = (d['pending'] as num?)?.toInt() ?? 0;
      return ServiceLiveStatus(
        online: true,
        badgeText: pending > 0 ? '$pending pending' : 'Online',
        badgeColor: pending > 0 ? LunaColours.orange : LunaColours.accent,
        activeCount: pending,
      );
    } catch (_) {
      return const ServiceLiveStatus(online: false, badgeText: 'Offline', badgeColor: LunaColours.red);
    }
  }

  static Future<ServiceLiveStatus?> _pollReadarr() async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.readarrHost);
      final res = await http.get(
        Uri.parse('$base/api/v1/wanted/missing?page=1&pageSize=1'),
        headers: {'X-Api-Key': HomelabarrDevConfig.readarrApiKey},
      ).timeout(_timeout);
      if (res.statusCode != 200) throw Exception();
      final d = json.decode(res.body) as Map<String, dynamic>;
      final total = (d['totalRecords'] as num?)?.toInt() ?? 0;
      return ServiceLiveStatus(
        online: true,
        badgeText: total > 0 ? '$total missing' : 'Online',
        badgeColor: total > 0 ? LunaColours.orange : LunaColours.accent,
        activeCount: total,
      );
    } catch (_) {
      return const ServiceLiveStatus(online: false, badgeText: 'Offline', badgeColor: LunaColours.red);
    }
  }

  static Future<ServiceLiveStatus?> _pollBazarr() async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.bazarrHost);
      final res = await http.get(
        Uri.parse('$base/api/badges'),
        headers: {'X-API-KEY': HomelabarrDevConfig.bazarrApiKey},
      ).timeout(_timeout);
      if (res.statusCode != 200) throw Exception();
      final d = json.decode(res.body) as Map<String, dynamic>;
      final missing = ((d['movies'] as num?)?.toInt() ?? 0) + ((d['episodes'] as num?)?.toInt() ?? 0);
      return ServiceLiveStatus(
        online: true,
        badgeText: missing > 0 ? '$missing wanted' : 'Online',
        badgeColor: missing > 0 ? LunaColours.orange : LunaColours.accent,
        activeCount: missing,
      );
    } catch (_) {
      return const ServiceLiveStatus(online: false, badgeText: 'Offline', badgeColor: LunaColours.red);
    }
  }

  static Future<ServiceLiveStatus?> _pollProwlarr() async {
    try {
      final base = HomelabarrDevConfig.normalizeBaseUrl(HomelabarrDevConfig.prowlarrHost);
      final res = await http.get(
        Uri.parse('$base/api/v1/health'),
        headers: {'X-Api-Key': HomelabarrDevConfig.prowlarrApiKey},
      ).timeout(_timeout);
      if (res.statusCode != 200) throw Exception();
      final warnings = (json.decode(res.body) as List<dynamic>).length;
      return ServiceLiveStatus(
        online: true,
        badgeText: warnings > 0 ? '$warnings warn' : 'Online',
        badgeColor: warnings > 0 ? LunaColours.orange : LunaColours.accent,
      );
    } catch (_) {
      return const ServiceLiveStatus(online: false, badgeText: 'Offline', badgeColor: LunaColours.red);
    }
  }
}
