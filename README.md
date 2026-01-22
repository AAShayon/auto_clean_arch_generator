# Auto Clean Architecture Generator

A Flutter/Dart package that automatically generates clean architecture code for API endpoints following the project's architecture patterns.

## Features

- Automatically analyzes API endpoints and generates corresponding clean architecture layers
- Generates data layer (models, datasources, repositories)
- Generates domain layer (entities, repositories interface, usecases)
- Generates core network files (API constants, Dio client, interceptors)
- Merges with existing code to avoid overwriting
- Follows the same architecture patterns as the mygov_efiling project

## Installation

To use this package globally:

```bash
dart pub global activate auto_clean_arch_generator
```

Or add as a development dependency:

```yaml
dev_dependencies:
  auto_clean_arch_generator: ^0.1.0
```

## Usage

```bash
# Basic usage
dart run auto_clean_arch_generator -e /api/users -m GET

# With custom output directory
dart run auto_clean_arch_generator -e /api/users -m GET -o ./lib/generated

# For POST requests with sample data
dart run auto_clean_arch_generator -e /api/users -m POST
```

## Generated Structure

The package generates the following structure:

```
lib/
├── core/
│   └── network/
│       ├── api_constants.dart
│       ├── dio_client.dart
│       ├── interceptor/
│       │   └── authorization_interceptor.dart
│       ├── network_info.dart
│       └── network_service.dart
└── feature/
    └── [feature_name]/
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        └── domain/
            ├── entities/
            ├── repositories/
            └── usecases/
```

## Architecture Patterns

This package follows the same clean architecture patterns as the mygov_efiling project:

- **Presentation Layer**: UI and controllers
- **Domain Layer**: Business logic, entities, repositories interface, and use cases
- **Data Layer**: Data sources, models, and repository implementations

## License

MIT