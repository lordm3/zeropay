class UpiData {
  final String pa;
  final String pn;
  final String mc;

  const UpiData({required this.pa, required this.pn, required this.mc});
}

class UpiParser {
  static const fallback = UpiData(
    pa: 'merchant.pay@okaxis',
    pn: 'Verified Merchant',
    mc: '',
  );

  static UpiData? parse(String rawValue) {
    if (!rawValue.startsWith('upi://pay')) return null;
    try {
      final uri = Uri.parse(rawValue);
      final pa = uri.queryParameters['pa'] ?? '';
      final pn = Uri.decodeComponent(uri.queryParameters['pn'] ?? '');
      final mc = uri.queryParameters['mc'] ?? '';
      if (pa.isEmpty) return null;
      return UpiData(pa: pa, pn: pn.isEmpty ? pa : pn, mc: mc);
    } catch (_) {
      return null;
    }
  }
}
