import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';

class ProfessionalCadPainter extends CustomPainter {
  final ComponentCategory category;
  final Map<String, dynamic> data;
  final String subType;

  ProfessionalCadPainter({
    required this.category,
    required this.data,
    required this.subType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // قلم‌های مهندسی CAD
    final cadLine = Paint()
      ..color = const Color(0xFFF2F2F7)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final centerLine = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dimLine = Paint()
      ..color = const Color(0xFF0A84FF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final accentLine = Paint()
      ..color = const Color(0xFFFF9F0A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final weldLine = Paint()
      ..color = const Color(0xFF30D158)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (category) {
      case ComponentCategory.pipe:
        final schs = data['schedules'] as Map<String, dynamic>;
        final currentSch = schs[subType] ?? schs.values.first;
        final double od = (data['od'] as num).toDouble();
        final double thk = (currentSch['thk'] as num).toDouble();

        final double rOut = size.height * 0.40;
        final double rIn = rOut * (1.0 - (2.0 * thk / od)).clamp(0.25, 0.94);

        // مقطع دوبعدی لوله با هاشور واقعی دیواره
        canvas.drawCircle(center, rOut, cadLine);
        canvas.drawCircle(center, rIn, cadLine);

        final hatch = Path()
          ..addOval(Rect.fromCircle(center: center, radius: rOut))
          ..addOval(Rect.fromCircle(center: center, radius: rIn))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(hatch, Paint()..color = const Color(0x22FFFFFF));

        // خط آکس مهندسی
        _drawCenterLines(canvas, center, rOut + 15, centerLine);

        // خط اندازه OD و THK
        _drawDimensionLine(canvas, Offset(center.dx - rOut, center.dy), Offset(center.dx + rOut, center.dy), 'OD: ${od.toStringAsFixed(1)} mm', dimLine);
        _drawLeader(canvas, Offset(center.dx + (rOut + rIn) / 2, center.dy - 8), Offset(center.dx + rOut + 25, center.dy - 35), 't: ${thk} mm (Weld Bevel 37.5°)', accentLine);
        break;

      case ComponentCategory.flange:
        final classes = data['classes'] as Map<String, dynamic>;
        final flg = classes[subType] ?? classes.values.first;
        final double rFlange = size.height * 0.44;
        final double rPcd = rFlange * 0.72;
        final double rBore = rFlange * 0.38;

        canvas.drawCircle(center, rFlange, cadLine);
        canvas.drawCircle(center, rBore, cadLine);
        canvas.drawCircle(center, rPcd, Paint()..color = const Color(0x66FF9F0A)..strokeWidth = 1.0..style = PaintingStyle.stroke);

        final int boltCount = flg['bolts'] as int;
        for (int i = 0; i < boltCount; i++) {
          final double angle = (i * 2 * math.pi) / boltCount;
          final boltPos = Offset(center.dx + rPcd * math.cos(angle), center.dy + rPcd * math.sin(angle));
          canvas.drawCircle(boltPos, 5.0, Paint()..color = const Color(0xFF000000));
          canvas.drawCircle(boltPos, 5.0, cadLine);
          // سنتر پین سوراخ پیچ
          canvas.drawLine(Offset(boltPos.dx - 7, boltPos.dy), Offset(boltPos.dx + 7, boltPos.dy), centerLine);
          canvas.drawLine(Offset(boltPos.dx, boltPos.dy - 7), Offset(boltPos.dx, boltPos.dy + 7), centerLine);
        }
        _drawDimensionLine(canvas, Offset(center.dx - rPcd, center.dy), Offset(center.dx + rPcd, center.dy), 'PCD: ${flg['pcd']} mm', accentLine);
        _drawLeader(canvas, Offset(center.dx + rFlange * 0.8, center.dy - rFlange * 0.5), Offset(center.dx + rFlange + 15, center.dy - rFlange * 0.6), '${boltCount}x Holes (${flg['boltSize']})', dimLine);
        break;

      case ComponentCategory.buttWeld:
        final double cToE = ((data['lrElbow90'] ?? 76.0) as num).toDouble();
        final path = Path();
        path.moveTo(center.dx - 65, center.dy + 65);
        path.quadraticBezierTo(center.dx - 65, center.dy - 65, center.dx + 65, center.dy - 65);
        canvas.drawPath(path, cadLine);

        // خط مرکزی زانویی (Centerline)
        final clPath = Path();
        clPath.moveTo(center.dx - 45, center.dy + 65);
        clPath.quadraticBezierTo(center.dx - 45, center.dy - 45, center.dx + 65, center.dy - 45);
        canvas.drawPath(clPath, centerLine);

        // خطوط اندازه فاصله مرکز تا پخ (Center to End)
        _drawDimensionLine(canvas, Offset(center.dx - 45, center.dy + 65), Offset(center.dx - 45, center.dy - 45), 'C-to-E: ${cToE} mm', accentLine);
        _drawLeader(canvas, Offset(center.dx + 65, center.dy - 65), Offset(center.dx + 75, center.dy - 85), 'ASME B16.9 Bevel End (Root Face: 1.6mm)', weldLine);
        break;

      case ComponentCategory.socketWeld:
        final double bore = ((data['boreDia'] ?? 21.8) as num).toDouble();
        final double depth = ((data['depth'] ?? 9.5) as num).toDouble();

        canvas.drawRect(Rect.fromCenter(center: center, width: 140, height: 80), cadLine);
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 15, center.dy), width: 90, height: 50), dimLine);

        // نمایش دقیق گپ حرارتی ۱.۶ میلی‌متری (Fit-up Gap)
        canvas.drawRect(Rect.fromLTWH(center.dx + 30, center.dy - 25, 4, 50), Paint()..color = const Color(0xFF30D158));

        _drawLeader(canvas, Offset(center.dx + 32, center.dy), Offset(center.dx + 45, center.dy + 45), 'Mandatory Gap: 1.6 mm (1/16")', weldLine);
        _drawDimensionLine(canvas, Offset(center.dx - 60, center.dy + 25), Offset(center.dx + 30, center.dy + 25), 'Bore Depth: ${depth} mm', dimLine);
        break;

      case ComponentCategory.threaded:
        final int tpi = data['tpi'] as int;
        final path = Path();
        path.moveTo(center.dx - 65, center.dy - 20);
        for (double x = -65; x <= 65; x += 12) {
          path.lineTo(center.dx + x + 6, center.dy - 8);
          path.lineTo(center.dx + x + 12, center.dy - 20);
        }
        canvas.drawPath(path, accentLine);

        _drawDimensionLine(canvas, Offset(center.dx - 65, center.dy + 25), Offset(center.dx + 65, center.dy + 25), 'Effective Thread L2: ${data['minThreadL2']} mm', dimLine);
        _drawLeader(canvas, Offset(center.dx, center.dy - 15), Offset(center.dx, center.dy - 45), 'ASME B1.20.1 NPT Taper 1:16 ($tpi TPI)', accentLine);
        break;
    }
  }

  void _drawCenterLines(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), paint);
  }

  void _drawDimensionLine(Canvas canvas, Offset start, Offset end, String text, Paint paint) {
    canvas.drawLine(start, end, paint);
    // تیک‌های ابتدا و انتهای خط اندازه
    canvas.drawLine(Offset(start.dx, start.dy - 4), Offset(start.dx, start.dy + 4), paint);
    canvas.drawLine(Offset(end.dx, end.dy - 4), Offset(end.dx, end.dy + 4), paint);

    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    _renderText(canvas, text, Offset(mid.dx, mid.dy - 14), paint.color);
  }

  void _drawLeader(Canvas canvas, Offset start, Offset end, String text, Paint paint) {
    canvas.drawLine(start, end, paint);
    canvas.drawCircle(start, 2.5, paint);
    _renderText(canvas, text, Offset(end.dx, end.dy - 12), paint.color);
  }

  void _renderText(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - (tp.width / 2), pos.dy));
  }

  @override
  bool shouldRepaint(covariant ProfessionalCadPainter oldDelegate) => true;
}
