import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/radarr.dart';

class RadarrAddMovieDetailsSearchTile extends StatelessWidget {
  const RadarrAddMovieDetailsSearchTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LunaBlock(
      title: 'radarr.StartSearchFor'.tr(),
      trailing: Selector<RadarrAddMovieDetailsState, bool>(
        selector: (_, state) => state.searchForMovie,
        builder: (context, searchForMovie, _) => LunaSwitch(
          value: searchForMovie,
          onChanged: (value) =>
              context.read<RadarrAddMovieDetailsState>().searchForMovie = value,
        ),
      ),
    );
  }
}
