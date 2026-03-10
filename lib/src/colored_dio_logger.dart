import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'logger_constants.dart';

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

  /// Maximum width of the log output (used for border formatting)
  ///
  /// Valid range: 60-200. Values outside this range will throw an [AssertionError].
  /// - Minimum 60: Ensures readable logs
  /// - Maximum 200: Prevents performance issues
  final int maxWidth;

  /// Only log endpoints matching these regex patterns
  ///
  /// Example: `[r'/api/v1/auth/.*', r'/api/v1/users/.*']`
  final List<String>? includeEndpoints;

  /// Exclude endpoints matching these regex patterns
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
  /// Useful for performance debugging and reducing log noise.
  ///
  /// Example: `slowRequestThresholdMs: 500` will only log requests taking 500ms or more
  final int? slowRequestThresholdMs;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      // Store request start time for duration calculation
      options.extra['_start_time'] = DateTime.now().millisecondsSinceEpoch;

      // Check if this endpoint should be logged
      if (_shouldLogEndpoint(options.path)) {
        _printRequest(options);
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      // Check filters
      if (_shouldLogResponse(response)) {
        _printResponse(response);
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && logErrors) {
      // Always log errors (unless filtered by endpoint)
      if (_shouldLogEndpoint(err.requestOptions.path)) {
        _printError(err);
      }
    }
    super.onError(err, handler);
  }

  /// Check if endpoint should be logged based on filters
  bool _shouldLogEndpoint(String path) {
    // If includeEndpoints is specified, only log matching endpoints
    if (includeEndpoints != null && includeEndpoints!.isNotEmpty) {
      final matches = includeEndpoints!.any((pattern) {
        return RegExp(pattern).hasMatch(path);
      });
      if (!matches) return false;
    }

    // If excludeEndpoints is specified, skip matching endpoints
    if (excludeEndpoints != null && excludeEndpoints!.isNotEmpty) {
      final matches = excludeEndpoints!.any((pattern) {
        return RegExp(pattern).hasMatch(path);
      });
      if (matches) return false;
    }

    return true;
  }

  /// Check if response should be logged based on filters
  bool _shouldLogResponse(Response response) {
    // Check endpoint filter
    if (!_shouldLogEndpoint(response.requestOptions.path)) {
      return false;
    }

    // If onlyErrors is true, skip successful responses
    if (onlyErrors) {
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 400) {
        return false;
      }
    }

    // If slow request threshold is set, skip fast responses
    if (slowRequestThresholdMs != null) {
      final startTime = response.requestOptions.extra['_start_time'] as int?;
      if (startTime != null) {
        final duration = DateTime.now().millisecondsSinceEpoch - startTime;
        if (duration < slowRequestThresholdMs!) {
          return false;
        }
      }
    }

    return true;
  }

  void _printRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    final uri = options.uri;
    final baseUrl = uri.origin + uri.path;
    final hasQueryParams = uri.queryParameters.isNotEmpty;

    // Calculate request body size
    final requestSize = options.data != null ? _calculateSize(options.data) : 0;
    final requestSizeText = requestSize > 0 ? _formatSize(requestSize) : null;

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpRequest} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorCyan}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    // Method and base URL (without query params)
    if (requestSizeText != null) {
      debugPrint(
        '${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}│${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$requestSizeText${LoggerConstants.colorReset}',
      );
    } else {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}');
    }

    // Query parameters (if any)
    if (hasQueryParams) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset}');
      uri.queryParameters.forEach((key, value) {
        debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}');
      });
    }

    if (logRequestHeader && options.headers.isNotEmpty) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textHeaders}${LoggerConstants.colorReset}');
      options.headers.forEach((key, value) {
        _printHeaderValue(key, value.toString(), LoggerConstants.colorCyan);
      });
    }

    if (logRequestBody && options.data != null) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
      final data = _formatJson(options.data);
      _printLongText(data, LoggerConstants.colorCyan);
    }

    debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  void _printResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri;
    final baseUrl = uri.origin + uri.path;
    final hasQueryParams = uri.queryParameters.isNotEmpty;
    final color = _getStatusColor(statusCode);

    // Calculate request duration
    final startTime = response.requestOptions.extra['_start_time'] as int?;
    final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;
    final durationText = duration != null ? _formatDuration(duration) : 'N/A';

    // Calculate response body size
    final responseSize = response.data != null ? _calculateSize(response.data) : 0;
    final responseSizeText = _formatSize(responseSize);

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpResponse} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}$color$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    // Method and base URL (without query params)
    debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}');

    // Query parameters (if any)
    if (hasQueryParams) {
      debugPrint(
          '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset} ${LoggerConstants.colorGrey}${uri.queryParameters.entries.map((param) => '${param.key}=${param.value}').join('&')}${LoggerConstants.colorReset}');
    }

    // Status, duration, and size with labels
    debugPrint(
      '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim} ${LoggerConstants.textStatus}${LoggerConstants.colorReset} $color$statusCode${LoggerConstants.colorReset} ${_getStatusEmoji(statusCode)} '
      '${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textDuration}${LoggerConstants.colorReset} ${LoggerConstants.colorMagenta}$durationText${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textSize}${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$responseSizeText${LoggerConstants.colorReset}',
    );

    if (logResponseHeader && response.headers.map.isNotEmpty) {
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textHeaders}${LoggerConstants.colorReset}');
      response.headers.map.forEach((key, value) {
        final joinedValue = value.join(', ');
        _printHeaderValue(key, joinedValue, color);
      });
    }

    if (logResponseBody && response.data != null) {
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
      final data = _formatJson(response.data);
      _printLongText(data, color);
    }

    debugPrint('$color${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  void _printError(DioException exception) {
    final method = exception.requestOptions.method.toUpperCase();
    final uri = exception.requestOptions.uri;
    final baseUrl = uri.origin + uri.path;
    final hasQueryParams = uri.queryParameters.isNotEmpty;

    // Calculate request duration
    final startTime = exception.requestOptions.extra['_start_time'] as int?;
    final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;
    final durationText = duration != null ? _formatDuration(duration) : 'N/A';

    // Calculate error response size (if available)
    final errorSize = exception.response?.data != null ? _calculateSize(exception.response!.data) : 0;
    final errorSizeText = errorSize > 0 ? _formatSize(errorSize) : null;

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpError} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorRed}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    // Method and base URL (without query params)
    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}');

    // Query parameters (if any)
    if (hasQueryParams) {
      debugPrint(
          '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset} ${LoggerConstants.colorGrey}${uri.queryParameters.entries.map((param) => '${param.key}=${param.value}').join('&')}${LoggerConstants.colorReset}');
    }

    // Error type, duration, and size with labels
    final sizeInfo = errorSizeText != null ? ' ${LoggerConstants.colorDim}│ ${LoggerConstants.textSize}${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$errorSizeText${LoggerConstants.colorReset}' : '';

    debugPrint(
      '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${exception.type}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}│ ${LoggerConstants.textDuration}${LoggerConstants.colorReset} ${LoggerConstants.colorMagenta}$durationText${LoggerConstants.colorReset}'
      '$sizeInfo',
    );
    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${exception.message ?? LoggerConstants.textUnknownError}');

    if (exception.response != null) {
      final statusCode = exception.response?.statusCode ?? 0;
      debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.textStatus}${LoggerConstants.colorReset} ${LoggerConstants.colorRed}$statusCode${LoggerConstants.colorReset}');

      if (exception.response?.data != null) {
        debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
        debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$LoggerConstants.textResponse${LoggerConstants.colorReset}');
        final data = _formatJson(exception.response?.data);
        _printLongText(data, LoggerConstants.colorRed);
      }
    }

    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  String _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return LoggerConstants.colorGreen;
    } else if (statusCode >= 300 && statusCode < 400) {
      return LoggerConstants.colorYellow;
    } else if (statusCode >= 400) {
      return LoggerConstants.colorRed;
    }
    return LoggerConstants.colorCyan;
  }

  /// Format duration in human-readable format
  String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    } else if (milliseconds < 60000) {
      final seconds = (milliseconds / 1000).toStringAsFixed(2);
      return '${seconds}s';
    } else {
      final minutes = milliseconds ~/ 60000;
      final seconds = ((milliseconds % 60000) / 1000).toStringAsFixed(0);
      return '${minutes}m ${seconds}s';
    }
  }

  /// Calculate byte size of data
  int _calculateSize(dynamic data) {
    try {
      if (data == null) return 0;

      if (data is String) {
        return utf8.encode(data).length;
      } else if (data is List<int>) {
        return data.length;
      } else if (data is Uint8List) {
        return data.length;
      } else if (data is Map || data is List) {
        final jsonString = jsonEncode(data);
        return utf8.encode(jsonString).length;
      } else {
        final stringData = data.toString();
        return utf8.encode(stringData).length;
      }
    } catch (_) {
      // Failed to calculate size, return 0
      return 0;
    }
  }

  /// Format size in human-readable format
  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(2);
      return '${kb}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
      return '${mb}MB';
    } else {
      final gb = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
      return '${gb}GB';
    }
  }

  /// Format header value - wrap long values to multiple lines
  void _printHeaderValue(String key, String value, String borderColor) {
    const maxLength = 100;

    if (value.length <= maxLength) {
      // Short value - print on same line with colorized key and value
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}');
    } else {
      // Long value - wrap to multiple lines with indentation
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset}');

      // Split value into chunks
      var remaining = value;
      while (remaining.isNotEmpty) {
        if (remaining.length <= maxLength) {
          debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorYellow}$remaining${LoggerConstants.colorReset}');
          break;
        }

        // Find a good break point
        var breakPoint = maxLength;
        // For JWT tokens, break at periods (.) for better readability
        if (value.contains('.') && key.toLowerCase() == 'authorization') {
          final dotIndex = remaining.lastIndexOf('.', maxLength);
          if (dotIndex > maxLength - 50 && dotIndex < maxLength) {
            breakPoint = dotIndex + 1;
          }
        }

        final chunk = remaining.substring(0, breakPoint);
        debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorYellow}$chunk${LoggerConstants.colorReset}');
        remaining = remaining.substring(breakPoint);
      }
    }
  }

  String _getStatusEmoji(int statusCode) {
    // Specific emojis for common status codes
    switch (statusCode) {
      // 2xx Success
      case 200:
        return '✅'; // OK
      case 201:
        return '✨'; // Created
      case 202:
        return '⏳'; // Accepted
      case 204:
        return '⭕'; // No Content

      // 3xx Redirection
      case 301:
        return '↪️'; // Moved Permanently
      case 302:
        return '🔄'; // Found (Temporary Redirect)
      case 304:
        return '📦'; // Not Modified (Cached)

      // 4xx Client Errors
      case 400:
        return '⚠️'; // Bad Request
      case 401:
        return '🔒'; // Unauthorized
      case 403:
        return '🚫'; // Forbidden
      case 404:
        return '🔍'; // Not Found
      case 405:
        return '🚷'; // Method Not Allowed
      case 408:
        return '⏱️'; // Request Timeout
      case 409:
        return '⚔️'; // Conflict
      case 422:
        return '📋'; // Unprocessable Entity
      case 429:
        return '🚦'; // Too Many Requests

      // 5xx Server Errors
      case 500:
        return '💥'; // Internal Server Error
      case 502:
        return '🚧'; // Bad Gateway
      case 503:
        return '🔴'; // Service Unavailable
      case 504:
        return '⌛'; // Gateway Timeout

      // Default fallback based on range
      default:
        if (statusCode >= 200 && statusCode < 300) {
          return '✅'; // 2xx Success
        } else if (statusCode >= 300 && statusCode < 400) {
          return '🔄'; // 3xx Redirect
        } else if (statusCode >= 400 && statusCode < 500) {
          return '⚠️'; // 4xx Client Error
        } else if (statusCode >= 500) {
          return '💥'; // 5xx Server Error
        }
        return 'ℹ️'; // Unknown
    }
  }

  String _formatJson(dynamic data) {
    try {
      if (data is Map || data is List) {
        // Convert to pretty JSON
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      }
      return data.toString();
    } catch (_) {
      // Failed to format as JSON, return as string
      return data.toString();
    }
  }

  /// Print long text by splitting into lines to avoid truncation
  void _printLongText(String text, String color) {
    // Split by newlines first (JSON is already formatted with newlines)
    final lines = text.split('\n');

    // Stack to track nested object/array names with their indent levels
    final stack = <MapEntry<String, int>>[];
    // Track if we're inside an array to add item comments
    var arrayItemIndex = 0;
    var insideArray = false;

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      var line = lines[lineIndex];

      // Calculate indent level (number of leading spaces)
      final indent = line.length - line.trimLeft().length;

      // Track opening braces/brackets with their keys and indent
      final openMatch = RegExp(r'"([^"]+)"\s*:\s*[\{\[]').firstMatch(line);
      if (openMatch != null) {
        final key = openMatch.group(1)!;
        stack.add(MapEntry(key, indent));

        // Check if it's an array
        if (line.contains('[')) {
          insideArray = true;
          arrayItemIndex = 0;
        }
      }

      // Track standalone array opening (not named)
      if (line.trim() == '[') {
        insideArray = true;
        arrayItemIndex = 0;
      }

      // Add closing comments for all } and ]
      line = _addClosingComments(line, stack, indent, insideArray, arrayItemIndex);

      // Track array closing
      if (line.trim().startsWith(']')) {
        insideArray = false;
        arrayItemIndex = 0;
      }

      // Colorize JSON keys (only for lines with key-value pairs)
      final colorizedLine = _colorizeJsonLine(line, color);

      // If line is still too long, split it properly
      if (line.length <= 800) {
        debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   $colorizedLine');
      } else {
        // For very long lines, use original line (no colorization to avoid complexity)
        _printVeryLongLine(line, color);
      }

      // Count array items
      if (insideArray && line.trim() == '{') {
        arrayItemIndex++;
      }
    }
  }

  /// Add closing comments to } and ] like Flutter editor
  String _addClosingComments(
    String line,
    List<MapEntry<String, int>> stack,
    int currentIndent,
    bool insideArray,
    int arrayItemIndex,
  ) {
    final trimmed = line.trim();
    final lineIndent = line.substring(0, line.indexOf(trimmed.isEmpty ? line.trim() : trimmed));

    // Check for closing bracket ] (for arrays)
    if ((trimmed == ']' || trimmed == '],') && stack.isNotEmpty) {
      // Check if this closing bracket matches the indent of the last opening
      final lastEntry = stack.last;
      if (currentIndent == lastEntry.value) {
        final name = stack.removeLast().key;
        final closingChar = trimmed.replaceAll(',', '');
        final comma = trimmed.endsWith(',') ? ',' : '';

        return '$lineIndent$closingChar$comma ${LoggerConstants.colorCyan}// $name${LoggerConstants.colorReset}';
      }
    }

    // Check for closing brace } (for objects)
    if (trimmed == '}' || trimmed == '},') {
      final closingChar = trimmed.replaceAll(',', '');
      final comma = trimmed.endsWith(',') ? ',' : '';

      // Check if it's a named object closing (matches indent in stack)
      if (stack.isNotEmpty) {
        final lastEntry = stack.last;
        if (currentIndent == lastEntry.value) {
          final name = stack.removeLast().key;
          return '$lineIndent$closingChar$comma ${LoggerConstants.colorCyan}// $name${LoggerConstants.colorReset}';
        }
      }

      // Otherwise it's an array item
      if (insideArray) {
        return '$lineIndent$closingChar$comma ${LoggerConstants.colorYellow}$LoggerConstants.textItemComment${LoggerConstants.colorReset}';
      }
    }

    return line;
  }

  /// Colorize JSON line - make keys dim grey, colorize values by type
  String _colorizeJsonLine(String line, String color) {
    // Handle structural characters (braces, brackets)
    if (line.trim() == '{' ||
        line.trim() == '}' ||
        line.trim() == '[' ||
        line.trim() == ']' ||
        line.trim() == '{,' ||
        line.trim() == '},' ||
        line.trim() == '[,' ||
        line.trim() == '],') {
      return '${LoggerConstants.colorDim}$line${LoggerConstants.colorReset}';
    }

    // Match JSON key-value pairs: "key": value
    final keyValuePattern = RegExp(r'^(\s*)"([^"]+)"\s*:\s*(.*)$');
    final match = keyValuePattern.firstMatch(line);

    if (match != null) {
      final indent = match.group(1) ?? '';
      final key = match.group(2) ?? '';
      var value = match.group(3) ?? '';

      // Colorize value based on type
      String colorizedValue;
      value = value.trimRight();

      if (value.startsWith('"')) {
        // String value - keep original color or use yellow
        colorizedValue = '${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}';
      } else if (RegExp(r'^-?\d+\.?\d*,?$').hasMatch(value)) {
        // Number - use magenta
        colorizedValue = '${LoggerConstants.colorMagenta}$value${LoggerConstants.colorReset}';
      } else if (value == 'true,' ||
          value == 'false,' ||
          value == 'null,' ||
          value == 'true' ||
          value == 'false' ||
          value == 'null') {
        // Boolean or null - use cyan
        colorizedValue = '${LoggerConstants.colorCyan}$value${LoggerConstants.colorReset}';
      } else if (value == '{' || value == '[') {
        // Opening brace/bracket - dim
        colorizedValue = '${LoggerConstants.colorDim}$value${LoggerConstants.colorReset}';
      } else {
        // Unknown - keep original color
        colorizedValue = '$color$value${LoggerConstants.colorReset}';
      }

      return '$indent${LoggerConstants.colorGrey}"$key"${LoggerConstants.colorReset}: $colorizedValue';
    }

    // Array items or other content - keep as is
    return line;
  }

  /// Print a very long single line by splitting at word boundaries
  void _printVeryLongLine(String line, String color) {
    const maxLength = 800;
    var remaining = line;

    while (remaining.isNotEmpty) {
      if (remaining.length <= maxLength) {
        debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   $remaining');
        break;
      }

      // Find a good break point (space, comma, etc.) before maxLength
      var breakPoint = maxLength;
      const searchStart = maxLength - 100; // Look back up to 100 chars

      for (var charPosition = maxLength; charPosition >= searchStart && charPosition < remaining.length; charPosition--) {
        if (remaining[charPosition] == ' ' || remaining[charPosition] == ',' || remaining[charPosition] == ';' || remaining[charPosition] == ':') {
          breakPoint = charPosition + 1;
          break;
        }
      }

      final chunk = remaining.substring(0, breakPoint).trimRight();
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   $chunk');
      remaining = remaining.substring(breakPoint).trimLeft();
    }
  }
}
