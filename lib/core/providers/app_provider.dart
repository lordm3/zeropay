import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/bank_profile.dart';
import '../models/session_state.dart';
import '../utils/device_auth.dart';

enum AppThemeMode { system, dark, light }

enum LaunchRoute { home, scanner }

enum LauncherName {
  zpay('ZPay', 'LauncherZPay'),
  quickScan('QuickScan QR', 'LauncherQuickScan'),
  scannerUtility('Scanner Utility', 'LauncherScannerUtility');

  final String label;
  final String alias;
  const LauncherName(this.label, this.alias);
}

class AppProvider extends ChangeNotifier {
  AppProvider({Future<bool> Function()? authenticator}) : _authenticator = authenticator ?? authenticateDevice;

  final Future<bool> Function() _authenticator;
  static const _storage = FlutterSecureStorage();
  static const _profilesKey = 'bank_profiles';
  static const _themeKey = 'app_theme';
  static const _launchRouteKey = 'launch_route';
  static const _launcherNameKey = 'launcher_name';
  static const _connectionDelayKey = 'connection_delay_ms';
  static const _appLockKey = 'app_lock';
  static const _avatarInitialKey = 'avatar_initial';
  static const _tapZonesKey = 'tap_zones';
  static const defaultAvatarInitial = 'A';

  List<BankProfile> _profiles = [];
  SessionState _session = SessionState.empty;
  AppThemeMode _themeMode = AppThemeMode.dark;
  LaunchRoute _launchRoute = LaunchRoute.home;
  LauncherName _launcherName = LauncherName.zpay;
  String _avatarInitial = defaultAvatarInitial;

  String get avatarInitial => _avatarInitial;

  bool _tapZones = false;

  bool get tapZones => _tapZones;

  bool _appLock = true;
  bool _locked = false;
  bool _authenticating = false;

  bool get appLock => _appLock;
  bool get isLocked => _locked;

  Future<void> unlock() async {
    if (_authenticating || !_locked) return;
    _authenticating = true;
    var success = false;
    try {
      success = await _authenticator();
    } finally {
      _authenticating = false;
    }
    if (success) {
      _locked = false;
      notifyListeners();
    }
  }

  // The system prompt can itself background the app; that must not re-lock it.
  void lockIfEnabled() {
    if (!_appLock || _authenticating || _locked) return;
    _locked = true;
    notifyListeners();
  }

  Future<void> setTapZones(bool enabled) async {
    _tapZones = enabled;
    await _storage.write(key: _tapZonesKey, value: enabled.toString());
    notifyListeners();
  }

  Future<void> setAppLock(bool enabled) async {
    _appLock = enabled;
    if (!enabled) _locked = false;
    await _storage.write(key: _appLockKey, value: enabled.toString());
    notifyListeners();
  }

  int _connectionDelayMs = 1500;

  int get connectionDelayMs => _connectionDelayMs;

  Duration nextConnectionDelay() {
    final jitter = 0.7 + Random().nextDouble() * 0.6;
    return Duration(milliseconds: (_connectionDelayMs * jitter).round());
  }

  BankProfile? get activeBank => _session.selectedBank ?? primaryBank;

  ErrorType get resolvedError =>
      _session.activeErrorOverride ?? activeBank?.defaultErrorType ?? ErrorType.serverUnavailable;
  LauncherName get launcherName => _launcherName;
  List<BankProfile> get profiles => List.unmodifiable(_profiles);
  SessionState get session => _session;
  AppThemeMode get themeMode => _themeMode;
  LaunchRoute get launchRoute => _launchRoute;

  BankProfile? get primaryBank =>
      _profiles.where((p) => p.isPrimary).firstOrNull ?? _profiles.firstOrNull;

  Future<void> init() async {
    await _loadProfiles();
    await _loadPrefs();
    if (_session.selectedBank == null && primaryBank != null) {
      _session = _session.copyWith(selectedBank: primaryBank);
    }
  }

  Future<void> _loadProfiles() async {
    final raw = await _storage.read(key: _profilesKey);
    if (raw == null) {
      _profiles = BankProfile.defaults();
      await _saveProfiles();
    } else {
      final list = jsonDecode(raw) as List;
      _profiles = list.map((e) => BankProfile.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _loadPrefs() async {
    final theme = await _storage.read(key: _themeKey);
    if (theme != null) _themeMode = AppThemeMode.values.byName(theme);
    final route = await _storage.read(key: _launchRouteKey);
    if (route != null) _launchRoute = LaunchRoute.values.byName(route);
    final launcher = await _storage.read(key: _launcherNameKey);
    if (launcher != null) _launcherName = LauncherName.values.byName(launcher);
    final connection = await _storage.read(key: _connectionDelayKey);
    if (connection != null) _connectionDelayMs = int.tryParse(connection) ?? 1500;
    _avatarInitial = await _storage.read(key: _avatarInitialKey) ?? defaultAvatarInitial;
    _tapZones = await _storage.read(key: _tapZonesKey) == 'true';
    _appLock = await _storage.read(key: _appLockKey) != 'false';
    _locked = _appLock;
  }

  Future<void> setConnectionDelayMs(int ms) async {
    _connectionDelayMs = ms.clamp(0, 3000);
    await _storage.write(key: _connectionDelayKey, value: _connectionDelayMs.toString());
    notifyListeners();
  }

  Future<void> setAvatarInitial(String initial) async {
    final letter = initial.trim().toUpperCase();
    _avatarInitial = letter.isEmpty ? defaultAvatarInitial : letter.substring(0, 1);
    await _storage.write(key: _avatarInitialKey, value: _avatarInitial);
    notifyListeners();
  }

  Future<void> setLauncherName(LauncherName name) async {
    _launcherName = name;
    await _storage.write(key: _launcherNameKey, value: name.name);
    notifyListeners();
  }

  Future<void> wipeAll() async {
    await _storage.deleteAll();
    _profiles = BankProfile.defaults();
    _themeMode = AppThemeMode.dark;
    _launchRoute = LaunchRoute.home;
    _launcherName = LauncherName.zpay;
    _connectionDelayMs = 1500;
    _avatarInitial = defaultAvatarInitial;
    _tapZones = false;
    _appLock = true;
    clearSession();
  }

  Future<void> _saveProfiles() async {
    final encoded = jsonEncode(_profiles.map((p) => p.toJson()).toList());
    await _storage.write(key: _profilesKey, value: encoded);
  }

  void updateSession(SessionState s) {
    _session = s;
    notifyListeners();
  }

  void clearSession() {
    _session = SessionState(
      selectedBank: primaryBank,
    );
    notifyListeners();
  }

  Future<void> saveProfile(BankProfile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx == -1) {
      _profiles.add(profile);
    } else {
      _profiles[idx] = profile;
    }
    if (profile.isPrimary) {
      _profiles = _profiles.map((p) => p.id == profile.id ? p : p.copyWith(isPrimary: false)).toList();
    }
    _session = SessionState(
      parsedUpiId: _session.parsedUpiId,
      parsedPayeeName: _session.parsedPayeeName,
      merchantCode: _session.merchantCode,
      enteredAmount: _session.enteredAmount,
      activeErrorOverride: _session.activeErrorOverride,
      selectedBank: _session.selectedBank?.id == profile.id ? profile : _session.selectedBank,
    );
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    if (_profiles.length <= 1) return;
    _profiles.removeWhere((p) => p.id == id);
    if (_session.selectedBank?.id == id) {
      _session = _session.copyWith(selectedBank: primaryBank);
    }
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> reorderProfiles(int oldIdx, int newIdx) async {
    final item = _profiles.removeAt(oldIdx);
    _profiles.insert(newIdx, item);
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _storage.write(key: _themeKey, value: mode.name);
    notifyListeners();
  }

  Future<void> setLaunchRoute(LaunchRoute route) async {
    _launchRoute = route;
    await _storage.write(key: _launchRouteKey, value: route.name);
    notifyListeners();
  }

}
