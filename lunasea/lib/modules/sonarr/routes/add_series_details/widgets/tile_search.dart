import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/sonarr.dart';

class SonarrSeriesAddDetailsSearchTile extends StatelessWidget {
  const SonarrSeriesAddDetailsSearchTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LunaBlock(
      title: 'sonarr.StartSearchFor'.tr(),
      trailing: Selector<SonarrSeriesAddDetailsState, bool>(
        selector: (_, state) => state.searchForMissing,
        builder: (context, searchForMissing, _) => LunaSwitch(
          value: searchForMissing,
          onChanged: (value) =>
              context.read<SonarrSeriesAddDetailsState>().searchForMissing = value,
        ),
      ),
    );
  }
}
