import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import '../core/models.dart';

/// Renders a CAD-style cross-section/elevation schematic for a component.
///
/// Every shape is drawn as a filled, shaded body (a light-to-dark metal
/// gradient tinted with [accentColor]) with a bold outline on top, the way a
/// real mechanical/piping drawing reads solid components rather than pure
/// wireframe — plus dimension lines, leaders and (for valves) the standard
/// P&ID body symbol for the selected valve type.
class VectorBlueprintPainter extends CustomPainter {
  final ComponentCategory category;
  final Map<String, dynamic> data;
  final String subType;
  final Color accentColor;
  final String valveType;

  VectorBlueprintPainter({
    required this.category,
    required this.data,
    required this.subType,
    this.accentColor = const Color(0xFF0A84FF),
    this.valveType = 'Gate Valve',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final lineOutline = Paint()
      ..color = const Color(0xFFF2F2F7)
      ..strokeWidth = 2.75
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final lineCenter = Paint()
      ..color = const Color(0x77FFFFFF)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final lineDim = Paint()
      ..color = const Color(0xFF0A84FF)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final lineAccent = Paint()
      ..color = const Color(0xFFFF9F0A)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final lineWeld = Paint()
      ..color = const Color(0xFF30D158)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final linePipeline = Paint()
      ..color = const Color(0xFFFF453A)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Shared "solid metal" body fill: a light-to-dark gradient tinted by the
    // category's accent color, so every body reads as a shaded solid rather
    // than a hollow line-drawing.
    Paint bodyFill(Rect bounds, {double lightness = 0.30}) {
      return Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF48484C), accentColor, lightness)!,
            const Color(0xFF201F22),
          ],
        ).createShader(bounds)
        ..style = PaintingStyle.fill;
    }

    switch (category) {
      case ComponentCategory.pipe:
      case ComponentCategory.pipelineTransport:
        final schs = data['schedules'] as Map<String, dynamic>;
        final currentSch = schs[subType] ?? schs.values.first;
        final double od = (data['od'] as num).toDouble();
        final double thk = (currentSch['thk'] as num).toDouble();
        final accent = category == ComponentCategory.pipelineTransport ? linePipeline : lineAccent;

        final double rOut = size.height * 0.40;
        final double rIn = rOut * (1.0 - (2.0 * thk / od)).clamp(0.20, 0.94);

        final wallRing = Path()
          ..addOval(Rect.fromCircle(center: center, radius: rOut))
          ..addOval(Rect.fromCircle(center: center, radius: rIn))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(wallRing, bodyFill(Rect.fromCircle(center: center, radius: rOut), lightness: 0.35));
        _drawRadialHatch(canvas, center, rIn, rOut, accent.color.withOpacity(0.35));
        canvas.drawCircle(center, rOut, lineOutline);
        canvas.drawCircle(center, rIn, lineOutline);
        canvas.drawCircle(center, rIn, Paint()..color = const Color(0xFF08080A));

        _drawCrosshairs(canvas, center, rOut + 16, lineCenter);
        _drawDimension(canvas, Offset(center.dx - rOut, center.dy), Offset(center.dx + rOut, center.dy), 'OD: ${od.toStringAsFixed(1)} mm', lineDim);
        final label = category == ComponentCategory.pipelineTransport ? 't: ${thk} mm (Transport Line)' : 't: ${thk} mm (Bevel 37.5°)';
        _drawLeader(canvas, Offset(center.dx + (rOut + rIn) / 2, center.dy - 8), Offset(center.dx + rOut + 25, center.dy - 35), label, accent);
        break;

      case ComponentCategory.flange:
        final classes = data['classes'] as Map<String, dynamic>;
        final flg = classes[subType] ?? classes.values.first;
        final double rFlange = size.height * 0.44;
        final double rPcd = rFlange * 0.72;
        final double rBore = rFlange * 0.38;

        final ring = Path()
          ..addOval(Rect.fromCircle(center: center, radius: rFlange))
          ..addOval(Rect.fromCircle(center: center, radius: rBore))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(ring, bodyFill(Rect.fromCircle(center: center, radius: rFlange)));
        canvas.drawCircle(center, rFlange, lineOutline);
        canvas.drawCircle(center, rBore, lineOutline);
        canvas.drawCircle(center, rBore, Paint()..color = const Color(0xFF08080A));
        canvas.drawCircle(center, rPcd, Paint()..color = accentColor.withOpacity(0.55)..strokeWidth = 1.0..style = PaintingStyle.stroke);

        final int boltCount = flg['bolts'] as int;
        for (int i = 0; i < boltCount; i++) {
          final double angle = (i * 2 * math.pi) / boltCount;
          final boltPos = Offset(center.dx + rPcd * math.cos(angle), center.dy + rPcd * math.sin(angle));
          canvas.drawCircle(boltPos, 5.2, Paint()..color = const Color(0xFF0B0B0D));
          canvas.drawCircle(boltPos, 5.2, lineOutline..strokeWidth = 1.6);
          canvas.drawLine(Offset(boltPos.dx - 7, boltPos.dy), Offset(boltPos.dx + 7, boltPos.dy), lineCenter);
          canvas.drawLine(Offset(boltPos.dx, boltPos.dy - 7), Offset(boltPos.dx, boltPos.dy + 7), lineCenter);
        }
        _drawDimension(canvas, Offset(center.dx - rPcd, center.dy), Offset(center.dx + rPcd, center.dy), 'PCD: ${flg['pcd']} mm', lineAccent);
        _drawLeader(canvas, Offset(center.dx + rFlange * 0.8, center.dy - rFlange * 0.5), Offset(center.dx + rFlange + 15, center.dy - rFlange * 0.6), '${boltCount}x Holes (${flg['boltSize']})', lineDim);
        break;

      case ComponentCategory.tee:
        final double cToE = ((data['teeCtoE'] ?? 64.0) as num).toDouble();
        final runPath = Path()
          ..moveTo(center.dx - 70, center.dy - 18)
          ..lineTo(center.dx + 70, center.dy - 18)
          ..lineTo(center.dx + 70, center.dy + 18)
          ..lineTo(center.dx - 70, center.dy + 18)
          ..close();
        final branchPath = Path()
          ..moveTo(center.dx - 18, center.dy - 18)
          ..lineTo(center.dx - 18, center.dy - 62)
          ..lineTo(center.dx + 18, center.dy - 62)
          ..lineTo(center.dx + 18, center.dy - 18)
          ..close();
        final combined = Path.combine(PathOperation.union, runPath, branchPath);
        canvas.drawPath(combined, bodyFill(Rect.fromLTRB(center.dx - 70, center.dy - 62, center.dx + 70, center.dy + 18)));
        canvas.drawPath(runPath, lineOutline);
        canvas.drawPath(branchPath, lineOutline);
        canvas.drawLine(Offset(center.dx - 70, center.dy), Offset(center.dx + 70, center.dy), lineCenter);
        canvas.drawLine(Offset(center.dx, center.dy - 62), Offset(center.dx, center.dy + 18), lineCenter);

        _drawDimension(canvas, Offset(center.dx, center.dy), Offset(center.dx + 70, center.dy), 'C-to-E: ${cToE.toStringAsFixed(0)} mm', lineAccent);
        _drawLeader(canvas, Offset(center.dx, center.dy - 62), Offset(center.dx - 30, center.dy - 85), 'ASME B16.9 Equal Tee', lineWeld);
        break;

      case ComponentCategory.elbow:
        final angles = data['angles'] as Map<String, dynamic>;
        final double cToE = ((angles[subType] ?? angles.values.first) as num).toDouble();
        final bool isFortyFive = subType == '45°';

        final Offset outerStart = Offset(center.dx - 65 - 16, center.dy + 65);
        final Offset innerStart = Offset(center.dx - 65 + 16, center.dy + 65);
        final Offset outerEnd = isFortyFive ? Offset(center.dx + 20 + 11, center.dy - 30 - 11) : Offset(center.dx + 65, center.dy - 65 - 16);
        final Offset innerEnd = isFortyFive ? Offset(center.dx + 20 - 11, center.dy - 30 + 11) : Offset(center.dx + 65, center.dy - 65 + 16);
        final Offset outerCtrl = isFortyFive ? Offset(center.dx - 65 - 16, center.dy + 4) : Offset(center.dx - 65 - 16, center.dy - 65 - 16);
        final Offset innerCtrl = isFortyFive ? Offset(center.dx - 65 + 16, center.dy + 16) : Offset(center.dx - 65 + 16, center.dy - 65 + 16);

        final outerPath = Path()
          ..moveTo(outerStart.dx, outerStart.dy)
          ..quadraticBezierTo(outerCtrl.dx, outerCtrl.dy, outerEnd.dx, outerEnd.dy);
        final innerPath = Path()
          ..moveTo(innerStart.dx, innerStart.dy)
          ..quadraticBezierTo(innerCtrl.dx, innerCtrl.dy, innerEnd.dx, innerEnd.dy);

        // A single closed band: out along the outer curve, across the end
        // face, back along the inner curve, across the start face.
        final bandPath = Path()
          ..moveTo(outerStart.dx, outerStart.dy)
          ..quadraticBezierTo(outerCtrl.dx, outerCtrl.dy, outerEnd.dx, outerEnd.dy)
          ..lineTo(innerEnd.dx, innerEnd.dy)
          ..quadraticBezierTo(innerCtrl.dx, innerCtrl.dy, innerStart.dx, innerStart.dy)
          ..close();
        canvas.drawPath(bandPath, bodyFill(Rect.fromLTWH(center.dx - 90, center.dy - 100, 180, 180)));
        canvas.drawPath(outerPath, lineOutline);
        canvas.drawPath(innerPath, lineOutline);
        canvas.drawLine(outerStart, innerStart, lineOutline);
        canvas.drawLine(outerEnd, innerEnd, lineOutline);

        final clPath = Path();
        clPath.moveTo(center.dx - 45, center.dy + 65);
        if (isFortyFive) {
          clPath.quadraticBezierTo(center.dx - 45, center.dy + 20, center.dx + 10, center.dy - 12);
        } else {
          clPath.quadraticBezierTo(center.dx - 45, center.dy - 45, center.dx + 65, center.dy - 45);
        }
        canvas.drawPath(clPath, lineCenter);

        _drawDimension(canvas, Offset(center.dx - 45, center.dy + 65), Offset(center.dx - 45, center.dy - 45), 'C-to-E: ${cToE.toStringAsFixed(1)} mm', lineAccent);
        _drawLeader(canvas, Offset(center.dx + 65, center.dy - 65), Offset(center.dx + 75, center.dy - 85), 'ASME B16.9 Bevel (Root 1.6mm)', lineWeld);
        break;

      case ComponentCategory.cap:
        final double capLen = ((data['capLen'] ?? 38.0) as num).toDouble();
        final capPath = Path()
          ..moveTo(center.dx - 20, center.dy + 55)
          ..lineTo(center.dx - 20, center.dy - 20)
          ..quadraticBezierTo(center.dx - 20, center.dy - 55, center.dx + 15, center.dy - 55)
          ..quadraticBezierTo(center.dx + 50, center.dy - 55, center.dx + 50, center.dy - 20)
          ..lineTo(center.dx + 50, center.dy + 55)
          ..close();
        canvas.drawPath(capPath, bodyFill(Rect.fromLTRB(center.dx - 20, center.dy - 55, center.dx + 50, center.dy + 55)));
        canvas.drawPath(capPath, lineOutline..style = PaintingStyle.stroke);
        canvas.drawLine(Offset(center.dx - 20, center.dy + 55), Offset(center.dx + 50, center.dy + 55), lineOutline);
        canvas.drawLine(Offset(center.dx + 15, center.dy - 55), Offset(center.dx + 15, center.dy + 60), lineCenter);

        _drawDimension(canvas, Offset(center.dx - 20, center.dy + 70), Offset(center.dx + 50, center.dy + 70), 'Length: ${capLen.toStringAsFixed(0)} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx + 15, center.dy - 55), Offset(center.dx + 45, center.dy - 78), 'Domed Closure (B16.9)', lineWeld);
        break;

      case ComponentCategory.socketWeld:
        final double depth = ((data['depth'] ?? 9.5) as num).toDouble();
        final outerRect = Rect.fromCenter(center: center, width: 140, height: 80);
        canvas.drawRect(outerRect, bodyFill(outerRect));
        canvas.drawRect(outerRect, lineOutline);
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 15, center.dy), width: 90, height: 50), Paint()..color = const Color(0xFF08080A));
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 15, center.dy), width: 90, height: 50), lineDim);
        canvas.drawRect(Rect.fromLTWH(center.dx + 30, center.dy - 25, 4, 50), Paint()..color = const Color(0xFF30D158));

        _drawLeader(canvas, Offset(center.dx + 32, center.dy), Offset(center.dx + 45, center.dy + 45), 'Mandatory Gap: 1.6 mm', lineWeld);
        _drawDimension(canvas, Offset(center.dx - 60, center.dy + 25), Offset(center.dx + 30, center.dy + 25), 'Bore Depth: ${depth} mm', lineDim);
        break;

      case ComponentCategory.threaded:
        final int tpi = data['tpi'] as int;
        final bandRect = Rect.fromLTRB(center.dx - 65, center.dy - 22, center.dx + 65, center.dy - 6);
        canvas.drawRect(bandRect, bodyFill(bandRect));
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

        final Path body = Path()
          ..moveTo(center.dx - halfLen, center.dy - rLarge)
          ..lineTo(center.dx + halfLen, center.dy - rSmall)
          ..lineTo(center.dx + halfLen, center.dy + rSmall)
          ..lineTo(center.dx - halfLen, center.dy + rLarge)
          ..close();
        canvas.drawPath(body, bodyFill(Rect.fromLTRB(center.dx - halfLen, center.dy - rLarge, center.dx + halfLen, center.dy + rLarge)));
        if (eccentric) {
          canvas.drawLine(Offset(center.dx - halfLen, center.dy + rLarge), Offset(center.dx + halfLen, center.dy + rSmall), lineCenter);
        }
        canvas.drawPath(body, lineOutline);
        canvas.drawLine(Offset(center.dx - halfLen - 14, center.dy), Offset(center.dx + halfLen + 14, center.dy), lineCenter);
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

        final ring = Path()
          ..addOval(Rect.fromCircle(center: center, radius: rOut))
          ..addOval(Rect.fromCircle(center: center, radius: rIn))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(ring, bodyFill(Rect.fromCircle(center: center, radius: rOut), lightness: 0.4));
        canvas.drawCircle(center, rOut, lineOutline);
        canvas.drawCircle(center, rIn, lineOutline);
        canvas.drawCircle(center, rIn, Paint()..color = const Color(0xFF08080A));

        for (int i = 1; i <= 3; i++) {
          final double r = rIn + (rOut - rIn) * (i / 4.0);
          canvas.drawCircle(center, r, Paint()..color = accentColor.withOpacity(0.4)..strokeWidth = 0.9..style = PaintingStyle.stroke);
        }

        _drawCrosshairs(canvas, center, rIn * 0.6, lineCenter);
        _drawDimension(canvas, Offset(center.dx - rOut, center.dy), Offset(center.dx + rOut, center.dy), 'OD: ${gOd.toStringAsFixed(1)} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx, center.dy - rIn), Offset(center.dx - 45, center.dy - rIn - 24), 'ID: ${gId.toStringAsFixed(1)} mm', lineAccent);
        _drawLeader(canvas, Offset(center.dx + rIn * 0.7, center.dy + rIn * 0.7), Offset(center.dx + rOut + 15, center.dy + rOut * 0.5), 'Spiral-Wound (316L/Graphite)', lineWeld);
        break;

      case ComponentCategory.valve:
        final types = data['types'] as Map<String, dynamic>;
        final classesForType = (types[valveType] ?? types.values.first) as Map<String, dynamic>;
        final vv = classesForType[subType] ?? classesForType.values.first;
        final double ftf = (vv['ftf'] as num).toDouble();
        _drawValveSymbol(canvas, center, valveType, bodyFill);
        _drawDimension(canvas, Offset(center.dx - 70, center.dy + 70), Offset(center.dx + 70, center.dy + 70), 'FtF: ${ftf.toStringAsFixed(0)} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx + 55, center.dy - 20), Offset(center.dx + 85, center.dy - 50), 'ASME B16.10', lineAccent);
        break;

      case ComponentCategory.weldolet:
      case ComponentCategory.sockolet:
      case ComponentCategory.threadolet:
        final double height = ((data['height'] ?? 40.0) as num).toDouble();
        final double runHalfW = 85.0;
        final double runH = 40.0;
        final double stubW = 26.0;
        final double stubTop = center.dy - runH / 2 - 60;

        final runRect = Rect.fromCenter(center: Offset(center.dx, center.dy + 30), width: runHalfW * 2, height: runH);
        canvas.drawRect(runRect, bodyFill(runRect));
        canvas.drawRect(runRect, lineOutline);
        canvas.drawLine(Offset(center.dx - runHalfW, center.dy + 30), Offset(center.dx + runHalfW, center.dy + 30), lineCenter);

        final stubTopY = category == ComponentCategory.weldolet
            ? stubTop
            : (category == ComponentCategory.sockolet ? stubTop + 6 : stubTop + 10);
        final stubRect = Rect.fromLTRB(center.dx - stubW / 2, stubTopY, center.dx + stubW / 2, center.dy + 30 - runH / 2 + 2);
        canvas.drawRect(stubRect, bodyFill(stubRect, lightness: 0.4));
        canvas.drawRect(stubRect, lineOutline);
        canvas.drawLine(Offset(center.dx, stubTopY - 4), Offset(center.dx, center.dy + 30 + runH / 2 - 4), lineCenter);

        if (category == ComponentCategory.weldolet) {
          canvas.drawLine(Offset(center.dx - stubW / 2 - 3, stubTopY - 3), Offset(center.dx + stubW / 2 + 3, stubTopY - 3), lineWeld);
        } else if (category == ComponentCategory.sockolet) {
          canvas.drawRect(Rect.fromLTRB(center.dx - stubW / 2 - 4, stubTopY, center.dx + stubW / 2 + 4, stubTopY + 14), lineDim);
        } else {
          for (double y = stubTopY; y <= stubTopY + 20; y += 5) {
            canvas.drawLine(Offset(center.dx - stubW / 2 - 4, y), Offset(center.dx + stubW / 2 + 4, y), lineAccent);
          }
        }

        _drawDimension(canvas, Offset(center.dx + stubW / 2 + 20, stubTopY), Offset(center.dx + stubW / 2 + 20, center.dy + 30 - runH / 2), 'H: ${height.toStringAsFixed(1)} mm', lineDim);
        _drawLeader(canvas, Offset(center.dx - runHalfW * 0.6, center.dy + 30), Offset(center.dx - runHalfW - 15, center.dy + 60), 'Run Pipe', lineAccent);
        _drawLeader(canvas, Offset(center.dx, stubTopY), Offset(center.dx + 40, stubTopY - 20), 'MSS SP-97', lineWeld);
        break;
    }
  }

  /// Draws the standard P&ID-style body symbol for the given valve type:
  /// Gate = bowtie wedge + handwheel stem; Globe = spherical body + baffle +
  /// handwheel stem; Ball = bowtie inside a circular shell + lever handle;
  /// Swing Check = a single directional wedge + hinge flap, no actuator.
  void _drawValveSymbol(Canvas canvas, Offset center, String type, Paint Function(Rect, {double lightness}) bodyFill) {
    final flangeOutline = Paint()
      ..color = const Color(0xFFF2F2F7)
      ..strokeWidth = 2.75
      ..style = PaintingStyle.stroke;
    final centerLine = Paint()
      ..color = const Color(0x77FFFFFF)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final metal = Paint()
      ..color = const Color(0xFFD1D1D6)
      ..style = PaintingStyle.fill;
    final metalDark = Paint()
      ..color = const Color(0xFF9B9BA1)
      ..style = PaintingStyle.fill;

    const double halfLen = 55.0;
    const double flangeH = 66.0;
    const double bodyR = 34.0;

    void drawEndFlanges() {
      canvas.drawLine(Offset(center.dx - halfLen, center.dy - flangeH / 2), Offset(center.dx - halfLen, center.dy + flangeH / 2), flangeOutline);
      canvas.drawLine(Offset(center.dx + halfLen, center.dy - flangeH / 2), Offset(center.dx + halfLen, center.dy + flangeH / 2), flangeOutline);
      canvas.drawRect(Rect.fromLTRB(center.dx - halfLen - 7, center.dy - flangeH / 2, center.dx - halfLen, center.dy + flangeH / 2), metalDark);
      canvas.drawRect(Rect.fromLTRB(center.dx + halfLen, center.dy - flangeH / 2, center.dx + halfLen + 7, center.dy + flangeH / 2), metalDark);
      canvas.drawLine(Offset(center.dx - halfLen - 6, center.dy - flangeH / 2), Offset(center.dx - halfLen - 6, center.dy + flangeH / 2), Paint()..color = accentColor..strokeWidth = 1.6);
      canvas.drawLine(Offset(center.dx + halfLen + 6, center.dy - flangeH / 2), Offset(center.dx + halfLen + 6, center.dy + flangeH / 2), Paint()..color = accentColor..strokeWidth = 1.6);
      canvas.drawLine(Offset(center.dx - halfLen - 6, center.dy), Offset(center.dx + halfLen + 6, center.dy), centerLine);
    }

    void drawHandwheelStem(double topY) {
      canvas.drawLine(Offset(center.dx, topY), Offset(center.dx, topY - 26), Paint()..color = const Color(0xFF30D158)..strokeWidth = 3.0);
      canvas.drawCircle(Offset(center.dx, topY - 34), 9.5, metal);
      canvas.drawCircle(Offset(center.dx, topY - 34), 9.5, flangeOutline..strokeWidth = 2.0);
      canvas.drawLine(Offset(center.dx - 9.5, topY - 34), Offset(center.dx + 9.5, topY - 34), Paint()..color = const Color(0xFF08080A)..strokeWidth = 1.4);
      canvas.drawLine(Offset(center.dx, topY - 43.5), Offset(center.dx, topY - 24.5), Paint()..color = const Color(0xFF08080A)..strokeWidth = 1.4);
    }

    switch (type) {
      case 'Gate Valve':
        drawEndFlanges();
        final bowtie = Path()
          ..moveTo(center.dx - halfLen + 8, center.dy - bodyR)
          ..lineTo(center.dx, center.dy)
          ..lineTo(center.dx - halfLen + 8, center.dy + bodyR)
          ..close()
          ..moveTo(center.dx + halfLen - 8, center.dy - bodyR)
          ..lineTo(center.dx, center.dy)
          ..lineTo(center.dx + halfLen - 8, center.dy + bodyR)
          ..close();
        canvas.drawPath(bowtie, bodyFill(Rect.fromLTRB(center.dx - halfLen, center.dy - bodyR, center.dx + halfLen, center.dy + bodyR)));
        canvas.drawPath(bowtie, flangeOutline);
        drawHandwheelStem(center.dy - bodyR * 0.15);
        break;

      case 'Ball Valve':
        drawEndFlanges();
        final circleRect = Rect.fromCircle(center: center, radius: bodyR);
        canvas.drawOval(circleRect, bodyFill(circleRect, lightness: 0.25));
        canvas.drawOval(circleRect, flangeOutline);
        final bowtie = Path()
          ..moveTo(center.dx - bodyR * 0.72, center.dy - bodyR * 0.62)
          ..lineTo(center.dx, center.dy)
          ..lineTo(center.dx - bodyR * 0.72, center.dy + bodyR * 0.62)
          ..close()
          ..moveTo(center.dx + bodyR * 0.72, center.dy - bodyR * 0.62)
          ..lineTo(center.dx, center.dy)
          ..lineTo(center.dx + bodyR * 0.72, center.dy + bodyR * 0.62)
          ..close();
        canvas.drawPath(bowtie, metalDark);
        canvas.drawPath(bowtie, flangeOutline..strokeWidth = 1.6);
        // Lever handle (perpendicular to flow when open) instead of a handwheel.
        canvas.drawLine(Offset(center.dx, center.dy - bodyR), Offset(center.dx, center.dy - bodyR - 24), Paint()..color = const Color(0xFF30D158)..strokeWidth = 3.2..strokeCap = StrokeCap.round);
        canvas.drawLine(Offset(center.dx - 16, center.dy - bodyR - 24), Offset(center.dx + 16, center.dy - bodyR - 24), Paint()..color = const Color(0xFF30D158)..strokeWidth = 4.0..strokeCap = StrokeCap.round);
        break;

      case 'Globe Valve':
        drawEndFlanges();
        final circleRect = Rect.fromCircle(center: center, radius: bodyR);
        canvas.drawOval(circleRect, bodyFill(circleRect, lightness: 0.3));
        canvas.drawOval(circleRect, flangeOutline);
        // Internal S-baffle showing the raised, perpendicular seat (the
        // feature that distinguishes a globe body from a gate/ball body).
        final baffle = Path()
          ..moveTo(center.dx - bodyR + 6, center.dy)
          ..quadraticBezierTo(center.dx - 6, center.dy, center.dx - 6, center.dy - bodyR * 0.55)
          ..moveTo(center.dx + 6, center.dy + bodyR * 0.55)
          ..quadraticBezierTo(center.dx + 6, center.dy, center.dx + bodyR - 6, center.dy);
        canvas.drawPath(baffle, Paint()..color = const Color(0xFF08080A)..strokeWidth = 3.0..style = PaintingStyle.stroke);
        drawHandwheelStem(center.dy - bodyR);
        break;

      case 'Swing Check Valve':
        drawEndFlanges();
        // Directional wedge (flow left-to-right) plus a hinge pin + flap arc
        // — the standard "no actuator, one-way" check-valve symbol.
        final wedge = Path()
          ..moveTo(center.dx - halfLen + 10, center.dy - bodyR * 0.8)
          ..lineTo(center.dx + halfLen - 14, center.dy)
          ..lineTo(center.dx - halfLen + 10, center.dy + bodyR * 0.8)
          ..close();
        canvas.drawPath(wedge, bodyFill(Rect.fromLTRB(center.dx - halfLen, center.dy - bodyR, center.dx + halfLen, center.dy + bodyR)));
        canvas.drawPath(wedge, flangeOutline);
        canvas.drawCircle(Offset(center.dx - halfLen + 12, center.dy - bodyR * 0.55), 3.5, Paint()..color = const Color(0xFF08080A));
        final flap = Path()
          ..moveTo(center.dx - halfLen + 12, center.dy - bodyR * 0.55)
          ..lineTo(center.dx + 6, center.dy - bodyR * 0.15);
        canvas.drawPath(flap, Paint()..color = const Color(0xFF8E8E93)..strokeWidth = 2.4..style = PaintingStyle.stroke);
        // Flow-direction arrow.
        final arrowY = center.dy + bodyR + 14;
        canvas.drawLine(Offset(center.dx - 22, arrowY), Offset(center.dx + 22, arrowY), Paint()..color = accentColor..strokeWidth = 2.0);
        canvas.drawPath(
          Path()
            ..moveTo(center.dx + 22, arrowY)
            ..lineTo(center.dx + 14, arrowY - 5)
            ..lineTo(center.dx + 14, arrowY + 5)
            ..close(),
          Paint()..color = accentColor,
        );
        break;
    }
  }

  void _drawRadialHatch(Canvas canvas, Offset center, double rIn, double rOut, Color color) {
    final paint = Paint()..color = color..strokeWidth = 1.0;
    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final p1 = Offset(center.dx + rIn * math.cos(angle), center.dy + rIn * math.sin(angle));
      final p2 = Offset(center.dx + rOut * math.cos(angle), center.dy + rOut * math.sin(angle));
      canvas.drawLine(p1, p2, paint);
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
