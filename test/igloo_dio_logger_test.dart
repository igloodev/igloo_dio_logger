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

  group('IglooDioLogger — calculateSize', () {
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

  group('IglooDioLogger — cURL logging', () {
    Future<String> curlOutputFor(RequestOptions options) async {
      final logger = IglooDioLogger(logCurl: true);
      final lines = await captureDebugPrint(() async {
        logger.onRequest(options, RequestInterceptorHandler());
      });
      return stripAnsi(lines.join('\n'));
    }

    test('cURL block title is printed', () async {
      final output = await curlOutputFor(
        RequestOptions(path: 'https://api.example.com/users', method: 'GET'),
      );
      expect(output, contains('cURL'));
    });

    test('GET request omits -X GET', () async {
      final output = await curlOutputFor(
        RequestOptions(path: 'https://api.example.com/users', method: 'GET'),
      );
      expect(output, isNot(contains('-X GET')));
    });

    test('POST request includes -X POST', () async {
      final output = await curlOutputFor(
        RequestOptions(path: 'https://api.example.com/users', method: 'POST'),
      );
      expect(output, contains('-X POST'));
    });

    test('includes -L for redirect following', () async {
      final output = await curlOutputFor(
        RequestOptions(path: 'https://api.example.com/users', method: 'GET'),
      );
      expect(output, contains('-L'));
    });

    test('JSON body included with -d flag', () async {
      final output = await curlOutputFor(
        RequestOptions(
          path: 'https://api.example.com/users',
          method: 'POST',
          data: {'name': 'Alice', 'age': 30},
        ),
      );
      expect(output, contains("-d '"));
      expect(output, contains('Alice'));
    });

    test('String body included with -d flag', () async {
      final output = await curlOutputFor(
        RequestOptions(
          path: 'https://api.example.com/raw',
          method: 'POST',
          data: 'raw body text',
        ),
      );
      expect(output, contains("-d 'raw body text'"));
    });

    test('headers included as -H flags', () async {
      final output = await curlOutputFor(
        RequestOptions(
          path: 'https://api.example.com/users',
          method: 'GET',
          headers: {'Authorization': 'Bearer token123', 'Accept': 'application/json'},
        ),
      );
      expect(output, contains("-H 'Authorization: Bearer token123'"));
      expect(output, contains("-H 'Accept: application/json'"));
    });

    test('URL is included as last argument', () async {
      final output = await curlOutputFor(
        RequestOptions(path: 'https://api.example.com/users', method: 'GET'),
      );
      expect(output, contains("'https://api.example.com/users'"));
    });

    test('single quotes in body values are escaped', () async {
      final output = await curlOutputFor(
        RequestOptions(
          path: 'https://api.example.com/users',
          method: 'POST',
          data: "it's a test",
        ),
      );
      // it's → it'\''s
      expect(output, contains(r"it'\''s"));
    });

    test('binary body shows placeholder note and omits -d', () async {
      final output = await curlOutputFor(
        RequestOptions(
          path: 'https://api.example.com/upload',
          method: 'POST',
          data: Uint8List.fromList([1, 2, 3]),
        ),
      );
      expect(output, contains('Binary body'));
      expect(output, isNot(contains("-d '")));
    });

    test('FormData text fields use --form flags', () async {
      final formData = FormData.fromMap({'username': 'alice', 'role': 'admin'});
      final output = await curlOutputFor(
        RequestOptions(
          path: 'https://api.example.com/login',
          method: 'POST',
          data: formData,
        ),
      );
      expect(output, contains('--form'));
      expect(output, contains('username'));
      expect(output, contains('alice'));
    });

    test('FormData file fields use --form @filename placeholder', () async {
      final formData = FormData()
        ..files.add(MapEntry(
          'avatar',
          MultipartFile.fromBytes([1, 2, 3], filename: 'photo.jpg'),
        ));
      final output = await curlOutputFor(
        RequestOptions(
          path: 'https://api.example.com/upload',
          method: 'POST',
          data: formData,
        ),
      );
      expect(output, contains('--form'));
      expect(output, contains('avatar'));
      expect(output, contains('@"photo.jpg"'));
    });

    test('logCurl: false does not print cURL block', () async {
      final logger = IglooDioLogger(logCurl: false);
      final lines = await captureDebugPrint(() async {
        logger.onRequest(
          RequestOptions(path: 'https://api.example.com/users', method: 'GET'),
          RequestInterceptorHandler(),
        );
      });
      final output = stripAnsi(lines.join('\n'));
      expect(output, isNot(contains('cURL')));
    });
  });

  group('IglooDioLogger — endpoint filtering', () {
    Future<List<String>> requestFor(String path, {List<String>? include, List<String>? exclude}) async {
      final logger = IglooDioLogger(
        includeEndpoints: include,
        excludeEndpoints: exclude,
      );
      return captureDebugPrint(() async {
        logger.onRequest(
          RequestOptions(path: 'https://api.example.com$path', method: 'GET'),
          RequestInterceptorHandler(),
        );
      });
    }

    test('includeEndpoints allows matching path', () async {
      final lines = await requestFor('/api/v1/users', include: [r'/api/v1/.*']);
      expect(stripAnsi(lines.join('\n')), contains('GET'));
    });

    test('includeEndpoints suppresses non-matching path', () async {
      final lines = await requestFor('/health', include: [r'/api/v1/.*']);
      expect(lines.where((l) => stripAnsi(l).contains('GET')), isEmpty);
    });

    test('excludeEndpoints suppresses matching path', () async {
      final lines = await requestFor('/api/v1/health', exclude: [r'/api/v1/health']);
      expect(lines.where((l) => stripAnsi(l).contains('GET')), isEmpty);
    });

    test('excludeEndpoints allows non-matching path', () async {
      final lines = await requestFor('/api/v1/users', exclude: [r'/api/v1/health']);
      expect(stripAnsi(lines.join('\n')), contains('GET'));
    });

    test('anchored pattern matches path only, not full URL', () async {
      // r'^/api' should match /api/v1/users even when full URL is passed
      final lines = await requestFor('/api/v1/users', include: [r'^/api']);
      expect(stripAnsi(lines.join('\n')), contains('GET'));
    });
  });

  group('IglooDioLogger — onlyErrors filter', () {
    Future<List<String>> respondWith(int statusCode) async {
      final logger = IglooDioLogger(onlyErrors: true, logResponseBody: false);
      return captureDebugPrint(() async {
        logger.onResponse(
          Response(
            requestOptions: RequestOptions(path: 'https://api.example.com/test'),
            data: null,
            statusCode: statusCode,
          ),
          ResponseInterceptorHandler(),
        );
      });
    }

    test('onlyErrors: true suppresses 200 response', () async {
      final lines = await respondWith(200);
      expect(lines.where((l) => stripAnsi(l).contains('200')), isEmpty);
    });

    test('onlyErrors: true suppresses 201 response', () async {
      final lines = await respondWith(201);
      expect(lines.where((l) => stripAnsi(l).contains('201')), isEmpty);
    });

    test('onlyErrors: true allows 400 response', () async {
      final lines = await respondWith(400);
      expect(stripAnsi(lines.join('\n')), contains('400'));
    });

    test('onlyErrors: true allows 500 response', () async {
      final lines = await respondWith(500);
      expect(stripAnsi(lines.join('\n')), contains('500'));
    });
  });

  group('IglooDioLogger — slowRequestThresholdMs filter', () {
    Future<List<String>> respondWithDelay(int thresholdMs, int delayMs) async {
      final logger = IglooDioLogger(
        slowRequestThresholdMs: thresholdMs,
        logResponseBody: false,
      );
      final startTime = DateTime.now().millisecondsSinceEpoch - delayMs;
      final options = RequestOptions(path: 'https://api.example.com/test');
      options.extra[LoggerConstants.startTimeKey] = startTime;
      return captureDebugPrint(() async {
        logger.onResponse(
          Response(requestOptions: options, data: null, statusCode: 200),
          ResponseInterceptorHandler(),
        );
      });
    }

    test('suppresses response faster than threshold', () async {
      final lines = await respondWithDelay(500, 100); // 100ms < 500ms threshold
      expect(lines.where((l) => stripAnsi(l).contains('200')), isEmpty);
    });

    test('allows response slower than threshold', () async {
      final lines = await respondWithDelay(500, 1000); // 1000ms > 500ms threshold
      expect(stripAnsi(lines.join('\n')), contains('200'));
    });
  });

  group('IglooDioLogger — request ID tracking', () {
    test('request block contains ID: #xxxx', () async {
      final logger = IglooDioLogger(logRequestBody: false, logRequestHeader: false);
      final lines = await captureDebugPrint(() async {
        logger.onRequest(
          RequestOptions(path: 'https://api.example.com/test', method: 'GET'),
          RequestInterceptorHandler(),
        );
      });
      final output = stripAnsi(lines.join('\n'));
      expect(output, contains('ID: #'));
    });

    test('response block contains the same ID as the request', () async {
      final logger = IglooDioLogger(logRequestBody: false, logRequestHeader: false, logResponseBody: false);
      final options = RequestOptions(path: 'https://api.example.com/test', method: 'GET');

      String? requestOutput;
      String? responseOutput;

      requestOutput = stripAnsi((await captureDebugPrint(() async {
        logger.onRequest(options, RequestInterceptorHandler());
      })).join('\n'));

      responseOutput = stripAnsi((await captureDebugPrint(() async {
        logger.onResponse(
          Response(requestOptions: options, data: null, statusCode: 200),
          ResponseInterceptorHandler(),
        );
      })).join('\n'));

      // Extract ID from request output
      final idMatch = RegExp(r'ID: #([0-9a-f]{4})').firstMatch(requestOutput);
      expect(idMatch, isNotNull);
      final requestId = idMatch!.group(0)!;
      expect(responseOutput, contains(requestId));
    });

    test('error block contains ID: #xxxx', () async {
      final logger = IglooDioLogger();
      final options = RequestOptions(path: 'https://api.example.com/test', method: 'GET');
      // Pre-set ID so we can assert on it
      options.extra[LoggerConstants.requestIdKey] = 'abcd';

      final lines = await captureDebugPrint(() async {
        final handler = ErrorInterceptorHandler();
        // ignore: invalid_use_of_protected_member
        unawaited(handler.future.then((_) {}, onError: (_) {}));
        logger.onError(
          DioException(requestOptions: options, type: DioExceptionType.connectionTimeout),
          handler,
        );
      });
      final output = stripAnsi(lines.join('\n'));
      expect(output, contains('ID: #abcd'));
    });
  });

  group('IglooDioLogger — FormData preview', () {
    Future<String> requestOutputFor(dynamic data) async {
      final logger = IglooDioLogger(logRequestHeader: false);
      final lines = await captureDebugPrint(() async {
        logger.onRequest(
          RequestOptions(path: 'https://api.example.com/upload', method: 'POST', data: data),
          RequestInterceptorHandler(),
        );
      });
      return stripAnsi(lines.join('\n'));
    }

    test('FormData shows [Form Data] label', () async {
      final output = await requestOutputFor(FormData.fromMap({'name': 'Alice'}));
      expect(output, contains('[Form Data]'));
    });

    test('FormData shows text fields with key and value', () async {
      final output = await requestOutputFor(FormData.fromMap({'name': 'Alice', 'role': 'admin'}));
      expect(output, contains('Fields: (2)'));
      expect(output, contains('name:'));
      expect(output, contains('Alice'));
      expect(output, contains('role:'));
      expect(output, contains('admin'));
    });

    test('FormData shows file fields with filename and content type', () async {
      final formData = FormData()
        ..files.add(MapEntry(
          'avatar',
          MultipartFile.fromBytes([1, 2, 3],
              filename: 'photo.jpg',
              contentType: DioMediaType('image', 'jpeg')),
        ));
      final output = await requestOutputFor(formData);
      expect(output, contains('Files: (1)'));
      expect(output, contains('avatar'));
      expect(output, contains('photo.jpg'));
      expect(output, contains('image/jpeg'));
    });

    test('plain Map body does not show [Form Data]', () async {
      final output = await requestOutputFor({'key': 'value'});
      expect(output, isNot(contains('[Form Data]')));
    });
  });

  group('IglooDioLogger — GraphQL support', () {
    Future<String> requestOutputFor(dynamic data) async {
      final logger = IglooDioLogger(logRequestHeader: false);
      final lines = await captureDebugPrint(() async {
        logger.onRequest(
          RequestOptions(path: 'https://api.example.com/graphql', method: 'POST', data: data),
          RequestInterceptorHandler(),
        );
      });
      return stripAnsi(lines.join('\n'));
    }

    test('GraphQL body shows [GraphQL] label', () async {
      final output = await requestOutputFor({'query': '{ users { id } }'});
      expect(output, contains('[GraphQL]'));
    });

    test('GraphQL query string is printed', () async {
      final output = await requestOutputFor({'query': 'query GetUser { user { name } }'});
      expect(output, contains('GetUser'));
    });

    test('GraphQL variables are printed when present', () async {
      final output = await requestOutputFor({
        'query': 'query GetUser(\$id: ID!) { user(id: \$id) { name } }',
        'variables': {'id': '123'},
      });
      expect(output, contains('Variables:'));
      expect(output, contains('123'));
    });

    test('GraphQL variables section omitted when not present', () async {
      final output = await requestOutputFor({'query': '{ users { id } }'});
      expect(output, isNot(contains('Variables:')));
    });

    test('plain Map without query key does not show [GraphQL]', () async {
      final output = await requestOutputFor({'mutation': 'createUser'});
      expect(output, isNot(contains('[GraphQL]')));
    });
  });

  group('IglooDioLogger — badResponse message suppression', () {
    Future<String> errorOutputFor(DioExceptionType type) async {
      final logger = IglooDioLogger();
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
            type: type,
            message: 'This exception was thrown because the response has a status code of 404 and RequestOptions.validateStatus...',
          ),
          handler,
        );
      });
      return stripAnsi(lines.join('\n'));
    }

    test('badResponse type suppresses verbose Dio message', () async {
      final output = await errorOutputFor(DioExceptionType.badResponse);
      expect(output, isNot(contains('RequestOptions')));
    });

    test('non-badResponse type shows message', () async {
      final logger = IglooDioLogger();
      final lines = await captureDebugPrint(() async {
        final handler = ErrorInterceptorHandler();
        // ignore: invalid_use_of_protected_member
        unawaited(handler.future.then((_) {}, onError: (_) {}));
        logger.onError(
          DioException(
            requestOptions: RequestOptions(path: 'https://api.example.com/test'),
            type: DioExceptionType.connectionTimeout,
            message: 'Connection timed out',
          ),
          handler,
        );
      });
      final output = stripAnsi(lines.join('\n'));
      expect(output, contains('Connection timed out'));
    });
  });

  group('IglooDioLogger — content wrapping', () {
    test('long string values wrap within maxWidth', () async {
      final logger = IglooDioLogger(maxWidth: 80, logResponseHeader: false);
      final longValue = 'A' * 200; // 200-char string — well over 80 char width
      final lines = await captureDebugPrint(() async {
        logger.onResponse(
          Response(
            requestOptions: RequestOptions(path: 'https://api.example.com/test'),
            data: {'body': longValue},
            statusCode: 200,
          ),
          ResponseInterceptorHandler(),
        );
      });
      // Every printed line should be within maxWidth + ANSI overhead
      // Strip ANSI and check no raw content line exceeds maxWidth
      final contentLines = lines
          .map(stripAnsi)
          .where((l) => l.startsWith('║'))
          .toList();
      for (final line in contentLines) {
        expect(line.length, lessThanOrEqualTo(80 + 10),
            reason: 'Line exceeded maxWidth: $line');
      }
    });
  });

  group('IglooDioLogger — error response label', () {
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
      expect(joined, isNot(contains('Instance of')));
    });
  });
}
