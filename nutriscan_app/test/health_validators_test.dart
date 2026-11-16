import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/core/utils/health_validators.dart';

void main() {
  group('HealthValidators', () {
    test('koma desimal diterima', () {
      expect(HealthValidators.parseNum('65,5'), 65.5);
      expect(HealthValidators.weight('65,5'), isNull);
    });

    test('berat di luar rentang ditolak', () {
      expect(HealthValidators.weight('5'), isNotNull);
      expect(HealthValidators.weight('600'), isNotNull);
      expect(HealthValidators.weight('abc'), isNotNull);
      expect(HealthValidators.weight(''), isNull);
      expect(HealthValidators.weight('', required: true), isNotNull);
    });

    test('tinggi dalam meter diberi petunjuk khusus', () {
      expect(HealthValidators.height('1.65'), contains('bukan meter'));
      expect(HealthValidators.height('165'), isNull);
      expect(HealthValidators.height('400'), isNotNull);
    });

    test('usia', () {
      expect(HealthValidators.age('30'), isNull);
      expect(HealthValidators.age('0'), isNotNull);
      expect(HealthValidators.age('150'), isNotNull);
    });

    test('data kesehatan opsional: kosong valid, angka aneh ditolak', () {
      expect(HealthValidators.bloodSugar(''), isNull);
      expect(HealthValidators.bloodSugar('126'), isNull);
      expect(HealthValidators.bloodSugar('99999'), isNotNull);
      expect(HealthValidators.systolic(''), isNull);
      expect(HealthValidators.systolic('140'), isNull);
      expect(HealthValidators.systolic('20'), isNotNull);
    });
  });
}
