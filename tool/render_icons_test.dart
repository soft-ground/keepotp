// Renders the launcher icon masters into assets/icon/ and the store graphics
// into store/assets/.
//
// Run from the repository root:
//   flutter test tool/render_icons_test.dart
//
// Then generate the platform icon sets:
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _background = ui.Color(0xFF10304A);
const _accent = ui.Color(0xFF4FD1C5);
const _keyhole = ui.Color(0xFFFFFFFF);
const _muted = ui.Color(0xFFB8C7D6);

/// Draws the mark: a countdown ring (three quarters left, like a TOTP timer)
/// around a keyhole, centered on [center]. [scale] 1.0 is a ring of about
/// 554 units across (a 1024 unit canvas).
void _drawMark(ui.Canvas canvas, {required ui.Offset center, required double scale}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
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

Future<void> _save(String path, int width, int height, void Function(ui.Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  draw(canvas);
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void _fill(ui.Canvas canvas, double w, double h) =>
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h), ui.Paint()..color = _background);

/// Loads Roboto from the Flutter SDK so text renders with a real font in tests.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set');
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final f in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
    final bytes = File('$dir/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void _text(ui.Canvas canvas, String text, ui.Offset at,
    {required double size, required ui.Color color, FontWeight weight = FontWeight.w400}) {
  final painter = TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: 'Roboto', fontSize: size, color: color, fontWeight: weight)),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, at);
}

void main() {
  testWidgets('render launcher icon masters and store graphics', (tester) async {
    await tester.runAsync(() async {
      await _loadRoboto();

      // Full-bleed icon (iOS and legacy Android): the mark can be larger.
      await _save('assets/icon/icon.png', 1024, 1024, (c) {
        _fill(c, 1024, 1024);
        _drawMark(c, center: const ui.Offset(512, 512), scale: 1.15);
      });
      // Adaptive foreground (transparent): flutter_launcher_icons insets this layer
      // by 16%, which keeps the mark inside the safe zone.
      await _save('assets/icon/icon_foreground.png', 1024, 1024, (c) {
        _drawMark(c, center: const ui.Offset(512, 512), scale: 1.5);
      });

      // Google Play: 512 x 512 icon (Play rounds the corners itself).
      await _save('store/assets/play-icon-512.png', 512, 512, (c) {
        _fill(c, 512, 512);
        _drawMark(c, center: const ui.Offset(256, 256), scale: 0.575);
      });

      // Google Play: 1024 x 500 feature graphic.
      await _save('store/assets/feature-graphic.png', 1024, 500, (c) {
        _fill(c, 1024, 500);
        _drawMark(c, center: const ui.Offset(250, 250), scale: 0.62);
        _text(c, 'Keep OTP', const ui.Offset(500, 150),
            size: 92, color: _keyhole, weight: FontWeight.w700);
        _text(c, 'Your codes stay on your device.', const ui.Offset(504, 262),
            size: 32, color: _accent);
        _text(c, 'Free  ·  Open source  ·  No tracking', const ui.Offset(504, 312),
            size: 26, color: _muted);
      });
    });
  });
}
