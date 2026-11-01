import 'package:flutter/material.dart';
import '../providers/app_provider.dart';

class SessionLifecycleObserver with WidgetsBindingObserver {
  final AppProvider provider;
  final VoidCallback onBackground;

  SessionLifecycleObserver({required this.provider, required this.onBackground});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      provider.clearSession();
      onBackground();
      provider.lockIfEnabled();
    }
  }
}
