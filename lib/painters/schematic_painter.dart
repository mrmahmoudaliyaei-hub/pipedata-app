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

  /// Every shape below is hand-tuned against this exact canvas size. Rather
  /// than re-deriving all of that math to be resolution-independent, [paint]
  /// draws it once at this fixed size and uniformly scales the whole canvas
  /// up (or down) to fit whatever size it's actually asked to fill — this is
  /// what lets the same painter serve both the small inline card and the
  /// full-screen zoomed view without maintaining two coordinate systems.
  static const Size _designSize = Size(260, 150);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = math.min(size.width / _designSize.width, size.height / _designSize.height);
    final double dx = (size.width - _designSize.width * scale) / 2;
    final double dy = (size.height - _designSize.height * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    _paintContent(canvas, _designSize);
    canvas.restore();
  }

  void _paintContent(Canvas canvas, Size size) {
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
        final label = category == ComponentCategory.pipelineTransport ? 't: $thk mm (Transport Line)' : 't: $thk mm (Bevel 37.5°)';
        _drawLeader(canvas, Offset(center.dx + (rOut + rIn) / 2, center.dy - 8), Offset(center.dx + rOut + 25, center.dy - 35), label, accent);
        final double idMm = (currentSch['id'] as num).toDouble();
        _drawLeader(canvas, Offset(center.dx - rIn * 0.7, center.dy + rIn * 0.7), Offset(center.dx - rOut - 25, center.dy + rOut * 0.6), 'ID: ${idMm.toStringAsFixed(1)} mm', lineWeld);
        break;

      case ComponentCategory.flange:
        final classes = data['classes'] as Map<String, dynamic>;
        final flg = classes[subType] ?? classes.values.first;
        final double fOd = (flg['od'] as num).toDouble();
        final double fPcd = (flg['pcd'] as num).toDouble();
        final double fThk = (flg['thk'] as num).toDouble();
        final int boltCount = flg['bolts'] as int;
        final String boltSize = (flg['boltSize'] as String?) ?? '';

        // Real mating-pipe bore for this flange's DN, at Sch 40 (STD) if
        // available — this is an actual dataset value (not invented), used
        // as the flange's through-bore in the cross-section below.
        double? boreMm;
        final matches = PipingMasterCatalog.pipes.where((p) => p['dn'] == data['dn']);
        if (matches.isNotEmpty) {
          final schedules = matches.first['schedules'] as Map<String, dynamic>;
          final sch = schedules['Sch 40 (STD)'] ?? schedules.values.first;
          boreMm = (sch['id'] as num).toDouble();
        }

        // Cross-section profile, drawn to scale: every horizontal width
        // below is proportional to its real mm value against fOd, so the
        // telescoping dimension lines are actually to-scale, not decorative.
        final double cx = size.width / 2;
        final double maxSpanPx = size.width - 84; // leaves room for the thickness dimension on the right
        double pxFor(double mm) => maxSpanPx * (mm / fOd);
        final double odPx = maxSpanPx;
        final double pcdPx = pxFor(fPcd);
        final double borePx = boreMm != null ? pxFor(boreMm) : 0;

        const double profileTopY = 22.0;
        const double bossH = 9.0;
        const double bodyH = 24.0;
        const double bodyTopY = profileTopY + bossH;
        const double bodyBottomY = bodyTopY + bodyH;
        final double bossW = odPx * 0.34;

        final bodyRect = Rect.fromLTRB(cx - odPx / 2, bodyTopY, cx + odPx / 2, bodyBottomY);
        canvas.drawRect(bodyRect, bodyFill(bodyRect));
        canvas.drawRect(bodyRect, lineOutline);
        final bossRect = Rect.fromLTRB(cx - bossW / 2, profileTopY, cx + bossW / 2, bodyTopY + 2);
        canvas.drawRect(bossRect, bodyFill(bossRect, lightness: 0.42));
        canvas.drawRect(bossRect, lineOutline);

        if (boreMm != null) {
          final boreRect = Rect.fromLTRB(cx - borePx / 2, profileTopY - 5, cx + borePx / 2, bodyBottomY);
          canvas.drawRect(boreRect, Paint()..color = const Color(0xFF08080A));
          canvas.drawLine(Offset(cx - borePx / 2, profileTopY - 5), Offset(cx - borePx / 2, bodyBottomY), lineOutline..strokeWidth = 1.6);
          canvas.drawLine(Offset(cx + borePx / 2, profileTopY - 5), Offset(cx + borePx / 2, bodyBottomY), lineOutline..strokeWidth = 1.6);
        }
        canvas.drawLine(Offset(cx, profileTopY - 9), Offset(cx, bodyBottomY + 9), lineCenter);

        // Thickness, as a vertical dimension beside the body.
        final double dimX = cx + odPx / 2 + 16;
        _drawVerticalDimension(canvas, Offset(dimX, bodyTopY), Offset(dimX, bodyBottomY), fThk.toStringAsFixed(1), lineDim);

        // Bolt-hole leader, from the boss edge.
        _drawLeader(
          canvas,
          Offset(cx + bossW / 2 - 3, profileTopY + 2),
          Offset(cx + bossW / 2 + 22, profileTopY - 20),
          '${boltCount}x $boltSize',
          lineAccent,
        );

        // Telescoping dimension lines: bore (if known), PCD, OD — stacked,
        // each to the width it's actually proportional to.
        double dimY = bodyBottomY + 16;
        if (boreMm != null) {
          _drawDimension(canvas, Offset(cx - borePx / 2, dimY), Offset(cx + borePx / 2, dimY), boreMm.toStringAsFixed(0), lineWeld);
          dimY += 15;
        }
        _drawDimension(canvas, Offset(cx - pcdPx / 2, dimY), Offset(cx + pcdPx / 2, dimY), fPcd.toStringAsFixed(0), lineAccent);
        dimY += 15;
        _drawDimension(canvas, Offset(cx - odPx / 2, dimY), Offset(cx + odPx / 2, dimY), fOd.toStringAsFixed(0), lineDim);
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

        // Equal tee: run and branch C-to-E are the same real value, so both
        // arms get a genuine dimension, not just the one on the right.
        _drawDimension(canvas, Offset(center.dx, center.dy), Offset(center.dx + 70, center.dy), '${cToE.toStringAsFixed(0)} mm', lineAccent);
        _drawVerticalDimension(canvas, Offset(center.dx - 26, center.dy - 62), Offset(center.dx - 26, center.dy - 18), cToE.toStringAsFixed(0), lineAccent);
        final teeOd = _matingPipeOd(data['dn']);
        if (teeOd != null) {
          _drawLeader(canvas, Offset(center.dx - 65, center.dy - 18), Offset(center.dx - 95, center.dy - 40), 'OD: ${teeOd.toStringAsFixed(1)} mm', lineWeld);
        }
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
        final elbowOd = _matingPipeOd(data['dn']);
        if (elbowOd != null) {
          _drawLeader(canvas, Offset(outerStart.dx + 8, outerStart.dy - 4), Offset(outerStart.dx - 20, outerStart.dy + 22), 'OD: ${elbowOd.toStringAsFixed(1)} mm', lineDim);
        }
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
        final capOd = _matingPipeOd(data['dn']);
        if (capOd != null) {
          _drawLeader(canvas, Offset(center.dx - 20, center.dy - 5), Offset(center.dx - 55, center.dy - 25), 'OD: ${capOd.toStringAsFixed(1)} mm', lineAccent);
        }
        break;

      case ComponentCategory.socketWeld:
        final double depth = ((data['depth'] ?? 9.5) as num).toDouble();
        final double boreDia = ((data['boreDia'] ?? 0.0) as num).toDouble();
        final outerRect = Rect.fromCenter(center: center, width: 140, height: 80);
        canvas.drawRect(outerRect, bodyFill(outerRect));
        canvas.drawRect(outerRect, lineOutline);
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 15, center.dy), width: 90, height: 50), Paint()..color = const Color(0xFF08080A));
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 15, center.dy), width: 90, height: 50), lineDim);
        canvas.drawRect(Rect.fromLTWH(center.dx + 30, center.dy - 25, 4, 50), Paint()..color = const Color(0xFF30D158));

        _drawLeader(canvas, Offset(center.dx + 32, center.dy), Offset(center.dx + 45, center.dy + 45), 'Mandatory Gap: 1.6 mm', lineWeld);
        _drawDimension(canvas, Offset(center.dx - 60, center.dy + 25), Offset(center.dx + 30, center.dy + 25), 'Bore Depth: $depth mm', lineDim);
        _drawVerticalDimension(canvas, Offset(center.dx - 60, center.dy - 25), Offset(center.dx - 60, center.dy + 25), 'Bore ⌀${boreDia.toStringAsFixed(1)}', lineAccent);
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
        final threadedOd = _matingPipeOd(data['dn']);
        if (threadedOd != null) {
          _drawLeader(canvas, Offset(center.dx - 65, center.dy - 14), Offset(center.dx - 95, center.dy - 34), 'OD: ${threadedOd.toStringAsFixed(1)} mm', lineWeld);
        }
        break;

      case ComponentCategory.reducer:
        final lengths = data['lengths'] as Map<String, dynamic>;
        final double lenMm = ((lengths[subType] ?? lengths.values.first) as num).toDouble();
        final bool eccentric = subType == 'Eccentric';
        const double halfLen = 60.0;
        const double rLarge = 46.0;
        const double rSmall = 22.0;

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
        final largeOd = _matingPipeOd(data['largeDn']);
        final smallOd = _matingPipeOd(data['smallDn']);
        _drawLeader(canvas, Offset(center.dx - halfLen, center.dy - rLarge * 0.4), Offset(center.dx - halfLen - 30, center.dy - rLarge - 10),
            largeOd != null ? 'Large End OD: ${largeOd.toStringAsFixed(1)} mm' : 'Large End', lineAccent);
        _drawLeader(canvas, Offset(center.dx + halfLen, center.dy - rSmall * 0.4), Offset(center.dx + halfLen + 20, center.dy - rSmall - 24),
            smallOd != null ? 'Small End OD: ${smallOd.toStringAsFixed(1)} mm' : 'Small End', lineWeld);
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
        final double gThk = (gk['thk'] as num).toDouble();
        _drawLeader(canvas, Offset(center.dx + rIn * 0.7, center.dy + rIn * 0.7), Offset(center.dx + rOut + 15, center.dy + rOut * 0.5), 'Spiral-Wound, ${gThk.toStringAsFixed(1)}mm (316L/Graphite)', lineWeld);
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
        const double runHalfW = 85.0;
        const double runH = 40.0;
        const double stubW = 26.0;
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
        final runOd = _matingPipeOd(data['dn']);
        _drawLeader(canvas, Offset(center.dx - runHalfW * 0.6, center.dy + 30), Offset(center.dx - runHalfW - 15, center.dy + 60),
            runOd != null ? 'Run OD: ${runOd.toStringAsFixed(1)} mm' : 'Run Pipe', lineAccent);
        if (category == ComponentCategory.sockolet && data.containsKey('socketDepth')) {
          final socketDepth = (data['socketDepth'] as num).toDouble();
          _drawLeader(canvas, Offset(center.dx, stubTopY), Offset(center.dx + 40, stubTopY - 20), 'MSS SP-97, Socket ${socketDepth.toStringAsFixed(1)}mm', lineWeld);
        } else {
          _drawLeader(canvas, Offset(center.dx, stubTopY), Offset(center.dx + 40, stubTopY - 20), 'MSS SP-97', lineWeld);
        }
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
      // Bonnet block between the body and the stem.
      final bonnetRect = Rect.fromLTRB(center.dx - 8, topY - 8, center.dx + 8, topY);
      canvas.drawRect(bonnetRect, bodyFill(bonnetRect, lightness: 0.32));
      canvas.drawRect(bonnetRect, flangeOutline..strokeWidth = 2.0);

      // Yoke: two struts flaring outward from the bonnet up to a stem-nut
      // block, the way a real handwheel-operated valve actually holds its
      // wheel off the body — instead of a single bare rod. Sized to still
      // fit above Globe Valve's higher-starting stem (topY = body top, not
      // Gate's lower near-centerline attach point).
      final double yokeBottomY = topY - 8;
      final double yokeTopY = yokeBottomY - 9;
      final yokePath = Path()
        ..moveTo(center.dx - 5, yokeBottomY)
        ..lineTo(center.dx - 10, yokeTopY)
        ..moveTo(center.dx + 5, yokeBottomY)
        ..lineTo(center.dx + 10, yokeTopY);
      canvas.drawPath(yokePath, Paint()..color = const Color(0xFFD1D1D6)..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      final nutRect = Rect.fromLTRB(center.dx - 5, yokeTopY - 3, center.dx + 5, yokeTopY);
      canvas.drawRect(nutRect, metalDark);
      canvas.drawRect(nutRect, flangeOutline..strokeWidth = 1.4);

      final double stemTopY = yokeTopY - 3 - 6;
      canvas.drawLine(Offset(center.dx, yokeTopY - 3), Offset(center.dx, stemTopY), Paint()..color = const Color(0xFF30D158)..strokeWidth = 2.0);

      // Handwheel: rim + hub + 4 spokes, instead of a single crossbar.
      final wheelCenter = Offset(center.dx, stemTopY - 5);
      const double wheelR = 7.0;
      canvas.drawCircle(wheelCenter, wheelR, metal);
      canvas.drawCircle(wheelCenter, wheelR, flangeOutline..strokeWidth = 1.6);
      canvas.drawCircle(wheelCenter, wheelR * 0.3, Paint()..color = const Color(0xFF08080A));
      for (final angle in [0.0, math.pi / 2, math.pi / 4, 3 * math.pi / 4]) {
        final dx = wheelR * math.cos(angle);
        final dy = wheelR * math.sin(angle);
        canvas.drawLine(Offset(wheelCenter.dx - dx, wheelCenter.dy - dy), Offset(wheelCenter.dx + dx, wheelCenter.dy + dy), Paint()..color = const Color(0xFF08080A)..strokeWidth = 1.2);
      }
    }

    switch (type) {
      case 'Gate Valve':
        drawEndFlanges();
        // Body casting: a rounded block (not the old bowtie-only shape)
        // with a distinct neck rising to the bonnet, plus a faint internal
        // wedge hint instead of the wedge shape *being* the whole body.
        const double neckH = 12.0;
        const double neckTopHalfW = 8.0;
        const double neckBottomHalfW = 13.0;
        final double bodyTop = center.dy - 18;
        final double bodyBottom = center.dy + 28;
        final double bodyLeft = center.dx - halfLen + 6;
        final double bodyRight = center.dx + halfLen - 6;
        final double neckTopY = bodyTop - neckH;

        final bodyRect = RRect.fromRectAndRadius(Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom), const Radius.circular(10));
        final neckPath = Path()
          ..moveTo(center.dx - neckBottomHalfW, bodyTop + 2)
          ..lineTo(center.dx - neckTopHalfW, neckTopY)
          ..lineTo(center.dx + neckTopHalfW, neckTopY)
          ..lineTo(center.dx + neckBottomHalfW, bodyTop + 2)
          ..close();
        final combinedBody = Path()
          ..addRRect(bodyRect)
          ..addPath(neckPath, Offset.zero);
        canvas.drawPath(combinedBody, bodyFill(Rect.fromLTRB(bodyLeft, neckTopY, bodyRight, bodyBottom)));
        canvas.drawRRect(bodyRect, flangeOutline);
        canvas.drawPath(neckPath, flangeOutline..strokeWidth = 2.2);

        // Faint internal wedge hint (the actual gate) instead of a bold
        // bowtie dominating the whole silhouette.
        final wedgeHint = Path()
          ..moveTo(bodyLeft + 10, center.dy - 12)
          ..lineTo(center.dx, center.dy)
          ..lineTo(bodyLeft + 10, center.dy + 18)
          ..moveTo(bodyRight - 10, center.dy - 12)
          ..lineTo(center.dx, center.dy)
          ..lineTo(bodyRight - 10, center.dy + 18);
        canvas.drawPath(wedgeHint, Paint()..color = const Color(0x66F2F2F7)..strokeWidth = 1.3..style = PaintingStyle.stroke);

        drawHandwheelStem(neckTopY);
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

  /// Looks up the real B36.10M pipe OD for a given DN (used to label
  /// fitting cross-sections with the actual mating-pipe size instead of
  /// leaving the body dimensionless). Returns null if no match is found.
  double? _matingPipeOd(dynamic dn) {
    if (dn == null) return null;
    final matches = PipingMasterCatalog.pipes.where((p) => p['dn'] == dn);
    if (matches.isEmpty) return null;
    return (matches.first['od'] as num).toDouble();
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

  /// Same idea as [_drawDimension] but for a vertical span (e.g. a
  /// thickness), with the label to the right of the line instead of
  /// centered above it.
  void _drawVerticalDimension(Canvas canvas, Offset start, Offset end, String text, Paint paint) {
    canvas.drawLine(start, end, paint);
    canvas.drawLine(Offset(start.dx - 4, start.dy), Offset(start.dx + 4, start.dy), paint);
    canvas.drawLine(Offset(end.dx - 4, end.dy), Offset(end.dx + 4, end.dy), paint);
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    _renderTextLeftAligned(canvas, text, Offset(mid.dx + 6, mid.dy - 5), paint.color);
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

  void _renderTextLeftAligned(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant VectorBlueprintPainter oldDelegate) => true;
}
