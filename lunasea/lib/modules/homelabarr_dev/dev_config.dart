import 'package:flutter/foundation.dart';
import 'package:lunasea/core.dart';

/// Persistent configuration for Homelabarr Dev modules (Torrent clients,
/// Overseerr/Jellyseerr, Prowlarr, and Bazarr), stored in `LunaBox.lunasea`.
class HomelabarrDevConfig {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void notify() => revision.value++;

  static dynamic _read(String key, [dynamic fallback]) {
    try {
      return LunaBox.lunasea.read(key, fallback: fallback);
    } catch (_) {
      return fallback;
    }
  }

  static void _write(String key, dynamic value) {
    try {
      LunaBox.lunasea.update(key, value);
      notify();
    } catch (_) {}
  }

  // --- qBittorrent ---
  static bool get qbitEnabled => _read('HL_QBIT_ENABLED', false) == true;
  static set qbitEnabled(bool v) => _write('HL_QBIT_ENABLED', v);

  static String get qbitHost => (_read('HL_QBIT_HOST', '') ?? '').toString();
  static set qbitHost(String v) => _write('HL_QBIT_HOST', v.trim());

  static String get qbitUser => (_read('HL_QBIT_USER', 'admin') ?? '').toString();
  static set qbitUser(String v) => _write('HL_QBIT_USER', v.trim());

  static String get qbitPass => (_read('HL_QBIT_PASS', '') ?? '').toString();
  static set qbitPass(String v) => _write('HL_QBIT_PASS', v);

  static String get qbitCategory => (_read('HL_QBIT_CAT', '') ?? '').toString();
  static set qbitCategory(String v) => _write('HL_QBIT_CAT', v.trim());

  // --- Transmission ---
  static bool get transEnabled => _read('HL_TRANS_ENABLED', false) == true;
  static set transEnabled(bool v) => _write('HL_TRANS_ENABLED', v);

  static String get transHost => (_read('HL_TRANS_HOST', '') ?? '').toString();
  static set transHost(String v) => _write('HL_TRANS_HOST', v.trim());

  static String get transUser => (_read('HL_TRANS_USER', '') ?? '').toString();
  static set transUser(String v) => _write('HL_TRANS_USER', v.trim());

  static String get transPass => (_read('HL_TRANS_PASS', '') ?? '').toString();
  static set transPass(String v) => _write('HL_TRANS_PASS', v);

  // --- Deluge ---
  static bool get delugeEnabled => _read('HL_DELUGE_ENABLED', false) == true;
  static set delugeEnabled(bool v) => _write('HL_DELUGE_ENABLED', v);

  static String get delugeHost => (_read('HL_DELUGE_HOST', '') ?? '').toString();
  static set delugeHost(String v) => _write('HL_DELUGE_HOST', v.trim());

  static String get delugePass => (_read('HL_DELUGE_PASS', '') ?? '').toString();
  static set delugePass(String v) => _write('HL_DELUGE_PASS', v);

  // --- Overseerr / Jellyseerr ---
  static bool get overseerrEnabled => _read('HL_OVERSEERR_ENABLED', false) == true;
  static set overseerrEnabled(bool v) => _write('HL_OVERSEERR_ENABLED', v);

  static String get overseerrHost => (_read('HL_OVERSEERR_HOST', '') ?? '').toString();
  static set overseerrHost(String v) => _write('HL_OVERSEERR_HOST', v.trim());

  static String get overseerrApiKey => (_read('HL_OVERSEERR_KEY', '') ?? '').toString();
  static set overseerrApiKey(String v) => _write('HL_OVERSEERR_KEY', v.trim());

  // --- Prowlarr (shared with Prowlarr Interactive Search) ---
  static bool get prowlarrEnabled => _read('HL_PROWLARR_MODULE_ENABLED', false) == true;
  static set prowlarrEnabled(bool v) => _write('HL_PROWLARR_MODULE_ENABLED', v);

  static String get prowlarrHost {
    return (_read('HOMELABARR_PROWLARR_HOST', '') ?? '').toString().trim();
  }
  static set prowlarrHost(String v) => _write('HOMELABARR_PROWLARR_HOST', v.trim());

  static String get prowlarrApiKey {
    return (_read('HOMELABARR_PROWLARR_API_KEY', '') ?? '').toString().trim();
  }
  static set prowlarrApiKey(String v) => _write('HOMELABARR_PROWLARR_API_KEY', v.trim());

  // --- Bazarr ---
  static bool get bazarrEnabled => _read('HL_BAZARR_ENABLED', false) == true;
  static set bazarrEnabled(bool v) => _write('HL_BAZARR_ENABLED', v);

  static String get bazarrHost => (_read('HL_BAZARR_HOST', '') ?? '').toString();
  static set bazarrHost(String v) => _write('HL_BAZARR_HOST', v.trim());

  static String get bazarrApiKey => (_read('HL_BAZARR_KEY', '') ?? '').toString();
  static set bazarrApiKey(String v) => _write('HL_BAZARR_KEY', v.trim());

  // --- Dashboard Layout ('stacked' | 'grid2' | 'grid3' | 'grouped') ---
  static String get dashboardLayout => (_read('HL_DASHBOARD_LAYOUT', 'stacked') ?? 'stacked').toString();
  static set dashboardLayout(String v) => _write('HL_DASHBOARD_LAYOUT', v);

  // --- Helpers ---
  static bool get anyTorrentEnabled => qbitEnabled || transEnabled || delugeEnabled;

  static List<String> get enabledTorrentClients {
    final out = <String>[];
    if (qbitEnabled) out.add('qBittorrent');
    if (transEnabled) out.add('Transmission');
    if (delugeEnabled) out.add('Deluge');
    return out;
  }

  static List<String> get configuredTorrentClients {
    final out = <String>[];
    if (qbitEnabled && qbitHost.isNotEmpty) out.add('qBittorrent');
    if (transEnabled && transHost.isNotEmpty) out.add('Transmission');
    if (delugeEnabled && delugeHost.isNotEmpty) out.add('Deluge');
    return out;
  }

  static bool get anyDevAppEnabled =>
      qbitEnabled ||
      transEnabled ||
      delugeEnabled ||
      overseerrEnabled ||
      prowlarrEnabled ||
      bazarrEnabled;

  static String normalizeBaseUrl(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return '';
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
