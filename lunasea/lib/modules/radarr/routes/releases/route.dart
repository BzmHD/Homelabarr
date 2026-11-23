import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/radarr.dart';
import 'package:lunasea/widgets/pages/invalid_route.dart';
import 'package:lunasea/widgets/sheets/download_client/button.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/button.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/sheet.dart';

class MovieReleasesRoute extends StatefulWidget {
  final int movieId;

  const MovieReleasesRoute({
    Key? key,
    required this.movieId,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<MovieReleasesRoute> with LunaScrollControllerMixin {
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
      _blocklistFuture = ProwlarrApi.fetchBlocklist(category: 'movies');
      _profileFuture = _fetchProfile(context);
    });
  }

  Future<RadarrMovie?> _findMovie(BuildContext context) async {
    try {
      final radarr = context.read<RadarrState>();
      final movies = await radarr.movies;
      if (movies != null) {
        for (final m in movies) {
          if (m.id == widget.movieId) return m;
        }
      }
      if (radarr.api != null) {
        return await radarr.api!.movie.get(movieId: widget.movieId);
      }
    } catch (_) {}
    return null;
  }

  Future<ProwlarrProfileInfo?> _fetchProfile(BuildContext context) async {
    final m = await _findMovie(context);
    return ProwlarrApi.fetchQualityProfile(
      category: 'movies',
      qualityProfileId: m?.qualityProfileId,
    );
  }

  Future<String> _buildProwlarrQuery(BuildContext context) async {
    final m = await _findMovie(context);
    if (m == null) return '';
    final yr = (m.year != null && m.year! > 0) ? ' ${m.year}' : '';
    return '${m.title ?? ''}$yr'.trim();
  }

  Future<List<Map<String, dynamic>>> _fetchProwlarr(BuildContext context) async {
    try {
      final m = await _findMovie(context);
      if (m == null) return [];
      final titleOnly = (m.title ?? '').trim();
      final yr = (m.year != null && m.year! > 0) ? ' ${m.year}' : '';
      final q = '$titleOnly$yr'.trim();
      if (q.isEmpty) return [];

      var res = await ProwlarrApi.search(q, category: 'movies');
      if (res.isEmpty && titleOnly.isNotEmpty && titleOnly != q) {
        res = await ProwlarrApi.search(titleOnly, category: 'movies');
      }
      return res;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movieId <= 0) {
      return InvalidRoutePage(
        title: 'Releases',
        message: 'Movie Not Found',
      );
    }
    return ChangeNotifierProvider(
      create: (context) => RadarrReleasesState(context, widget.movieId),
      builder: (context, _) => LunaScaffold(
        scaffoldKey: _scaffoldKey,
        appBar: _appBar(context) as PreferredSizeWidget?,
        body: _body(context),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return LunaAppBar(
      title: 'Releases',
      scrollControllers: [scrollController],
      bottom: RadarrReleasesSearchBar(scrollController: scrollController),
      actions: [
        ProwlarrSearchButton(
          defaultCategory: 'movies',
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
        context.read<RadarrReleasesState>().refreshReleases(context);
        _refreshProwlarr(context);
        await Future.wait([
          context.read<RadarrReleasesState>().releases ?? Future.value(),
          _prowlarrFuture ?? Future.value(),
          _blocklistFuture ?? Future.value(),
          _profileFuture ?? Future.value(),
        ]);
      },
      child: FutureBuilder(
        future: Future.wait([
          (context.read<RadarrReleasesState>().releases ??
                  Future.value(<RadarrRelease>[]))
              .catchError((_) => <RadarrRelease>[]),
          (_prowlarrFuture ?? Future.value(<Map<String, dynamic>>[]))
              .catchError((_) => <Map<String, dynamic>>[]),
          (_blocklistFuture ?? Future.value(<String, String>{}))
              .catchError((_) => <String, String>{}),
          (_profileFuture ?? Future<ProwlarrProfileInfo?>.value(null))
              .catchError((_) => null),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasData) {
            final radarrReleases =
                (snapshot.data![0] as List<RadarrRelease>?) ?? [];
            final prowlarrReleases =
                (snapshot.data![1] as List<Map<String, dynamic>>?) ?? [];
            final blocklist =
                (snapshot.data![2] as Map<String, String>?) ?? {};
            final qualityProfile = snapshot.data![3] as ProwlarrProfileInfo?;
            return _list(
              context,
              radarrReleases,
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
    List<RadarrRelease> releases,
    List<Map<String, dynamic>> prowlarrReleases,
    Map<String, String> blocklist,
    ProwlarrProfileInfo? qualityProfile,
  ) {
    return Consumer<RadarrReleasesState>(
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
            category: 'movies',
            blocklist: blocklist,
            qualityProfile: qualityProfile,
          ).isNotEmpty;
          final bRej = ProwlarrApi.evaluateRejections(
            b,
            category: 'movies',
            blocklist: blocklist,
            qualityProfile: qualityProfile,
          ).isNotEmpty;
          if (aRej == bRej) return 0;
          return aRej ? 1 : -1;
        });

        final totalCount = processed.length + filteredProwlarr.length;
        if (totalCount == 0) {
          return LunaMessage(
            text: 'No Releases Found',
            buttonText: 'Refresh',
            onTap: _refreshKey.currentState!.show,
          );
        }

        return LunaListViewBuilder(
          controller: scrollController,
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (index < processed.length) {
              return RadarrReleasesTile(release: processed[index]);
            }
            return ProwlarrApi.buildReleaseTile(
              filteredProwlarr[index - processed.length],
              category: 'movies',
              blocklist: blocklist,
              qualityProfile: qualityProfile,
            );
          },
        );
      },
    );
  }

  List<RadarrRelease> _filterAndSortReleases(
    List<RadarrRelease> releases,
    RadarrReleasesState state,
  ) {
    if (releases.isEmpty) return releases;
    List<RadarrRelease> filtered = releases.where(
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
