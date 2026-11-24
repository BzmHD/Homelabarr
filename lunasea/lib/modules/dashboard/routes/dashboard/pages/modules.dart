import 'package:flutter/material.dart';

import 'package:lunasea/modules.dart';
import 'package:lunasea/database/box.dart';
import 'package:lunasea/database/models/profile.dart';
import 'package:lunasea/database/tables/lunasea.dart';
import 'package:lunasea/vendor.dart';
import 'package:lunasea/widgets/ui.dart';
import 'package:lunasea/api/wake_on_lan/wake_on_lan.dart';
import 'package:lunasea/modules/dashboard/routes/dashboard/widgets/navigation_bar.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/dashboard_live_status.dart';
import 'package:lunasea/modules/homelabarr_dev/torrents_route.dart';
import 'package:lunasea/modules/homelabarr_dev/overseerr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/prowlarr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/bazarr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/readarr_route.dart';

class _DashTile {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String group;
  final VoidCallback onTap;

  const _DashTile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.group,
    required this.onTap,
  });
}

class ModulesPage extends StatefulWidget {
  const ModulesPage({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<ModulesPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DashboardLiveStatusService.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LunaBox.profiles.listenableBuilder(
      builder: (context, _) => ValueListenableBuilder<int>(
        valueListenable: HomelabarrDevConfig.revision,
        builder: (context, _, __) => ValueListenableBuilder<Map<String, ServiceLiveStatus>>(
          valueListenable: DashboardLiveStatusService.statuses,
          builder: (context, liveStatuses, ___) => _list(liveStatuses),
        ),
      ),
    );
  }

  String _groupForLunaModule(LunaModule m) {
    switch (m) {
      case LunaModule.RADARR:
      case LunaModule.SONARR:
      case LunaModule.LIDARR:
        return 'Media Managers';
      case LunaModule.NZBGET:
      case LunaModule.SABNZBD:
        return 'Downloaders';
      case LunaModule.SEARCH:
        return 'Indexers & Search';
      case LunaModule.TAUTULLI:
      case LunaModule.OVERSEERR:
        return 'Requests & Monitoring';
      default:
        return 'System & Tools';
    }
  }

  List<_DashTile> _collectTiles() {
    final tiles = <_DashTile>[];

    final orderedModules = LunaSeaDatabase.DRAWER_AUTOMATIC_MANAGE.read()
        ? (LunaModule.active
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())))
        : LunaDrawer.moduleOrderedList();

    for (final module in orderedModules) {
      if (!module.isEnabled) continue;
      tiles.add(_DashTile(
        id: module.key.toLowerCase(),
        title: module.title,
        subtitle: module.description,
        icon: module.icon,
        color: module.color,
        group: _groupForLunaModule(module),
        onTap: module == LunaModule.WAKE_ON_LAN
            ? () async => LunaWakeOnLAN().wake()
            : module.launch,
      ));
    }

    if (HomelabarrDevConfig.qbitEnabled) {
      tiles.add(_DashTile(
        id: 'qbittorrent',
        title: 'qBittorrent',
        subtitle: 'Manage qBittorrent Downloads',
        icon: Icons.downloading_rounded,
        color: LunaColours.accent,
        group: 'Downloaders',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TorrentsRoute(initialClient: 'qBittorrent')),
        ),
      ));
    }
    if (HomelabarrDevConfig.transEnabled) {
      tiles.add(_DashTile(
        id: 'transmission',
        title: 'Transmission',
        subtitle: 'Manage Transmission Torrents',
        icon: Icons.swap_vert_circle_rounded,
        color: LunaColours.accent,
        group: 'Downloaders',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TorrentsRoute(initialClient: 'Transmission')),
        ),
      ));
    }
    if (HomelabarrDevConfig.delugeEnabled) {
      tiles.add(_DashTile(
        id: 'deluge',
        title: 'Deluge',
        subtitle: 'Manage Deluge Torrents',
        icon: Icons.water_drop_rounded,
        color: LunaColours.accent,
        group: 'Downloaders',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TorrentsRoute(initialClient: 'Deluge')),
        ),
      ));
    }
    if (HomelabarrDevConfig.overseerrEnabled) {
      tiles.add(_DashTile(
        id: 'overseerr',
        title: 'Overseerr',
        subtitle: 'Discover & Manage Media Requests',
        icon: Icons.movie_filter_rounded,
        color: LunaColours.accent,
        group: 'Requests & Monitoring',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OverseerrRoute()),
        ),
      ));
    }
    if (HomelabarrDevConfig.prowlarrEnabled) {
      tiles.add(_DashTile(
        id: 'prowlarr',
        title: 'Prowlarr',
        subtitle: 'Search Indexers & Monitor Health',
        icon: Icons.travel_explore_rounded,
        color: LunaColours.accent,
        group: 'Indexers & Search',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProwlarrModuleRoute()),
        ),
      ));
    }
    if (HomelabarrDevConfig.bazarrEnabled) {
      tiles.add(_DashTile(
        id: 'bazarr',
        title: 'Bazarr',
        subtitle: 'Manage Wanted Subtitles',
        icon: Icons.subtitles_rounded,
        color: LunaColours.accent,
        group: 'Media Managers',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BazarrRoute()),
        ),
      ));
    }
    if (HomelabarrDevConfig.readarrEnabled) {
      tiles.add(_DashTile(
        id: 'readarr',
        title: 'Readarr',
        subtitle: 'Manage Books & Audiobooks',
        icon: Icons.menu_book_rounded,
        color: LunaColours.accent,
        group: 'Media Managers',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReadarrRoute()),
        ),
      ));
    }

    tiles.add(_DashTile(
      id: 'settings',
      title: LunaModule.SETTINGS.title,
      subtitle: LunaModule.SETTINGS.description,
      icon: LunaModule.SETTINGS.icon,
      color: LunaModule.SETTINGS.color,
      group: 'System & Tools',
      onTap: LunaModule.SETTINGS.launch,
    ));

    return tiles;
  }

  Widget? _buildNowDownloadingBanner(Map<String, ServiceLiveStatus> live) {
    const dlKeys = ['nzbget', 'sabnzbd', 'qbittorrent', 'transmission', 'deluge'];
    int totalSpeed = 0;
    int totalActive = 0;
    final activeNames = <String>[];
    final nzb = live['nzbget'];

    for (final k in dlKeys) {
      final s = live[k];
      if (s == null || !s.online) continue;
      totalSpeed += s.dlSpeedBytes;
      totalActive += s.activeCount;
      if (s.dlSpeedBytes > 0 || s.activeCount > 0 || s.isPaused) {
        activeNames.add(k.toUpperCase());
      }
    }

    if (totalSpeed <= 0 && totalActive <= 0 && (nzb == null || !nzb.isPaused)) {
      return null;
    }

    final isPaused = nzb?.isPaused == true && totalSpeed == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isPaused ? LunaColours.orange : LunaColours.accent).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isPaused ? LunaColours.orange : LunaColours.accent).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPaused ? Icons.pause_circle_filled_rounded : Icons.downloading_rounded,
            color: isPaused ? LunaColours.orange : LunaColours.accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaused
                      ? 'Downloads Paused'
                      : 'Now Downloading • ${DashboardLiveStatusService.fmtSpeed(totalSpeed)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  activeNames.join(' + '),
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (nzb != null && nzb.online)
            IconButton(
              icon: Icon(
                nzb.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.white,
              ),
              onPressed: () => DashboardLiveStatusService.toggleNzbgetPause(!nzb.isPaused),
            ),
        ],
      ),
    );
  }

  Widget _statusPill(ServiceLiveStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: s.badgeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: s.online ? s.badgeColor : LunaColours.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            s.badgeText,
            style: TextStyle(
              color: s.online ? s.badgeColor : LunaColours.red,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(Map<String, ServiceLiveStatus> live) {
    if (!(LunaProfile.current.isAnythingEnabled()) && !HomelabarrDevConfig.anyDevAppEnabled) {
      return LunaMessage(
        text: 'lunasea.NoModulesEnabled'.tr(),
        buttonText: 'lunasea.GoToSettings'.tr(),
        onTap: LunaModule.SETTINGS.launch,
      );
    }

    final tiles = _collectTiles();
    final layout = HomelabarrDevConfig.dashboardLayout;
    final banner = _buildNowDownloadingBanner(live);

    Widget content;
    if (layout == 'grid2') {
      content = _buildGrid(tiles, live, crossAxisCount: 2, compact: false);
    } else if (layout == 'grid3') {
      content = _buildGrid(tiles, live, crossAxisCount: 3, compact: true);
    } else if (layout == 'grouped') {
      content = _buildGrouped(tiles, live);
    } else {
      content = ListView.builder(
        controller: HomeNavigationBar.scrollControllers[0],
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        itemCount: tiles.length,
        itemBuilder: (_, idx) => _buildStackedBlock(tiles[idx], live[tiles[idx].id]),
      );
    }

    return Column(
      children: [
        if (banner != null) banner,
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => DashboardLiveStatusService.refresh(force: true),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildStackedBlock(_DashTile tile, ServiceLiveStatus? status) {
    return LunaBlock(
      title: tile.title,
      body: [
        TextSpan(text: tile.subtitle),
        if (status != null)
          TextSpan(
            text: '  •  ${status.badgeText}',
            style: TextStyle(
              color: status.online ? status.badgeColor : LunaColours.red,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
      trailing: LunaIconButton(icon: tile.icon, color: tile.color),
      onTap: tile.onTap,
    );
  }

  Widget _buildGrid(
    List<_DashTile> tiles,
    Map<String, ServiceLiveStatus> live, {
    required int crossAxisCount,
    required bool compact,
  }) {
    return GridView.builder(
      controller: HomeNavigationBar.scrollControllers[0],
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: compact ? 0.92 : 1.32,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, idx) {
        final t = tiles[idx];
        final s = live[t.id];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: t.onTap,
          child: Container(
            padding: EdgeInsets.all(compact ? 8 : 13),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: compact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: t.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(t.icon, color: t.color, size: 22),
                          ),
                          if (s != null)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: s.online ? s.badgeColor : LunaColours.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (s != null)
                        Text(
                          s.badgeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: s.online ? s.badgeColor : LunaColours.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: t.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(t.icon, color: t.color, size: 21),
                          ),
                          if (s != null)
                            _statusPill(s)
                          else
                            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildGrouped(List<_DashTile> tiles, Map<String, ServiceLiveStatus> live) {
    const groupOrder = [
      'Media Managers',
      'Indexers & Search',
      'Downloaders',
      'Requests & Monitoring',
      'System & Tools',
    ];
    final children = <Widget>[];
    for (final groupName in groupOrder) {
      final groupTiles = tiles.where((t) => t.group == groupName).toList();
      if (groupTiles.isEmpty) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            groupName.toUpperCase(),
            style: TextStyle(
              color: LunaColours.accent,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
      children.addAll(groupTiles.map((t) => _buildStackedBlock(t, live[t.id])));
    }
    return ListView(
      controller: HomeNavigationBar.scrollControllers[0],
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}
