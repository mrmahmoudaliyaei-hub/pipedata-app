import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';

class ComponentSchematicPainter extends CustomPainter {
  final ComponentCategory category;
  final ComponentRecord record;

  ComponentSchematicPainter({required this.category, required this.record});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintLine = Paint()
      ..color = const Color(0xFFE5E5EA)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintAccent = Paint()
      ..color = const Color(0xFFFF9F0A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintDim = Paint()
      ..color = const Color(0xFF0A84FF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    switch (category) {
      case ComponentCategory.pipe:
        final double rOut = size.height * 0.38;
        final double rIn = rOut * 0.76;
        canvas.drawCircle(center, rOut, paintLine);
        canvas.drawCircle(center, rIn, paintLine);
        
        final path = Path()
          ..addOval(Rect.fromCircle(center: center, radius: rOut))
          ..addOval(Rect.fromCircle(center: center, radius: rIn))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(path, Paint()..color = const Color(0x22FFFFFF));

        canvas.drawLine(Offset(center.dx - rOut, center.dy), Offset(center.dx + rOut, center.dy), paintDim);
        _drawText(canvas, 'OD: ${record.metrics['od']} mm', Offset(center.dx, center.dy - 16), const Color(0xFF0A84FF));
        break;

      case ComponentCategory.flange:
        final double rFlange = size.height * 0.42;
        final double rPcd = rFlange * 0.72;
        final double rBore = rFlange * 0.40;

        canvas.drawCircle(center, rFlange, paintLine);
        canvas.drawCircle(center, rBore, paintLine);
        canvas.drawCircle(center, rPcd, Paint()..color = const Color(0xFFFF9F0A)..strokeWidth = 1.0..style = PaintingStyle.stroke);

        final int boltCount = record.metrics['bolts'] as int? ?? 4;
        for (int i = 0; i < boltCount; i++) {
          final double angle = (i * 2 * math.pi) / boltCount;
          final boltPos = Offset(center.dx + rPcd * math.cos(angle), center.dy + rPcd * math.sin(angle));
          canvas.drawCircle(boltPos, 5.0, Paint()..color = const Color(0xFF000000));
          canvas.drawCircle(boltPos, 5.0, paintLine);
        }
        _drawText(canvas, 'PCD: ${record.metrics['pcd']} mm', Offset(center.dx, center.dy + rPcd + 8), const Color(0xFFFF9F0A));
        break;

      case ComponentCategory.buttWeld:
        final pathElbow = Path();
        pathElbow.moveTo(center.dx - 50, center.dy + 50);
        pathElbow.quadraticBezierTo(center.dx - 50, center.dy - 50, center.dx + 50, center.dy - 50);
        canvas.drawPath(pathElbow, paintLine);
        canvas.drawLine(Offset(center.dx - 50, center.dy + 50), Offset(center.dx - 50, center.dy - 50), paintAccent);
        canvas.drawLine(Offset(center.dx - 50, center.dy - 50), Offset(center.dx + 50, center.dy - 50), paintAccent);
        _drawText(canvas, 'Center-to-End: ${record.metrics['elbow90LR']} mm', Offset(center.dx, center.dy - 65), const Color(0xFFFF9F0A));
        break;

      case ComponentCategory.socketWeld:
        canvas.drawRect(Rect.fromCenter(center: center, width: 130, height: 80), paintLine);
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 10, center.dy), width: 90, height: 50), paintAccent);
        canvas.drawRect(Rect.fromLTWH(center.dx + 35, center.dy - 25, 4, 50), Paint()..color = const Color(0xFF30D158));
        _drawText(canvas, 'Fit-up Gap: 1.6 mm', Offset(center.dx, center.dy + 46), const Color(0xFF30D158));
        break;

      case ComponentCategory.threaded:
        final pathThread = Path();
        pathThread.moveTo(center.dx - 50, center.dy - 20);
        for (double x = -50; x <= 50; x += 10) {
          pathThread.lineTo(center.dx + x + 5, center.dy - 10);
          pathThread.lineTo(center.dx + x + 10, center.dy - 20);
        }
        canvas.drawPath(pathThread, paintAccent);
        _drawText(canvas, 'NPT 1:16 Taper (${record.metrics['tpi']} TPI)', Offset(center.dx, center.dy + 20), const Color(0xFFFF9F0A));
        break;
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(position.dx - (textPainter.width / 2), position.dy));
  }

  @override
  bool shouldRepaint(covariant ComponentSchematicPainter oldDelegate) => true;
}
