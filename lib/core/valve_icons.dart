/// Static reference-photo assets for the 4 valve types, used instead of the
/// procedurally-drawn CustomPainter schematic for this one category.
///
/// Why valves are different from every other category: the painter's
/// hand-coded body shapes (bowtie triangles etc.) were assessed by the app
/// owner as not looking like real engineering illustrations, and repeated
/// attempts to improve the drawing code didn't close that gap. These are
/// real product photos (AI-generated via Gemini/Nano Banana, background
/// removed, size/class-specific markings blurred out since one photo has to
/// represent every size+class combination for that valve type) used purely
/// as a visual reference — the actual dimensions for whichever size/class
/// the user has selected still come from PipingMasterCatalog and are shown
/// in the Dimensions/Rating/Bolting tabs, not drawn onto this image.
const Map<String, String> valveIconAssets = {
  'Gate Valve': 'assets/images/valves/gate_valve.png',
  'Globe Valve': 'assets/images/valves/globe_valve.png',
  'Ball Valve': 'assets/images/valves/ball_valve.png',
  'Swing Check Valve': 'assets/images/valves/swing_check_valve.png',
};
