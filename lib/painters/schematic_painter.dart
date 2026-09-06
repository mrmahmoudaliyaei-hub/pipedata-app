import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';

class VectorBlueprintPainter extends CustomPainter {
  final ComponentCategory category;
  final Map<String, dynamic> data;
  final String subType;

  VectorBlueprintPainter({
    required this.category,
    required this.data,
    required this.subType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final lineOutline = Paint()
      ..color = const Color(0xFFF2F2F7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final lineCenter = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final lineDim = Paint()
      ..color = const Color(0xFF0A84FF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final lineAccent = Paint()
      ..color = const Color(0xFFFF9F0A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final lineWeld = Paint()
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
        final double rIn = rOut * (1.0 - (2.0 * thk / od)).clamp(0.20, 0.94);

        canvas.drawCircle(center, rOut, lineOutline);
        canvas.drawCircle(center, rIn, lineOutline);

        final hatch = Path()
          ..addOval(Rect.fromCircle(center: center, radius: rOut))
          ..addOval(Rect.fromCircle(center: center, radius: rIn))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(hatch, Paint()..color = const Color(0x22FFFFFF));

        _drawCrosshairs(canvas, center, rOut + 16, lineCenter);
        _drawDimension(canvas, Offset(center.dx - rOut, center.dy), Offset(center.dx + rOut, center.dy), 'OD: ${od.toStringAsFixed(1)} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx + (rOut + rIn) / 2, center.dy - 8), Offset(center.dx + rOut + 25, center.dy - 35), 't: ${thk} mm (Bevel 37.5°)', lineAccent);
        break;

      case ComponentCategory.flange:
        final classes = data['classes'] as Map<String, dynamic>;
        final flg = classes[subType] ?? classes.values.first;
        final double rFlange = size.height * 0.44;
        final double rPcd = rFlange * 0.72;
        final double rBore = rFlange * 0.38;

        canvas.drawCircle(center, rFlange, lineOutline);
        canvas.drawCircle(center, rBore, lineOutline);
        canvas.drawCircle(center, rPcd, Paint()..color = const Color(0x66FF9F0A)..strokeWidth = 1.0..style = PaintingStyle.stroke);

        final int boltCount = flg['bolts'] as int;
        for (int i = 0; i < boltCount; i++) {
          final double angle = (i * 2 * math.pi) / boltCount;
          final boltPos = Offset(center.dx + rPcd * math.cos(angle), center.dy + rPcd * math.sin(angle));
          canvas.drawCircle(boltPos, 5.0, Paint()..color = const Color(0xFF000000));
          canvas.drawCircle(boltPos, 5.0, lineOutline);
          canvas.drawLine(Offset(boltPos.dx - 7, boltPos.dy), Offset(boltPos.dx + 7, boltPos.dy), lineCenter);
          canvas.drawLine(Offset(boltPos.dx, boltPos.dy - 7), Offset(boltPos.dx, boltPos.dy + 7), lineCenter);
        }
        _drawDimension(canvas, Offset(center.dx - rPcd, center.dy), Offset(center.dx + rPcd, center.dy), 'PCD: ${flg['pcd']} mm', lineAccent);
        _drawLeader(canvas, Offset(center.dx + rFlange * 0.8, center.dy - rFlange * 0.5), Offset(center.dx + rFlange + 15, center.dy - rFlange * 0.6), '${boltCount}x Holes (${flg['boltSize']})', lineDim);
        break;

      case ComponentCategory.buttWeld:
        final double cToE = ((data['lrElbow90'] ?? 76.0) as num).toDouble();
        final path = Path();
        path.moveTo(center.dx - 65, center.dy + 65);
        path.quadraticBezierTo(center.dx - 65, center.dy - 65, center.dx + 65, center.dy - 65);
        canvas.drawPath(path, lineOutline);

        final clPath = Path();
        clPath.moveTo(center.dx - 45, center.dy + 65);
        clPath.quadraticBezierTo(center.dx - 45, center.dy - 45, center.dx + 65, center.dy - 45);
        canvas.drawPath(clPath, lineCenter);

        _drawDimension(canvas, Offset(center.dx - 45, center.dy + 65), Offset(center.dx - 45, center.dy - 45), 'C-to-E: ${cToE} mm', lineAccent);
        _drawLeader(canvas, Offset(center.dx + 65, center.dy - 65), Offset(center.dx + 75, center.dy - 85), 'ASME B16.9 Bevel (Root 1.6mm)', lineWeld);
        break;

      case ComponentCategory.socketWeld:
        final double depth = ((data['depth'] ?? 9.5) as num).toDouble();
        canvas.drawRect(Rect.fromCenter(center: center, width: 140, height: 80), lineOutline);
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 15, center.dy), width: 90, height: 50), lineDim);
        canvas.drawRect(Rect.fromLTWH(center.dx + 30, center.dy - 25, 4, 50), Paint()..color = const Color(0xFF30D158));

        _drawLeader(canvas, Offset(center.dx + 32, center.dy), Offset(center.dx + 45, center.dy + 45), 'Mandatory Gap: 1.6 mm', lineWeld);
        _drawDimension(canvas, Offset(center.dx - 60, center.dy + 25), Offset(center.dx + 30, center.dy + 25), 'Bore Depth: ${depth} mm', lineDim);
        break;

      case ComponentCategory.threaded:
        final int tpi = data['tpi'] as int;
        final path = Path();
        path.moveTo(center.dx - 65, center.dy - 20);
        for (double x = -65; x <= 65; x += 12) {
          path.lineTo(center.dx + x + 6, center.dy - 8);
          path.lineTo(center.dx + x + 12, center.dy - 20);
        }
        canvas.drawPath(path, lineAccent);
        _drawDimension(canvas, Offset(center.dx - 65, center.dy + 25), Offset(center.dx + 65, center.dy + 25), 'Effective Thread L2: ${data['minThreadL2']} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx, center.dy - 15), Offset(center.dx, center.dy - 45), 'NPT 1:16 Taper ($tpi TPI)', lineAccent);
        break;

      case ComponentCategory.reducer:
        final lengths = data['lengths'] as Map<String, dynamic>;
        final double lenMm = ((lengths[subType] ?? lengths.values.first) as num).toDouble();
        final bool eccentric = subType == 'Eccentric';
        final double halfLen = 60.0;
        final double rLarge = 46.0;
        final double rSmall = 22.0;

        final Path body;
        if (eccentric) {
          // Flat on the bottom (common orientation to keep a level pipe run), taper on top only.
          body = Path()
            ..moveTo(center.dx - halfLen, center.dy - rLarge)
            ..lineTo(center.dx + halfLen, center.dy - rSmall)
            ..lineTo(center.dx + halfLen, center.dy + rSmall)
            ..lineTo(center.dx - halfLen, center.dy + rLarge)
            ..close();
          canvas.drawLine(Offset(center.dx - halfLen, center.dy + rLarge), Offset(center.dx + halfLen, center.dy + rSmall), lineCenter);
        } else {
          body = Path()
            ..moveTo(center.dx - halfLen, center.dy - rLarge)
            ..lineTo(center.dx + halfLen, center.dy - rSmall)
            ..lineTo(center.dx + halfLen, center.dy + rSmall)
            ..lineTo(center.dx - halfLen, center.dy + rLarge)
            ..close();
        }
        canvas.drawPath(body, lineOutline);
        canvas.drawLine(Offset(center.dx - halfLen - 14, center.dy), Offset(center.dx + halfLen + 14, center.dy), lineCenter);
        // End flange ticks
        canvas.drawLine(Offset(center.dx - halfLen, center.dy - rLarge), Offset(center.dx - halfLen, center.dy + rLarge), lineOutline);
        canvas.drawLine(Offset(center.dx + halfLen, center.dy - rSmall), Offset(center.dx + halfLen, center.dy + rSmall), lineOutline);

        _drawDimension(canvas, Offset(center.dx - halfLen, center.dy - rLarge - 16), Offset(center.dx + halfLen, center.dy - rLarge - 16), 'H: ${lenMm.toStringAsFixed(0)} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx - halfLen, center.dy - rLarge * 0.4), Offset(center.dx - halfLen - 30, center.dy - rLarge - 10), 'Large End', lineAccent);
        _drawLeader(canvas, Offset(center.dx + halfLen, center.dy - rSmall * 0.4), Offset(center.dx + halfLen + 20, center.dy - rSmall - 24), 'Small End', lineWeld);
        break;

      case ComponentCategory.gasket:
        final classes = data['classes'] as Map<String, dynamic>;
        final gk = classes[subType] ?? classes.values.first;
        final double gOd = (gk['od'] as num).toDouble();
        final double gId = (gk['id'] as num).toDouble();

        final double rOut = size.height * 0.40;
        final double rIn = rOut * (gId / gOd).clamp(0.15, 0.92);

        canvas.drawCircle(center, rOut, lineOutline);
        canvas.drawCircle(center, rIn, lineOutline);

        // Spiral winding hint: a few concentric dashed-look rings between ID and OD.
        for (int i = 1; i <= 3; i++) {
          final double r = rIn + (rOut - rIn) * (i / 4.0);
          canvas.drawCircle(center, r, Paint()..color = const Color(0x40FF9F0A)..strokeWidth = 0.8..style = PaintingStyle.stroke);
        }

        _drawCrosshairs(canvas, center, rIn * 0.6, lineCenter);
        _drawDimension(canvas, Offset(center.dx - rOut, center.dy), Offset(center.dx + rOut, center.dy), 'OD: ${gOd.toStringAsFixed(1)} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx, center.dy - rIn), Offset(center.dx - 45, center.dy - rIn - 24), 'ID: ${gId.toStringAsFixed(1)} mm', lineAccent);
        _drawLeader(canvas, Offset(center.dx + rIn * 0.7, center.dy + rIn * 0.7), Offset(center.dx + rOut + 15, center.dy + rOut * 0.5), 'Spiral-Wound (316L/Graphite)', lineWeld);
        break;

      case ComponentCategory.valve:
        final classes = data['classes'] as Map<String, dynamic>;
        final vv = classes[subType] ?? classes.values.first;
        final double ftf = (vv['gateFtf'] as num).toDouble();

        final double halfLen = 55.0;
        final double bodyH = 46.0;
        final double flangeH = 64.0;

        // Body (lens/oval-ish valve body)
        final bodyPath = Path()
          ..moveTo(center.dx - halfLen + 10, center.dy - bodyH / 2)
          ..quadraticBezierTo(center.dx, center.dy - bodyH / 2 - 10, center.dx + halfLen - 10, center.dy - bodyH / 2)
          ..lineTo(center.dx + halfLen - 10, center.dy + bodyH / 2)
          ..quadraticBezierTo(center.dx, center.dy + bodyH / 2 + 10, center.dx - halfLen + 10, center.dy + bodyH / 2)
          ..close();
        canvas.drawPath(bodyPath, lineOutline);

        // Flanged ends
        canvas.drawLine(Offset(center.dx - halfLen, center.dy - flangeH / 2), Offset(center.dx - halfLen, center.dy + flangeH / 2), lineOutline);
        canvas.drawLine(Offset(center.dx + halfLen, center.dy - flangeH / 2), Offset(center.dx + halfLen, center.dy + flangeH / 2), lineOutline);
        canvas.drawLine(Offset(center.dx - halfLen - 6, center.dy - flangeH / 2), Offset(center.dx - halfLen - 6, center.dy + flangeH / 2), lineDim);
        canvas.drawLine(Offset(center.dx + halfLen + 6, center.dy - flangeH / 2), Offset(center.dx + halfLen + 6, center.dy + flangeH / 2), lineDim);

        // Stem + handwheel indicator
        canvas.drawLine(Offset(center.dx, center.dy - bodyH / 2 - 8), Offset(center.dx, center.dy - bodyH / 2 - 30), lineWeld);
        canvas.drawCircle(Offset(center.dx, center.dy - bodyH / 2 - 38), 8.0, lineWeld);

        canvas.drawLine(Offset(center.dx - halfLen - 6, center.dy), Offset(center.dx + halfLen + 6, center.dy), lineCenter);

        _drawDimension(canvas, Offset(center.dx - halfLen - 6, center.dy + flangeH / 2 + 16), Offset(center.dx + halfLen + 6, center.dy + flangeH / 2 + 16), 'FtF (Gate): ${ftf.toStringAsFixed(0)} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx, center.dy - bodyH / 2 - 46), Offset(center.dx + 20, center.dy - bodyH / 2 - 70), 'ASME B16.10', lineAccent);
        break;
    }
  }

  void _drawCrosshairs(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), paint);
  }

  void _drawDimension(Canvas canvas, Offset start, Offset end, String text, Paint paint) {
    canvas.drawLine(start, end, paint);
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
  bool shouldRepaint(covariant VectorBlueprintPainter oldDelegate) => true;
}
