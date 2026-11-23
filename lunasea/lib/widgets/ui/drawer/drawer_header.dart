import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/widgets/ui/homelabarr_themes.dart';

class LunaDrawerHeader extends StatelessWidget {
  final String page;

  const LunaDrawerHeader({
    Key? key,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = HomelabarrTheme.current;
    return LunaSeaDatabase.ENABLED_PROFILE.listenableBuilder(
      builder: (context, _) => Container(
        child: LunaAppBar.dropdown(
          backgroundColor: Colors.transparent,
          hideLeading: true,
          useDrawer: false,
          title: LunaBox.profiles.keys.length == 1
              ? 'Homelabarr'
              : LunaSeaDatabase.ENABLED_PROFILE.read(),
          profiles: LunaBox.profiles.keys.cast<String>().toList(),
          actions: [
            LunaIconButton(
              icon: LunaIcons.SETTINGS,
              onPressed: page == LunaModule.SETTINGS.key
                  ? Navigator.of(context).pop
                  : LunaModule.SETTINGS.launch,
            )
          ],
        ),
        decoration: BoxDecoration(
          color: t.secondary,
          image: DecorationImage(
            image: AssetImage(t.previewAsset),
            colorFilter: ColorFilter.mode(
              t.primary.withOpacity(0.28),
              BlendMode.dstATop,
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
