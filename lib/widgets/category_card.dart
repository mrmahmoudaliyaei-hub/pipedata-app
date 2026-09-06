import 'package:flutter/cupertino.dart';
import '../core/category_meta.dart';

/// A single grouped-grid card on the home screen, styled after Apple's
/// Settings/Health app category tiles: colored icon glyph, label, and the
/// governing standard as a subtitle.
class CategoryCard extends StatelessWidget {
  final CategoryMeta meta;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF).withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: const Color(0xFF0A84FF), size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              meta.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white, letterSpacing: -0.2),
            ),
            const SizedBox(height: 2),
            Text(
              meta.standard,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93)),
            ),
          ],
        ),
      ),
    );
  }
}
