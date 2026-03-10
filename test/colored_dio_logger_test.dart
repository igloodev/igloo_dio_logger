import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:colored_dio_logger/colored_dio_logger.dart';

void main() {
  group('ColoredDioLogger', () {
    test('can be instantiated with default values', () {
      final logger = ColoredDioLogger();
      expect(logger, isNotNull);
      expect(logger, isA<Interceptor>());
    });

    test('can be instantiated with custom values', () {
      final logger = ColoredDioLogger(
        logRequestHeader: false,
        logRequestBody: false,
        logResponseHeader: true,
        logResponseBody: false,
        logErrors: true,
        maxWidth: 120,
        onlyErrors: true,
        slowRequestThresholdMs: 1000,
      );
      expect(logger, isNotNull);
    });

    test('can be added to Dio interceptors', () {
      final dio = Dio();
      final logger = ColoredDioLogger();
      dio.interceptors.add(logger);
      expect(dio.interceptors.contains(logger), isTrue);
    });

    test('throws assertion error when maxWidth is too small', () {
      expect(
        () => ColoredDioLogger(maxWidth: 50),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error when maxWidth is too large', () {
      expect(
        () => ColoredDioLogger(maxWidth: 300),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts maxWidth within valid range', () {
      expect(() => ColoredDioLogger(maxWidth: 60), returnsNormally);
      expect(() => ColoredDioLogger(maxWidth: 120), returnsNormally);
      expect(() => ColoredDioLogger(maxWidth: 200), returnsNormally);
    });
  });
}
