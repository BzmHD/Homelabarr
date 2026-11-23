import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/nzbget.dart';
import 'package:lunasea/modules/radarr.dart';
import 'package:lunasea/modules/sonarr.dart';
import 'package:lunasea/widgets/sheets/prowlarr_search/sheet.dart';
import 'package:lunasea/widgets/ui/homelabarr_themes.dart';

class HomelabarrWalkthrough {
  static const String _doneKey = 'HOMELABARR_ONBOARDING_DONE_V1';

  static bool get isCompleted => LunaBox.lunasea.read(_doneKey) == true;

  static Future<void> markCompleted() async {
    await LunaBox.lunasea.update(_doneKey, true);
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    if (isCompleted) return;
    await show(context);
  }

  static Future<void> show(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _WalkthroughPage(),
      ),
    );
  }
}

class _WalkthroughPage extends StatefulWidget {
  const _WalkthroughPage();

  @override
  State<_WalkthroughPage> createState() => _WalkthroughPageState();
}

class _WalkthroughPageState extends State<_WalkthroughPage> {
  int _step = 0;
  static const int _totalSteps = 7;

  // Sonarr
  late bool _sonarrEnabled;
  late TextEditingController _sonarrHost;
  late TextEditingController _sonarrKey;

  // Radarr
  late bool _radarrEnabled;
  late TextEditingController _radarrHost;
  late TextEditingController _radarrKey;

  // Prowlarr
  late TextEditingController _prowlarrHost;
  late TextEditingController _prowlarrKey;
  bool _prowlarrConfigured = true;

  // NZBGet
  late bool _nzbgetEnabled;
  late TextEditingController _nzbgetHost;
  late TextEditingController _nzbgetUser;
  late TextEditingController _nzbgetPass;

  @override
  void initState() {
    super.initState();
    final p = LunaProfile.current;
    _sonarrEnabled = p.sonarrEnabled;
    _sonarrHost = TextEditingController(text: p.sonarrHost);
    _sonarrKey = TextEditingController(text: p.sonarrKey);

    _radarrEnabled = p.radarrEnabled;
    _radarrHost = TextEditingController(text: p.radarrHost);
    _radarrKey = TextEditingController(text: p.radarrKey);

    _prowlarrHost = TextEditingController(text: ProwlarrConfig.host);
    _prowlarrKey = TextEditingController(text: ProwlarrConfig.apiKey);

    _nzbgetEnabled = p.nzbgetEnabled;
    _nzbgetHost = TextEditingController(text: p.nzbgetHost);
    _nzbgetUser = TextEditingController(text: p.nzbgetUser);
    _nzbgetPass = TextEditingController(text: p.nzbgetPass);
  }

  @override
  void dispose() {
    _sonarrHost.dispose();
    _sonarrKey.dispose();
    _radarrHost.dispose();
    _radarrKey.dispose();
    _prowlarrHost.dispose();
    _prowlarrKey.dispose();
    _nzbgetHost.dispose();
    _nzbgetUser.dispose();
    _nzbgetPass.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentStep() async {
    final key = LunaSeaDatabase.ENABLED_PROFILE.read();
    final p = LunaBox.profiles.read(key) ?? LunaProfile();

    if (_step == 2) {
      p.sonarrEnabled = _sonarrEnabled;
      p.sonarrHost = _sonarrHost.text.trim();
      p.sonarrKey = _sonarrKey.text.trim();
      await LunaBox.profiles.update(key, p);
      if (mounted) context.read<SonarrState>().reset();
    } else if (_step == 3) {
      p.radarrEnabled = _radarrEnabled;
      p.radarrHost = _radarrHost.text.trim();
      p.radarrKey = _radarrKey.text.trim();
      await LunaBox.profiles.update(key, p);
      if (mounted) context.read<RadarrState>().reset();
    } else if (_step == 4) {
      ProwlarrConfig.host = _prowlarrHost.text.trim();
      ProwlarrConfig.apiKey = _prowlarrKey.text.trim();
      _prowlarrConfigured = ProwlarrConfig.host.isNotEmpty;
    } else if (_step == 5) {
      p.nzbgetEnabled = _nzbgetEnabled;
      p.nzbgetHost = _nzbgetHost.text.trim();
      p.nzbgetUser = _nzbgetUser.text.trim();
      p.nzbgetPass = _nzbgetPass.text.trim();
      await LunaBox.profiles.update(key, p);
      if (mounted) context.read<NZBGetState>().reset();
    }
  }

  Future<void> _next({bool save = true}) async {
    if (save) await _saveCurrentStep();
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    await HomelabarrWalkthrough.markCompleted();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: LunaColours.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: LunaColours.grey),
          filled: true,
          fillColor: LunaColours.secondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: LunaColours.blueGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: LunaColours.blueGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: LunaColours.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                LunaAssets.brandingLogo,
                width: 112,
                height: 112,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Homelabarr',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: LunaColours.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Manage Sonarr, Radarr, NZBGet, and direct Prowlarr Interactive Search from one clean app.\n\nSet up each service below or skip any option you don\'t use.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: LunaColours.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.palette_rounded, color: HomelabarrTheme.current.accent, size: 42),
            const SizedBox(height: 14),
            Text(
              'Choose Theme & App Icon',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: HomelabarrTheme.current.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick your favorite color palette and matching iPhone Home Screen icon. You can change this anytime in Settings.',
              style: TextStyle(fontSize: 14, color: HomelabarrTheme.current.grey, height: 1.4),
            ),
            const SizedBox(height: 18),
            const HomelabarrThemePicker(),
          ],
        );

      case 2:
        return _serviceStep(
          icon: Icons.tv_rounded,
          title: 'Sonarr (TV Shows)',
          subtitle: 'Connect your Sonarr instance for TV libraries, calendar, and interactive episode search.',
          enabled: _sonarrEnabled,
          onToggle: (v) => setState(() => _sonarrEnabled = v),
          fields: [
            _field('Sonarr Host URL', _sonarrHost),
            _field('Sonarr API Key', _sonarrKey),
          ],
        );

      case 3:
        return _serviceStep(
          icon: Icons.movie_rounded,
          title: 'Radarr (Movies)',
          subtitle: 'Connect your Radarr instance for movie libraries, quality profiles, and interactive search.',
          enabled: _radarrEnabled,
          onToggle: (v) => setState(() => _radarrEnabled = v),
          fields: [
            _field('Radarr Host URL', _radarrHost),
            _field('Radarr API Key', _radarrKey),
          ],
        );

      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.travel_explore_rounded, color: HomelabarrTheme.current.accent, size: 42),
            const SizedBox(height: 14),
            Text(
              'Prowlarr (Direct Search)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: HomelabarrTheme.current.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Powers automatic inline Prowlarr results inside Sonarr & Radarr Interactive Search with live quality profile & blocklist checks.',
              style: TextStyle(fontSize: 14, color: HomelabarrTheme.current.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            _field('Prowlarr Host URL', _prowlarrHost),
            _field('Prowlarr API Key', _prowlarrKey),
          ],
        );

      case 5:
        return _serviceStep(
          icon: Icons.download_rounded,
          title: 'NZBGet (Downloads)',
          subtitle: 'Control your Usenet queue and 1-tap send releases straight from Prowlarr.',
          enabled: _nzbgetEnabled,
          onToggle: (v) => setState(() => _nzbgetEnabled = v),
          fields: [
            _field('NZBGet Host URL', _nzbgetHost),
            _field('Username', _nzbgetUser),
            _field('Password', _nzbgetPass, obscure: true),
          ],
        );

      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: LunaColours.accent, size: 72),
            const SizedBox(height: 20),
            const Text(
              'Homelabarr is Ready',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: LunaColours.white),
            ),
            const SizedBox(height: 16),
            _summaryRow('Sonarr', _sonarrEnabled),
            _summaryRow('Radarr', _radarrEnabled),
            _summaryRow('Prowlarr', _prowlarrConfigured),
            _summaryRow('NZBGet', _nzbgetEnabled),
          ],
        );
    }
  }

  Widget _serviceStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required List<Widget> fields,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: LunaColours.accent, size: 42),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LunaColours.white),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: LunaColours.grey, height: 1.4),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: LunaColours.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: const Text('Enable Service', style: TextStyle(color: LunaColours.white, fontWeight: FontWeight.w600)),
            activeColor: LunaColours.accent,
            value: enabled,
            onChanged: onToggle,
          ),
        ),
        const SizedBox(height: 14),
        ...fields,
      ],
    );
  }

  Widget _summaryRow(String name, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LunaColours.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: LunaColours.white, fontSize: 15, fontWeight: FontWeight.w600)),
          Text(
            active ? 'Configured' : 'Skipped',
            style: TextStyle(
              color: active ? LunaColours.accent : LunaColours.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / _totalSteps;
    return Scaffold(
      backgroundColor: LunaColours.primary,
      appBar: AppBar(
        backgroundColor: LunaColours.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LunaColours.white, size: 20),
                onPressed: () => setState(() => _step--),
              )
            : null,
        title: Text(
          'Step ${_step + 1} of $_totalSteps',
          style: const TextStyle(color: LunaColours.grey, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_step < _totalSteps - 1)
            TextButton(
              onPressed: _finish,
              child: const Text(
                'Skip All',
                style: TextStyle(color: LunaColours.grey, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: LunaColours.secondary,
                  valueColor: const AlwaysStoppedAnimation<Color>(LunaColours.accent),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepBody(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_step > 0 && _step < _totalSteps - 1)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LunaColours.white,
                          side: const BorderSide(color: LunaColours.blueGrey),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _next(save: false),
                        child: const Text('Skip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (_step > 0 && _step < _totalSteps - 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LunaColours.accent,
                        foregroundColor: LunaColours.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _next(save: true),
                      child: Text(
                        _step == 0
                            ? 'Get Started'
                            : _step == _totalSteps - 1
                                ? 'Open Homelabarr'
                                : 'Save & Next',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
