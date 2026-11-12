// Renders the launcher icon masters into assets/icon/.
//
// Run from the repository root:
//   flutter test tool/render_icons_test.dart
//
// Then generate the platform icon sets:
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;
const _background = ui.Color(0xFF10304A);
const _accent = ui.Color(0xFF4FD1C5);
const _keyhole = ui.Color(0xFFFFFFFF);

/// Draws the mark: a countdown ring (three quarters left, like a TOTP timer)
/// around a keyhole. [scale] 1.0 is the base size.
void _drawMark(ui.Canvas canvas, {required double scale}) {
  canvas.save();
  canvas.translate(_size / 2, _size / 2);
  canvas.scale(scale);

  const radius = 250.0;
  const stroke = 54.0;
  final ring = ui.Rect.fromCircle(center: ui.Offset.zero, radius: radius);

  // Faint full track behind the remaining time.
  canvas.drawCircle(
    ui.Offset.zero,
    radius,
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = _accent.withValues(alpha: 0.22),
  );
  // Remaining time: 270 degrees, starting at 12 o'clock, clockwise.
  canvas.drawArc(
    ring,
    -math.pi / 2,
    math.pi * 1.5,
    false,
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = ui.StrokeCap.round
      ..color = _accent,
  );

  // Keyhole: a disc on top of a tapered slot.
  final keyhole = ui.Path()
    ..addOval(ui.Rect.fromCircle(center: const ui.Offset(0, -34), radius: 64))
    ..moveTo(-34, 6)
    ..lineTo(34, 6)
    ..lineTo(56, 112)
    ..lineTo(-56, 112)
    ..close();
  canvas.drawPath(keyhole, ui.Paint()..color = _keyhole);
  canvas.restore();
}

Future<void> _write(String path, {required bool withBackground, required double scale}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (withBackground) {
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, _size, _size), ui.Paint()..color = _background);
  }
  _drawMark(canvas, scale: scale);
  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render launcher icon masters', (tester) async {
    await tester.runAsync(() async {
      // Full-bleed icon (iOS and legacy Android): the mark can be larger.
      await _write('assets/icon/icon.png', withBackground: true, scale: 1.15);
      // Adaptive foreground (transparent): flutter_launcher_icons insets this layer by 16%, which keeps the mark inside the safe zone.
      await _write('assets/icon/icon_foreground.png', withBackground: false, scale: 1.5);
    });
  });
}
