import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';

class SchematicPainter extends CustomPainter {
  final ComponentCategory category;
  final ComponentMetric metric;
  final String subTypeKey;

  SchematicPainter({
    required this.category,
    required this.metric,
    required this.subTypeKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final borderPaint = Paint()
      ..color = const Color(0xFFF2F2F7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dimPaint = Paint()
      ..color = const Color(0xFF0A84FF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final centerLinePaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    switch (category) {
      case ComponentCategory.pipe:
        final schedules = metric.data['schedules'] as Map<String, dynamic>;
        final sch = schedules[subTypeKey] ?? schedules.values.first;
        final double thk = (sch['thk'] as num).toDouble();
        final double od = metric.od;

        final double rOut = (size.height * 0.40);
        final double rIn = rOut * (1 - (2 * thk / od)).clamp(0.2, 0.95);

        // مقطع لوله
        canvas.drawCircle(center, rOut, borderPaint);
        canvas.drawCircle(center, rIn, borderPaint);

        // هاشور ضخامت جداره لوله
        final hatchPath = Path()
          ..addOval(Rect.fromCircle(center: center, radius: rOut))
          ..addOval(Rect.fromCircle(center: center, radius: rIn))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(hatchPath, Paint()..color = const Color(0x1FFFFFFF));

        // خط اندازه OD
        canvas.drawLine(Offset(center.dx - rOut, center.dy), Offset(center.dx + rOut, center.dy), dimPaint);
        _renderLabel(canvas, 'OD: ${metric.od} mm', Offset(center.dx, center.dy - 16), const Color(0xFF0A84FF));
        _renderLabel(canvas, 'THK: $thk mm', Offset(center.dx, center.dy + 8), const Color(0xFF30D158));
        break;

      case ComponentCategory.flange:
        final classes = metric.data['classes'] as Map<String, dynamic>;
        final flg = classes[subTypeKey] ?? classes.values.first;
        final double rFlange = size.height * 0.44;
        final double rPcd = rFlange * 0.72;
        final double rBore = rFlange * 0.38;

        canvas.drawCircle(center, rFlange, borderPaint);
        canvas.drawCircle(center, rBore, borderPaint);
        canvas.drawCircle(center, rPcd, Paint()..color = const Color(0xFFFF9F0A)..strokeWidth = 1.0..style = PaintingStyle.stroke);

        final int bolts = flg['bolts'] as int;
        for (int i = 0; i < bolts; i++) {
          final double angle = (i * 2 * math.pi) / bolts;
          final boltCenter = Offset(center.dx + rPcd * math.cos(angle), center.dy + rPcd * math.sin(angle));
          canvas.drawCircle(boltCenter, 5.0, Paint()..color = const Color(0xFF000000));
          canvas.drawCircle(boltCenter, 5.0, borderPaint);
        }
        _renderLabel(canvas, 'PCD: ${flg['pcd']} mm (${bolts}x ${flg['boltDia']})', Offset(center.dx, center.dy + rPcd + 8), const Color(0xFFFF9F0A));
        break;

      case ComponentCategory.buttWeld:
        final double cToE = ((metric.data['elbow90LR'] ?? 76) as num).toDouble();
        final path = Path();
        path.moveTo(center.dx - 60, center.dy + 60);
        path.quadraticBezierTo(center.dx - 60, center.dy - 60, center.dx + 60, center.dy - 60);
        canvas.drawPath(path, borderPaint);

        canvas.drawLine(Offset(center.dx - 60, center.dy + 60), Offset(center.dx - 60, center.dy - 60), centerLinePaint);
        canvas.drawLine(Offset(center.dx - 60, center.dy - 60), Offset(center.dx + 60, center.dy - 60), centerLinePaint);

        _renderLabel(canvas, '90° LR Center-to-End: $cToE mm', Offset(center.dx, center.dy - 75), const Color(0xFFFF9F0A));
        break;

      case ComponentCategory.socketWeld:
        final double bore = ((metric.data['bore'] ?? 21.8) as num).toDouble();
        final double depth = ((metric.data['depth'] ?? 9.5) as num).toDouble();

        canvas.drawRect(Rect.fromCenter(center: center, width: 140, height: 80), borderPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 12, center.dy), width: 90, height: 50), dimPaint);
        canvas.drawRect(Rect.fromLTWH(center.dx + 33, center.dy - 25, 4, 50), Paint()..color = const Color(0xFF30D158));

        _renderLabel(canvas, 'Socket Bore: $bore mm | Depth: $depth mm', Offset(center.dx, center.dy - 55), const Color(0xFF0A84FF));
        _renderLabel(canvas, 'Fit-up Expansion Gap: 1.6 mm', Offset(center.dx, center.dy + 50), const Color(0xFF30D158));
        break;

      case ComponentCategory.threaded:
        final int tpi = metric.data['tpi'] as int;
        final pathThread = Path();
        pathThread.moveTo(center.dx - 60, center.dy - 20);
        for (double x = -60; x <= 60; x += 12) {
          pathThread.lineTo(center.dx + x + 6, center.dy - 8);
          pathThread.lineTo(center.dx + x + 12, center.dy - 20);
        }
        canvas.drawPath(pathThread, Paint()..color = const Color(0xFFFF9F0A)..strokeWidth = 2.0..style = PaintingStyle.stroke);
        _renderLabel(canvas, 'NPT 1:16 Taper ($tpi TPI)', Offset(center.dx, center.dy + 25), const Color(0xFFFF9F0A));
        break;
    }
  }

  void _renderLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: -0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - (tp.width / 2), pos.dy));
  }

  @override
  bool shouldRepaint(covariant SchematicPainter oldDelegate) => true;
}
