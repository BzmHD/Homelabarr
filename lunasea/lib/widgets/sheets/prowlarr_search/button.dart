import 'package:flutter/material.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/sheet.dart';
import 'package:lunasea/widgets/ui.dart';

class ProwlarrSearchButton extends StatelessWidget {
  final Future<String> Function(BuildContext context)? queryBuilder;
  final String defaultCategory;

  const ProwlarrSearchButton({
    super.key,
    this.queryBuilder,
    this.defaultCategory = 'all',
  });

  @override
  Widget build(BuildContext context) {
    return LunaIconButton.appBar(
      icon: Icons.travel_explore_rounded,
      onPressed: () async {
        String query = '';
        if (queryBuilder != null) {
          try {
            query = await queryBuilder!(context);
          } catch (_) {}
        }
        await ProwlarrSearchSheet(
          initialQuery: query,
          defaultCategory: defaultCategory,
        ).show();
      },
    );
  }
}
