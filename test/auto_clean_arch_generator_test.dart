import 'dart:io';
import 'package:auto_clean_arch_generator/auto_clean_arch_generator.dart';
import 'package:test/test.dart';

/// Tests for the Auto Clean Architecture Generator
/// A Dart package that automatically generates clean architecture code
/// with data-to-domain layer generation and core directory files for API endpoints
void main() {
  group('CleanArchitectureGenerator', () {
    late CleanArchitectureGenerator generator;
    late String testOutputDir;

    setUp(() {
      testOutputDir = './test_output_${DateTime.now().millisecondsSinceEpoch}';
      generator = CleanArchitectureGenerator(testOutputDir);
    });

    tearDown(() {
      // Clean up test output directory
      try {
        final dir = Directory(testOutputDir);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('should create generator instance', () {
      expect(generator, isNotNull);
      expect(generator.outputDir, equals(testOutputDir));
    });

    test('should have correct output directory', () {
      expect(generator.outputDir, isNotNull);
      expect(generator.outputDir, isA<String>());
    });

    // Add more tests as needed
  });
}
