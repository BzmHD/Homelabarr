import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/sonarr.dart';
import 'package:lunasea/widgets/sheets/download_client/button.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/button.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/sheet.dart';

class ReleasesRoute extends StatefulWidget {
  final int? episodeId;
  final int? seriesId;
  final int? seasonNumber;

  const ReleasesRoute({
    Key? key,
    this.episodeId,
    this.seriesId,
    this.seasonNumber,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<ReleasesRoute> with LunaScrollControllerMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  Future<List<Map<String, dynamic>>>? _prowlarrFuture;
  Future<Map<String, String>>? _blocklistFuture;
  Future<ProwlarrProfileInfo?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshProwlarr(context);
    });
  }

  void _refreshProwlarr(BuildContext context) {
    setState(() {
      _prowlarrFuture = _fetchProwlarr(context);
      _blocklistFuture = ProwlarrApi.fetchBlocklist(category: 'tv');
      _profileFuture = _fetchProfile(context);
    });
  }

  Future<SonarrSeries?> _findSeries(BuildContext context) async {
    try {
      final sonarr = context.read<SonarrState>();
      final allSeries = await sonarr.series;
      int? sid = widget.seriesId;
      if (sid == null && widget.episodeId != null && sonarr.api != null) {
        try {
          final ep = await sonarr.api!.episode.get(episodeId: widget.episodeId!);
          sid = ep.seriesId;
        } catch (_) {}
      }
      if (sid != null && allSeries != null && allSeries[sid] != null) {
        return allSeries[sid];
      }
      if (sid != null && sonarr.api != null) {
        return await sonarr.api!.series.get(seriesId: sid);
      }
    } catch (_) {}
    return null;
  }

  Future<ProwlarrProfileInfo?> _fetchProfile(BuildContext context) async {
    final s = await _findSeries(context);
    return ProwlarrApi.fetchQualityProfile(
      category: 'tv',
      qualityProfileId: s?.qualityProfileId,
    );
  }

  Future<String> _buildProwlarrQuery(BuildContext context) async {
    try {
      final sonarr = context.read<SonarrState>();
      int? sNum = widget.seasonNumber;
      int? eNum;

      if (widget.episodeId != null && sonarr.api != null) {
        try {
          final ep = await sonarr.api!.episode.get(episodeId: widget.episodeId!);
          sNum ??= ep.seasonNumber;
          eNum = ep.episodeNumber;
        } catch (_) {}
      }

      final s = await _findSeries(context);
      final title = (s?.title ?? '').trim();
      if (title.isEmpty) return '';

      if (sNum != null && eNum != null) {
        final sn = sNum.toString().padLeft(2, '0');
        final en = eNum.toString().padLeft(2, '0');
        return '$title S${sn}E$en';
      }
      if (sNum != null) {
        final sn = sNum.toString().padLeft(2, '0');
        return '$title S$sn';
      }
      return title;
    } catch (_) {
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProwlarr(BuildContext context) async {
    try {
      final q = await _buildProwlarrQuery(context);
      if (q.isEmpty) return [];
      return await ProwlarrApi.search(q, category: 'tv');
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SonarrReleasesState(
        context: context,
        episodeId: widget.episodeId,
        seriesId: widget.seriesId,
        seasonNumber: widget.seasonNumber,
      ),
      builder: (context, _) => LunaScaffold(
        scaffoldKey: _scaffoldKey,
        appBar: _appBar(context) as PreferredSizeWidget?,
        body: _body(context),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return LunaAppBar(
      title: 'sonarr.Releases'.tr(),
      scrollControllers: [scrollController],
      bottom: SonarrReleasesSearchBar(scrollController: scrollController),
      actions: [
        ProwlarrSearchButton(
          defaultCategory: 'tv',
          queryBuilder: (ctx) => _buildProwlarrQuery(ctx),
        ),
        const DownloadClientButton(),
      ],
    );
  }

  Widget _body(BuildContext context) {
    return LunaRefreshIndicator(
      context: context,
      key: _refreshKey,
      onRefresh: () async {
        context.read<SonarrReleasesState>().refreshReleases(context);
        _refreshProwlarr(context);
        await Future.wait([
          context.read<SonarrReleasesState>().releases ?? Future.value(),
          _prowlarrFuture ?? Future.value(),
          _blocklistFuture ?? Future.value(),
          _profileFuture ?? Future.value(),
        ]);
      },
      child: FutureBuilder(
        future: Future.wait([
          (context.read<SonarrReleasesState>().releases ??
                  Future.value(<SonarrRelease>[]))
              .catchError((_) => <SonarrRelease>[]),
          (_prowlarrFuture ?? Future.value(<Map<String, dynamic>>[]))
              .catchError((_) => <Map<String, dynamic>>[]),
          (_blocklistFuture ?? Future.value(<String, String>{}))
              .catchError((_) => <String, String>{}),
          (_profileFuture ?? Future<ProwlarrProfileInfo?>.value(null))
              .catchError((_) => null),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasData) {
            final sonarrReleases =
                (snapshot.data![0] as List<SonarrRelease>?) ?? [];
            final prowlarrReleases =
                (snapshot.data![1] as List<Map<String, dynamic>>?) ?? [];
            final blocklist =
                (snapshot.data![2] as Map<String, String>?) ?? {};
            final qualityProfile = snapshot.data![3] as ProwlarrProfileInfo?;
            return _list(
              context,
              sonarrReleases,
              prowlarrReleases,
              blocklist,
              qualityProfile,
            );
          }
          return const LunaLoader();
        },
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<SonarrRelease> releases,
    List<Map<String, dynamic>> prowlarrReleases,
    Map<String, String> blocklist,
    ProwlarrProfileInfo? qualityProfile,
  ) {
    return Consumer<SonarrReleasesState>(
      builder: (context, state, _) {
        final processed = _filterAndSortReleases(releases, state);
        final q = state.searchQuery.trim().toLowerCase();
        final filteredProwlarr = prowlarrReleases.where((r) {
          if (q.isEmpty) return true;
          return (r['title'] ?? '').toString().toLowerCase().contains(q);
        }).toList();

        // Sort approved/matching-quality releases first, rejected/mismatched below
        filteredProwlarr.sort((a, b) {
          final aRej = ProwlarrApi.evaluateRejections(
            a,
            category: 'tv',
            blocklist: blocklist,
            qualityProfile: qualityProfile,
          ).isNotEmpty;
          final bRej = ProwlarrApi.evaluateRejections(
            b,
            category: 'tv',
            blocklist: blocklist,
            qualityProfile: qualityProfile,
          ).isNotEmpty;
          if (aRej == bRej) return 0;
          return aRej ? 1 : -1;
        });

        final totalCount = processed.length + filteredProwlarr.length;
        if (totalCount == 0) {
          return LunaMessage(
            text: 'sonarr.NoReleasesFound'.tr(),
            buttonText: 'lunasea.Refresh'.tr(),
            onTap: _refreshKey.currentState!.show,
          );
        }

        return LunaListViewBuilder(
          controller: scrollController,
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (index < processed.length) {
              return SonarrReleasesTile(release: processed[index]);
            }
            return ProwlarrApi.buildReleaseTile(
              filteredProwlarr[index - processed.length],
              category: 'tv',
              blocklist: blocklist,
              qualityProfile: qualityProfile,
            );
          },
        );
      },
    );
  }

  List<SonarrRelease> _filterAndSortReleases(
    List<SonarrRelease> releases,
    SonarrReleasesState state,
  ) {
    if (releases.isEmpty) return releases;
    List<SonarrRelease> filtered = releases.where(
      (release) {
        String _query = state.searchQuery;
        if (_query.isNotEmpty) {
          return release.title!.toLowerCase().contains(_query.toLowerCase());
        }
        return true;
      },
    ).toList();
    filtered = state.filterType.filter(filtered);
    filtered = state.sortType.sort(filtered, state.sortAscending);
    return filtered;
  }
}
