import 'dart:io';
import 'package:auto_clean_arch_generator/src/generator.dart';

/// Auto Clean Architecture Generator
///
/// A command-line tool that automatically generates clean architecture code
/// with data-to-domain layer generation and core directory files for API endpoints.
///
/// This tool follows the same architecture patterns as the mygov_efiling project,
/// creating complete clean architecture layers (Data, Domain, Core Network) with
/// proper separation of concerns and standardized code patterns.
void main(List<String> arguments) async {
  print('===========================================');
  print('  Auto Clean Architecture Generator');
  print('===========================================');
  print('Automatically generates clean architecture code with data-to-domain layer generation');
  print('and core directory files for API endpoints\n');

  // Interactive prompts for user input
  stdout.write('Enter the API endpoint URL (e.g., /api/users or https://api.example.com/api/users): ');
  String? endpoint = stdin.readLineSync()?.trim();

  if (endpoint == null || endpoint.isEmpty) {
    print('Error: Endpoint is required.');
    return;
  }

  stdout.write('Enter the endpoint name (e.g., users, products): ');
  String? endpointName = stdin.readLineSync()?.trim();

  if (endpointName == null || endpointName.isEmpty) {
    // Extract from endpoint if not provided
    endpointName = _extractEndpointName(endpoint);
  }

  stdout.write('Enter query parameters if available (press Enter if none): ');
  String? queryParams = stdin.readLineSync()?.trim();

  stdout.write('Enter HTTP method (GET/POST/PUT/DELETE) [default: GET]: ');
  String? method = stdin.readLineSync()?.trim();
  method = method?.toUpperCase() ?? 'GET';

  // Validate method
  if (!['GET', 'POST', 'PUT', 'DELETE'].contains(method)) {
    print('Invalid method. Using GET as default.');
    method = 'GET';
  }

  stdout.write('Enter output directory for generated files [default: ./lib/feature/$endpointName]: ');
  String? outputDirInput = stdin.readLineSync()?.trim();
  String outputDir = outputDirInput?.isEmpty == true
    ? './lib/feature/$endpointName'
    : outputDirInput!;

  stdout.write('Enter project path to update pubspec.yaml [default: .]: ');
  String? projectPathInput = stdin.readLineSync()?.trim();
  String projectPath = projectPathInput?.isEmpty == true ? '.' : projectPathInput!;

  print('\nGenerating clean architecture with the following parameters:');
  print('- Endpoint: $endpoint');
  print('- Endpoint Name: $endpointName');
  print('- Method: $method');
  if (queryParams != null && queryParams.isNotEmpty) {
    print('- Query Parameters: $queryParams');
  }
  print('- Output Directory: $outputDir');
  print('- Project Path: $projectPath');
  print('');

  stdout.write('Press Enter to continue or type "cancel" to abort: ');
  String? confirmation = stdin.readLineSync()?.trim();

  if (confirmation?.toLowerCase() == 'cancel') {
    print('Operation cancelled by user.');
    return;
  }

  print('\nGenerating clean architecture with data-to-domain layer and core directory files for endpoint: $endpoint');

  final generator = CleanArchitectureGenerator(outputDir);
  await generator.generateFromEndpoint(endpoint, method, projectPath);

  print('\n===========================================');
  print('Code generation completed successfully!');
  print('Files generated in: $outputDir');
  if (projectPath != '.') {
    print('Updated pubspec.yaml in: $projectPath');
  } else {
    print('Checked current directory for pubspec.yaml update');
  }
  print('===========================================');
}

String _extractEndpointName(String endpoint) {
  // Extract endpoint name from URL
  // e.g., /api/users -> users, https://api.example.com/api/products -> products
  final pathSegments = endpoint.replaceAll(RegExp(r'https?://[^/]+'), '').split('/');
  final nonEmptySegments = pathSegments.where((segment) => segment.isNotEmpty).toList();

  if (nonEmptySegments.isNotEmpty) {
    return nonEmptySegments.last.toLowerCase();
  }

  return 'default';
}
