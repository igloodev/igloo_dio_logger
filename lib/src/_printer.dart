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

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpRequest} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorCyan}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    if (requestSizeText != null) {
      debugPrint(
        '${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}│${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$requestSizeText${LoggerConstants.colorReset}',
      );
    } else {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}');
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
      _printLongText(_formatJson(options.data), LoggerConstants.colorCyan);
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

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpResponse} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}$color$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}');

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

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpError} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorRed}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} ${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}');

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
    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${exception.message ?? LoggerConstants.textUnknownError}');

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
