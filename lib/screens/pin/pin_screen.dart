import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';

const _ink = Color(0xFF1F1F1F);
const _muted = Color(0xFF5F6368);
const _payBlue = Color(0xFF1A56C4);
const _cardCream = Color(0xFFFDF3DC);
const _keyGrey = Color(0xFFF1F3F4);

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _connecting = true;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
    Future.delayed(context.read<AppProvider>().nextConnectionDelay(), () {
      if (mounted) setState(() => _connecting = false);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKey(String key, int pinLength) {
    if (key == '⌫') {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
    } else if (_pin.length < pinLength) {
      setState(() => _pin += key);
    }
  }

  void _onSubmit(int pinLength) {
    if (_pin.length < pinLength) {
      _shakeController.forward(from: 0);
      return;
    }
    context.pushReplacement(AppRouter.processing);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final session = provider.session;
    final bank = session.selectedBank ?? provider.primaryBank;
    final pn = session.parsedPayeeName.isEmpty ? 'Merchant' : session.parsedPayeeName;
    final pinLength = bank?.pinLength ?? 4;
    final accountKind = (bank?.accountType ?? 'Savings Account').split(' ').first.toUpperCase();

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(primary: AppColors.npciNavy, surface: AppColors.npciSurface),
      ),
      child: Scaffold(
        backgroundColor: AppColors.npciSurface,
        body: SafeArea(
          child: _connecting
              ? const Center(child: CircularProgressIndicator(color: AppColors.npciNavy))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _UpiWordmark(),
                                IconButton(
                                  icon: const Icon(Icons.close, color: _ink),
                                  onPressed: () => context.pop(),
                                ),
                              ],
                            ),
                            Text(
                              '$accountKind · ${bank?.bankName ?? 'Bank'} · ••• ${bank?.accountLast4 ?? '0000'}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink),
                            ),
                            const SizedBox(height: 12),
                            _PayCard(
                              title: session.isBalanceCheck
                                  ? 'Check balance'
                                  : 'Pay ₹${formatInr(session.enteredAmount)}.00',
                              payee: session.isBalanceCheck ? null : pn,
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Enter your PIN',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ink),
                            ),
                            const SizedBox(height: 16),
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) =>
                                  Transform.translate(offset: Offset(_shakeAnimation.value, 0), child: child),
                              child: _PinDots(length: pinLength, filled: _pin.length),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const _PinNotice(),
                    _Keypad(
                      submitLabel: session.isBalanceCheck ? 'Submit' : 'Pay',
                      onKey: (k) => _onKey(k, pinLength),
                      onSubmit: () => _onSubmit(pinLength),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  final String title;
  final String? payee;
  const _PayCard({required this.title, required this.payee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardCream, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                if (payee != null) ...[
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 13, color: _ink),
                      children: [
                        const TextSpan(text: 'To  '),
                        TextSpan(
                          text: payee!.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            children: [
              Icon(Icons.currency_rupee, size: 20, color: _ink),
              SizedBox(height: 6),
              Icon(Icons.account_box, size: 22, color: _payBlue),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int length;
  final int filled;
  const _PinDots({required this.length, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        return Container(
          key: ValueKey('pin-dot-$i'),
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? _ink : Colors.transparent,
            border: Border.all(color: i < filled ? _ink : _muted, width: 1.5),
          ),
        );
      }),
    );
  }
}

class _PinNotice extends StatelessWidget {
  const _PinNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.npciWarningText),
          SizedBox(width: 4),
          Flexible(
            child: Text('Never enter your UPI PIN to receive money', style: TextStyle(fontSize: 12, color: _ink)),
          ),
        ],
      ),
    );
  }
}

class _UpiWordmark extends StatelessWidget {
  const _UpiWordmark();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
        children: [
          TextSpan(
            text: 'UPI',
            style: TextStyle(color: AppColors.npciNavy),
          ),
          TextSpan(
            text: '/',
            style: TextStyle(color: Color(0xFFE8710A)),
          ),
          TextSpan(
            text: '/',
            style: TextStyle(color: Color(0xFF34A853)),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final String submitLabel;
  final ValueChanged<String> onKey;
  final VoidCallback onSubmit;

  const _Keypad({required this.submitLabel, required this.onKey, required this.onSubmit});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['⌫', '0', '✓'],
  ];

  Widget _key({required Color color, required VoidCallback onTap, required Widget child, Key? key}) {
    return Material(
      key: key,
      color: color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Center(child: child)),
    );
  }

  Widget _cell(String k) {
    if (k == '✓') {
      return _key(
        key: const ValueKey('pin-submit'),
        color: _payBlue,
        onTap: onSubmit,
        child: Text(
          submitLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    if (k == '⌫') {
      return _key(
        color: Colors.white,
        onTap: () => onKey(k),
        child: const Icon(Icons.backspace_outlined, color: _ink),
      );
    }
    return _key(
      color: _keyGrey,
      onTap: () => onKey(k),
      child: Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: _ink)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Column(
        children: _rows
            .map(
              (row) => SizedBox(
                height: 60,
                child: Row(
                  children: row
                      .map(
                        (k) => Expanded(
                          child: Padding(padding: const EdgeInsets.all(4), child: _cell(k)),
                        ),
                      )
                      .toList(),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
