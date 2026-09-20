# Changelog

All notable changes to Piping Data Pro are logged here. Dates are UTC.

## Unreleased

### Changed
- **Reverted the flange/gasket bore-darkening from the previous update** —
  the app owner found the dark-hole treatment looked worse, not better, so
  both are back to how they looked before that change.
- **App icon replaced** — the old hand-drawn flat 2D icon is gone; the new
  one is the real weld-neck flange product photo composited onto a dark
  navy gradient with a soft glow and drop shadow for actual depth, instead
  of another from-scratch illustration attempt.
- **Accent color palette redone as a single dark-blue family** — every
  category still gets its own distinct shade (so cards remain visually
  distinct), but all colors now live within the blue spectrum instead of
  a multicolor rainbow. `pipeline_screen.dart`'s hardcoded red accents
  updated to match. (Broader sweep of every remaining non-blue accent in
  the app — e.g. the favorites star, a couple of Rating-tab highlight
  colors — not done in this pass; flagged for a follow-up.)
- **Home screen category grouping reordered and re-split**: now follows
  pipe → fittings → flanges/gaskets → valves (now its own top-level group,
  previously buried inside Flanged Components) → branch outlets →
  small-bore → pipeline transport, instead of the previous ordering.

- **Every category's schematic replaced with a real reference photo** —
  extending the valve-only change below to all 13 remaining categories
  (pipes, flanges, gaskets, reducers, tees, elbows, caps, socket-weld,
  threaded, weldolets, sockolets, threadolets). Same approach as valves:
  AI-generated photos, background removed, any size/class-specific
  markings (stamped numbers, engraved text) blurred or cropped out, since
  one photo represents every size+class combination of that category.
  - `lib/core/component_icons.dart` replaces `valve_icons.dart`: one
    category → asset map for everything except valves (which still need
    a second key, the selected valve type), plus a single
    `resolveIconAsset()` every screen calls instead of branching on
    category type itself.
  - `lib/painters/` (the whole CustomPainter-based schematic renderer,
    `VectorBlueprintPainter` and everything in it) is now fully unused
    and has been deleted rather than left as dead code — nothing in the
    app references it anymore.
  - `category_detail_screen.dart`, `schematic_fullscreen_screen.dart`,
    `pipeline_screen.dart`: all three schematic-rendering call sites
    (inline card, full-screen zoom, and the separate Pipeline calculator's
    own card) now just call `Image.asset(resolveIconAsset(...))` — no
    per-category branching left in any of them.
  - `pipe` and `pipelineTransport` intentionally share one photo (same
    physical product, different governing standard); `socketWeld`/
    `threaded` reuse the `sockolet`/`threadolet` photos (visually the
    same kind of part, smooth vs. threaded bore, no distinct clean
    reference photo existed for the plain-fitting version).
  - `test/component_icons_test.dart` replaces `valve_icons_test.dart`:
    checks every `ComponentCategory` (and every valve type) resolves to
    a real asset entry, not just valves.

- **Valve schematics replaced with real reference photos.** After several
  rounds of trying to improve the procedurally-drawn valve body (bowtie
  shapes → faceted casting silhouette → real-yoke elevation), the app owner
  assessed that none of it read as a professional engineering illustration.
  Rather than keep iterating on drawing code blind, the 4 valve types (Gate,
  Globe, Ball, Swing Check) now show a real product reference photo
  (AI-generated, background removed, size/class-specific markings blurred
  out since one photo represents every size+class combination) instead of
  the CustomPainter drawing. The actual per-size/class dimensions the user
  selects are unaffected — those still come from PipingMasterCatalog and
  show in the Dimensions/Rating/Bolting tabs exactly as before; only the
  picture changed. Every other category (pipes, flanges, fittings, branch
  outlets) still uses the procedural painter.
  - `lib/core/valve_icons.dart`: valve-type → asset path map.
  - `assets/images/valves/*.png`: the four reference images.
  - `category_detail_screen.dart`, `schematic_fullscreen_screen.dart`: show
    `Image.asset` for valves, the painter for everything else.

### Changed
- **Schematics redesigned to read like real engineering drawings**, per a
  reference (PIPEDATA) screenshot: proportional cross-sections with
  telescoping dimension lines, instead of decorative shapes with a single
  floating label.
  - **Flanges**: full rewrite — a scaled cross-section profile (body + raised
    face + through-bore) with three stacked, to-scale dimension lines (bore /
    PCD / OD) plus a thickness dimension and a bolt-hole leader, closely
    following the reference's layout.
  - **Pipes, Tees, Elbows, Caps, Socket-Welds, Threaded, Reducers,
    Weldolets/Sockolets/Threadolets**: each now labels at least one
    additional real dimension it didn't before (mating-pipe OD/ID looked up
    from the pipes dataset by DN, gasket/socket-weld thickness, both tee
    arms, both reducer ends, etc.) instead of an unlabeled or purely
    decorative body.
  - **Valves**: bonnet block + a proper 4-spoke handwheel (rim, hub, spokes)
    replacing the single crossbar-and-dot stem, for a more literal elevation
    silhouette. Deliberately did **not** add overall-height or handwheel-
    diameter dimensions like the reference shows — this app's valve dataset
    only has face-to-face length, and inventing numbers for dimensions we
    don't have data for would be a fabricated figure presented as real.
  - New shared helper `_matingPipeOd()` looks up a fitting's real mating-pipe
    OD from `PipingMasterCatalog.pipes` by DN; used across most of the
    categories above instead of leaving those bodies dimensionless.

### Changed
- **Data moved out of Dart source and into JSON assets.** All 13 component
  datasets (pipes, flanges, gaskets, valves, tees, elbows, caps, reducers,
  socket-welds, threaded, weldolets, sockolets, threadolets) now live in
  `assets/data/*.json` instead of being hardcoded Dart list/map literals in
  `lib/core/models.dart`. `PipingMasterCatalog.loadAll()` loads and parses
  them once at startup (awaited in `main()` before `runApp()`); every screen
  still reads the same static fields synchronously, so no screen code
  changed. The JSON was generated by parsing the original Dart literals
  (via Python's `ast.literal_eval`, not regex) and round-trip-validated
  against the source before the Dart literals were removed, specifically
  to avoid silently corrupting any values during the conversion.
  Practical effect: updating a dimension or adding a new size no longer
  requires touching Dart code or a full rebuild — just edit the matching
  JSON file.

### Fixed
- CI: `flutter analyze` was failing on an unadapted default
  `test/widget_test.dart` (auto-generated by `flutter create .` referencing
  a `MyApp` class that doesn't exist in this project) — replaced with a
  real smoke test against `PipingWorkstationApp`.
- Two `lib/core/*.dart` files imported `category_meta.dart` expecting it to
  transitively expose `ComponentCategory` — Dart imports aren't transitive;
  fixed to import `models.dart` (where `ComponentCategory` is actually
  defined) directly.
- `CupertinoIcons.rectangle_split_2x1` doesn't exist in the `cupertino_icons`
  package (used for the Compare button) — swapped for the verified
  `CupertinoIcons.arrow_left_right`.
- `test/engines_test.dart`: a couple of `closeTo` tolerances were tighter
  than the app's own independent-rounding behavior allows for, causing
  false-failing tests rather than catching a real calculation bug.
- All the info-level `flutter_lints` findings from the first `flutter
  analyze` run in CI (unnecessary string-interpolation braces,
  `prefer_const_*`, `prefer_final_fields`).

## Previous session

### Fixed
- Pipe data: NPS 24" Sch 80 (XS) inside diameter was `447.68mm`, corrected to
  `547.68mm` (OD − 2×wall, per the physical relationship — the old value was
  a typo, off by exactly 100mm).
- `Pipeline (Transport)` category no longer shares its accent color with
  `Valves` — it has its own (`_crimson`) per the app's own "one accent per
  category" convention.

### Added
- **mm ⇄ inch unit toggle** — a persistent-for-the-session toggle in the nav
  bar of the category detail and Pipeline screens; every length-valued field
  in Dimensions/Rating/Bolting now renders through one shared formatter.
- **Comparison mode** — pick two sizes/classes (and, for valves, two body
  types) within the same category and see both Dimensions cards at once.
- **PDF data-sheet export** — share a one-page PDF (title, standard, and the
  current item's dimension rows) via the platform share sheet.
- **Favorites** — bookmark a (category, size, sub-option) combination with a
  star toggle; a FAVORITES strip on the home screen jumps straight back to
  it. Persisted locally via `shared_preferences`.
- **Branch-reinforcement reference** — the Rating tab for Weldolets/
  Sockolets/Threadolets now shows the actual ASME B31.3 §304.3.3
  area-replacement formula and defines every term, instead of a one-line
  dismissal. It intentionally still does **not** compute a pass/fail verdict:
  that requires a design pressure/temperature and corrosion allowance this
  screen doesn't collect yet, and showing a computed answer without those
  inputs would be a guess presented as a calculation.
- App icon (flange/bolt-circle motif, matching the in-app dark/blue theme),
  wired up via `flutter_launcher_icons` with a CI step to generate it.
- CI now runs `flutter analyze` and `flutter test` before building the APK.
- `test/data_integrity_test.dart`, `test/engines_test.dart`,
  `test/units_test.dart`, `test/favorites_test.dart` — structural data
  checks (the kind that would have caught the ID typo above automatically)
  plus unit tests for the calculation engines, the unit formatter, and
  favorites persistence.
- `.gitignore`, `analysis_options.yaml` (so the existing `flutter_lints`
  dependency actually does something).

### Known gaps (tracked, not yet fixed)
- `flanges` dataset: `torqueNm` values don't progress monotonically with
  size — flagged with a `TODO(data-audit)` comment in `lib/core/models.dart`,
  not corrected yet (needs a verified source, not a guess).
- `reducers` dataset: `20"x16"` and `24"x20"` list an identical center-to-end
  length — flagged, unconfirmed against an authoritative ASME B16.9 table.
- ~~Data is still hardcoded Dart literals in `lib/core/models.dart` rather than
  JSON assets — a larger refactor, deliberately deferred to its own session
  rather than rushed alongside everything else above.~~ Done — see
  "Unreleased" above.
