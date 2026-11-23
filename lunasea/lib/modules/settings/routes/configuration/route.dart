import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/settings.dart';
import 'package:lunasea/router/routes/settings.dart';
import 'package:lunasea/system/quick_actions/quick_actions.dart';
import 'package:lunasea/utils/profile_tools.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_settings_route.dart';

class ConfigurationRoute extends StatefulWidget {
  const ConfigurationRoute({
    Key? key,
  }) : super(key: key);

  @override
  State<ConfigurationRoute> createState() => _State();
}

class _State extends State<ConfigurationRoute> with LunaScrollControllerMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: _appBar() as PreferredSizeWidget?,
      body: _body(),
    );
  }

  Widget _appBar() {
    return LunaAppBar(
      title: 'settings.Configuration'.tr(),
      scrollControllers: [scrollController],
      actions: [_enabledProfile()],
    );
  }

  Widget _enabledProfile() {
    return LunaBox.profiles.listenableBuilder(
      builder: (context, _) {
        if (LunaBox.profiles.size < 2) return const SizedBox();
        return LunaIconButton(
          icon: Icons.switch_account_rounded,
          onPressed: () async {
            final dialogs = SettingsDialogs();
            final enabledProfile = LunaSeaDatabase.ENABLED_PROFILE.read();
            final profiles = LunaProfile.list;
            profiles.removeWhere((p) => p == enabledProfile);

            if (profiles.isEmpty) {
              showLunaInfoSnackBar(
                title: 'settings.NoProfilesFound'.tr(),
                message: 'settings.NoAdditionalProfilesAdded'.tr(),
              );
              return;
            }

            final selected = await dialogs.enabledProfile(
              LunaState.context,
              profiles,
            );
            if (selected.item1) {
              LunaProfileTools().changeTo(selected.item2);
            }
          },
        );
      },
    );
  }

  Widget _body() {
    return LunaListView(
      controller: scrollController,
      children: [
        LunaBlock(
          title: 'settings.General'.tr(),
          body: [TextSpan(text: 'settings.GeneralDescription'.tr())],
          trailing: const LunaIconButton(icon: Icons.brush_rounded),
          onTap: SettingsRoutes.CONFIGURATION_GENERAL.go,
        ),
        LunaBlock(
          title: 'settings.Drawer'.tr(),
          body: [TextSpan(text: 'settings.DrawerDescription'.tr())],
          trailing: const LunaIconButton(icon: Icons.menu_rounded),
          onTap: SettingsRoutes.CONFIGURATION_DRAWER.go,
        ),
        if (LunaQuickActions.isSupported)
          LunaBlock(
            title: 'settings.QuickActions'.tr(),
            body: [TextSpan(text: 'settings.QuickActionsDescription'.tr())],
            trailing: const LunaIconButton(icon: Icons.rounded_corner_rounded),
            onTap: SettingsRoutes.CONFIGURATION_QUICK_ACTIONS.go,
          ),
        LunaDivider(),
        ..._moduleList(),
      ],
    );
  }

  List<Widget> _moduleList() {
    final entries = <MapEntry<String, Widget>>[
      for (final module in [LunaModule.DASHBOARD, ...LunaModule.active])
        MapEntry(module.title.toLowerCase(), _tileFromModuleMap(module)),
      MapEntry(
        'bazarr',
        _devAppTile('Bazarr', 'Configure Bazarr', Icons.subtitles_rounded, 'bazarr'),
      ),
      MapEntry(
        'deluge',
        _devAppTile('Deluge', 'Configure Deluge', Icons.water_drop_rounded, 'deluge'),
      ),
      MapEntry(
        'overseerr',
        _devAppTile('Overseerr', 'Configure Overseerr / Jellyseerr', Icons.movie_filter_rounded, 'overseerr'),
      ),
      MapEntry(
        'prowlarr',
        _devAppTile('Prowlarr', 'Configure Prowlarr', Icons.travel_explore_rounded, 'prowlarr'),
      ),
      MapEntry(
        'qbittorrent',
        _devAppTile('qBittorrent', 'Configure qBittorrent', Icons.downloading_rounded, 'qbit'),
      ),
      MapEntry(
        'transmission',
        _devAppTile('Transmission', 'Configure Transmission', Icons.swap_vert_circle_rounded, 'transmission'),
      ),
    ];
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => e.value).toList();
  }

  Widget _devAppTile(String title, String subtitle, IconData icon, String appId) {
    return LunaBlock(
      title: title,
      body: [TextSpan(text: subtitle)],
      trailing: LunaIconButton(icon: icon),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HomelabarrDevSettingsRoute(filterApp: appId),
        ),
      ),
    );
  }

  Widget _tileFromModuleMap(LunaModule module) {
    return LunaBlock(
      title: module.title,
      body: [
        TextSpan(text: 'settings.ConfigureModule'.tr(args: [module.title]))
      ],
      trailing: LunaIconButton(icon: module.icon),
      onTap: module.settingsRoute!.go,
    );
  }
}
