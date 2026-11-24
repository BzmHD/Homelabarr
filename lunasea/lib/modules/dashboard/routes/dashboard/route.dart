import 'package:flutter/material.dart';

import 'package:lunasea/modules.dart';
import 'package:lunasea/database/tables/dashboard.dart';
import 'package:lunasea/database/tables/lunasea.dart';
import 'package:lunasea/widgets/ui.dart';
import 'package:lunasea/modules/dashboard/routes/dashboard/pages/calendar.dart';
import 'package:lunasea/modules/dashboard/routes/dashboard/pages/modules.dart';
import 'package:lunasea/modules/dashboard/routes/dashboard/widgets/switch_view_action.dart';
import 'package:lunasea/modules/dashboard/routes/dashboard/widgets/navigation_bar.dart';
import 'package:lunasea/widgets/sheets/onboarding/walkthrough.dart';
import 'package:lunasea/modules/homelabarr_dev/dev_config.dart';
import 'package:lunasea/modules/homelabarr_dev/global_search_route.dart';

class DashboardRoute extends StatefulWidget {
  const DashboardRoute({
    Key? key,
  }) : super(key: key);

  @override
  State<DashboardRoute> createState() => _State();
}

class _State extends State<DashboardRoute> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  LunaPageController? _pageController;

  @override
  void initState() {
    super.initState();

    int page = DashboardDatabase.NAVIGATION_INDEX.read();
    _pageController = LunaPageController(initialPage: page);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) HomelabarrWalkthrough.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      module: LunaModule.DASHBOARD,
      body: _body(),
      appBar: _appBar(),
      drawer: LunaDrawer(page: LunaModule.DASHBOARD.key),
      bottomNavigationBar: HomeNavigationBar(pageController: _pageController),
    );
  }

  PreferredSizeWidget _appBar() {
    return LunaAppBar(
      title: 'Homelabarr',
      useDrawer: true,
      scrollControllers: HomeNavigationBar.scrollControllers,
      pageController: _pageController,
      actions: [
        LunaIconButton.appBar(
          icon: Icons.search_rounded,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GlobalSearchRoute()),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: HomelabarrDevConfig.revision,
          builder: (context, _, __) {
            final layout = HomelabarrDevConfig.dashboardLayout;
            final icon = layout == 'grid2'
                ? Icons.grid_view_rounded
                : (layout == 'grid3'
                    ? Icons.apps_rounded
                    : (layout == 'grouped'
                        ? Icons.view_agenda_rounded
                        : Icons.view_stream_rounded));
            return LunaIconButton.appBar(
              icon: icon,
              onPressed: () => _showLayoutPicker(context),
            );
          },
        ),
        LunaIconButton.appBar(
          icon: Icons.auto_fix_high_rounded,
          onPressed: () => HomelabarrWalkthrough.show(context),
        ),
        SwitchViewAction(pageController: _pageController),
      ],
    );
  }

  void _showLayoutPicker(BuildContext context) {
    final current = HomelabarrDevConfig.dashboardLayout;
    final options = <Map<String, dynamic>>[
      {
        'id': 'stacked',
        'title': 'Stacked Tiles',
        'subtitle': 'Classic full-width cards with descriptions',
        'icon': Icons.view_stream_rounded,
      },
      {
        'id': 'grid2',
        'title': '2-Column Grid',
        'subtitle': 'Modern side-by-side visual cards',
        'icon': Icons.grid_view_rounded,
      },
      {
        'id': 'grid3',
        'title': '3-Column Compact Grid',
        'subtitle': 'App-launcher style compact icon tiles',
        'icon': Icons.apps_rounded,
      },
      {
        'id': 'grouped',
        'title': 'Grouped by Usage',
        'subtitle': 'Organized into Media, Indexers, Downloaders & Apps',
        'icon': Icons.view_agenda_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Layout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose how your apps are displayed on the Dashboard.',
                style: TextStyle(color: Colors.white60, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final selected = opt['id'] == current;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? LunaColours.accent.withValues(alpha: 0.18)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? LunaColours.accent : Colors.white12,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      opt['icon'] as IconData,
                      color: selected ? LunaColours.accent : Colors.white70,
                    ),
                    title: Text(
                      opt['title'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      opt['subtitle'] as String,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    trailing: selected
                        ? Icon(Icons.check_circle_rounded, color: LunaColours.accent)
                        : null,
                    onTap: () {
                      HomelabarrDevConfig.dashboardLayout = opt['id'] as String;
                      Navigator.of(ctx).pop();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return LunaSeaDatabase.ENABLED_PROFILE.listenableBuilder(
      builder: (context, _) => LunaPageView(
        controller: _pageController,
        children: [
          ModulesPage(key: ValueKey(LunaSeaDatabase.ENABLED_PROFILE.read())),
          CalendarPage(key: ValueKey(LunaSeaDatabase.ENABLED_PROFILE.read())),
        ],
      ),
    );
  }
}
