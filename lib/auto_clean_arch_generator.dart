/// Auto Clean Architecture Generator
///
/// A Dart package that automatically generates clean architecture code
/// with data-to-domain layer generation and core directory files for API endpoints
/// following the project's architecture patterns.
///
/// ## Features
///
/// - Automatically analyzes API endpoints and generates corresponding clean architecture layers
/// - Generates data layer (models, datasources, repositories)
/// - Generates domain layer (entities, repositories interface, usecases)
/// - Generates core network files (API constants, Dio client, interceptors)
/// - Merges with existing code to avoid overwriting
/// - Follows the same architecture patterns as the mygov_efiling project
///
/// ## Usage
///
/// ```dart
/// import 'package:auto_clean_arch_generator/auto_clean_arch_generator.dart';
///
/// void main() async {
///   final generator = CleanArchitectureGenerator('./output_dir');
///   await generator.generateFromEndpoint('/api/users', 'GET');
/// }
/// ```
///
/// ## Generated Architecture Structure
///
/// The package generates the following structure:
///
/// ```
/// lib/
/// ├── core/
/// │   └── network/
/// │       ├── api_constants.dart
/// │       ├── dio_client.dart
/// │       ├── interceptor/
/// │       │   └── authorization_interceptor.dart
/// │       ├── network_info.dart
/// │       └── network_service.dart
/// └── feature/
///     └── [feature_name]/
///         ├── data/
///         │   ├── datasources/
///         │   ├── models/
///         │   └── repositories/
///         └── domain/
///             ├── entities/
///             ├── repositories/
///             └── usecases/
/// ```
///
/// ## Architecture Patterns
///
/// This package follows the same clean architecture patterns as the mygov_efiling project:
///
/// - **Presentation Layer**: UI and controllers
/// - **Domain Layer**: Business logic, entities, repositories interface, and use cases
/// - **Data Layer**: Data sources, models, and repository implementations
///
/// ## Dependencies Added
///
/// The package automatically adds these dependencies to the target project's pubspec.yaml:
/// - `dio`: For HTTP requests
/// - `dartz`: For functional programming patterns (Either, Option, etc.)
/// - `equatable`: For value equality comparisons
/// - `get`: For state management (optional)
/// - `connectivity_plus`: For network connectivity checks
///
/// ## System Requirements
///
/// - Dart SDK: Version 3.0.0 or higher
/// - Operating System: Linux, macOS, or Windows
/// - Git: For version control and package management
///
library;

export 'src/generator.dart';
