import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class TimedLongPress extends StatelessWidget {
  final Duration duration;
  final VoidCallback onLongPress;
  final Widget child;

  const TimedLongPress({
    super.key,
    required this.duration,
    required this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: duration),
          (recognizer) => recognizer.onLongPress = onLongPress,
        ),
      },
      child: child,
    );
  }
}
