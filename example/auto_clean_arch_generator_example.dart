import 'package:auto_clean_arch_generator/auto_clean_arch_generator.dart';

void main() async {
  // Example usage of the generator
  final generator = CleanArchitectureGenerator('./example_output');
  print(generator.outputDir); // Use the generator variable

  // This would generate code for a sample endpoint
  // await generator.generateFromEndpoint('/api/users', 'GET');

  print(
      'Auto Clean Architecture Generator example - generates clean architecture with data-to-domain layer and core directory files');
  print('Check the README.md for usage instructions');
}
