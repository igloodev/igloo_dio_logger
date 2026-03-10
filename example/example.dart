import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:igloo_dio_logger/igloo_dio_logger.dart';

void main() async {
  // Create Dio instance
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  // Add ColoredDioLogger interceptor
  dio.interceptors.add(
    ColoredDioLogger(
      logRequestHeader: true,
      logRequestBody: true,
      logResponseHeader: false,
      logResponseBody: true,
      logErrors: true,
      maxWidth: 90,
    ),
  );

  debugPrint('Making HTTP requests with ColoredDioLogger...\n');

  // Example 1: Successful GET request
  debugPrint('Example 1: GET request (Success)');
  try {
    await dio.get('/users/1');
  } catch (e) {
    debugPrint('Error: $e');
  }

  await Future.delayed(const Duration(seconds: 1));

  // Example 2: Successful POST request
  debugPrint('\nExample 2: POST request (Success)');
  try {
    await dio.post(
      '/posts',
      data: {
        'title': 'Test Post',
        'body': 'This is a test post created via ColoredDioLogger example',
        'userId': 1,
      },
    );
  } catch (e) {
    debugPrint('Error: $e');
  }

  await Future.delayed(const Duration(seconds: 1));

  // Example 3: 404 Error
  debugPrint('\nExample 3: GET request (404 Error)');
  try {
    await dio.get('/users/99999');
  } catch (e) {
    // Error will be logged by ColoredDioLogger
  }

  await Future.delayed(const Duration(seconds: 1));

  // Example 4: Using filters
  debugPrint('\nExample 4: Using filters (only log /posts endpoints)');
  final filteredDio = Dio(
    BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'),
  );

  filteredDio.interceptors.add(
    ColoredDioLogger(
      includeEndpoints: [r'/posts/.*'],
    ),
  );

  // This will be logged
  await filteredDio.get('/posts/1');

  await Future.delayed(const Duration(seconds: 1));

  // This will NOT be logged (doesn't match filter)
  await filteredDio.get('/users/1');

  // Example 5: Only log errors
  debugPrint('\nExample 5: Only log errors');
  final errorOnlyDio = Dio(
    BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'),
  );

  errorOnlyDio.interceptors.add(
    ColoredDioLogger(
      onlyErrors: true,
    ),
  );

  // This will NOT be logged (success)
  await errorOnlyDio.get('/users/1');

  await Future.delayed(const Duration(seconds: 1));

  // This will be logged (error)
  try {
    await errorOnlyDio.get('/invalid-endpoint');
  } catch (e) {
    // Error logged by ColoredDioLogger
  }

  debugPrint('\n✅ All examples completed!');
}
