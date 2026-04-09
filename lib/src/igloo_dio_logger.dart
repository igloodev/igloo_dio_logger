import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'logger_constants.dart';

part '_helpers.dart';
part '_printer.dart';
part '_json_formatter.dart';
part '_curl_builder.dart';

/// Igloo Dio Logger Interceptor
///
/// Beautiful HTTP request/response logging with ANSI colors and emojis
class IglooDioLogger extends Interceptor {
  /// Creates a [IglooDioLogger] interceptor with customizable options
  IglooDioLogger({
    this.logRequestHeader = true,
    this.logRequestBody = true,
    this.logResponseHeader = false,
    this.logResponseBody = true,
    this.logErrors = true,
    this.logCurl = false,
    this.maxWidth = 90,
    this.includeEndpoints,
    this.excludeEndpoints,
    this.onlyErrors = false,
    this.slowRequestThresholdMs,
  }) : assert(maxWidth >= 60 && maxWidth <= 200, LoggerConstants.textMaxWidthError);

  /// Whether to log request headers
  final bool logRequestHeader;

  /// Whether to log request body
  final bool logRequestBody;

  /// Whether to log response headers
  final bool logResponseHeader;

  /// Whether to log response body
  final bool logResponseBody;

  /// Whether to log errors
  final bool logErrors;

  /// Whether to print a cURL command after each request block.
  ///
  /// The cURL is printed with the `║` border prefix, consistent with the
  /// request/response block style.
  ///
  /// Body handling:
  /// - JSON / Map / String → `-d '...'` (single quotes safely escaped)
  /// - [FormData] → `--form 'key=value'` per field; `--form 'key=@"filename"'` per file
  /// - [Uint8List] / `List<int>` → body omitted; a placeholder note is shown above the command
  /// - Other unknown types → body omitted; a note with the runtime type is shown
  ///
  /// cURL syntax is bash/zsh/fish. Windows CMD users should run under WSL or
  /// Git Bash, or adapt `\` → `^` and single quotes → double quotes manually.
  ///
  /// Defaults to `false`.
  final bool logCurl;

  /// Maximum width of the log output (used for border formatting)
  ///
  /// Valid range: 60-200. Values outside this range will throw an [AssertionError].
  final int maxWidth;

  /// Only log endpoints matching these regex patterns.
  ///
  /// Patterns are matched against the **URL path only** (e.g. `/api/v1/users`),
  /// not the full URL. Scheme, host, and query parameters are not included.
  ///
  /// Example: `[r'/api/v1/auth/.*', r'/api/v1/users/.*']`
  final List<String>? includeEndpoints;

  /// Exclude endpoints matching these regex patterns.
  ///
  /// Patterns are matched against the **URL path only** (e.g. `/api/v1/health`),
  /// not the full URL. Scheme, host, and query parameters are not included.
  ///
  /// Example: `[r'/api/v1/health', r'/api/v1/ping']`
  final List<String>? excludeEndpoints;

  /// Only log error responses (4xx and 5xx status codes)
  ///
  /// When true, successful responses (2xx, 3xx) are not logged
  final bool onlyErrors;

  /// Threshold for logging slow requests (in milliseconds)
  ///
  /// Only logs requests that take longer than this duration.
  ///
  /// Example: `slowRequestThresholdMs: 500` will only log requests taking 500ms or more
  final int? slowRequestThresholdMs;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra[LoggerConstants.startTimeKey] = DateTime.now().millisecondsSinceEpoch;
      if (_shouldLogEndpoint(options.path)) {
        _printRequest(options);
        if (logCurl) _printCurl(options);
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      if (_shouldLogResponse(response)) {
        _printResponse(response);
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && logErrors) {
      if (_shouldLogEndpoint(err.requestOptions.path)) {
        _printError(err);
      }
    }
    super.onError(err, handler);
  }

  // =========================================================================
  // FILTERING
  // =========================================================================

  bool _shouldLogEndpoint(String path) {
    // Extract the URI path segment only (e.g. "/api/v1/users") so that
    // anchored patterns like r'^/api' work whether the caller passes a full
    // URL or a bare path string.
    final uriPath = Uri.tryParse(path)?.path ?? path;
    if (includeEndpoints != null && includeEndpoints!.isNotEmpty) {
      final matches = includeEndpoints!.any((p) => RegExp(p).hasMatch(uriPath));
      if (!matches) return false;
    }
    if (excludeEndpoints != null && excludeEndpoints!.isNotEmpty) {
      final matches = excludeEndpoints!.any((p) => RegExp(p).hasMatch(uriPath));
      if (matches) return false;
    }
    return true;
  }

  bool _shouldLogResponse(Response response) {
    if (!_shouldLogEndpoint(response.requestOptions.path)) return false;

    if (onlyErrors) {
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 400) return false;
    }

    if (slowRequestThresholdMs != null) {
      final startTime = response.requestOptions.extra[LoggerConstants.startTimeKey] as int?;
      if (startTime != null) {
        final duration = DateTime.now().millisecondsSinceEpoch - startTime;
        if (duration < slowRequestThresholdMs!) return false;
      }
    }

    return true;
  }
}
