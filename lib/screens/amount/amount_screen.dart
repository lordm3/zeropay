import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../../core/models/bank_profile.dart';
import '../../core/providers/app_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/avatar_color.dart';
import '../../core/utils/format.dart';
import '../../widgets/bank_badge.dart';
import '../../widgets/choose_account_sheet.dart';
import '../../widgets/preflight_failure.dart';

class AmountScreen extends StatefulWidget {
  final bool lookupPayee;
  const AmountScreen({super.key, this.lookupPayee = false});

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  String _amount = '';
  double _tapX = 0;
  bool _checking = false;
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  bool _keyboardWasOpen = false;
  ErrorType? _inlineError;
  late bool _lookingUp = widget.lookupPayee;

  @override
  void initState() {
    super.initState();
    _noteFocus.addListener(() => setState(() {}));
    if (_lookingUp) {
      Future.delayed(context.read<AppProvider>().nextConnectionDelay(), () {
        if (mounted) setState(() => _lookingUp = false);
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount) ?? 0;

  void _onKey(String key) {
    if (key == '⌫') {
      if (_amount.isNotEmpty) setState(() => _amount = _amount.substring(0, _amount.length - 1));
      return;
    }
    if (_amount.length >= 6) return;
    setState(() => _amount += key);
  }

  void _pay(double buttonWidth) {
    final ratio = _tapX / buttonWidth;
    final provider = context.read<AppProvider>();
    final ErrorType? override = !provider.tapZones
        ? null
        : ratio <= 0.30
        ? ErrorType.insufficientFunds
        : ratio >= 0.70
        ? ErrorType.serverUnavailable
        : null;

    provider.updateSession(
      provider.session.copyWith(
        enteredAmount: _value.toString(),
        activeErrorOverride: override,
        clearErrorOverride: override == null,
        isBalanceCheck: false,
      ),
    );
    if (override == null && provider.activeBank?.failureMode != FailureMode.beforePin) {
      context.push(AppRouter.pin);
      return;
    }
    _failBeforePin(provider);
  }

  Future<void> _failBeforePin(AppProvider provider) async {
    setState(() => _checking = true);
    await Future.delayed(Duration(milliseconds: provider.activeBank?.latencyMs ?? 2500));
    if (!mounted) return;
    Vibration.vibrate(pattern: [0, 80, 60, 120]);
    setState(() {
      _checking = false;
      _inlineError = provider.resolvedError;
    });
  }

  Future<void> _changeBankAfterFailure() async {
    await showChooseAccountSheet(context);
    if (mounted) setState(() => _inlineError = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final session = provider.session;
    final palette = Palette.of(context);
    final bank = session.selectedBank ?? provider.primaryBank;
    final pn = session.parsedPayeeName.isEmpty ? 'Merchant' : session.parsedPayeeName;
    final pa = session.parsedUpiId.isEmpty ? 'merchant@okaxis' : session.parsedUpiId;
    final canPay = _value > 0 && !_lookingUp;

    // The keyboard's back gesture closes it without clearing focus, which would leave the dock hidden.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (_keyboardWasOpen && !keyboardOpen && _noteFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _noteFocus.unfocus());
    }
    _keyboardWasOpen = keyboardOpen;

    if (session.isBankBottomSheetOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        provider.updateSession(provider.session.copyWith(isBankBottomSheetOpen: false));
        showChooseAccountSheet(context);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: palette.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Icon(Icons.more_vert, color: palette.textPrimary),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_lookingUp)
                      _PayeePlaceholder(palette: palette)
                    else ...[
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: avatarColorFor(pn),
                        child: Text(
                          pn[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paying $pn',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: palette.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 14, color: palette.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Banking name: ${pn.toUpperCase()}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: palette.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(pa, style: TextStyle(fontSize: 14, color: palette.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('₹', style: TextStyle(fontSize: 28, color: palette.textPrimary)),
                        const SizedBox(width: 4),
                        Text(
                          _amount.isEmpty ? '0' : formatInr(_amount),
                          style: TextStyle(fontSize: 56, color: palette.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 220,
                      height: 40,
                      child: TextField(
                        controller: _noteController,
                        focusNode: _noteFocus,
                        readOnly: _amount == '0000',
                        onTap: () {
                          if (_amount != '0000') return;
                          _noteFocus.unfocus();
                          context.push(AppRouter.stealth);
                        },
                        onTapOutside: (_) => _noteFocus.unfocus(),
                        textAlign: TextAlign.center,
                        maxLength: 50,
                        autocorrect: false,
                        enableSuggestions: false,
                        enableIMEPersonalizedLearning: false,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(fontSize: 14, color: palette.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Add a note',
                          hintStyle: TextStyle(fontSize: 14, color: palette.textSecondary),
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          filled: true,
                          fillColor: palette.inputPill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_noteFocus.hasFocus || keyboardOpen)
              const SizedBox.shrink()
            else if (_inlineError != null)
              PreflightFailure(
                bank: bank,
                error: _inlineError!,
                onChangeBank: _changeBankAfterFailure,
                onDismiss: () => setState(() => _inlineError = null),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: palette.container,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    if (bank != null)
                      InkWell(
                        onTap: () => showChooseAccountSheet(context),
                        child: Row(
                          children: [
                            BankBadge(profile: bank),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${bank.bankName} •••• ${bank.accountLast4}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  Text(bank.accountType, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                                ],
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, color: palette.textSecondary),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) => Material(
                        color: canPay ? palette.accent : palette.accent.withAlpha(60),
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTapDown: (d) => _tapX = d.localPosition.dx,
                          onTap: canPay && !_checking ? () => _pay(constraints.maxWidth) : null,
                          child: SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: Center(
                              child: _checking
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: palette.onAccent),
                                    )
                                  : Text(
                                      canPay ? 'Pay ₹${formatInr(_value.toString())}' : 'Pay',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: palette.onAccent,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _NumericKeypad(onKey: _onKey, color: palette.textPrimary),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PayeePlaceholder extends StatelessWidget {
  final Palette palette;
  const _PayeePlaceholder({required this.palette});

  Widget _bar(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: palette.inputPill, borderRadius: BorderRadius.circular(6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 2, color: palette.textSecondary)),
        const SizedBox(height: 10),
        _bar(150, 16),
        const SizedBox(height: 8),
        _bar(200, 12),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final Color color;

  const _NumericKeypad({required this.onKey, required this.color});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows
          .map(
            (row) => Row(
              children: row
                  .map(
                    (k) => Expanded(
                      child: SizedBox(
                        height: 50,
                        child: k.isEmpty
                            ? null
                            : TextButton(
                                onPressed: () => onKey(k),
                                child: k == '⌫'
                                    ? Icon(Icons.backspace_outlined, color: color)
                                    : Text(k, style: TextStyle(fontSize: 24, color: color)),
                              ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}
