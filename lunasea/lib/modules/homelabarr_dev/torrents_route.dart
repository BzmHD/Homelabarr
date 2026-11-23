import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_settings_route.dart';
import 'package:lunasea/modules/homelabarr_dev/download_clients_api.dart';

class TorrentsRoute extends StatefulWidget {
  final String? initialClient;

  const TorrentsRoute({Key? key, this.initialClient}) : super(key: key);

  @override
  State<TorrentsRoute> createState() => _TorrentsRouteState();
}

class _TorrentsRouteState extends State<TorrentsRoute> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedClient;
  bool _loading = false;
  String? _error;
  TorrentClientStats? _stats;

  List<String> get _clients => HomelabarrDevConfig.enabledTorrentClients;

  @override
  void initState() {
    super.initState();
    HomelabarrDevConfig.revision.addListener(_onConfigChanged);
    if (widget.initialClient != null && _clients.contains(widget.initialClient)) {
      _selectedClient = widget.initialClient;
      _refresh();
    } else if (_clients.isNotEmpty) {
      _selectedClient = _clients.first;
      _refresh();
    }
  }

  @override
  void dispose() {
    HomelabarrDevConfig.revision.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    if (!mounted) return;
    final list = _clients;
    if (list.isEmpty) {
      setState(() {
        _selectedClient = null;
        _stats = null;
      });
    } else if (_selectedClient == null || !list.contains(_selectedClient)) {
      _selectedClient = list.first;
      _refresh();
    } else {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    final client = _selectedClient;
    if (client == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      TorrentClientStats stats;
      if (client == 'qBittorrent') {
        stats = await DownloadClientsApi.fetchQBittorrent();
      } else if (client == 'Transmission') {
        stats = await DownloadClientsApi.fetchTransmission();
      } else {
        stats = await DownloadClientsApi.fetchDeluge();
      }
      if (mounted) {
        setState(() {
          _stats = stats;
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

  String _fmtBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double v = bytes.toDouble();
    int i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[i]}';
  }

  Future<void> _addTorrentDialog() async {
    final client = _selectedClient;
    if (client == null) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Add Torrent to $client', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Paste magnet:? or .torrent URL',
            hintStyle: TextStyle(color: Colors.white54),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Add', style: TextStyle(color: LunaColours.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      try {
        if (client == 'qBittorrent') {
          await DownloadClientsApi.addToQBittorrent(ctrl.text.trim());
        } else if (client == 'Transmission') {
          await DownloadClientsApi.addToTransmission(ctrl.text.trim());
        } else {
          await DownloadClientsApi.addToDeluge(ctrl.text.trim());
        }
        showLunaSuccessSnackBar(title: 'Torrent Added', message: 'Sent to $client');
        _refresh();
      } catch (e) {
        showLunaErrorSnackBar(title: 'Add Failed', message: e.toString());
      }
    }
  }

  Future<void> _doAction(TorrentItem item, String action, {bool deleteFiles = false}) async {
    try {
      if (item.client == 'qBittorrent') {
        await DownloadClientsApi.qbitAction(action, item.id, deleteFiles: deleteFiles);
      } else if (item.client == 'Transmission') {
        await DownloadClientsApi.transmissionAction(action, item.id, deleteFiles: deleteFiles);
      } else {
        await DownloadClientsApi.delugeAction(action, item.id, deleteFiles: deleteFiles);
      }
      showLunaSuccessSnackBar(
        title: action == 'delete' ? 'Removed' : (action == 'pause' ? 'Paused' : 'Resumed'),
        message: item.name,
      );
      _refresh();
    } catch (e) {
      showLunaErrorSnackBar(title: 'Action Failed', message: e.toString());
    }
  }

  Future<void> _confirmDelete(TorrentItem item) async {
    bool deleteFiles = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text('Remove Torrent?', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: deleteFiles,
                activeColor: LunaColours.red,
                title: const Text('Also delete downloaded files', style: TextStyle(color: Colors.white, fontSize: 14)),
                onChanged: (v) => setS(() => deleteFiles = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove', style: TextStyle(color: LunaColours.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _doAction(item, 'delete', deleteFiles: deleteFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = _clients;
    final drawerKey = _selectedClient == 'qBittorrent'
        ? 'qbit'
        : (_selectedClient == 'Transmission'
            ? 'transmission'
            : (_selectedClient == 'Deluge' ? 'deluge' : 'torrents'));
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: LunaDrawer(page: drawerKey),
      appBar: LunaAppBar(
        title: _selectedClient ?? 'Torrents',
        useDrawer: true,
        actions: [
          if (clients.isNotEmpty)
            LunaIconButton(
              icon: Icons.add_link_rounded,
              onPressed: _addTorrentDialog,
            ),
          LunaIconButton(
            icon: Icons.tune_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HomelabarrDevSettingsRoute()),
            ),
          ),
        ],
      ),
      body: clients.isEmpty ? _emptyState() : _content(clients),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.downloading_rounded, size: 56, color: LunaColours.accent),
            const SizedBox(height: 14),
            const Text(
              'No Torrent Clients Enabled',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect qBittorrent, Transmission, or Deluge to manage torrents and send torrent releases straight from Prowlarr.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 20),
            LunaButton.text(
              text: 'Configure Torrent Clients',
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

  Widget _content(List<String> clients) {
    return Column(
      children: [
        if (clients.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: clients.map((c) {
                  final active = c == _selectedClient;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: FontWeight.w600)),
                      selected: active,
                      selectedColor: LunaColours.accent,
                      backgroundColor: Theme.of(context).primaryColor,
                      onSelected: (_) {
                        setState(() => _selectedClient = c);
                        _refresh();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        if (_stats != null)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_stats!.items.length} Torrents',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 15, color: LunaColours.accent),
                    const SizedBox(width: 4),
                    Text('${_fmtBytes(_stats!.dlSpeed)}/s', style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                    const SizedBox(width: 14),
                    const Icon(Icons.arrow_upward_rounded, size: 15, color: LunaColours.blue),
                    const SizedBox(width: 4),
                    Text('${_fmtBytes(_stats!.ulSpeed)}/s', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _loading && _stats == null
                ? const Center(child: LunaLoader())
                : _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 42, color: LunaColours.red),
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 14),
                          LunaButton.text(text: 'Retry', icon: Icons.refresh_rounded, onTap: _refresh),
                        ],
                      )
                    : (_stats == null || _stats!.items.isEmpty)
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text('Queue is empty', style: TextStyle(color: Colors.white60, fontSize: 15)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                            itemCount: _stats!.items.length,
                            itemBuilder: (_, idx) => _torrentCard(_stats!.items[idx]),
                          ),
          ),
        ),
      ],
    );
  }

  Widget _torrentCard(TorrentItem item) {
    final pct = (item.progress * 100).toStringAsFixed(1);
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
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    item.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: item.isPaused ? LunaColours.accent : Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => _doAction(item, item.isPaused ? 'resume' : 'pause'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: LunaColours.red, size: 20),
                  onPressed: () => _confirmDelete(item),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 5,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  item.progress >= 1.0 ? LunaColours.accent : LunaColours.blue,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.state} • $pct% • ${_fmtBytes(item.sizeBytes)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
                Text(
                  '↓ ${_fmtBytes(item.dlSpeed)}/s  ↑ ${_fmtBytes(item.ulSpeed)}/s',
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
