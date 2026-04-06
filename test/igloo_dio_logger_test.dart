import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:igloo_dio_logger/igloo_dio_logger.dart';

/// Strips ANSI escape codes from a string for clean text assertions.
String stripAnsi(String text) => text.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

/// Captures all [debugPrint] output during [action] and returns the lines.
Future<List<String>> captureDebugPrint(Future<void> Function() action) async {
  final output = <String>[];
  final original = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    if (message != null) output.add(message);
  };
  try {
    await action();
  } finally {
    debugPrint = original;
  }
  return output;
}

void main() {
  group('IglooDioLogger — instantiation', () {
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
      expect(() => IglooDioLogger(maxWidth: 50), throwsA(isA<AssertionError>()));
    });

    test('throws assertion error when maxWidth is too large', () {
      expect(() => IglooDioLogger(maxWidth: 300), throwsA(isA<AssertionError>()));
    });

    test('accepts maxWidth within valid range', () {
      expect(() => IglooDioLogger(maxWidth: 60), returnsNormally);
      expect(() => IglooDioLogger(maxWidth: 120), returnsNormally);
      expect(() => IglooDioLogger(maxWidth: 200), returnsNormally);
    });
  });

  group('IglooDioLogger — array item comments // [n]', () {
    late IglooDioLogger logger;

    setUp(() => logger = IglooDioLogger(logResponseHeader: false));

    /// Helper: fire onResponse with a JSON body and return captured output lines.
    Future<List<String>> respondWith(dynamic body) async {
      return captureDebugPrint(() async {
        final completer = ResponseInterceptorHandler();
        logger.onResponse(
          Response(
            requestOptions: RequestOptions(path: 'https://api.example.com/test'),
            data: body,
            statusCode: 200,
          ),
          completer,
        );
      });
    }

    test('single array — items labeled // [0], // [1] (zero-based)', () async {
      final lines = await respondWith({
        'items': [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ],
      });
      final joined = lines.join('\n');
      expect(joined, contains('// [0]'));
      expect(joined, contains('// [1]'));
    });

    test('nested arrays — each level tracked independently', () async {
      final lines = await respondWith({
        'groups': [
          {
            'id': 1,
            'members': [
              {'name': 'Alice'},
              {'name': 'Bob'},
            ],
          },
          {
            'id': 2,
            'members': [
              {'name': 'Charlie'},
            ],
          },
        ],
      });
      final joined = lines.join('\n');
      // outer array: groups[0] and groups[1]
      expect(joined, contains('// [0]'));
      expect(joined, contains('// [1]'));
    });

    test('named array closing labeled with key name', () async {
      final lines = await respondWith({
        'users': [
          {'id': 1},
        ],
      });
      final joined = lines.join('\n');
      expect(joined, contains('// users'));
    });

    test('named object closing labeled with key name', () async {
      final lines = await respondWith({
        'meta': {'total': 10, 'page': 1},
      });
      final joined = lines.join('\n');
      expect(joined, contains('// meta'));
    });
  });

  group('IglooDioLogger — Items count in status line', () {
    late IglooDioLogger logger;
    setUp(() => logger = IglooDioLogger(logResponseHeader: false, logResponseBody: false));

    Future<List<String>> respondWith(dynamic body) async {
      return captureDebugPrint(() async {
        logger.onResponse(
          Response(
            requestOptions: RequestOptions(path: 'https://api.example.com/test'),
            data: body,
            statusCode: 200,
          ),
          ResponseInterceptorHandler(),
        );
      });
    }

    test('shows Items count when root response is a List', () async {
      final lines = await respondWith([
        {'id': 1},
        {'id': 2},
        {'id': 3},
      ]);
      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('Items: 3'));
    });

    test('shows Items count when response has "data" wrapper key', () async {
      final lines = await respondWith({
        'data': [{'id': 1}, {'id': 2}],
        'total': 2,
      });
      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('Items: 2'));
    });

    test('shows Items count when response has "users" wrapper key', () async {
      final lines = await respondWith({
        'users': [{'id': 1}, {'id': 2}, {'id': 3}],
        'total': 3,
      });
      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('Items: 3'));
    });

    test('does not show Items when root response is a plain Map with no list', () async {
      final lines = await respondWith({'success': true, 'message': 'ok'});
      final joined = lines.join('\n');
      expect(joined, isNot(contains('Items:')));
    });

    test('does not show Items when response has multiple matching wrapper keys', () async {
      final lines = await respondWith({
        'data': [{'id': 1}],
        'results': [{'id': 2}],
      });
      final joined = lines.join('\n');
      expect(joined, isNot(contains('Items:')));
    });
  });

  group('IglooDioLogger — calculateSize (Bug 2: Uint8List before List<int>)', () {
    late IglooDioLogger logger;
    setUp(() => logger = IglooDioLogger());

    /// We verify correct sizing via response body size shown in log output.
    Future<String> logForData(dynamic data) async {
      final lines = await captureDebugPrint(() async {
        logger.onResponse(
          Response(
            requestOptions: RequestOptions(path: 'https://api.example.com/test'),
            data: data,
            statusCode: 200,
          ),
          ResponseInterceptorHandler(),
        );
      });
      return lines.join('\n');
    }

    test('Uint8List size is reported correctly', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]); // 5 bytes
      final output = await logForData(bytes);
      expect(output, contains('5B'));
    });

    test('String size is reported correctly', () async {
      // 'hello' = 5 bytes in UTF-8
      final output = await logForData('hello');
      expect(output, contains('5B'));
    });

    test('Map size is reported correctly', () async {
      final output = await logForData({'key': 'val'});
      // {"key":"val"} = 13 bytes
      expect(output, contains('13B'));
    });
  });

  group('IglooDioLogger — error response label (Bug 1)', () {
    late IglooDioLogger logger;
    setUp(() => logger = IglooDioLogger());

    test('error response body label shows "Response:" not class name', () async {
      final lines = await captureDebugPrint(() async {
        final handler = ErrorInterceptorHandler();
        // ignore: invalid_use_of_protected_member
        unawaited(handler.future.then((_) {}, onError: (_) {}));
        logger.onError(
          DioException(
            requestOptions: RequestOptions(path: 'https://api.example.com/test'),
            response: Response(
              requestOptions: RequestOptions(path: 'https://api.example.com/test'),
              data: {'error': 'not found'},
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
          handler,
        );
      });
      final joined = lines.join('\n');
      expect(joined, contains('Response:'));
      expect(joined, isNot(contains('LoggerConstants.textResponse')));
    });
  });
}
