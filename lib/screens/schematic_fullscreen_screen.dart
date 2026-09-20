import 'package:flutter/cupertino.dart';
import '../core/component_icons.dart';
import '../core/models.dart';

/// Full-screen version of the schematic card — the bundled reference
/// photo (see component_icons.dart) at its own natural aspect ratio,
/// framed in a bordered card sized to match exactly.
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
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withOpacity(0.25)),
              ),
              child: Image.asset(resolveIconAsset(category, valveType: valveType), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
