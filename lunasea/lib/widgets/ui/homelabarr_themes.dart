import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunasea/core.dart';

enum HomelabarrTheme {
  forestSage(
    id: 'forest_sage',
    name: 'Forest Sage',
    subtitle: 'Deep olive & dark sage',
    primary: Color(0xFF14160F),
    secondary: Color(0xFF1F2A24),
    accent: Color(0xFF7FA88F),
    grey: Color(0xFFB2AEB6),
    white: Color(0xFFE9E8ED),
    iosIconName: null,
    previewAsset: 'assets/images/branding_logo.png',
  ),
  midnightOcean(
    id: 'midnight_ocean',
    name: 'Midnight Ocean',
    subtitle: 'Deep navy & sky cyan',
    primary: Color(0xFF0B1120),
    secondary: Color(0xFF152036),
    accent: Color(0xFF38BDF8),
    grey: Color(0xFF94A3B8),
    white: Color(0xFFF1F5F9),
    iosIconName: 'IconOcean',
    previewAsset: 'assets/images/icon_IconOcean.png',
  ),
  obsidianGold(
    id: 'obsidian_gold',
    name: 'Obsidian Gold',
    subtitle: 'True dark & warm amber',
    primary: Color(0xFF0D0C0A),
    secondary: Color(0xFF1C1915),
    accent: Color(0xFFE5A93C),
    grey: Color(0xFFA8A29E),
    white: Color(0xFFFAF7F2),
    iosIconName: 'IconGold',
    previewAsset: 'assets/images/icon_IconGold.png',
  ),
  crimsonNoir(
    id: 'crimson_noir',
    name: 'Crimson Noir',
    subtitle: 'Charcoal & muted ruby',
    primary: Color(0xFF120D10),
    secondary: Color(0xFF22181E),
    accent: Color(0xFFE86A7A),
    grey: Color(0xFFB0A3AA),
    white: Color(0xFFF6EFF2),
    iosIconName: 'IconCrimson',
    previewAsset: 'assets/images/icon_IconCrimson.png',
  );

  final String id;
  final String name;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color grey;
  final Color white;
  final String? iosIconName;
  final String previewAsset;

  const HomelabarrTheme({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.grey,
    required this.white,
    required this.iosIconName,
    required this.previewAsset,
  });

  static const String boxKey = 'HOMELABARR_THEME';
  static const MethodChannel _iconChannel = MethodChannel('homelabarr/app_icon');

  static HomelabarrTheme get current {
    try {
      final saved = LunaBox.lunasea.read(boxKey)?.toString();
      return HomelabarrTheme.values.firstWhere(
        (t) => t.id == saved,
        orElse: () => HomelabarrTheme.forestSage,
      );
    } catch (_) {
      return HomelabarrTheme.forestSage;
    }
  }

  static Future<void> apply(
    HomelabarrTheme theme, {
    bool changeAppIcon = true,
  }) async {
    await LunaBox.lunasea.update(boxKey, theme.id);
    if (changeAppIcon) {
      await setAppIcon(theme.iosIconName);
    }
  }

  static Future<void> setAppIcon(String? iconName) async {
    try {
      await _iconChannel.invokeMethod('setIcon', iconName);
    } catch (_) {}
  }
}

class HomelabarrThemePicker extends StatefulWidget {
  const HomelabarrThemePicker({super.key});

  @override
  State<HomelabarrThemePicker> createState() => _HomelabarrThemePickerState();
}

class _HomelabarrThemePickerState extends State<HomelabarrThemePicker> {
  bool _syncIcon = true;

  @override
  Widget build(BuildContext context) {
    final active = HomelabarrTheme.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: active.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: Text(
              'Match Home Screen App Icon',
              style: TextStyle(color: active.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Automatically switch iPhone app icon with theme',
              style: TextStyle(color: active.grey, fontSize: 12),
            ),
            activeColor: active.accent,
            value: _syncIcon,
            onChanged: (v) => setState(() => _syncIcon = v),
          ),
        ),
        ...HomelabarrTheme.values.map((t) {
          final selected = t == active;
          return GestureDetector(
            onTap: () async {
              await HomelabarrTheme.apply(t, changeAppIcon: _syncIcon);
              if (mounted) setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.secondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? t.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      t.previewAsset,
                      width: 48,
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            color: t.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.subtitle,
                          style: TextStyle(color: t.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _swatch(t.primary),
                            _swatch(t.secondary),
                            _swatch(t.accent),
                            _swatch(t.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: selected ? t.accent : t.grey,
                    size: 24,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _swatch(Color c) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }
}

class HomelabarrThemeRoute extends StatelessWidget {
  const HomelabarrThemeRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final active = HomelabarrTheme.current;
    return Scaffold(
      backgroundColor: active.primary,
      appBar: AppBar(
        backgroundColor: active.secondary,
        title: Text(
          'Themes & App Icon',
          style: TextStyle(color: active.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: active.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: HomelabarrThemePicker(),
      ),
    );
  }
}
