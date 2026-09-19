import 'package:flutter/cupertino.dart';
import '../core/models.dart';
import '../painters/schematic_painter.dart';

/// Full-screen version of the schematic card. Reuses the exact same
/// [VectorBlueprintPainter] — its `paint()` uniformly scales its whole
/// fixed-coordinate drawing to whatever canvas size it's given, so handing
/// it a much bigger canvas here just makes everything (lines, dimension
/// text, the valve yoke/wheel) larger and more legible, with no separate
/// "zoomed" layout to maintain.
class SchematicFullscreenScreen extends StatelessWidget {
  final ComponentCategory category;
  final Map<String, dynamic> data;
  final String subType;
  final Color accentColor;
  final String valveType;
  final String title;

  const SchematicFullscreenScreen({
    super.key,
    required this.category,
    required this.data,
    required this.subType,
    required this.accentColor,
    this.valveType = 'Gate Valve',
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xF0161618),
        middle: Text(title),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox.expand(
            child: CustomPaint(
              painter: VectorBlueprintPainter(
                category: category,
                data: data,
                subType: subType,
                accentColor: accentColor,
                valveType: valveType,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
