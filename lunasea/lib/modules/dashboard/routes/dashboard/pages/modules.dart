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
import 'package:lunasea/modules/homelabarr_dev/torrents_route.dart';
import 'package:lunasea/modules/homelabarr_dev/overseerr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/prowlarr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/bazarr_route.dart';

class _DashTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String group;
  final VoidCallback onTap;

  const _DashTile({
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
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<ModulesPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LunaBox.profiles.listenableBuilder(
      builder: (context, _) => ValueListenableBuilder<int>(
        valueListenable: HomelabarrDevConfig.revision,
        builder: (context, _, __) => _list(),
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

    tiles.add(_DashTile(
      title: LunaModule.SETTINGS.title,
      subtitle: LunaModule.SETTINGS.description,
      icon: LunaModule.SETTINGS.icon,
      color: LunaModule.SETTINGS.color,
      group: 'System & Tools',
      onTap: LunaModule.SETTINGS.launch,
    ));

    return tiles;
  }

  Widget _list() {
    if (!(LunaProfile.current.isAnythingEnabled()) && !HomelabarrDevConfig.anyDevAppEnabled) {
      return LunaMessage(
        text: 'lunasea.NoModulesEnabled'.tr(),
        buttonText: 'lunasea.GoToSettings'.tr(),
        onTap: LunaModule.SETTINGS.launch,
      );
    }

    final tiles = _collectTiles();
    final layout = HomelabarrDevConfig.dashboardLayout;

    if (layout == 'grid2') {
      return _buildGrid(tiles, crossAxisCount: 2, compact: false);
    }
    if (layout == 'grid3') {
      return _buildGrid(tiles, crossAxisCount: 3, compact: true);
    }
    if (layout == 'grouped') {
      return _buildGrouped(tiles);
    }

    // Default: Stacked Tiles
    return LunaListView(
      controller: HomeNavigationBar.scrollControllers[0],
      itemExtent: LunaBlock.calculateItemExtent(1),
      children: tiles.map(_buildStackedBlock).toList(),
    );
  }

  Widget _buildStackedBlock(_DashTile tile) {
    return LunaBlock(
      title: tile.title,
      body: [TextSpan(text: tile.subtitle)],
      trailing: LunaIconButton(icon: tile.icon, color: tile.color),
      onTap: tile.onTap,
    );
  }

  Widget _buildGrid(List<_DashTile> tiles, {required int crossAxisCount, required bool compact}) {
    return GridView.builder(
      controller: HomeNavigationBar.scrollControllers[0],
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: compact ? 0.98 : 1.38,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, idx) {
        final t = tiles[idx];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: t.onTap,
          child: Container(
            padding: EdgeInsets.all(compact ? 10 : 14),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: compact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: t.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(t.icon, color: t.color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
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
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: t.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(t.icon, color: t.color, size: 22),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
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
                              fontSize: 15,
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

  Widget _buildGrouped(List<_DashTile> tiles) {
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
      children.addAll(groupTiles.map(_buildStackedBlock));
    }
    return ListView(
      controller: HomeNavigationBar.scrollControllers[0],
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}
