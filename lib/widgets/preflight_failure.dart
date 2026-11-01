import 'package:flutter/material.dart';
import '../core/models/bank_profile.dart';
import '../core/theme/palette.dart';
import '../core/utils/error_content.dart';
import 'bank_badge.dart';

const _refundTitleHi = 'पैसे वापस कर दिए जाएंगे';
const _refundBodyHi =
    'पाने वाले का बैंक इस बैंक खाते में भुगतान की अनुमति नहीं देता। अगर पैसे कट गए हैं, तो वे अगले 3 दिनों में वापस कर दिए जाएंगे।';

class PreflightFailure extends StatefulWidget {
  final BankProfile? bank;
  final ErrorType error;
  final VoidCallback onChangeBank;
  final VoidCallback onDismiss;

  const PreflightFailure({
    super.key,
    required this.bank,
    required this.error,
    required this.onChangeBank,
    required this.onDismiss,
  });

  @override
  State<PreflightFailure> createState() => _PreflightFailureState();
}

class _PreflightFailureState extends State<PreflightFailure> {
  bool _hindi = false;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final bank = widget.bank;
    final isRefund = widget.error == ErrorType.paymentNotAllowed;
    final content = preflightContentFor(widget.error);
    final cardColor = palette.isDark ? const Color(0xFF8C1D18) : const Color(0xFFF9DEDC);
    final cardText = palette.isDark ? const Color(0xFFF9DEDC) : const Color(0xFF410E0B);
    final bankDown = widget.error == ErrorType.serverUnavailable;

    return Container(
      decoration: BoxDecoration(
        color: palette.container,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose account to pay with', style: TextStyle(fontSize: 16, color: palette.textPrimary)),
          const SizedBox(height: 12),
          if (bank != null)
            InkWell(
              onTap: widget.onChangeBank,
              child: Row(
                children: [
                  BankBadge(profile: bank),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${bank.bankName} ••••${bank.accountLast4}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, color: palette.textPrimary)),
                        Text(bankDown ? 'Temporarily Unavailable' : bank.accountType,
                            style: TextStyle(fontSize: 13, color: bankDown ? palette.error : palette.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: palette.textSecondary),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: cardText),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_hindi ? _refundTitleHi : content.title,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cardText)),
                      const SizedBox(height: 6),
                      Text(_hindi ? _refundBodyHi : content.body,
                          style: TextStyle(fontSize: 14, height: 1.3, color: cardText.withAlpha(215))),
                      if (isRefund) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _LanguageToggle(
                            hindi: _hindi,
                            color: cardColor,
                            textColor: cardText,
                            onChanged: (v) => setState(() => _hindi = v),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                foregroundColor: palette.accent,
                side: BorderSide(color: palette.textSecondary),
              ),
              onPressed: widget.onDismiss,
              child: const Text('Dismiss'),
            ),
          ),
          const SizedBox(height: 12),
          Text('Powered by UPI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: palette.textSecondary)),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final bool hindi;
  final Color color;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  const _LanguageToggle({
    required this.hindi,
    required this.color,
    required this.textColor,
    required this.onChanged,
  });

  Widget _option(String label, bool value) {
    final selected = value == hindi;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: selected ? ShapeDecoration(color: color, shape: const StadiumBorder()) : null,
        child: Text(label, style: TextStyle(fontSize: 13, color: textColor)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const ShapeDecoration(color: Colors.black38, shape: StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_option('English', false), _option('हिन्दी', true)],
      ),
    );
  }
}
