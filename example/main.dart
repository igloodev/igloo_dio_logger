import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:igloo_dio_logger/igloo_dio_logger.dart';

void main() async {
  // Create Dio instance
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // Add Colored Dio Logger
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

  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('Example 1: GET Request with Query Params');
  debugPrint('═══════════════════════════════════════════════════════\n');

  try {
    await dio.get('/posts', queryParameters: {'userId': 1, 'limit': 5});
  } catch (e) {
    debugPrint('Error: $e');
  }

  debugPrint('\n═══════════════════════════════════════════════════════');
  debugPrint('Example 2: POST Request with Body');
  debugPrint('═══════════════════════════════════════════════════════\n');

  try {
    await dio.post('/posts', data: {
      'title': 'foo',
      'body': 'bar',
      'userId': 1,
    });
  } catch (e) {
    debugPrint('Error: $e');
  }

  debugPrint('\n═══════════════════════════════════════════════════════');
  debugPrint('Example 3: 404 Not Found');
  debugPrint('═══════════════════════════════════════════════════════\n');

  try {
    await dio.get('/posts/999999');
  } catch (e) {
    debugPrint('Caught error (expected)');
  }

  debugPrint('\n═══════════════════════════════════════════════════════');
  debugPrint('Example 4: With Endpoint Filtering');
  debugPrint('═══════════════════════════════════════════════════════\n');

  final filteredDio = Dio(
    BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'),
  );

  filteredDio.interceptors.add(
    ColoredDioLogger(
      includeEndpoints: [r'/posts.*'],       // Only log /posts endpoints
      slowRequestThresholdMs: 100,           // Only log slow requests (>100ms)
    ),
  );

  try {
    await filteredDio.get('/posts/1');
    await filteredDio.get('/users/1');  // This won't be logged (filtered out)
  } catch (e) {
    debugPrint('Error: $e');
  }

  debugPrint('\n✅ All examples completed!');
}
