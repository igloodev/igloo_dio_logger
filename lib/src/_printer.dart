part of 'igloo_dio_logger.dart';

extension _IglooDioLoggerPrinter on IglooDioLogger {
  // =========================================================================
  // REQUEST
  // =========================================================================

  void _printRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    final uri = options.uri;
    final baseUrl = uri.origin + uri.path;
    final hasQueryParams = uri.queryParameters.isNotEmpty;

    final requestSize = options.data != null ? _calculateSize(options.data) : 0;
    final requestSizeText = requestSize > 0 ? _formatSize(requestSize) : null;
    final requestId = options.extra[LoggerConstants.requestIdKey] as String?;
    final requestIdSuffix = requestId != null
        ? ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textRequestId}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorCyan}#$requestId${LoggerConstants.colorReset}'
        : '';

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpRequest} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorCyan}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    if (requestSizeText != null) {
      debugPrint(
        '${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}│${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$requestSizeText${LoggerConstants.colorReset}$requestIdSuffix',
      );
    } else {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}$requestIdSuffix');
    }

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
      if (options.data is FormData) {
        _printFormData(options.data as FormData, LoggerConstants.colorCyan);
      } else if (_isGraphQLRequest(options.data)) {
        _printGraphQL(options.data as Map, LoggerConstants.colorCyan);
      } else {
        _printLongText(_formatJson(options.data), LoggerConstants.colorCyan);
      }
    }

    debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // RESPONSE
  // =========================================================================

  void _printResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri;
    final baseUrl = uri.origin + uri.path;
    final hasQueryParams = uri.queryParameters.isNotEmpty;
    final color = _getStatusColor(statusCode);

    final startTime = response.requestOptions.extra[LoggerConstants.startTimeKey] as int?;
    final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;
    final durationText = duration != null ? _formatDuration(duration) : 'N/A';

    final responseSize = response.data != null ? _calculateSize(response.data) : 0;
    final responseSizeText = _formatSize(responseSize);
    final itemsCount = _extractItemsCount(response.data);
    final requestId = response.requestOptions.extra[LoggerConstants.requestIdKey] as String?;
    final requestIdSuffix = requestId != null
        ? ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textRequestId}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorCyan}#$requestId${LoggerConstants.colorReset}'
        : '';

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpResponse} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}$color$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}$requestIdSuffix');

    if (hasQueryParams) {
      debugPrint(
        '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorGrey}${uri.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}${LoggerConstants.colorReset}',
      );
    }

    final itemsInfo = itemsCount != null
        ? ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textItems}${LoggerConstants.colorReset} ${LoggerConstants.colorCyan}$itemsCount${LoggerConstants.colorReset}'
        : '';
    debugPrint(
      '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim} ${LoggerConstants.textStatus}${LoggerConstants.colorReset} $color$statusCode${LoggerConstants.colorReset} ${_getStatusEmoji(statusCode)} '
      '${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textDuration}${LoggerConstants.colorReset} ${LoggerConstants.colorMagenta}$durationText${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textSize}${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$responseSizeText${LoggerConstants.colorReset}'
      '$itemsInfo',
    );

    if (logResponseHeader && response.headers.map.isNotEmpty) {
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textHeaders}${LoggerConstants.colorReset}');
      response.headers.map.forEach((key, value) {
        _printHeaderValue(key, value.join(', '), color);
      });
    }

    if (logResponseBody && response.data != null) {
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
      _printLongText(_formatJson(response.data), color);
    }

    debugPrint('$color${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // ERROR
  // =========================================================================

  void _printError(DioException exception) {
    final method = exception.requestOptions.method.toUpperCase();
    final uri = exception.requestOptions.uri;
    final baseUrl = uri.origin + uri.path;
    final hasQueryParams = uri.queryParameters.isNotEmpty;

    final startTime = exception.requestOptions.extra[LoggerConstants.startTimeKey] as int?;
    final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;
    final durationText = duration != null ? _formatDuration(duration) : 'N/A';

    final errorSize = exception.response?.data != null ? _calculateSize(exception.response!.data) : 0;
    final errorSizeText = errorSize > 0 ? _formatSize(errorSize) : null;
    final requestId = exception.requestOptions.extra[LoggerConstants.requestIdKey] as String?;
    final requestIdSuffix = requestId != null
        ? ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textRequestId}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorCyan}#$requestId${LoggerConstants.colorReset}'
        : '';

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpError} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorRed}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}$requestIdSuffix');

    if (hasQueryParams) {
      debugPrint(
        '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorGrey}${uri.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}${LoggerConstants.colorReset}',
      );
    }

    final sizeInfo = errorSizeText != null
        ? ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textSize}${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$errorSizeText${LoggerConstants.colorReset}'
        : '';
    debugPrint(
      '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${exception.type}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textDuration}${LoggerConstants.colorReset} ${LoggerConstants.colorMagenta}$durationText${LoggerConstants.colorReset}'
      '$sizeInfo',
    );
    // For badResponse the status code + response body already tell the full story.
    // For other types (timeout, connection error, cancel etc.) the message is useful.
    if (exception.type != DioExceptionType.badResponse) {
      final message = exception.message ?? LoggerConstants.textUnknownError;
      debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} $message');
    }

    if (exception.response != null) {
      final statusCode = exception.response!.statusCode ?? 0;
      debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.textStatus}${LoggerConstants.colorReset} ${LoggerConstants.colorRed}$statusCode${LoggerConstants.colorReset}');

      if (exception.response!.data != null) {
        debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
        debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textResponse}${LoggerConstants.colorReset}');
        _printLongText(_formatJson(exception.response!.data), LoggerConstants.colorRed);
      }
    }

    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // FORM DATA
  // =========================================================================

  void _printFormData(FormData formData, String borderColor) {
    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}[Form Data]${LoggerConstants.colorReset}');

    if (formData.fields.isNotEmpty) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}${LoggerConstants.textFormFields} (${formData.fields.length})${LoggerConstants.colorReset}');
      for (final field in formData.fields) {
        debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorGrey}${field.key}:${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}${field.value}${LoggerConstants.colorReset}');
      }
    }

    if (formData.files.isNotEmpty) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}${LoggerConstants.textFormFiles} (${formData.files.length})${LoggerConstants.colorReset}');
      for (final file in formData.files) {
        final filename = file.value.filename ?? 'unknown';
        final contentType = file.value.contentType?.mimeType ?? 'application/octet-stream';
        debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorGrey}${file.key}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}→${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$filename${LoggerConstants.colorReset} ${LoggerConstants.colorDim}($contentType)${LoggerConstants.colorReset}');
      }
    }
  }

  // =========================================================================
  // GRAPHQL
  // =========================================================================

  bool _isGraphQLRequest(dynamic data) {
    if (data is! Map) return false;
    final query = data['query'];
    return query is String && query.isNotEmpty;
  }

  void _printGraphQL(Map data, String borderColor) {
    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}[GraphQL]${LoggerConstants.colorReset}');

    final query = (data['query'] as String).trim();
    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}${LoggerConstants.textGraphQL}${LoggerConstants.colorReset}');
    for (final line in query.split('\n')) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorYellow}$line${LoggerConstants.colorReset}');
    }

    final variables = data['variables'];
    if (variables != null) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}${LoggerConstants.textVariables}${LoggerConstants.colorReset}');
      _printLongText(_formatJson(variables), borderColor);
    }
  }

  // =========================================================================
  // HEADER VALUE
  // =========================================================================

  /// Prints a header key-value pair, wrapping long values (e.g. JWT tokens).
  void _printHeaderValue(String key, String value, String borderColor) {
    const maxLength = 100;

    if (value.length <= maxLength) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}');
      return;
    }

    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset}');
    var remaining = value;
    while (remaining.isNotEmpty) {
      if (remaining.length <= maxLength) {
        debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorYellow}$remaining${LoggerConstants.colorReset}');
        break;
      }
      var breakPoint = maxLength;
      if (value.contains('.') && key.toLowerCase() == 'authorization') {
        final dotIndex = remaining.lastIndexOf('.', maxLength);
        if (dotIndex > maxLength - 50 && dotIndex < maxLength) breakPoint = dotIndex + 1;
      }
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorYellow}${remaining.substring(0, breakPoint)}${LoggerConstants.colorReset}');
      remaining = remaining.substring(breakPoint);
    }
  }
}
