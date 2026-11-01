import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../../core/models/bank_profile.dart';
import '../../core/models/session_state.dart';
import '../../core/providers/app_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/app_exit.dart';
import '../../core/utils/avatar_color.dart';
import '../../core/utils/error_content.dart';
import '../../core/utils/format.dart';
import '../../widgets/bank_badge.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/timed_long_press.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  bool _showFailure = false;
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final String _upiRef;
  late final String _txnId;
  DateTime _failedAt = DateTime.now();
  bool _detailsOpen = true;

  @override
  void initState() {
    super.initState();
    final random = Random.secure();
    _upiRef = List.generate(12, (_) => random.nextInt(10)).join();
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    _txnId = List.generate(16, (_) => alphabet[random.nextInt(alphabet.length)]).join();
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _iconScale = CurvedAnimation(parent: _iconController, curve: Curves.easeOut);
    final provider = context.read<AppProvider>();
    final isPayment = !provider.session.isBalanceCheck;
    final bank = provider.activeBank;
    if (isPayment && bank?.failureMode == FailureMode.indefinite) return;
    final latency = isPayment && bank?.failureMode == FailureMode.longDelay
        ? 10000 + random.nextInt(10001)
        : bank?.latencyMs ?? 2500;
    Future.delayed(Duration(milliseconds: latency), _revealFailure);
  }

  void _revealFailure() {
    if (!mounted || _showFailure) return;
    Vibration.vibrate(pattern: [0, 80, 60, 120]);
    _iconController.forward();
    setState(() {
      _failedAt = DateTime.now();
      _showFailure = true;
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _exitToStart() {
    final provider = context.read<AppProvider>();
    provider.clearSession();
    context.go(AppRouter.launchPath(provider));
  }

  void _tryAgain() {
    final provider = context.read<AppProvider>();
    provider.updateSession(provider.session.copyWith(isBankBottomSheetOpen: true, clearErrorOverride: true));
    context.pop();
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final session = provider.session;
    final palette = Palette.of(context);
    final pn = session.parsedPayeeName.isEmpty ? 'Merchant' : session.parsedPayeeName;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: !_showFailure
              ? _buildProgress(session, pn, palette)
              : session.isBalanceCheck
                  ? _buildBalanceFailure(palette)
                  : _buildPaymentFailure(session, provider, pn, palette),
        ),
      ),
    );
  }

  Widget _buildProgress(SessionState session, String pn, Palette palette) {
    final label = session.isBalanceCheck
        ? 'Checking balance...'
        : 'Paying $pn ₹${formatInr(session.enteredAmount)}...';
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TimedLongPress(
                  duration: const Duration(seconds: 2),
                  onLongPress: _revealFailure,
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(child: CircularProgressIndicator(color: palette.accent, strokeWidth: 3)),
                        if (!session.isBalanceCheck)
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: avatarColorFor(pn),
                            child: Text(pn[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black87)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: palette.textPrimary)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text('Powered by UPI', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
        ),
      ],
    );
  }

  Widget _errorIcon(Palette palette) {
    return ScaleTransition(
      scale: _iconScale,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(color: palette.error, shape: BoxShape.circle),
        child: Icon(Icons.priority_high, color: palette.surface, size: 32),
      ),
    );
  }

  Widget _buildBalanceFailure(Palette palette) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(child: _errorIcon(palette)),
          const SizedBox(height: 16),
          Text('Unable to check balance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: palette.textPrimary)),
          const SizedBox(height: 8),
          Text("Your bank's servers didn't respond. Please try again later. (Error: U16)",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.textSecondary)),
          const Spacer(),
          PillButton(label: 'Close', outlined: true, onTap: _exitToStart),
        ],
      ),
    );
  }

  Widget _buildPaymentFailure(SessionState session, AppProvider provider, String pn, Palette palette) {
    final bank = session.selectedBank ?? provider.primaryBank;
    final pa = session.parsedUpiId.isEmpty ? 'merchant@okaxis' : session.parsedUpiId;
    final amount = formatInr(session.enteredAmount);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _receiptHeader(amount, pn, pa, palette),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _statusCard(amount, provider.resolvedError, bank, palette),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: PillButton(label: 'Close', outlined: true, onTap: finishTask)),
              const SizedBox(width: 12),
              Expanded(
                child: PillButton(
                  label: 'Try again',
                  icon: const Icon(Icons.refresh, size: 20),
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  onTap: _tryAgain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _receiptHeader(String amount, String pn, String pa, Palette palette) {
    return Container(
      color: palette.container,
      padding: const EdgeInsets.only(bottom: 48),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(icon: Icon(Icons.arrow_back, color: palette.textPrimary), onPressed: _exitToStart),
              const Spacer(),
              Icon(Icons.more_vert, color: palette.textPrimary),
              const SizedBox(width: 12),
            ],
          ),
          CircleAvatar(
            radius: 26,
            backgroundColor: avatarColorFor(pn),
            child: Text(pn[0].toUpperCase(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black87)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('₹', style: TextStyle(fontSize: 22, color: palette.textPrimary)),
              ),
              const SizedBox(width: 4),
              Text(amount, style: TextStyle(fontSize: 52, fontWeight: FontWeight.w300, color: palette.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Text('To', style: TextStyle(fontSize: 13, color: palette.textSecondary)),
          const SizedBox(height: 2),
          Text(pn, style: TextStyle(fontSize: 15, color: palette.textPrimary)),
          Text(pa, style: TextStyle(fontSize: 13, color: palette.textSecondary)),
        ],
      ),
    );
  }

  Widget _statusCard(String amount, ErrorType error, BankProfile? bank, Palette palette) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.inputPill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _detailsOpen = !_detailsOpen),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _iconScale,
                    child: Icon(Icons.error, size: 24, color: palette.error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment failed', style: TextStyle(fontSize: 15, color: palette.textPrimary)),
                        Text(_timestamp(_failedAt), style: TextStyle(fontSize: 13, color: palette.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(_detailsOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: palette.textPrimary),
                ],
              ),
            ),
          ),
          if (_detailsOpen) ...[
            Divider(height: 1, color: palette.inputPill),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹ $amount', style: TextStyle(fontSize: 24, color: palette.textPrimary)),
                  const SizedBox(height: 12),
                  // Neutral on purpose: a green tick is banned by AC-1.
                  _Step(
                    icon: Icon(Icons.check_circle_outline, size: 20, color: palette.textSecondary),
                    label: 'Payment started',
                    palette: palette,
                  ),
                  _Step(
                    icon: Icon(Icons.error_outline, size: 20, color: palette.error),
                    label: 'Payment processing by partner bank',
                    palette: palette,
                  ),
                  _Step(
                    icon: Icon(Icons.circle_outlined, size: 20, color: palette.textSecondary),
                    label: "Money deposited in recipient's bank",
                    palette: palette,
                    last: true,
                  ),
                  const SizedBox(height: 12),
                  Text('Error: ${receiptErrorLine(error)}',
                      style: TextStyle(fontSize: 14, height: 1.4, color: palette.textPrimary)),
                ],
              ),
            ),
          ],
          Divider(height: 1, color: palette.inputPill),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Party(
                  icon: Icons.account_balance,
                  leading: bank == null ? null : BankBadge(profile: bank, width: 40, height: 40, circular: true),
                  label: 'FROM',
                  title: bank?.bankName ?? 'Bank',
                  subtitle: '•••• ${bank?.accountLast4 ?? '0000'}',
                  palette: palette,
                ),
                const SizedBox(height: 12),
                _idRow('UPI transaction ID', _upiRef, palette),
                const SizedBox(height: 4),
                _idRow('Google transaction ID', _txnId, palette),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idRow(String label, String value, Palette palette) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
              Text(value, style: TextStyle(fontSize: 14, color: palette.textPrimary)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.copy_outlined, size: 18, color: palette.textSecondary),
          onPressed: () => _copy(value),
        ),
      ],
    );
  }

  String _timestamp(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return 'Today • $hour:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Step extends StatelessWidget {
  final Widget icon;
  final String label;
  final Palette palette;
  final bool last;

  const _Step({required this.icon, required this.label, required this.palette, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: palette.textPrimary))),
          ],
        ),
        if (!last)
          Padding(
            padding: const EdgeInsets.only(left: 9, top: 3, bottom: 3),
            child: Column(
              children: List.generate(
                4,
                (_) => Container(
                  width: 2,
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 1.5),
                  color: palette.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Party extends StatelessWidget {
  final IconData icon;
  final Widget? leading;
  final String label;
  final String title;
  final String subtitle;
  final Palette palette;

  const _Party({
    required this.icon,
    this.leading,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading ??
            CircleAvatar(radius: 20, backgroundColor: palette.inputPill, child: Icon(icon, size: 20, color: palette.accent)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, letterSpacing: 0.5, color: palette.textSecondary)),
              Text(title, style: TextStyle(fontSize: 16, color: palette.textPrimary)),
              Text(subtitle, style: TextStyle(fontSize: 13, color: palette.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
