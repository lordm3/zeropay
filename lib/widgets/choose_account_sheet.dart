import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/models/bank_profile.dart';
import '../core/providers/app_provider.dart';
import '../core/router/app_router.dart';
import '../core/theme/palette.dart';
import 'bank_badge.dart';
import 'timed_long_press.dart';

Future<void> showChooseAccountSheet(
  BuildContext context, {
  VoidCallback? onContinue,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChooseAccountSheet(
      onContinue: onContinue,
      onOpenStealth: () => context.push(AppRouter.stealth),
    ),
  );
}

class ChooseAccountSheet extends StatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback onOpenStealth;

  const ChooseAccountSheet({
    super.key,
    this.onContinue,
    required this.onOpenStealth,
  });

  @override
  State<ChooseAccountSheet> createState() => _ChooseAccountSheetState();
}

class _ChooseAccountSheetState extends State<ChooseAccountSheet> {
  String? _checkingId;
  String? _failedId;
  String? _addBankError;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selected = provider.session.selectedBank;
    final palette = Palette.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: palette.container,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.textSecondary.withAlpha(90),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Choose account to pay with',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: palette.textSecondary),
                          style: IconButton.styleFrom(
                            backgroundColor: palette.inputPill,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      'Instant payment via Unified Payments Interface (UPI)',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...provider.profiles.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AccountTile(
                          profile: p,
                          isSelected: selected?.id == p.id,
                          checking: _checkingId == p.id,
                          failed: _failedId == p.id,
                          onTap: () => provider.updateSession(
                            provider.session.copyWith(selectedBank: p),
                          ),
                          onCheckBalance: () => _checkBalance(p.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TimedLongPress(
                      duration: const Duration(seconds: 2),
                      onLongPress: () {
                        Navigator.pop(context);
                        widget.onOpenStealth();
                      },
                      child: Material(
                        color: palette.inputPill,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: palette.textSecondary.withAlpha(
                              50,
                            ),
                            child: Icon(Icons.add, color: palette.textPrimary),
                          ),
                          title: Text(
                            'Add bank account',
                            style: TextStyle(color: palette.textPrimary),
                          ),
                          subtitle: Text(
                            _addBankError ?? 'Link any UPI-enabled bank',
                            style: TextStyle(
                              fontSize: 12,
                              color: _addBankError == null
                                  ? palette.textSecondary
                                  : palette.error,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: palette.textSecondary,
                          ),
                          onTap: _addBank,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onContinue?.call();
                    },
                    child: Text(
                      'Continue with ${BankBadge.badgeLabel(selected.bankName)} •••• ${selected.accountLast4}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkBalance(String id) async {
    setState(() {
      _checkingId = id;
      _failedId = null;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _checkingId = null;
      _failedId = id;
    });
  }

  Future<void> _addBank() async {
    setState(() => _addBankError = null);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text('Finding accounts linked to your mobile number...'),
            ),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    navigator.pop();
    setState(() => _addBankError = 'Could not reach NPCI servers');
  }
}

class _AccountTile extends StatelessWidget {
  final BankProfile profile;
  final bool isSelected;
  final bool checking;
  final bool failed;
  final VoidCallback onTap;
  final VoidCallback onCheckBalance;

  const _AccountTile({
    required this.profile,
    required this.isSelected,
    required this.checking,
    required this.failed,
    required this.onTap,
    required this.onCheckBalance,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Material(
      color: isSelected ? palette.inputPill : palette.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BankBadge(
                    profile: profile,
                    width: 44,
                    height: 44,
                    circular: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.bankName} •••• ${profile.accountLast4}',
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.textPrimary,
                          ),
                        ),
                        Text(
                          profile.accountType,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? palette.accent : palette.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ActionChip(
                    label: Text(
                      checking ? 'Checking...' : 'Check balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textPrimary,
                      ),
                    ),
                    backgroundColor: palette.container,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: checking ? null : onCheckBalance,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profile.isPrimary ? 'Primary default' : 'UPI linked',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (failed)
                Text(
                  'Unable to fetch balance. Try again later',
                  style: TextStyle(fontSize: 12, color: palette.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
