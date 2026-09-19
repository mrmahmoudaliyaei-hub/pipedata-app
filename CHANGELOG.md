# Changelog

All notable changes to Piping Data Pro are logged here. Dates are UTC.

## Unreleased

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
- Data is still hardcoded Dart literals in `lib/core/models.dart` rather than
  JSON assets — a larger refactor, deliberately deferred to its own session
  rather than rushed alongside everything else above.
