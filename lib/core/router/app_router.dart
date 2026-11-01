import 'package:go_router/go_router.dart';
import '../../screens/amount/amount_screen.dart';
import '../../screens/entry/manual_entry_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/pin/pin_screen.dart';
import '../../screens/processing/processing_screen.dart';
import '../../screens/scanner/scanner_screen.dart';
import '../../screens/stealth/stealth_screen.dart';
import '../providers/app_provider.dart';

class AppRouter {
  static const home = '/';
  static const scanner = '/scanner';
  static const amount = '/amount';
  static const pin = '/pin';
  static const processing = '/processing';
  static const stealth = '/stealth';
  static const entry = '/entry';
  static const history = '/history';

  static String launchPath(AppProvider provider) =>
      provider.launchRoute == LaunchRoute.home ? home : scanner;

  static GoRouter router(AppProvider provider) => GoRouter(
    initialLocation: launchPath(provider),
    routes: [
      GoRoute(path: home, builder: (ctx, state) => const HomeScreen()),
      GoRoute(path: scanner, builder: (ctx, state) => const ScannerScreen()),
      GoRoute(path: amount, builder: (ctx, state) => AmountScreen(lookupPayee: state.extra == true)),
      GoRoute(path: pin, builder: (ctx, state) => const PinScreen()),
      GoRoute(path: processing, builder: (ctx, state) => const ProcessingScreen()),
      GoRoute(path: stealth, builder: (ctx, state) => const StealthScreen()),
      GoRoute(path: history, builder: (ctx, state) => const HistoryScreen()),
      GoRoute(
        path: entry,
        builder: (ctx, state) => ManualEntryScreen(mode: state.extra as EntryMode),
      ),
    ],
  );
}
