import 'models.dart';

/// Static reference-photo assets, one per non-valve category, shown
/// instead of the retired CustomPainter schematic (see git history:
/// after several rounds of trying to improve the procedural line-art —
/// bowtie valves, faceted castings, real-yoke elevations — the app owner
/// judged real product photos as the only thing that actually looked
/// professional). Background removed, size/class-specific markings
/// blurred or cropped out, since one photo has to represent every
/// size+class combination of that category.
///
/// `pipelineTransport` intentionally reuses the `pipe` image — it's the
/// same physical product (a length of pipe), just under ASME B31.4
/// instead of B31.3.
///
/// `socketWeld` and `threaded` reuse the `sockolet`/`threadolet` images:
/// a generic small forged Socket-Weld or Threaded fitting and its
/// branch-outlet counterpart (Sockolet/Threadolet) are visually the same
/// kind of part (smooth bore vs. NPT-threaded bore, no bolt holes either
/// way) — there wasn't a distinct clean reference photo for the plain
/// fitting version, and re-using the outlet photo beats a fabricated or
/// mismatched substitute.
const Map<ComponentCategory, String> categoryIconAssets = {
  ComponentCategory.pipe: 'assets/images/parts/pipe.png',
  ComponentCategory.pipelineTransport: 'assets/images/parts/pipe.png',
  ComponentCategory.flange: 'assets/images/parts/flange.png',
  ComponentCategory.socketWeld: 'assets/images/parts/socket_weld.png',
  ComponentCategory.threaded: 'assets/images/parts/threaded.png',
  ComponentCategory.reducer: 'assets/images/parts/reducer.png',
  ComponentCategory.gasket: 'assets/images/parts/gasket.png',
  ComponentCategory.tee: 'assets/images/parts/tee.png',
  ComponentCategory.elbow: 'assets/images/parts/elbow.png',
  ComponentCategory.cap: 'assets/images/parts/cap.png',
  ComponentCategory.weldolet: 'assets/images/parts/weldolet.png',
  ComponentCategory.sockolet: 'assets/images/parts/sockolet.png',
  ComponentCategory.threadolet: 'assets/images/parts/threadolet.png',
  // ComponentCategory.valve is intentionally absent — it needs a second
  // key (the selected valve type), so it's handled by valveIconAssets
  // and resolveIconAsset() below instead of this map alone.
};

/// Same idea as [categoryIconAssets], but valves need a photo per valve
/// *type* (Gate/Globe/Ball/Swing Check), not just per category.
const Map<String, String> valveIconAssets = {
  'Gate Valve': 'assets/images/valves/gate_valve.png',
  'Globe Valve': 'assets/images/valves/globe_valve.png',
  'Ball Valve': 'assets/images/valves/ball_valve.png',
  'Swing Check Valve': 'assets/images/valves/swing_check_valve.png',
};

/// Single entry point every screen uses to find the right static image
/// for whatever's currently selected — so there's one place that knows
/// valves are keyed differently from everything else, not several.
String resolveIconAsset(ComponentCategory category, {String valveType = 'Gate Valve'}) {
  if (category == ComponentCategory.valve) {
    return valveIconAssets[valveType] ?? valveIconAssets['Gate Valve']!;
  }
  return categoryIconAssets[category]!;
}
