import 'package:flutter/cupertino.dart';
import '../core/category_meta.dart';

/// One row in a grouped list section (iOS Settings-style), not a
/// standalone card — the enclosing group container supplies the shared
/// background, corner radius, and hairline dividers between rows.
class CategoryRow extends StatelessWidget {
  final CategoryMeta meta;
  final VoidCallback onTap;
  final bool showDivider;

  const CategoryRow({super.key, required this.meta, required this.onTap, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final Color c = meta.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: Color(0xFF232326), width: 0.6)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.withOpacity(0.16), borderRadius: BorderRadius.circular(8)),
              child: Icon(meta.icon, color: c, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: CupertinoColors.white)),
                  const SizedBox(height: 1),
                  Text(meta.standard, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, size: 15, color: Color(0xFF48484A)),
          ],
        ),
      ),
    );
  }
}
