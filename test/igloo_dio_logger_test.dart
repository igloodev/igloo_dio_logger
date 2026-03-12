import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:igloo_dio_logger/igloo_dio_logger.dart';

void main() {
  group('IglooDioLogger', () {
    test('can be instantiated with default values', () {
      final logger = IglooDioLogger();
      expect(logger, isNotNull);
      expect(logger, isA<Interceptor>());
    });

    test('can be instantiated with custom values', () {
      final logger = IglooDioLogger(
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
      final logger = IglooDioLogger();
      dio.interceptors.add(logger);
      expect(dio.interceptors.contains(logger), isTrue);
    });

    test('throws assertion error when maxWidth is too small', () {
      expect(
        () => IglooDioLogger(maxWidth: 50),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error when maxWidth is too large', () {
      expect(
        () => IglooDioLogger(maxWidth: 300),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts maxWidth within valid range', () {
      expect(() => IglooDioLogger(maxWidth: 60), returnsNormally);
      expect(() => IglooDioLogger(maxWidth: 120), returnsNormally);
      expect(() => IglooDioLogger(maxWidth: 200), returnsNormally);
    });
  });
}
