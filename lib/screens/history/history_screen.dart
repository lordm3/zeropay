import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/palette.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.surface,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 56, color: palette.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      "Couldn't load transaction history. Servers are temporarily unreachable. Please try again later.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: palette.textPrimary),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: palette.onAccent,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
