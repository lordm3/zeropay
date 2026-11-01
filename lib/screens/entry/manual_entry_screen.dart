import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/palette.dart';

enum EntryMode { search, contacts, phone, bankTransfer }

class ManualEntryScreen extends StatefulWidget {
  final EntryMode mode;
  const ManualEntryScreen({super.key, required this.mode});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _primary = TextEditingController();
  final _ifsc = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _primary.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  bool get _isBankTransfer => widget.mode == EntryMode.bankTransfer;

  bool get _valid {
    final text = _primary.text.trim();
    final isPhone = RegExp(r'^\d{10}$').hasMatch(text);
    return switch (widget.mode) {
      EntryMode.phone => isPhone,
      EntryMode.bankTransfer => text.isNotEmpty && _ifsc.text.trim().isNotEmpty,
      _ => isPhone || RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(text),
    };
  }

  Future<void> _proceed() async {
    if (_isBankTransfer) {
      setState(() {
        _busy = true;
        _error = null;
      });
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Bank server down';
        });
      }
      return;
    }
    final text = _primary.text.trim();
    final provider = context.read<AppProvider>();
    provider.updateSession(provider.session.copyWith(
      parsedPayeeName: text,
      parsedUpiId: text.contains('@') ? text : '$text@upi',
      merchantCode: '',
    ));
    context.pushReplacement(AppRouter.amount);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final (title, hint) = switch (widget.mode) {
      EntryMode.search => ('Pay friends and merchants', 'Phone number or UPI ID'),
      EntryMode.contacts => ('Pay anyone', 'Phone number or UPI ID'),
      EntryMode.phone => ('Pay phone number', '10-digit phone number'),
      EntryMode.bankTransfer => ('Bank transfer', 'Account number'),
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.surface,
        title: Text(title, style: const TextStyle(fontSize: 18)),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              controller: _primary,
              hint: hint,
              autofocus: true,
              digitsOnly: widget.mode == EntryMode.phone || _isBankTransfer,
              onChanged: () => setState(() {}),
            ),
            if (_isBankTransfer) ...[
              const SizedBox(height: 12),
              _Field(controller: _ifsc, hint: 'IFSC', onChanged: () => setState(() {})),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: palette.error)),
              ),
            const Spacer(),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  shape: const StadiumBorder(),
                ),
                onPressed: _valid && !_busy ? _proceed : null,
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final bool digitsOnly;
  final VoidCallback onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
    this.digitsOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: digitsOnly ? TextInputType.number : TextInputType.emailAddress,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: palette.container,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
