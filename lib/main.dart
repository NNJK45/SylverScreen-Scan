import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'api/gate_api.dart';

// Palette SylverScreen partagée avec l'application Club et le site web.
const ink = Color(0xFF070A12);
const inkSoft = Color(0xFF374151);
const muted = Color(0xFF7C86A2);
const line = Color(0xFFE1E6F2);
const background = Color(0xFFF4F6FB);
const gold = Color(0xFFD9A400);
const goldSoft = Color(0xFFFFF3C4);
const success = Color(0xFF16A34A);

final appSettings = AppSettingsController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appSettings.load();
  runApp(const SylverScreenScanApp());
}

class AppSettingsController extends ChangeNotifier {
  bool darkMode = false;
  String language = 'fr';

  Future<void> load() async {
    darkMode = await GateApi().darkModeEnabled();
    language = await GateApi().preferredLanguage();
  }

  Future<void> setDarkMode(bool value) async {
    if (darkMode == value) return;
    darkMode = value;
    notifyListeners();
    await GateApi().saveDarkMode(value);
  }

  Future<void> setLanguage(String value) async {
    if (language == value) return;
    language = value;
    notifyListeners();
    await GateApi().savePreferredLanguage(value);
  }
}

class SylverScreenScanApp extends StatelessWidget {
  const SylverScreenScanApp({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appSettings,
    builder: (_, _) => MaterialApp(
      title: 'SylverScreen Scan',
      debugShowCheckedModeBanner: false,
      themeMode: appSettings.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _appTheme(Brightness.light),
      darkTheme: _appTheme(Brightness.dark),
      home: const LoginScreen(),
    ),
  );
}

ThemeData _appTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final surface = isDark ? const Color(0xFF171C27) : Colors.white;
  final page = isDark ? const Color(0xFF0E1320) : background;
  final border = isDark ? const Color(0xFF30394C) : line;
  final foreground = isDark ? const Color(0xFFF4F6FB) : ink;
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: gold,
      primary: ink,
      secondary: gold,
      surface: surface,
    ),
    scaffoldBackgroundColor: page,
    fontFamily: 'Arial',
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: page,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: TextStyle(color: isDark ? const Color(0xFFB9C1D1) : muted),
      prefixIconColor: isDark ? const Color(0xFFB9C1D1) : inkSoft,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool hidden = true;
  bool loading = false;
  bool rememberMe = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _restoreRememberedEmail();
  }

  Future<void> _restoreRememberedEmail() async {
    final email = await GateApi().rememberedEmail();
    if (!mounted || email == null || email.isEmpty) return;
    setState(() {
      _email.text = email;
      rememberMe = true;
    });
  }
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => error = 'Saisissez votre email et votre mot de passe.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final email = _email.text.trim();
      final session = await GateApi().login(email, _password.text);
      await GateApi().saveRememberedEmail(rememberMe ? email : null);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GateHomeScreen(session: session)),
      );
    } on GateApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ListView(
          children: [
            const SizedBox(height: 18),
            const Icon(Icons.qr_code_scanner_rounded, color: gold, size: 104),
            const SizedBox(height: 12),
            const Text(
              'SYLVERSCREEN\nSCAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Connexion agent',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous pour contrôler les billets.',
              style: TextStyle(color: muted, fontSize: 16),
            ),
            const SizedBox(height: 28),
            _Input(
              label: 'Adresse email',
              icon: Icons.mail_outline,
              controller: _email,
            ),
            const SizedBox(height: 16),
            _Input(
              label: 'Mot de passe',
              icon: Icons.lock_outline,
              controller: _password,
              obscure: hidden,
              trailing: IconButton(
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: gold,
                ),
                onPressed: () => setState(() => hidden = !hidden),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: rememberMe,
              onChanged: loading
                  ? null
                  : (value) => setState(() => rememberMe = value ?? false),
              title: const Text('Se souvenir de moi'),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: gold,
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              Text(
                error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ink,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: loading ? null : _login,
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.trailing,
  });
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: label.contains('email')
        ? TextInputType.emailAddress
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: trailing,
    ),
  );
}

class GateHomeScreen extends StatefulWidget {
  const GateHomeScreen({super.key, required this.session});
  final GateSession session;
  @override
  State<GateHomeScreen> createState() => _GateHomeScreenState();
}

class _GateHomeScreenState extends State<GateHomeScreen> {
  late Future<List<GateProjection>> _projections;
  @override
  void initState() {
    super.initState();
    _projections = GateApi().projections(widget.session.token);
  }

  void _refresh() => setState(
    () => _projections = GateApi().projections(widget.session.token),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Mes projections',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Historique des scans',
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GateScanHistoryScreen(session: widget.session),
            ),
          ),
        ),
      ],
    ),
    body: FutureBuilder<List<GateProjection>>(
      future: _projections,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: gold));
        if (snapshot.hasError)
          return _LoadError(
            message: snapshot.error.toString(),
            retry: _refresh,
          );
        final projections = snapshot.data ?? [];
        if (projections.isEmpty)
          return const Center(
            child: Text(
              'Aucune projection accessible.',
              style: TextStyle(color: muted),
            ),
          );
        return RefreshIndicator(
          color: gold,
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: projections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (_, index) => GateProjectionCard(
              session: widget.session,
              projection: projections[index],
            ),
          ),
        );
      },
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GateSettingsScreen(session: widget.session),
            ),
          );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Projections',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Paramètres',
        ),
      ],
    ),
  );
}

class GateSettingsScreen extends StatelessWidget {
  const GateSettingsScreen({super.key, required this.session});
  final GateSession session;

  Future<void> _logout(BuildContext context) async {
    await GateApi().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appSettings,
    builder: (_, _) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDark ? const Color(0xFFF4F6FB) : ink;
      final secondaryColor = isDark ? const Color(0xFFB9C1D1) : muted;
      final tileColor = isDark ? const Color(0xFF171C27) : Colors.white;
      return Scaffold(
        appBar: AppBar(title: const Text('Paramètres'), centerTitle: true),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 1,
          onDestinationSelected: (index) {
            if (index == 0) Navigator.pop(context);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Projections'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Paramètres'),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: goldSoft,
                      child: Text(
                        session.name.isEmpty ? 'A' : session.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 39, color: ink, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_user_outlined, size: 19, color: ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(session.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 4),
              Text(session.email, textAlign: TextAlign.center, style: TextStyle(color: secondaryColor)),
              const SizedBox(height: 30),
              Text('Compte', style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 8),
              Card(
                color: tileColor,
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined, color: gold),
                  title: Text(session.role, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                  subtitle: Text('Session sécurisée', style: TextStyle(color: secondaryColor)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Langue', style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 8),
              Card(
                color: tileColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: appSettings.language,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: gold),
                      dropdownColor: tileColor,
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (value) {
                        if (value != null) appSettings.setLanguage(value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Apparence', style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 8),
              Card(
                color: tileColor,
                child: SwitchListTile.adaptive(
                  secondary: Icon(appSettings.darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: gold),
                  title: Text('Mode sombre', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                  subtitle: Text(appSettings.darkMode ? 'Activé' : 'Désactivé', style: TextStyle(color: secondaryColor)),
                  value: appSettings.darkMode,
                  activeTrackColor: gold,
                  onChanged: appSettings.setDarkMode,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE5484D), minimumSize: const Size.fromHeight(54)),
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
              const SizedBox(height: 18),
              Text('SylverScreen Scan', textAlign: TextAlign.center, style: TextStyle(color: secondaryColor, fontSize: 12)),
            ],
          ),
        ),
      );
    },
  );
}

class GateScanHistoryScreen extends StatefulWidget {
  const GateScanHistoryScreen({super.key, required this.session});
  final GateSession session;

  @override
  State<GateScanHistoryScreen> createState() => _GateScanHistoryScreenState();
}

class _GateScanHistoryScreenState extends State<GateScanHistoryScreen> {
  late Future<List<GateScanHistory>> _scans;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _scans = GateApi().scans(widget.session.token);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historique des scans')),
    body: FutureBuilder<List<GateScanHistory>>(
      future: _scans,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: gold));
        }
        if (snapshot.hasError) {
          return _LoadError(
            message: snapshot.error.toString(),
            retry: () => setState(_load),
          );
        }
        final scans = snapshot.data ?? [];
        if (scans.isEmpty) {
          return const Center(
            child: Text('Aucun scan enregistré.', style: TextStyle(color: muted)),
          );
        }
        return RefreshIndicator(
          color: gold,
          onRefresh: () async => setState(_load),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: scans.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final scan = scans[index];
              final accepted = scan.status == 'accepted';
              final color = accepted ? success : scan.status == 'already_used' ? gold : Colors.redAccent;
              final label = accepted ? 'Validé' : scan.status == 'already_used' ? 'Déjà utilisé' : 'Refusé';
              return Card(
                child: ListTile(
                  leading: Icon(accepted ? Icons.check_circle : Icons.info_outline, color: color),
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                  subtitle: Text(
                    '${_scanTime(scan.scannedAt)}${scan.reason == null ? '' : '\\n${scan.reason}'}',
                    style: const TextStyle(color: muted),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

String _scanTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${_clock(value)}';
class GateProjectionCard extends StatelessWidget {
  const GateProjectionCard({
    super.key,
    required this.session,
    required this.projection,
  });
  final GateSession session;
  final GateProjection projection;
  @override
  Widget build(BuildContext context) {
    final running = projection.status == 'ongoing';
    final stateLabel = running
        ? 'En cours'
        : projection.status == 'finished'
        ? 'Terminée'
        : 'À venir';
    final stateColor = running
        ? success
        : projection.status == 'finished'
        ? muted
        : gold;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    projection.movieName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                _StatusPill(label: stateLabel, color: stateColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${projection.cinemaName} · ${projection.hallName}',
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 5),
            Text(
              '${_clock(projection.startsAt)} - ${_clock(projection.endsAt)}',
              style: const TextStyle(
                color: inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: ink),
                onPressed: projection.status == 'finished'
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GateScannerScreen(
                            session: session,
                            projection: projection,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner les billets'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GateTicketsScreen(
                      session: session,
                      projection: projection,
                    ),
                  ),
                ),
                icon: const Icon(Icons.confirmation_number_outlined),
                label: const Text('Voir les billets'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GateScannerScreen extends StatefulWidget {
  const GateScannerScreen({
    super.key,
    required this.session,
    required this.projection,
  });
  final GateSession session;
  final GateProjection projection;
  @override
  State<GateScannerScreen> createState() => _GateScannerScreenState();
}

class _GateScannerScreenState extends State<GateScannerScreen> {
  final _controller = MobileScannerController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String code) async {
    if (_submitting || code.trim().isEmpty) return;
    setState(() => _submitting = true);
    await _controller.stop();
    GateScanResult result;
    try {
      result = await GateApi().scan(
        widget.session.token,
        code.trim(),
        widget.projection.id,
      );
    } on GateApiException catch (e) {
      result = GateScanResult(status: 'rejected', message: e.message);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GateScanResultScreen(
          session: widget.session,
          projection: widget.projection,
          result: result,
        ),
      ),
    );
  }

  Future<void> _manualCode() async {
    final input = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir un code'),
        content: TextField(
          controller: input,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Contenu du QR / référence',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    input.dispose();
    if (code != null) await _submit(code);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(
        widget.projection.movieName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    body: Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) _submit(code);
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: gold, width: 3),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        if (_submitting)
          const Center(child: CircularProgressIndicator(color: gold)),
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ink,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _submitting ? null : _manualCode,
            icon: const Icon(Icons.keyboard),
            label: const Text('Saisir un code manuellement'),
          ),
        ),
      ],
    ),
  );
}

class GateScanResultScreen extends StatelessWidget {
  const GateScanResultScreen({
    super.key,
    required this.session,
    required this.projection,
    required this.result,
  });
  final GateSession session;
  final GateProjection projection;
  final GateScanResult result;

  @override
  Widget build(BuildContext context) {
    final accepted = result.status == 'accepted';
    final alreadyUsed = result.status == 'already_used';
    final color = accepted
        ? success
        : alreadyUsed
        ? gold
        : Colors.redAccent;
    final title = accepted
        ? 'Billet validé'
        : alreadyUsed
        ? 'Billet déjà utilisé'
        : 'Entrée refusée';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat du contrôle'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.movie_outlined, size: 34, color: gold),
                      const SizedBox(height: 8),
                      const Text('PROJECTION', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(result.movieName ?? projection.movieName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(height: 4),
                      Text(result.cinemaName != null ? '${result.cinemaName} · ${result.hallName}' : '${projection.cinemaName} · ${projection.hallName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted)),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: line)),
                      const Text('PARTICIPANT', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(result.customerName ?? 'Participant non identifié', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(height: 12),
                      Text('Montant total : ${_formatXaf(result.totalAmount)}', style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 13),
                      Row(children: [
                        Expanded(child: _ResultTime(label: 'Début', value: result.projectionStart ?? projection.startsAt)),
                        Expanded(child: _ResultTime(label: 'Fin', value: result.projectionEnd ?? projection.endsAt, alignEnd: true)),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: .35))),
                child: Column(
                  children: [
                    Icon(accepted ? Icons.check_circle : alreadyUsed ? Icons.info_outline : Icons.cancel_outlined, color: color, size: 42),
                    const SizedBox(height: 7),
                    Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
                    if (alreadyUsed && result.firstCheckedInDate != null) ...[
                      const SizedBox(height: 6),
                      Text('Validé le ${_fullDateTime(result.firstCheckedInDate!)}', textAlign: TextAlign.center, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 5),
                    Text(result.message, textAlign: TextAlign.center, style: const TextStyle(color: inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: ink, minimumSize: const Size.fromHeight(54)),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => GateScannerScreen(session: session, projection: projection)),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner un autre billet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTime extends StatelessWidget {
  const _ResultTime({required this.label, required this.value, this.alignEnd = false});
  final String label;
  final DateTime value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(_shortDateTime(value), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: alignEnd ? TextAlign.end : TextAlign.start, style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
    ],
  );
}
class GateTicketsScreen extends StatefulWidget {
  const GateTicketsScreen({
    super.key,
    required this.session,
    required this.projection,
  });
  final GateSession session;
  final GateProjection projection;
  @override
  State<GateTicketsScreen> createState() => _GateTicketsScreenState();
}

class _GateTicketsScreenState extends State<GateTicketsScreen> {
  String filter = 'Tous';
  String? _validatingTicketId;
  late Future<List<GateTicket>> tickets;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    tickets = GateApi().tickets(
      widget.session.token,
      widget.projection.id,
      status: filter == 'Validés'
          ? 'validated'
          : filter == 'À valider'
          ? 'unused'
          : null,
    );
  }

  Future<void> _validate(GateTicket ticket) async {
    if (_validatingTicketId != null) return;
    setState(() => _validatingTicketId = ticket.id);
    try {
      final result = await GateApi().checkIn(widget.session.token, ticket.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.status == 'accepted'
              ? success
              : Colors.redAccent,
          content: Text(result.message),
        ),
      );
      setState(_load);
    } on GateApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _validatingTicketId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.projection.movieName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: ['Tous', 'Validés', 'À valider']
                .map(
                  (value) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: value == 'À valider' ? 0 : 8,
                      ),
                      child: ChoiceChip(
                        label: Text(value),
                        selected: filter == value,
                        selectedColor: goldSoft,
                        side: const BorderSide(color: line),
                        onSelected: (_) => setState(() {
                          filter = value;
                          _load();
                        }),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<GateTicket>>(
            future: tickets,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(
                  child: CircularProgressIndicator(color: gold),
                );
              if (snapshot.hasError)
                return _LoadError(
                  message: snapshot.error.toString(),
                  retry: () => setState(_load),
                );
              final data = snapshot.data ?? [];
              if (data.isEmpty)
                return const Center(
                  child: Text(
                    'Aucun billet trouvé.',
                    style: TextStyle(color: muted),
                  ),
                );
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: data.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final t = data[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.customerName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: ink,
                                  ),
                                ),
                              ),
                              _StatusPill(
                                label: t.checkedIn ? 'Validé' : 'À valider',
                                color: t.checkedIn ? success : gold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Billet n° ${t.sequenceNumber}',
                            style: const TextStyle(color: muted),
                          ),
                          if (!t.checkedIn) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: ink,
                                ),
                                onPressed: _validatingTicketId == null
                                    ? () => _validate(t)
                                    : null,
                                icon: _validatingTicketId == t.id
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(
                                  _validatingTicketId == t.id
                                      ? 'Validation en cours…'
                                      : 'Valider le billet',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .5)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w800),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, color: gold, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: retry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}

String _formatXaf(double amount) {
  final digits = amount.round().toString();
  return '${digits.replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => ' ')} XAF';
}

String _fullDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} à ${_clock(value)}';
String _shortDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} · ${_clock(value)}';
String _clock(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

class ProjectionsScreen extends StatelessWidget {
  const ProjectionsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Mes projections',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      centerTitle: true,
      backgroundColor: background,
    ),
    bottomNavigationBar: const _BottomBar(current: 0),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ProjectionCard(
          title: 'Spider-Man: Brand New Day',
          cinema: 'Canal Olympia Bessengue',
          hall: 'Salle 1',
          time: 'Aujourd’hui • 18:30 - 20:42',
          status: 'En cours',
        ),
        SizedBox(height: 16),
        ProjectionCard(
          title: 'Avatar: Fire and Ash',
          cinema: 'Canal Olympia Bessengue',
          hall: 'Salle 2',
          time: 'Aujourd’hui • 21:00 - 23:58',
          status: 'À venir',
        ),
        SizedBox(height: 16),
        ProjectionCard(
          title: 'Les Bad Guys 2',
          cinema: 'Canal Olympia Bessengue',
          hall: 'Salle 1',
          time: 'Hier • 16:00 - 17:44',
          status: 'Terminée',
        ),
      ],
    ),
  );
}

class ProjectionCard extends StatelessWidget {
  const ProjectionCard({
    super.key,
    required this.title,
    required this.cinema,
    required this.hall,
    required this.time,
    required this.status,
  });
  final String title, cinema, hall, time, status;
  @override
  Widget build(BuildContext context) {
    final active = status != 'Terminée';
    final color = status == 'En cours'
        ? success
        : status == 'À venir'
        ? gold
        : muted;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('$cinema • $hall', style: const TextStyle(color: muted)),
            const SizedBox(height: 6),
            Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: active
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScannerScreen(projection: title),
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scanner les billets'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketsListScreen(projection: title),
                      ),
                    ),
                    child: const Text('Voir les billets'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.projection});
  final String projection;
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool scanned = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(widget.projection, style: const TextStyle(fontSize: 16)),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            if (scanned) return;
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code == null) return;
            scanned = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ScanResultScreen(
                  payload: code,
                  projection: widget.projection,
                ),
              ),
            );
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        Positioned(
          bottom: 34,
          left: 24,
          right: 24,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: background,
              foregroundColor: ink,
            ),
            onPressed: () {},
            icon: const Icon(Icons.keyboard),
            label: const Text('Saisir un code manuellement'),
          ),
        ),
      ],
    ),
  );
}

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({
    super.key,
    required this.payload,
    required this.projection,
  });
  final String payload;
  final String projection;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résultat du contrôle'),
      centerTitle: true,
    ),
    bottomNavigationBar: const _BottomBar(current: 0),
    body: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.movie_outlined, size: 48, color: ink),
                  const SizedBox(height: 18),
                  Text(
                    projection,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Canal Olympia Bessengue • Salle 1'),
                  const Divider(height: 32),
                  const Text(
                    'Référence du billet',
                    style: TextStyle(color: muted),
                  ),
                  Text(
                    payload.length > 14
                        ? '${payload.substring(0, 14)}…'
                        : payload,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: success.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle, color: success, size: 50),
                SizedBox(height: 10),
                Text(
                  'Billet validé',
                  style: TextStyle(
                    color: success,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                SizedBox(height: 6),
                Text('Entrée autorisée'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ink,
              minimumSize: const Size.fromHeight(58),
            ),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ScannerScreen(projection: projection),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner un autre billet'),
          ),
        ],
      ),
    ),
  );
}

class DemoTicket {
  DemoTicket({
    required this.customer,
    required this.reference,
    required this.seat,
    this.validated = false,
  });
  final String customer;
  final String reference;
  final String seat;
  bool validated;
}

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key, required this.projection});
  final String projection;
  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  final _searchController = TextEditingController();
  String _filter = 'Tous';
  final List<DemoTicket> _tickets = [
    DemoTicket(
      customer: 'Mireille Ngono',
      reference: 'SSC-8F42A1',
      seat: 'Salle 1 · Place F08',
    ),
    DemoTicket(
      customer: 'Jean-Marc Ndzié',
      reference: 'SSC-9C17B5',
      seat: 'Salle 1 · Place F09',
    ),
    DemoTicket(
      customer: 'Aïcha Mahamat',
      reference: 'SSC-3D91E2',
      seat: 'Salle 1 · Place G03',
      validated: true,
    ),
    DemoTicket(
      customer: 'Paul Tchana',
      reference: 'SSC-6A04C8',
      seat: 'Salle 1 · Place G04',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DemoTicket> get _visibleTickets {
    final query = _searchController.text.trim().toLowerCase();
    return _tickets.where((ticket) {
      final matchesFilter =
          _filter == 'Tous' ||
          (_filter == 'Validés' && ticket.validated) ||
          (_filter == 'À valider' && !ticket.validated);
      final matchesSearch =
          query.isEmpty ||
          ticket.customer.toLowerCase().contains(query) ||
          ticket.reference.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _validate(DemoTicket ticket) {
    setState(() => ticket.validated = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success,
        content: Text('Billet de ${ticket.customer} validé.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _visibleTickets;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.projection,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Rechercher un billet ou un client',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['Tous', 'Validés', 'À valider']
                  .map(
                    (filter) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: filter == 'À valider' ? 0 : 8,
                        ),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          selectedColor: goldSoft,
                          labelStyle: TextStyle(
                            color: _filter == filter ? ink : muted,
                            fontWeight: FontWeight.w700,
                          ),
                          side: const BorderSide(color: line),
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tickets.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun billet trouvé',
                      style: TextStyle(color: muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _TicketCard(
                      ticket: tickets[index],
                      onValidate: () => _validate(tickets[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onValidate});
  final DemoTicket ticket;
  final VoidCallback onValidate;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.customer,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _TicketStatus(validated: ticket.validated),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Réf. ${ticket.reference}',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 3),
          Text(ticket.seat, style: const TextStyle(color: inkSoft)),
          if (!ticket.validated) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: onValidate,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Valider le billet'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _TicketStatus extends StatelessWidget {
  const _TicketStatus({required this.validated});
  final bool validated;
  @override
  Widget build(BuildContext context) {
    final color = validated ? success : gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            validated ? Icons.check_circle_outline : Icons.pending_outlined,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            validated ? 'Validé' : 'À valider',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Paramètres'), centerTitle: true),
    bottomNavigationBar: const _BottomBar(current: 1),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(
          radius: 54,
          backgroundColor: Color(0xFF5267B9),
          child: Text('A', style: TextStyle(fontSize: 44, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Agent SylverScreen',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'agent@sylverscreen.com',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 30),
        const Text(
          'Cinéma associé',
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            leading: Icon(Icons.theaters_outlined, color: gold),
            title: Text('Canal Olympia Bessengue'),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Langue',
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            title: Text('Français'),
            trailing: Icon(Icons.keyboard_arrow_down, color: gold),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mode de l’application',
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
        Card(
          child: SwitchListTile(
            value: darkMode,
            onChanged: (value) => setState(() => darkMode = value),
            title: const Text('Mode sombre'),
            secondary: const Icon(Icons.dark_mode_outlined, color: gold),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE5484D),
            minimumSize: const Size.fromHeight(54),
          ),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
        ),
      ],
    ),
  );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.current});
  final int current;
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: current,
    onDestinationSelected: (i) {
      if (i == 0) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProjectionsScreen()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
          (_) => false,
        );
      }
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Mes projections',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Paramètres',
      ),
    ],
  );
}





