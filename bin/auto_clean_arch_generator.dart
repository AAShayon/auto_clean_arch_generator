import 'package:args/args.dart';
import 'package:auto_clean_arch_generator/src/generator.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('endpoint', abbr: 'e', help: 'API endpoint URL to generate code for')
    ..addOption('method', abbr: 'm', help: 'HTTP method (GET, POST, PUT, DELETE)', defaultsTo: 'GET')
    ..addOption('output', abbr: 'o', help: 'Output directory for generated files', defaultsTo: './generated')
    ..addOption('project-path', abbr: 'p', help: 'Path to the Flutter project to update pubspec.yaml', defaultsTo: '.')
    ..addFlag('help', abbr: 'h', help: 'Show this help message', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool || arguments.isEmpty) {
      print('Auto Clean Architecture Generator');
      print('Automatically generates clean architecture code for API endpoints\n');
      print(parser.usage);
      return;
    }

    if (results['endpoint'] == null) {
      print('Error: Endpoint is required. Use -e or --endpoint to specify the API endpoint.');
      print(parser.usage);
      return;
    }

    final endpoint = results['endpoint'] as String;
    final method = results['method'] as String;
    final outputDir = results['output'] as String;
    final projectPath = results['project-path'] as String;

    print('Welcome to Auto Clean Architecture Generator!');
    print('Analyzing endpoint: $endpoint');

    final generator = CleanArchitectureGenerator(outputDir);
    await generator.generateFromEndpoint(endpoint, method.toUpperCase(), projectPath);

    print('\nCode generation completed successfully!');
    print('Files generated in: $outputDir');
    if (projectPath != '.') {
      print('Updated pubspec.yaml in: $projectPath');
    } else {
      print('Checked current directory for pubspec.yaml update');
    }

  } catch (e) {
    print('Error: $e');
  }
}