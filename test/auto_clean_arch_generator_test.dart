import 'package:auto_clean_arch_generator/auto_clean_arch_generator.dart';
import 'package:test/test.dart';

void main() {
  group('CleanArchitectureGenerator', () {
    test('should create generator instance', () {
      final generator = CleanArchitectureGenerator('./test_output');
      expect(generator, isNotNull);
    });

    // Add more tests as needed
  });
}