import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// A generator class that creates clean architecture code with data-to-domain layer generation
/// and core directory files for API endpoints following the project's architecture patterns.
///
/// The generator automatically analyzes API endpoints and creates the complete clean architecture
/// structure including:
///
/// - Core network layer (API constants, Dio client, interceptors, network info)
/// - Data layer (models, datasources, repository implementations)
/// - Domain layer (entities, repository interfaces, use cases)
///
/// It follows the same architecture patterns as the mygov_efiling project with proper
/// separation of concerns and standardized code patterns.
class CleanArchitectureGenerator {
  /// The output directory where generated files will be placed
  final String outputDir;

  final Dio _dio = Dio();

  /// Creates a new CleanArchitectureGenerator instance
  ///
  /// [outputDir] is the directory where generated files will be placed
  CleanArchitectureGenerator(this.outputDir);

  /// Generates clean architecture code for the specified endpoint
  ///
  /// [endpoint] is the API endpoint to generate code for
  /// [method] is the HTTP method (GET, POST, PUT, DELETE)
  /// [projectPath] is an optional path to the Flutter project to update pubspec.yaml
  Future<void> generateFromEndpoint(String endpoint, String method,
      [String? projectPath]) async {
    // Create the output directory if it doesn't exist
    await Directory(outputDir).create(recursive: true);

    // Fetch the API response to analyze its structure
    print('Fetching API response...');
    final apiResponse = await _fetchApiResponse(endpoint, method);

    if (apiResponse == null) {
      print(
          'Could not fetch API response. Please check the endpoint and try again.');
      return;
    }

    // Extract feature name from endpoint
    final featureName = _extractFeatureName(endpoint);

    // Generate the architecture layers
    await _generateCoreNetworkLayer(endpoint);
    await _generateDataLayer(featureName, apiResponse, endpoint, method);
    await _generateDomainLayer(featureName, apiResponse);

    // Update project pubspec.yaml with required dependencies if project path is provided
    if (projectPath != null) {
      await updateProjectPubspec(projectPath);
    }

    print('Generated clean architecture for endpoint: $endpoint');
  }

  // Method to merge with existing code
  Future<void> _mergeWithExistingCode(
      String filePath, String newContent) async {
    final file = File(filePath);

    if (await file.exists()) {
      print('File already exists: $filePath. Checking for updates...');

      final existingContent = await file.readAsString();

      // For now, we'll just append new content that doesn't already exist
      // In a more sophisticated implementation, we could parse and merge intelligently
      if (!_contentExists(existingContent, newContent)) {
        // Ask user if they want to overwrite or merge
        print('File $filePath already contains content. Overwrite? (y/n)');
        final response = stdin.readLineSync()?.toLowerCase();

        if (response == 'y' || response == 'yes') {
          await file.writeAsString(newContent);
          print('Updated file: $filePath');
        } else {
          print('Skipped updating file: $filePath');
        }
      } else {
        print('Content already exists in file: $filePath');
      }
    } else {
      // Create the file with new content
      await file.create(recursive: true);
      await file.writeAsString(newContent);
      print('Created new file: $filePath');
    }
  }

  bool _contentExists(String existingContent, String newContent) {
    // Simple check - in a real implementation, this would be more sophisticated
    return existingContent.contains(newContent);
  }

  // Enhanced generation methods that use merging
  Future<void> _generateDataLayer(String featureName,
      Map<String, dynamic> apiResponse, String endpoint, String method) async {
    final featureDir = Directory(
        path.join(outputDir, 'lib', 'feature', featureName.toLowerCase()));
    await featureDir.create(recursive: true);

    // Create data subdirectory
    final dataDir = Directory(path.join(featureDir.path, 'data'));
    await dataDir.create(recursive: true);

    // Create subdirectories
    await Directory(path.join(dataDir.path, 'datasources'))
        .create(recursive: true);
    await Directory(path.join(dataDir.path, 'models')).create(recursive: true);
    await Directory(path.join(dataDir.path, 'repositories'))
        .create(recursive: true);

    // Generate datasource
    final dataSourceFile = path.join(dataDir.path, 'datasources',
        '${featureName.toLowerCase()}_remote_data_source.dart');
    await _mergeWithExistingCode(dataSourceFile,
        _generateRemoteDataSource(featureName, endpoint, method));

    // Generate model
    final modelFile = path.join(dataDir.path, 'models',
        '${featureName.toLowerCase()}_response_model.dart');
    await _mergeWithExistingCode(
        modelFile, _generateResponseModel(featureName, apiResponse));

    // Generate repository implementation
    final repoImplFile = path.join(dataDir.path, 'repositories',
        '${featureName.toLowerCase()}_repository_impl.dart');
    await _mergeWithExistingCode(
        repoImplFile, _generateRepositoryImpl(featureName));
  }

  Future<void> _generateDomainLayer(
      String featureName, Map<String, dynamic> apiResponse) async {
    final featureDir = Directory(
        path.join(outputDir, 'lib', 'feature', featureName.toLowerCase()));

    // Create domain subdirectory
    final domainDir = Directory(path.join(featureDir.path, 'domain'));
    await domainDir.create(recursive: true);

    // Create subdirectories
    await Directory(path.join(domainDir.path, 'entities'))
        .create(recursive: true);
    await Directory(path.join(domainDir.path, 'repositories'))
        .create(recursive: true);
    await Directory(path.join(domainDir.path, 'usecases'))
        .create(recursive: true);

    // Generate entity
    final entityFile = path.join(domainDir.path, 'entities',
        '${featureName.toLowerCase()}_response_entity.dart');
    await _mergeWithExistingCode(
        entityFile, _generateResponseEntity(featureName, apiResponse));

    // Generate repository interface
    final repoInterfaceFile = path.join(domainDir.path, 'repositories',
        '${featureName.toLowerCase()}_repository.dart');
    await _mergeWithExistingCode(
        repoInterfaceFile, _generateRepositoryInterface(featureName));

    // Generate usecase
    final useCaseFile = path.join(domainDir.path, 'usecases',
        'get_${featureName.toLowerCase()}_use_case.dart');
    await _mergeWithExistingCode(useCaseFile, _generateUseCase(featureName));

    // Generate params
    final paramsFile = path.join(domainDir.path, 'usecases',
        'get_${featureName.toLowerCase()}_params.dart');
    await _mergeWithExistingCode(paramsFile, _generateParams(featureName));
  }

  String _generateRepositoryImpl(String featureName) {
    return '''import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../entities/${featureName.toLowerCase()}_response_entity.dart';
import '../repositories/${featureName.toLowerCase()}_repository.dart';
import '../usecases/get_${featureName.toLowerCase()}_params.dart';
import '../../datasources/${featureName.toLowerCase()}_remote_data_source.dart';

class ${featureName}RepositoryImpl implements ${featureName}Repository {
  final ${featureName}RemoteDataSource remoteDataSource;

  ${featureName}RepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, $featureName ResponseEntity>> get$featureName(
    Get$featureName Params params,
  ) async {
    try {
      final remoteData = await remoteDataSource.get$featureName(params);
      return Right(remoteData);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
''';
  }

  /// Updates the project's pubspec.yaml file with required dependencies
  ///
  /// [projectPath] is the path to the Flutter project to update
  Future<void> updateProjectPubspec(String projectPath) async {
    final pubspecPath = path.join(projectPath, 'pubspec.yaml');

    if (!await File(pubspecPath).exists()) {
      print(
          'pubspec.yaml not found at $pubspecPath. Skipping dependency update.');
      return;
    }

    try {
      final yamlString = await File(pubspecPath).readAsString();
      final yamlDoc = loadYamlNode(yamlString) as YamlMap;

      // Check if dependencies already exist
      final dependencies = (yamlDoc['dependencies'] as YamlMap?) ??
          YamlMap.wrap(<String, Object?>{});

      // Required dependencies for the generated code
      final requiredDeps = {
        'dio': '^5.3.2',
        'dartz': '^0.10.1',
        'equatable': '^2.0.5',
        'get': '^4.6.6',
        'connectivity_plus': '^4.0.2',
      };

      bool needsUpdate = false;
      final editor = YamlEditor(yamlString);

      for (final entry in requiredDeps.entries) {
        final depName = entry.key;
        final depVersion = entry.value;

        if (!dependencies.containsKey(depName)) {
          print('Adding dependency: $depName: $depVersion');
          editor.update(['dependencies', depName], depVersion);
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        await File(pubspecPath).writeAsString(editor.toString());
        print('Updated pubspec.yaml with required dependencies');
      } else {
        print('All required dependencies already exist in pubspec.yaml');
      }
    } catch (e) {
      print('Error updating pubspec.yaml: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchApiResponse(
      String endpoint, String method) async {
    try {
      // Determine if the endpoint is a full URL or just a path
      String fullUrl;
      if (endpoint.startsWith('http')) {
        fullUrl = endpoint;
      } else {
        // If it's just a path, we'll need to make assumptions about the base URL
        // For now, we'll use a placeholder - in a real scenario, this would be configurable
        // We'll prompt the user for the base URL if needed
        print(
            'Enter the base URL for the API (e.g., https://api.example.com):');
        final baseUrl = stdin.readLineSync()?.trim();
        if (baseUrl == null || baseUrl.isEmpty) {
          print('Base URL is required. Using default: https://api.example.com');
          fullUrl = 'https://api.example.com$endpoint';
        } else {
          fullUrl = '$baseUrl$endpoint';
        }
      }

      // Prompt user for any required headers or authentication
      print('Does this endpoint require authentication? (y/n):');
      final requiresAuth = stdin.readLineSync()?.toLowerCase() == 'y';

      if (requiresAuth) {
        print('Enter the Authorization header value (e.g., Bearer <token>):');
        final authValue = stdin.readLineSync()?.trim();
        if (authValue != null && authValue.isNotEmpty) {
          _dio.options.headers['Authorization'] = authValue;
        }
      }

      // Prepare request based on method
      Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(fullUrl);
          break;
        case 'POST':
          // For POST requests, we might need to send sample data
          print(
              'For POST requests, sample data might be needed. Press Enter to continue or provide sample data:');
          final sampleDataInput = stdin.readLineSync();
          if (sampleDataInput != null && sampleDataInput.trim().isNotEmpty) {
            final sampleData = jsonDecode(sampleDataInput);
            response = await _dio.post(fullUrl, data: sampleData);
          } else {
            response = await _dio.post(fullUrl);
          }
          break;
        case 'PUT':
          print(
              'For PUT requests, sample data might be needed. Press Enter to continue or provide sample data:');
          final sampleDataInput = stdin.readLineSync();
          if (sampleDataInput != null && sampleDataInput.trim().isNotEmpty) {
            final sampleData = jsonDecode(sampleDataInput);
            response = await _dio.put(fullUrl, data: sampleData);
          } else {
            response = await _dio.put(fullUrl);
          }
          break;
        case 'DELETE':
          response = await _dio.delete(fullUrl);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        try {
          return jsonDecode(response.data) as Map<String, dynamic>;
        } catch (e) {
          print('Could not parse response as JSON: $e');
          print('Response received: ${response.data}');
          return null;
        }
      } else if (response.data is List) {
        // If the response is a list, wrap it in a map with a generic key
        return {'data': response.data};
      } else {
        print('Unexpected response format: ${response.data.runtimeType}');
        return null;
      }
    } catch (e) {
      print('Error fetching API response: $e');
      print(
          'Please make sure the endpoint is accessible and the method is correct.');
      return null;
    }
  }

  /// Extracts the feature name from an endpoint URL
  ///
  /// [endpoint] is the API endpoint URL
  /// Returns the feature name in PascalCase
  String _extractFeatureName(String endpoint) {
    // Extract feature name from endpoint URL
    // e.g., /api/users/profile -> users
    final segments = endpoint.split('/');
    // Find the first non-empty segment after api or after the domain
    for (final segment in segments) {
      if (segment.isNotEmpty && segment != 'api') {
        return ReCase(segment).pascalCase;
      }
    }
    return 'DefaultFeature';
  }

  /// Generates the core network layer files
  ///
  /// [newEndpoint] is an optional endpoint to add to API constants
  Future<void> _generateCoreNetworkLayer([String? newEndpoint]) async {
    final networkDir =
        Directory(path.join(outputDir, 'lib', 'core', 'network'));
    await networkDir.create(recursive: true);

    // Generate API constants
    String apiConstantsContent = _generateApiConstants();

    // If there's a new endpoint to add, append it to the constants
    if (newEndpoint != null) {
      // Find the closing brace and insert before it
      final lines = apiConstantsContent.split('\n');
      final newLines = <String>[];

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim() == '// Add your endpoints here') {
          newLines.add('  // Generated endpoint');
          newLines.add(_addEndpointToApiConstants(newEndpoint));
          newLines.add(lines[i]); // Add the comment line
        } else {
          newLines.add(lines[i]);
        }
      }

      apiConstantsContent = newLines.join('\n');
    }

    final apiConstantsFile = path.join(networkDir.path, 'api_constants.dart');
    await _mergeWithExistingCode(apiConstantsFile, apiConstantsContent);

    // Generate Dio client
    final dioClientFile = path.join(networkDir.path, 'dio_client.dart');
    await _mergeWithExistingCode(dioClientFile, _generateDioClient());

    // Generate authorization interceptor
    final interceptorDir = Directory(path.join(networkDir.path, 'interceptor'));
    await interceptorDir.create(recursive: true);

    final authInterceptorFile =
        path.join(interceptorDir.path, 'authorization_interceptor.dart');
    await _mergeWithExistingCode(
        authInterceptorFile, _generateAuthInterceptor());

    // Generate network info
    final networkInfoFile = path.join(networkDir.path, 'network_info.dart');
    await _mergeWithExistingCode(networkInfoFile, _generateNetworkInfo());

    // Generate network service
    final networkServiceFile =
        path.join(networkDir.path, 'network_service.dart');
    await _mergeWithExistingCode(networkServiceFile, _generateNetworkService());
  }

  /// Generates API constants file content
  ///
  /// Returns the content for the API constants file
  String _generateApiConstants() {
    return '''final class ApiList {
  ApiList._();

  // --- Base URLs ---
  static const apiBaseUrl = "https://your-api-base-url.com";
  static const doptorApiBaseUrl = "https://api-stage.doptor.gov.bd";

  // --- Generated API Endpoints ---
  // Add your endpoints here
}
''';
  }

  /// Adds an endpoint to the API constants
  ///
  /// [endpoint] is the endpoint to add
  /// Returns the constant declaration for the endpoint
  String _addEndpointToApiConstants(String endpoint) {
    // Convert endpoint path to a variable name (e.g., /api/users -> apiUsers)
    final segments = endpoint.replaceAll(RegExp(r'^/+|/+$'), '').split('/');
    String variableName = '';

    if (segments.length > 1) {
      variableName = segments.skip(1).map((s) => ReCase(s).camelCase).join('');
    } else {
      variableName = ReCase(segments.first).camelCase;
    }

    // If the variable name is empty, use a default
    if (variableName.isEmpty) {
      variableName = 'generatedEndpoint';
    }

    return '  static const $variableName = "$endpoint";';
  }

  /// Generates Dio client file content
  ///
  /// Returns the content for the Dio client file
  String _generateDioClient() {
    return '''import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../error/exceptions.dart'; // your custom exceptions with message, status, code
import 'api_constants.dart';
import 'interceptor/authorization_interceptor.dart';

class DioClient {
  final Dio _dio;

  DioClient(this._dio) {
    _dio
      ..options.baseUrl = ApiList.apiBaseUrl
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.responseType = ResponseType.json
      ..options.headers = {'Accept': 'application/json'};

    // keep this — token will be added automatically
    _dio.interceptors.add(AuthorizationInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  // =====================
  // GET
  // =====================
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // =====================
  // POST
  // =====================
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // =====================
  // PUT
  // =====================
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // =====================
  // DELETE
  // =====================
  Future<dynamic> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ============================
  // MERGED EXCEPTION HANDLER
  // ============================
  void _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiTimeoutException();

      case DioExceptionType.badResponse:
        final data = e.response?.data;

        final serverMessage = data != null && data['message'] != null
            ? data['message'].toString()
            : 'Server Error';

        final serverStatus = data != null && data['status'] != null
            ? data['status'].toString()
            : 'error';

        switch (e.response?.statusCode) {
          case 400:
          case 422:
            throw BadRequestException(
              message: serverMessage,
              status: serverStatus,
              code: e.response?.statusCode,
            );

          case 401:
            throw UnauthorizedException(
              message: serverMessage,
              status: serverStatus,
              code: e.response?.statusCode,
            );

          case 404:
            throw ServerException(
              message: serverMessage,
              status: serverStatus,
              code: e.response?.statusCode,
            );

          default:
            throw ServerException(
              message: serverMessage,
              status: serverStatus,
              code: e.response?.statusCode,
            );
        }

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          throw NoInternetException();
        }
        throw UnknownApiException();

      case DioExceptionType.cancel:
        throw RequestCancelledException();

      case DioExceptionType.badCertificate:
        throw BadRequestException(message: "Bad certificate.");
    }
  }
}
''';
  }

  /// Generates authorization interceptor file content
  ///
  /// Returns the content for the authorization interceptor file
  String _generateAuthInterceptor() {
    return '''import 'package:dio/dio.dart';
import 'package:mygov_efiling/core/constant/app_constant.dart';

class AuthorizationInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = AppConstant.kKeyToken;
    if (token != null) {
      options.headers['Authorization'] = "Bearer \$token";
    }
    handler.next(options); // Continue with the Request
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle token expiration (401 errors)
    if (err.response?.statusCode == 401) {
      // Clear the token if it's expired
      AppConstant.kKeyToken = null;
    }
    handler.next(err); // Continue with the error
  }
}
''';
  }

  /// Generates network info file content
  ///
  /// Returns the content for the network info file
  String _generateNetworkInfo() {
    return '''import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    var connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
''';
  }

  /// Generates network service file content
  ///
  /// Returns the content for the network service file
  String _generateNetworkService() {
    return '''import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  Future<bool> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi)) {
      return true;
    } else {
      return false;
    }
  }
}

enum ConnectionStatus {
  checking,
  connected,
  disconnected,
}
''';
  }

  /// Generates remote data source file content
  ///
  /// [featureName] is the name of the feature
  /// [endpoint] is the API endpoint
  /// [method] is the HTTP method
  /// Returns the content for the remote data source file
  String _generateRemoteDataSource(
      String featureName, String endpoint, String method) {
    String methodSpecificCode = '';

    switch (method.toUpperCase()) {
      case 'GET':
        methodSpecificCode = '''
      final response = await dio.get(
        ApiList.${_camelCase(endpoint)},
        queryParameters: requestData,
      );
        ''';
        break;
      case 'POST':
        // Check if this is likely a form submission (which needs FormData) or JSON
        methodSpecificCode = '''
      final formData = FormData.fromMap(requestData);

      final response = await dio.post(
        ApiList.${_camelCase(endpoint)},
        data: formData,
      );
        ''';
        break;
      case 'PUT':
        methodSpecificCode = '''
      final formData = FormData.fromMap(requestData);

      final response = await dio.put(
        ApiList.${_camelCase(endpoint)},
        data: formData,
      );
        ''';
        break;
      case 'DELETE':
        methodSpecificCode = '''
      final response = await dio.delete(
        ApiList.${_camelCase(endpoint)},
        data: json.encode(requestData),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
        ''';
        break;
      default:
        methodSpecificCode = '''
      Response response;
      switch ('${method.toUpperCase()}') {
        case 'GET':
          response = await dio.get(
            ApiList.${_camelCase(endpoint)},
            queryParameters: requestData,
          );
          break;
        case 'POST':
          final formData = FormData.fromMap(requestData);
          response = await dio.post(
            ApiList.${_camelCase(endpoint)},
            data: formData,
          );
          break;
        case 'PUT':
          final formData = FormData.fromMap(requestData);
          response = await dio.put(
            ApiList.${_camelCase(endpoint)},
            data: formData,
          );
          break;
        case 'DELETE':
          response = await dio.delete(
            ApiList.${_camelCase(endpoint)},
            data: json.encode(requestData),
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          break;
        default:
          throw ServerException(message: 'Unsupported HTTP method');
      }
        ''';
    }

    return '''import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/usecases/get_${featureName.toLowerCase()}_params.dart';
import '../models/${featureName.toLowerCase()}_response_model.dart';

abstract class $featureName RemoteDataSource {
  Future<$featureName ResponseModel> get$featureName(Get$featureName Params params);
}

class $featureName RemoteDataSourceImpl implements $featureName RemoteDataSource {
  final DioClient dio;

  ${featureName}RemoteDataSourceImpl({required this.dio});

  @override
  Future<$featureName ResponseModel> get$featureName(Get$featureName Params params) async {
    try {
      // Prepare request data based on params
      final requestData = params.toJson();

      $methodSpecificCode

      // Directly return the model since the DioClient returns the response body
      if (response != null && response is Map<String, dynamic>) {
        return ${featureName}ResponseModel.fromJson(response);
      } else {
        throw ServerException(message: 'Invalid response format from server.');
      }
    } on AppException {
      rethrow;
    }
  }
}
''';
  }

  String _camelCase(String str) {
    // Convert endpoint to camelCase for use in code
    // e.g., /api/users -> apiUsers
    final segments = str.replaceAll(RegExp(r'^/+|/+$'), '').split('/');
    if (segments.length > 1) {
      return segments.skip(1).map((s) => ReCase(s).camelCase).join('');
    } else {
      return ReCase(segments.first).camelCase;
    }
  }

  /// Generates response model file content
  ///
  /// [featureName] is the name of the feature
  /// [apiResponse] is the API response structure
  /// Returns the content for the response model file
  String _generateResponseModel(
      String featureName, Map<String, dynamic> apiResponse) {
    final fields = _generateFieldsFromResponse(apiResponse, 'Model');
    final fromJsonMethod = _generateFromJsonMethod(apiResponse, featureName);

    // Generate nested classes
    final nestedClassesBuffer = StringBuffer();
    _generateNestedClasses(
        apiResponse, featureName, 'Model', nestedClassesBuffer);
    final nestedClasses = nestedClassesBuffer.toString();

    return '''import '../../../../core/utils/data_parser.dart';
import '../../domain/entities/${featureName.toLowerCase()}_response_entity.dart';

$nestedClasses

class ${featureName}ResponseModel extends ${featureName}ResponseEntity {
$fields

  const ${featureName}ResponseModel({
${_generateConstructorParams(apiResponse)}
  });

  factory ${featureName}ResponseModel.fromJson(Map<String, dynamic> json) {
$fromJsonMethod
  }
}
''';
  }

  String _generateFieldsFromResponse(
      Map<String, dynamic> response, String suffix) {
    final buffer = StringBuffer();

    for (final entry in response.entries) {
      final fieldName = entry.key;
      final value = entry.value;
      final fieldType = _inferFieldType(value, fieldName, suffix);

      buffer.writeln('  final $fieldType $fieldName;');
    }

    return buffer.toString();
  }

  String _inferFieldType(dynamic value, String fieldName, String suffix) {
    if (value == null) return 'dynamic';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is String) return 'String';
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final elementType = _inferFieldType(value.first, fieldName, suffix);
      return 'List<$elementType>';
    }
    if (value is Map<String, dynamic>) {
      // Create a model/entity for nested objects
      final nestedTypeName = _generateNestedTypeName(fieldName, suffix);
      return nestedTypeName;
    }
    return 'dynamic';
  }

  String _generateNestedTypeName(String fieldName, String suffix) {
    // Convert field name to PascalCase for class name
    return '${ReCase(fieldName).pascalCase}$suffix';
  }

  // Generate nested model/entity classes
  void _generateNestedClasses(Map<String, dynamic> response, String featureName,
      String suffix, StringBuffer buffer) {
    for (final entry in response.entries) {
      final fieldName = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        // Generate a nested class for this map
        final nestedClassName = _generateNestedTypeName(fieldName, suffix);
        final nestedFields = _generateFieldsFromResponse(value, suffix);
        final nestedConstructorParams = _generateConstructorParams(value);

        buffer.writeln('');
        buffer.writeln('class $nestedClassName {');
        buffer.writeln(nestedFields);
        buffer.writeln('');
        buffer.writeln('  $nestedClassName({');
        buffer.writeln(nestedConstructorParams);
        buffer.writeln('  });');
        buffer.writeln('');
        buffer.writeln(
            '  factory $nestedClassName.fromJson(Map<String, dynamic> json) {');
        buffer.writeln('    return $nestedClassName(');
        for (final fieldEntry in value.entries) {
          final fieldKey = fieldEntry.key;
          final fieldValue = fieldEntry.value;

          if (fieldValue is Map<String, dynamic>) {
            final nestedNestedClassName =
                _generateNestedTypeName(fieldKey, suffix);
            buffer.writeln(
                '      $fieldKey: json[\'$fieldKey\'] != null ? $nestedNestedClassName.fromJson(json[\'$fieldKey\'] as Map<String, dynamic>) : null,');
          } else if (fieldValue is List && fieldValue.isNotEmpty) {
            final elementType =
                _inferFieldType(fieldValue.first, fieldKey, suffix);
            if (elementType.contains(suffix)) {
              // This is a nested list of objects
              buffer.writeln(
                  '      $fieldKey: json[\'$fieldKey\'] != null ? (json[\'$fieldKey\'] as List).map((e) => ${elementType.replaceFirst('List<', '').replaceAll('>', '')}.fromJson(e as Map<String, dynamic>)).toList() : [],');
            } else {
              buffer.writeln(
                  '      $fieldKey: json[\'$fieldKey\'] != null ? List<$elementType>.from(json[\'$fieldKey\']) : [],');
            }
          } else {
            buffer.writeln('      $fieldKey: json[\'$fieldKey\'],');
          }
        }
        buffer.writeln('    );');
        buffer.writeln('  }');
        buffer.writeln('}');
        buffer.writeln('');
      } else if (value is List &&
          value.isNotEmpty &&
          value.first is Map<String, dynamic>) {
        // Generate a class for list items
        final listItemValue = value.first as Map<String, dynamic>;
        final nestedClassName = _generateNestedTypeName(fieldName, suffix)
            .replaceAll(suffix, '${ReCase(fieldName).pascalCase}s$suffix');
        final nestedFields = _generateFieldsFromResponse(listItemValue, suffix);
        final nestedConstructorParams =
            _generateConstructorParams(listItemValue);

        buffer.writeln('');
        buffer.writeln('class $nestedClassName {');
        buffer.writeln(nestedFields);
        buffer.writeln('');
        buffer.writeln('  $nestedClassName({');
        buffer.writeln(nestedConstructorParams);
        buffer.writeln('  });');
        buffer.writeln('');
        buffer.writeln(
            '  factory $nestedClassName.fromJson(Map<String, dynamic> json) {');
        buffer.writeln('    return $nestedClassName(');
        for (final fieldEntry in listItemValue.entries) {
          final fieldKey = fieldEntry.key;
          final fieldValue = fieldEntry.value;

          if (fieldValue is Map<String, dynamic>) {
            final nestedNestedClassName =
                _generateNestedTypeName(fieldKey, suffix);
            buffer.writeln(
                '      $fieldKey: json[\'$fieldKey\'] != null ? $nestedNestedClassName.fromJson(json[\'$fieldKey\'] as Map<String, dynamic>) : null,');
          } else {
            buffer.writeln('      $fieldKey: json[\'$fieldKey\'],');
          }
        }
        buffer.writeln('    );');
        buffer.writeln('  }');
        buffer.writeln('}');
        buffer.writeln('');
      }
    }
  }

  String _generateConstructorParams(Map<String, dynamic> response) {
    final buffer = StringBuffer();

    for (final entry in response.entries) {
      final fieldName = entry.key;
      buffer.writeln('    required super.$fieldName,');
    }

    return buffer.toString();
  }

  String _generateFromJsonMethod(
      Map<String, dynamic> response, String featureName) {
    final buffer = StringBuffer();

    // Add the creation of the object
    buffer.writeln('    return ${featureName}ResponseModel(');
    for (final entry in response.entries) {
      final fieldName = entry.key;
      final value = entry.value;

      if (value is List && value.isNotEmpty) {
        final elementType = _inferFieldType(value.first, fieldName, 'Model');
        if (elementType.contains('Model')) {
          // This is a list of nested objects
          buffer.writeln(
              '      $fieldName: json[\'$fieldName\'] != null ? (json[\'$fieldName\'] as List).map((e) => ${elementType.replaceFirst('List<', '').replaceAll('>', '')}.fromJson(e as Map<String, dynamic>)).toList() : [],');
        } else {
          // This is a list of primitive types
          buffer.writeln(
              '      $fieldName: safeParse<List<$elementType>>(json[\'$fieldName\'], \'$fieldName\'),');
        }
      } else if (value is Map<String, dynamic>) {
        final nestedType = _inferFieldType(value, fieldName, 'Model');
        buffer.writeln(
            '      $fieldName: json[\'$fieldName\'] != null ? ${nestedType.replaceFirst('Entity', 'Model')}.fromJson(json[\'$fieldName\'] as Map<String, dynamic>) : null,');
      } else {
        // Use safeParse for primitive types
        final type = _inferFieldType(value, fieldName, 'Model');
        buffer.writeln(
            '      $fieldName: safeParse<$type>(json[\'$fieldName\'], \'$fieldName\'),');
      }
    }
    buffer.writeln('    );');

    return buffer.toString();
  }

  /// Generates response entity file content
  ///
  /// [featureName] is the name of the feature
  /// [apiResponse] is the API response structure
  /// Returns the content for the response entity file
  String _generateResponseEntity(
      String featureName, Map<String, dynamic> apiResponse) {
    final fields = _generateFieldsFromResponse(apiResponse, 'Entity');

    // Generate nested classes
    final nestedClassesBuffer = StringBuffer();
    _generateNestedClasses(
        apiResponse, featureName, 'Entity', nestedClassesBuffer);
    final nestedClasses = nestedClassesBuffer.toString();

    return '''import 'package:equatable/equatable.dart';

$nestedClasses

class ${featureName}ResponseEntity extends Equatable {
$fields

  const ${featureName}ResponseEntity({
${_generateConstructorParams(apiResponse)}
  });

  @override
  List<Object?> get props => [${apiResponse.keys.map((key) => key).join(', ')}];
}
''';
  }

  /// Generates repository interface file content
  ///
  /// [featureName] is the name of the feature
  /// Returns the content for the repository interface file
  String _generateRepositoryInterface(String featureName) {
    return '''import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${featureName.toLowerCase()}_response_entity.dart';
import '../usecases/get_${featureName.toLowerCase()}_params.dart';

abstract class ${featureName}Repository {
  Future<Either<Failure, ${featureName}ResponseEntity>> get$featureName(
    Get${featureName}Params params,
  );
}
''';
  }

  /// Generates use case file content
  ///
  /// [featureName] is the name of the feature
  /// Returns the content for the use case file
  String _generateUseCase(String featureName) {
    return '''import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${featureName.toLowerCase()}_response_entity.dart';
import '../repositories/${featureName.toLowerCase()}_repository.dart';
import 'get_${featureName.toLowerCase()}_params.dart';

class Get${featureName}UseCase {
  final ${featureName}Repository repository;

  Get${featureName}UseCase(this.repository);

  Future<Either<Failure, ${featureName}ResponseEntity>> call(
      Get${featureName}Params params) async {
    return await repository.get$featureName(params);
  }
}
''';
  }

  /// Generates parameters file content
  ///
  /// [featureName] is the name of the feature
  /// Returns the content for the parameters file
  String _generateParams(String featureName) {
    return '''import 'package:equatable/equatable.dart';

class Get$featureName Params extends Equatable {
  // TODO: Define your parameters based on the API requirements

  const Get$featureName Params({
    // Add your parameters here
  });

  @override
  List<Object?> get props => [];

  Map<String, dynamic> toJson() => {
    // Add your parameters here
  };
}
''';
  }
}
