import 'package:flutter/foundation.dart';

enum LengthUnit { mm, inch }

/// App-wide unit preference (mm vs. inch) for dimension displays.
///
/// This is deliberately a single global ValueNotifier, not a full
/// state-management dependency (Provider/Riverpod) — there is exactly one
/// app-wide setting here, so a singleton + ValueListenableBuilder is enough.
/// If more shared/global state shows up later, that's the point to bring in
/// a real state-management package instead of adding more ad-hoc globals.
class UnitsController extends ValueNotifier<LengthUnit> {
  UnitsController() : super(LengthUnit.mm);

  void toggle() => value = value == LengthUnit.mm ? LengthUnit.inch : LengthUnit.mm;

  /// Formats a millimeter value in the currently-selected unit, with suffix.
  String format(num mm, {int mmDecimals = 2, int inchDecimals = 3}) {
    if (value == LengthUnit.mm) {
      return '${mm.toStringAsFixed(mmDecimals)} mm';
    }
    final inches = mm.toDouble() / 25.4;
    return '${inches.toStringAsFixed(inchDecimals)}"';
  }
}

/// One instance shared across the whole app.
final UnitsController unitsController = UnitsController();
