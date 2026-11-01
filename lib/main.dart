import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/lifecycle/session_lifecycle_observer.dart';
import 'core/providers/app_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'screens/lock/lock_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = AppProvider();
  await provider.init();
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const ZPayApp(),
    ),
  );
}

class ZPayApp extends StatefulWidget {
  const ZPayApp({super.key});

  @override
  State<ZPayApp> createState() => _ZPayAppState();
}

class _ZPayAppState extends State<ZPayApp> {
  late final SessionLifecycleObserver _lifecycleObserver;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _router = AppRouter.router(provider);
    _lifecycleObserver = SessionLifecycleObserver(
      provider: provider,
      onBackground: () => _router.go(AppRouter.launchPath(provider)),
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = switch (context.select<AppProvider, AppThemeMode>((p) => p.themeMode)) {
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'ZPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      builder: (context, child) => LockGate(child: child!),
    );
  }
}
