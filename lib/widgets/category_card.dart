import 'package:flutter/cupertino.dart';
import '../core/category_meta.dart';

/// A single grouped-grid card on the home screen. Each category gets its
/// own accent color (see CategoryRegistry) rendered as a soft glowing icon
/// badge, a subtle tinted top-hairline, and a small standard "pill" — so the
/// grid reads as a set of distinct, deliberately designed tiles rather than
/// one repeated blue icon on a flat gray card.
class CategoryCard extends StatelessWidget {
  final CategoryMeta meta;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color c = meta.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C1C1F),
              Color.lerp(const Color(0xFF161618), c, 0.05)!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.16), width: 1),
          boxShadow: [
            BoxShadow(color: c.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.withOpacity(0.32), c.withOpacity(0.12)],
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(color: c.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(meta.icon, color: c, size: 21),
            ),
            const SizedBox(height: 14),
            Text(
              meta.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: CupertinoColors.white, letterSpacing: -0.2),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: c.withOpacity(0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                meta.standard,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c, letterSpacing: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
