import 'package:flutter_test/flutter_test.dart';
import 'package:pipedata_pro/core/models.dart';

void main() {
  group('PipingStressEngine.calculatePipeMAWP', () {
    test('4" Sch 40 (STD), A106 Gr. B, default (ambient) conditions', () {
      final res = PipingStressEngine.calculatePipeMAWP(
        outerDiameterMm: 114.30,
        nominalWallThkMm: 6.02,
        material: MaterialGrade.a106B,
      );

      expect(res.mawpBar, closeTo(93.4, 0.2));
      expect(res.mawpPsi, closeTo(1355, 5));
      expect(res.hydroTestBar, closeTo(res.mawpBar * 1.5, 0.05));
      expect(res.netTMin, closeTo(3.77, 0.02));
      expect(res.allowableStressMpa, 138.0);
    });

    test('hydrostatic test pressure is always 1.5x MAWP per B31.3 345.4.2', () {
      final res = PipingStressEngine.calculatePipeMAWP(
        outerDiameterMm: 60.33,
        nominalWallThkMm: 3.91,
        material: MaterialGrade.a312Tp316L,
      );
      expect(res.hydroTestBar, closeTo(res.mawpBar * 1.5, 0.05));
      expect(res.hydroTestPsi, closeTo(res.mawpPsi * 1.5, 5));
    });

    test('MAWP never goes negative for a very thin/large pipe', () {
      final res = PipingStressEngine.calculatePipeMAWP(
        outerDiameterMm: 1219.20,
        nominalWallThkMm: 1.0, // thinner than the corrosion allowance
        material: MaterialGrade.a106B,
      );
      expect(res.mawpBar, greaterThanOrEqualTo(0));
    });
  });

  group('PipelineTransportEngine.calculateMAOP', () {
    test('12" Sch 40 (STD), API 5L X52 — Barlow formula with F=0.72', () {
      final res = PipelineTransportEngine.calculateMAOP(
        outerDiameterMm: 323.85,
        nominalWallThkMm: 10.31,
        grade: PipelineGrade.x52,
      );

      expect(res.maopBar, closeTo(164.1, 0.2));
      expect(res.maopPsi, closeTo(2380, 5));
      expect(res.designFactor, 0.72);
      expect(res.smysMpa, 358.0);
    });

    test('hydrostatic test pressure is always 1.25x MAOP per B31.4 437.4.1', () {
      final res = PipelineTransportEngine.calculateMAOP(
        outerDiameterMm: 508.0,
        nominalWallThkMm: 15.09,
        grade: PipelineGrade.x60,
      );
      expect(res.hydroTestBar, closeTo(res.maopBar * 1.25, 0.05));
      expect(res.hydroTestPsi, closeTo(res.maopPsi * 1.25, 5));
    });
  });

  group('PipingMasterCatalog data integrity', () {
    test('every pipe schedule row satisfies ID = OD - 2*thk (within 0.5mm)', () {
      final failures = <String>[];
      for (final row in PipingMasterCatalog.pipes) {
        final od = (row['od'] as num).toDouble();
        final schedules = row['schedules'] as Map<String, dynamic>;
        schedules.forEach((schedName, sched) {
          final thk = (sched['thk'] as num).toDouble();
          final id = (sched['id'] as num).toDouble();
          final expectedId = od - 2 * thk;
          if ((expectedId - id).abs() > 0.5) {
            failures.add('${row['nps']} / $schedName: id=$id expected=${expectedId.toStringAsFixed(2)}');
          }
        });
      }
      expect(failures, isEmpty, reason: failures.join('; '));
    });

    test('every pipe NPS size has at least one schedule', () {
      for (final row in PipingMasterCatalog.pipes) {
        final schedules = row['schedules'] as Map<String, dynamic>;
        expect(schedules, isNotEmpty, reason: 'NPS ${row['nps']} has no schedules');
      }
    });
  });
}
