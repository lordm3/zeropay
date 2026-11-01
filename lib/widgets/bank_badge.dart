import 'package:flutter/material.dart';
import '../core/models/bank_catalog.dart';
import '../core/models/bank_profile.dart';

class BankBadge extends StatelessWidget {
  final BankProfile profile;
  final double width;
  final double height;
  final bool circular;

  const BankBadge({
    super.key,
    required this.profile,
    this.width = 36,
    this.height = 24,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final entry = BankCatalog.find(profile.bankName);
    return BankBadgeView(
      bankName: profile.bankName,
      logoAsset: entry?.assetPath,
      color: parseHexColor(profile.badgeColorHex) ?? const Color(0xFF444746),
      width: width,
      height: height,
      circular: circular,
    );
  }

  static String badgeLabel(String bankName) {
    final words = bankName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    final significant = words.where((w) => w.toLowerCase() != 'bank').toList();
    if (significant.length == 1) {
      final word = significant.first.toUpperCase();
      return word.length > 5 ? word.substring(0, 5) : word;
    }
    return words
        .where((w) => w.toLowerCase() != 'of')
        .map((w) => w[0].toUpperCase())
        .take(4)
        .join();
  }
}

/// Null unless [hex] is exactly six hex digits, with or without a leading #.
Color? parseHexColor(String hex) {
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(hex.trim());
  if (match == null) return null;
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

class BankBadgeView extends StatelessWidget {
  final String bankName;
  final String? logoAsset;
  final Color color;
  final double width;
  final double height;
  final bool circular;

  const BankBadgeView({
    super.key,
    required this.bankName,
    required this.logoAsset,
    required this.color,
    this.width = 36,
    this.height = 24,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = logoAsset;
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(logo == null ? 2 : height * 0.14),
      decoration: BoxDecoration(
        color: logo == null ? color : Colors.white,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(6),
      ),
      child: logo == null
          ? _label()
          : Image.asset(logo, fit: BoxFit.contain, errorBuilder: (_, _, _) => _label(onWhite: true)),
    );
  }

  Widget _label({bool onWhite = false}) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          BankBadge.badgeLabel(bankName),
          style: TextStyle(color: onWhite ? color : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
