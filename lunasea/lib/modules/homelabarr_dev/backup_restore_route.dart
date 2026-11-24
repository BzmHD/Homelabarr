import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/sheet.dart';
import 'package:lunasea/widgets/ui/homelabarr_themes.dart';

class HomelabarrBackupRoute extends StatefulWidget {
  const HomelabarrBackupRoute({super.key});

  @override
  State<HomelabarrBackupRoute> createState() => _HomelabarrBackupRouteState();
}

class _HomelabarrBackupRouteState extends State<HomelabarrBackupRoute> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> _buildBackupPayload() {
    final p = LunaProfile.current;
    return {
      'app': 'Homelabarr',
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'ui': {
        'theme': HomelabarrTheme.current.id,
        'dashboardLayout': HomelabarrDevConfig.dashboardLayout,
      },
      'profile': {
        'radarrEnabled': p.radarrEnabled,
        'radarrHost': p.radarrHost,
        'radarrKey': p.radarrKey,
        'sonarrEnabled': p.sonarrEnabled,
        'sonarrHost': p.sonarrHost,
        'sonarrKey': p.sonarrKey,
        'lidarrEnabled': p.lidarrEnabled,
        'lidarrHost': p.lidarrHost,
        'lidarrKey': p.lidarrKey,
        'nzbgetEnabled': p.nzbgetEnabled,
        'nzbgetHost': p.nzbgetHost,
        'nzbgetUser': p.nzbgetUser,
        'nzbgetPass': p.nzbgetPass,
        'sabnzbdEnabled': p.sabnzbdEnabled,
        'sabnzbdHost': p.sabnzbdHost,
        'sabnzbdKey': p.sabnzbdKey,
        'tautulliEnabled': p.tautulliEnabled,
        'tautulliHost': p.tautulliHost,
        'tautulliKey': p.tautulliKey,
      },
      'apps': {
        'qbitEnabled': HomelabarrDevConfig.qbitEnabled,
        'qbitHost': HomelabarrDevConfig.qbitHost,
        'qbitUser': HomelabarrDevConfig.qbitUser,
        'qbitPass': HomelabarrDevConfig.qbitPass,
        'qbitCategory': HomelabarrDevConfig.qbitCategory,
        'transEnabled': HomelabarrDevConfig.transEnabled,
        'transHost': HomelabarrDevConfig.transHost,
        'transUser': HomelabarrDevConfig.transUser,
        'transPass': HomelabarrDevConfig.transPass,
        'delugeEnabled': HomelabarrDevConfig.delugeEnabled,
        'delugeHost': HomelabarrDevConfig.delugeHost,
        'delugePass': HomelabarrDevConfig.delugePass,
        'overseerrEnabled': HomelabarrDevConfig.overseerrEnabled,
        'overseerrHost': HomelabarrDevConfig.overseerrHost,
        'overseerrApiKey': HomelabarrDevConfig.overseerrApiKey,
        'prowlarrEnabled': HomelabarrDevConfig.prowlarrEnabled,
        'prowlarrHost': HomelabarrDevConfig.prowlarrHost,
        'prowlarrApiKey': HomelabarrDevConfig.prowlarrApiKey,
        'bazarrEnabled': HomelabarrDevConfig.bazarrEnabled,
        'bazarrHost': HomelabarrDevConfig.bazarrHost,
        'bazarrApiKey': HomelabarrDevConfig.bazarrApiKey,
        'readarrEnabled': HomelabarrDevConfig.readarrEnabled,
        'readarrHost': HomelabarrDevConfig.readarrHost,
        'readarrApiKey': HomelabarrDevConfig.readarrApiKey,
      },
    };
  }

  Future<void> _exportFile() async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(_buildBackupPayload());
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/homelabarr-backup-$ts.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], subject: 'Homelabarr Backup ($ts)');
    } catch (e) {
      showLunaErrorSnackBar(title: 'Export Failed', message: e.toString());
    }
  }

  Future<void> _copyToClipboard() async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(_buildBackupPayload());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    showLunaSuccessSnackBar(
      title: 'Backup Copied',
      message: 'Full Homelabarr JSON backup copied to clipboard.',
    );
  }

  Future<void> _applyBackupJson(String rawJson) async {
    final data = json.decode(rawJson) as Map<String, dynamic>;
    if (data['app'] != 'Homelabarr') {
      throw Exception('Not a valid Homelabarr backup file');
    }

    final ui = (data['ui'] as Map<String, dynamic>?) ?? {};
    if (ui['theme'] is String) {
      final matched = HomelabarrTheme.values.firstWhere(
        (t) => t.id == ui['theme'],
        orElse: () => HomelabarrTheme.forestSage,
      );
      await HomelabarrTheme.apply(matched, changeAppIcon: false);
    }
    if (ui['dashboardLayout'] is String) {
      HomelabarrDevConfig.dashboardLayout = ui['dashboardLayout'] as String;
    }

    final prof = (data['profile'] as Map<String, dynamic>?) ?? {};
    final key = LunaSeaDatabase.ENABLED_PROFILE.read();
    final p = LunaBox.profiles.read(key) ?? LunaProfile();
    p.radarrEnabled = prof['radarrEnabled'] == true;
    p.radarrHost = (prof['radarrHost'] ?? '').toString();
    p.radarrKey = (prof['radarrKey'] ?? '').toString();
    p.sonarrEnabled = prof['sonarrEnabled'] == true;
    p.sonarrHost = (prof['sonarrHost'] ?? '').toString();
    p.sonarrKey = (prof['sonarrKey'] ?? '').toString();
    p.lidarrEnabled = prof['lidarrEnabled'] == true;
    p.lidarrHost = (prof['lidarrHost'] ?? '').toString();
    p.lidarrKey = (prof['lidarrKey'] ?? '').toString();
    p.nzbgetEnabled = prof['nzbgetEnabled'] == true;
    p.nzbgetHost = (prof['nzbgetHost'] ?? '').toString();
    p.nzbgetUser = (prof['nzbgetUser'] ?? '').toString();
    p.nzbgetPass = (prof['nzbgetPass'] ?? '').toString();
    p.sabnzbdEnabled = prof['sabnzbdEnabled'] == true;
    p.sabnzbdHost = (prof['sabnzbdHost'] ?? '').toString();
    p.sabnzbdKey = (prof['sabnzbdKey'] ?? '').toString();
    p.tautulliEnabled = prof['tautulliEnabled'] == true;
    p.tautulliHost = (prof['tautulliHost'] ?? '').toString();
    p.tautulliKey = (prof['tautulliKey'] ?? '').toString();
    await LunaBox.profiles.update(key, p);

    final apps = (data['apps'] as Map<String, dynamic>?) ?? {};
    HomelabarrDevConfig.qbitEnabled = apps['qbitEnabled'] == true;
    HomelabarrDevConfig.qbitHost = (apps['qbitHost'] ?? '').toString();
    HomelabarrDevConfig.qbitUser = (apps['qbitUser'] ?? '').toString();
    HomelabarrDevConfig.qbitPass = (apps['qbitPass'] ?? '').toString();
    HomelabarrDevConfig.qbitCategory = (apps['qbitCategory'] ?? '').toString();

    HomelabarrDevConfig.transEnabled = apps['transEnabled'] == true;
    HomelabarrDevConfig.transHost = (apps['transHost'] ?? '').toString();
    HomelabarrDevConfig.transUser = (apps['transUser'] ?? '').toString();
    HomelabarrDevConfig.transPass = (apps['transPass'] ?? '').toString();

    HomelabarrDevConfig.delugeEnabled = apps['delugeEnabled'] == true;
    HomelabarrDevConfig.delugeHost = (apps['delugeHost'] ?? '').toString();
    HomelabarrDevConfig.delugePass = (apps['delugePass'] ?? '').toString();

    HomelabarrDevConfig.overseerrEnabled = apps['overseerrEnabled'] == true;
    HomelabarrDevConfig.overseerrHost = (apps['overseerrHost'] ?? '').toString();
    HomelabarrDevConfig.overseerrApiKey = (apps['overseerrApiKey'] ?? '').toString();

    HomelabarrDevConfig.prowlarrEnabled = apps['prowlarrEnabled'] == true;
    HomelabarrDevConfig.prowlarrHost = (apps['prowlarrHost'] ?? '').toString();
    HomelabarrDevConfig.prowlarrApiKey = (apps['prowlarrApiKey'] ?? '').toString();
    ProwlarrConfig.host = HomelabarrDevConfig.prowlarrHost;
    ProwlarrConfig.apiKey = HomelabarrDevConfig.prowlarrApiKey;

    HomelabarrDevConfig.bazarrEnabled = apps['bazarrEnabled'] == true;
    HomelabarrDevConfig.bazarrHost = (apps['bazarrHost'] ?? '').toString();
    HomelabarrDevConfig.bazarrApiKey = (apps['bazarrApiKey'] ?? '').toString();

    HomelabarrDevConfig.readarrEnabled = apps['readarrEnabled'] == true;
    HomelabarrDevConfig.readarrHost = (apps['readarrHost'] ?? '').toString();
    HomelabarrDevConfig.readarrApiKey = (apps['readarrApiKey'] ?? '').toString();

    HomelabarrDevConfig.notify();
    showLunaSuccessSnackBar(
      title: 'Backup Restored',
      message: 'All apps, credentials, theme & layout restored!',
    );
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) throw Exception('Unable to read file path');
      final content = await File(path).readAsString();
      await _applyBackupJson(content);
    } catch (e) {
      showLunaErrorSnackBar(title: 'Import Failed', message: e.toString());
    }
  }

  Future<void> _importFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) throw Exception('Clipboard is empty');
      await _applyBackupJson(text);
    } catch (e) {
      showLunaErrorSnackBar(title: 'Clipboard Import Failed', message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: LunaAppBar(title: 'Full Backup & Restore'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.backup_rounded, color: LunaColours.accent, size: 26),
                    const SizedBox(width: 10),
                    const Text(
                      'Export Full Config',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saves all connected apps (Radarr, Sonarr, Readarr, Bazarr, Prowlarr, Overseerr, NZBGet, SABnzbd, qBittorrent, Transmission, Deluge, Lidarr, Tautulli), your Theme, and your Dashboard Layout into one JSON file.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                LunaButton.text(
                  text: 'Export & Share .json File',
                  icon: Icons.ios_share_rounded,
                  onTap: _exportFile,
                ),
                const SizedBox(height: 8),
                LunaButton.text(
                  text: 'Copy Backup JSON to Clipboard',
                  icon: Icons.copy_rounded,
                  color: LunaColours.blue,
                  onTap: _copyToClipboard,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restore_rounded, color: LunaColours.orange, size: 26),
                    const SizedBox(width: 10),
                    const Text(
                      'Restore Backup',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Import a previously exported Homelabarr JSON backup to restore all apps and preferences in seconds.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                LunaButton.text(
                  text: 'Import from .json File',
                  icon: Icons.folder_open_rounded,
                  onTap: _importFromFile,
                ),
                const SizedBox(height: 8),
                LunaButton.text(
                  text: 'Restore from Clipboard JSON',
                  icon: Icons.content_paste_rounded,
                  color: LunaColours.orange,
                  onTap: _importFromClipboard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
