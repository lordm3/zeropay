import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../../core/providers/app_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/upi_parser.dart';
import '../../widgets/timed_long_press.dart';

const _cutoutSize = 260.0;
const _frameSize = 284.0;

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController();
  late final AnimationController _anim;
  bool _scanned = false;
  bool _torchOn = false;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    _proceed(capture.barcodes.firstOrNull?.rawValue ?? '');
  }

  Future<void> _proceed(String raw) async {
    if (_scanned) return;
    _scanned = true;
    final parsed = UpiParser.parse(raw) ?? UpiParser.fallback;
    final provider = context.read<AppProvider>();
    provider.updateSession(
      provider.session.copyWith(parsedUpiId: parsed.pa, parsedPayeeName: parsed.pn, merchantCode: parsed.mc),
    );
    setState(() => _zoom = 1.15);
    Vibration.vibrate(duration: 20);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) context.pushReplacement(AppRouter.amount, extra: true);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cutoutTop = MediaQuery.paddingOf(context).top + 84;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRouter.home);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedScale(
                scale: _zoom,
                duration: const Duration(milliseconds: 150),
                child: MobileScanner(controller: _controller, onDetect: _handleBarcode),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _ScrimPainter(cutoutTop))),
            Positioned(
              top: cutoutTop - (_frameSize - _cutoutSize) / 2,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () => _proceed(''),
                  child: SizedBox(
                    width: _frameSize,
                    height: _frameSize,
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (_, _) => CustomPaint(painter: _FramePainter(_anim.value)),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _TopIcon(icon: Icons.close, onPressed: _close),
                    const Spacer(),
                    TimedLongPress(
                      duration: const Duration(seconds: 3),
                      onLongPress: () => context.push(AppRouter.stealth),
                      child: _TopIcon(
                        icon: _torchOn ? Icons.flashlight_on_outlined : Icons.flashlight_off_outlined,
                        onPressed: () {
                          _controller.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                      ),
                    ),
                    const _TopIcon(icon: Icons.qr_code_2),
                    const _TopIcon(icon: Icons.more_vert),
                  ],
                ),
              ),
            ),
            Positioned(
              top: cutoutTop + _cutoutSize + 32,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('Unable to load gallery media'))),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFECECEC),
                    foregroundColor: const Color(0xFF1F1F1F),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Upload from gallery', style: TextStyle(fontSize: 15)),
                ),
              ),
            ),
            const Align(alignment: Alignment.bottomCenter, child: _ScanDock()),
          ],
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _TopIcon({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onPressed,
      radius: 24,
      child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 24)),
    );
  }
}

class _ScanDock extends StatelessWidget {
  const _ScanDock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF303030),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 3,
                decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              const Text('Scan any QR code to pay', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 6),
              const Text('All UPI apps accepted', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final double cutoutTop;
  const _ScrimPainter(this.cutoutTop);

  @override
  void paint(Canvas canvas, Size size) {
    final left = (size.width - _cutoutSize) / 2;
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, cutoutTop, _cutoutSize, _cutoutSize), const Radius.circular(24)),
      );
    canvas.drawPath(path, Paint()..color = const Color(0x99000000));
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.cutoutTop != cutoutTop;
}

class _FramePainter extends CustomPainter {
  final double t;
  const _FramePainter(this.t);

  static const _colors = [Color(0xFFEA4335), Color(0xFFFBBC04), Color(0xFF34A853), Color(0xFF4285F4)];

  Color _colorAt(int corner) {
    final position = (t * _colors.length + corner) % _colors.length;
    final index = position.floor();
    return Color.lerp(_colors[index], _colors[(index + 1) % _colors.length], position - index)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const r = 28.0;
    const arm = 16.0;
    final w = size.width;
    final h = size.height;
    Paint stroke(int corner) => Paint()
      ..color = _colorAt(corner)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(0, r + arm)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(r + arm, 0),
      stroke(0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - r - arm, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, r + arm),
      stroke(1),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, h - r - arm)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
        ..lineTo(w - r - arm, h),
      stroke(2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(r + arm, h)
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
        ..lineTo(0, h - r - arm),
      stroke(3),
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.t != t;
}
