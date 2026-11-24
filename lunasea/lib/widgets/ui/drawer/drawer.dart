import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/api/wake_on_lan/wake_on_lan.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/torrents_route.dart';
import 'package:lunasea/modules/homelabarr_dev/overseerr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/prowlarr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/bazarr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/readarr_route.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_settings_route.dart';

class LunaDrawer extends StatelessWidget {
  final String page;

  const LunaDrawer({
    Key? key,
    required this.page,
  }) : super(key: key);

  static List<LunaModule> moduleAlphabeticalList() {
    return LunaModule.active
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  static List<LunaModule> moduleOrderedList() {
    try {
      const db = LunaSeaDatabase.DRAWER_MANUAL_ORDER;
      final modules = List.from(db.read());
      final missing = LunaModule.active;

      missing.retainWhere((m) => !modules.contains(m));
      modules.addAll(missing);
      modules.retainWhere((m) => (m as LunaModule).featureFlag);

      return modules.cast<LunaModule>();
    } catch (error, stack) {
      LunaLogger().error('Failed to create ordered module list', error, stack);
      return moduleAlphabeticalList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LunaSeaDatabase.ENABLED_PROFILE.listenableBuilder(
      builder: (context, _) => LunaBox.indexers.listenableBuilder(
        builder: (context, _) => Drawer(
          elevation: LunaUI.ELEVATION,
          backgroundColor: Theme.of(context).primaryColor,
          child: LunaSeaDatabase.DRAWER_AUTOMATIC_MANAGE.listenableBuilder(
            builder: (context, _) => Column(
              children: [
                LunaDrawerHeader(page: page),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: HomelabarrDevConfig.revision,
                    builder: (context, _, __) => LunaListView(
                      controller: PrimaryScrollController.of(context),
                      children: [
                        ..._moduleList(
                          context,
                          LunaSeaDatabase.DRAWER_AUTOMATIC_MANAGE.read()
                              ? moduleAlphabeticalList()
                              : moduleOrderedList(),
                        ),
                        ..._homelabarrDevEntries(context),
                      ],
                      physics: const ClampingScrollPhysics(),
                      padding: MediaQuery.of(context).padding.copyWith(top: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sharedHeader(BuildContext context) {
    return [
      _buildEntry(
        context: context,
        module: LunaModule.DASHBOARD,
      ),
    ];
  }

  List<Widget> _moduleList(BuildContext context, List<LunaModule> modules) {
    return <Widget>[
      ..._sharedHeader(context),
      ...modules.map((module) {
        if (module.isEnabled) {
          return _buildEntry(
            context: context,
            module: module,
            onTap: module == LunaModule.WAKE_ON_LAN ? _wakeOnLAN : null,
          );
        }
        return const SizedBox(height: 0.0);
      }),
    ];
  }

  Widget _buildEntry({
    required BuildContext context,
    required LunaModule module,
    void Function()? onTap,
  }) {
    bool currentPage = page == module.key.toLowerCase();
    return SizedBox(
      height: LunaTextInputBar.defaultAppBarHeight,
      child: InkWell(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              child: Icon(
                module.icon,
                color: currentPage ? module.color : LunaColours.white,
              ),
              padding: LunaUI.MARGIN_DEFAULT_HORIZONTAL * 1.5,
            ),
            Text(
              module.title,
              style: TextStyle(
                color: currentPage ? module.color : LunaColours.white,
                fontWeight: LunaUI.FONT_WEIGHT_BOLD,
              ),
            ),
          ],
        ),
        onTap: onTap ??
            () async {
              final nav = Navigator.of(context);
              nav.pop();
              nav.popUntil((route) => route.isFirst);
              if (!currentPage) module.launch();
            },
      ),
    );
  }

  Future<void> _wakeOnLAN() async => LunaWakeOnLAN().wake();

  void _openCustomRoute(BuildContext context, WidgetBuilder builder) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.popUntil((route) => route.isFirst);
    nav.push(MaterialPageRoute(builder: builder));
  }

  List<Widget> _homelabarrDevEntries(BuildContext context) {
    return [
      if (HomelabarrDevConfig.qbitEnabled)
        _buildCustomEntry(
          context: context,
          keyName: 'qbit',
          title: 'qBittorrent',
          icon: Icons.downloading_rounded,
          onTap: () => _openCustomRoute(
            context,
            (_) => const TorrentsRoute(initialClient: 'qBittorrent'),
          ),
        ),
      if (HomelabarrDevConfig.transEnabled)
        _buildCustomEntry(
          context: context,
          keyName: 'transmission',
          title: 'Transmission',
          icon: Icons.swap_vert_circle_rounded,
          onTap: () => _openCustomRoute(
            context,
            (_) => const TorrentsRoute(initialClient: 'Transmission'),
          ),
        ),
      if (HomelabarrDevConfig.delugeEnabled)
        _buildCustomEntry(
          context: context,
          keyName: 'deluge',
          title: 'Deluge',
          icon: Icons.water_drop_rounded,
          onTap: () => _openCustomRoute(
            context,
            (_) => const TorrentsRoute(initialClient: 'Deluge'),
          ),
        ),
      if (HomelabarrDevConfig.overseerrEnabled)
        _buildCustomEntry(
          context: context,
          keyName: 'overseerr',
          title: 'Overseerr',
          icon: Icons.movie_filter_rounded,
          onTap: () => _openCustomRoute(
            context,
            (_) => const OverseerrRoute(),
          ),
        ),
      if (HomelabarrDevConfig.prowlarrEnabled)
        _buildCustomEntry(
          context: context,
          keyName: 'prowlarr',
          title: 'Prowlarr',
          icon: Icons.travel_explore_rounded,
          onTap: () => _openCustomRoute(
            context,
            (_) => const ProwlarrModuleRoute(),
          ),
        ),
      if (HomelabarrDevConfig.bazarrEnabled)
        _buildCustomEntry(
          context: context,
          keyName: 'bazarr',
          title: 'Bazarr',
          icon: Icons.subtitles_rounded,
          onTap: () => _openCustomRoute(
            context,
            (_) => const BazarrRoute(),
          ),
        ),
      if (HomelabarrDevConfig.readarrEnabled)
        _buildCustomEntry(
          context: context,
          keyName: 'readarr',
          title: 'Readarr',
          icon: Icons.menu_book_rounded,
          onTap: () => _openCustomRoute(
            context,
            (_) => const ReadarrRoute(),
          ),
        ),
    ];
  }

  Widget _buildCustomEntry({
    required BuildContext context,
    required String keyName,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final currentPage = page == keyName;
    return SizedBox(
      height: LunaTextInputBar.defaultAppBarHeight,
      child: InkWell(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              child: Icon(
                icon,
                color: currentPage ? LunaColours.accent : LunaColours.white,
              ),
              padding: LunaUI.MARGIN_DEFAULT_HORIZONTAL * 1.5,
            ),
            Text(
              title,
              style: TextStyle(
                color: currentPage ? LunaColours.accent : LunaColours.white,
                fontWeight: LunaUI.FONT_WEIGHT_BOLD,
              ),
            ),
          ],
        ),
        onTap: () {
          if (currentPage) {
            Navigator.of(context).pop();
            return;
          }
          onTap();
        },
      ),
    );
  }
}
