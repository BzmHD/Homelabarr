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
          icon: Icons.auto_fix_high_rounded,
          onPressed: () => HomelabarrWalkthrough.show(context),
        ),
        SwitchViewAction(pageController: _pageController),
      ],
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
