part of 'igloo_dio_logger.dart';

extension _IglooDioLoggerHelpers on IglooDioLogger {
  // =========================================================================
  // ITEMS COUNT
  // =========================================================================

  /// Extracts item count from response data.
  ///
  /// Returns the length if [data] is a root List, or if it's a Map containing
  /// a common wrapper key whose value is a List.
  ///
  /// If multiple wrapper keys match, returns null to avoid an ambiguous count.
  int? _extractItemsCount(dynamic data) {
    if (data is List) return data.length;
    if (data is Map) {
      const wrapperKeys = {
        'data', 'items', 'results', 'users', 'posts',
        'products', 'records', 'list', 'content', 'entries',
      };
      List? found;
      for (final key in wrapperKeys) {
        if (data[key] is List) {
          if (found != null) return null; // multiple matches — ambiguous
          found = data[key] as List;
        }
      }
      return found?.length;
    }
    return null;
  }

  // =========================================================================
  // STATUS HELPERS
  // =========================================================================

  String _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return LoggerConstants.colorGreen;
    if (statusCode >= 300 && statusCode < 400) return LoggerConstants.colorYellow;
    if (statusCode >= 400) return LoggerConstants.colorRed;
    return LoggerConstants.colorCyan;
  }

  String _getStatusEmoji(int statusCode) {
    switch (statusCode) {
      // 2xx Success
      case 200: return '✅';
      case 201: return '✨';
      case 202: return '⏳';
      case 204: return '⭕';
      // 3xx Redirection
      case 301: return '↪️';
      case 302: return '🔄';
      case 304: return '📦';
      // 4xx Client Errors
      case 400: return '⚠️';
      case 401: return '🔒';
      case 403: return '🚫';
      case 404: return '🔍';
      case 405: return '🚷';
      case 408: return '⏱️';
      case 409: return '⚔️';
      case 422: return '📋';
      case 429: return '🚦';
      // 5xx Server Errors
      case 500: return '💥';
      case 502: return '🚧';
      case 503: return '🔴';
      case 504: return '⌛';
      default:
        if (statusCode >= 200 && statusCode < 300) return '✅';
        if (statusCode >= 300 && statusCode < 400) return '🔄';
        if (statusCode >= 400 && statusCode < 500) return '⚠️';
        if (statusCode >= 500) return '💥';
        return 'ℹ️';
    }
  }

  // =========================================================================
  // SIZE / DURATION FORMATTERS
  // =========================================================================

  String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) return '${milliseconds}ms';
    if (milliseconds < 60000) return '${(milliseconds / 1000).toStringAsFixed(2)}s';
    final minutes = milliseconds ~/ 60000;
    final seconds = ((milliseconds % 60000) / 1000).toStringAsFixed(0);
    return '${minutes}m ${seconds}s';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  int _calculateSize(dynamic data) {
    try {
      if (data == null) return 0;
      if (data is Uint8List) return data.length;
      if (data is List<int>) return data.length;
      if (data is String) return utf8.encode(data).length;
      if (data is Map || data is List) return utf8.encode(jsonEncode(data)).length;
      if (data is FormData) {
        // Sum text field bytes. File content is not counted because
        // the bytes are not accessible synchronously from MultipartFile.
        var size = 0;
        for (final field in data.fields) {
          size += utf8.encode(field.key).length + utf8.encode(field.value).length;
        }
        return size;
      }
      return utf8.encode(data.toString()).length;
    } catch (_) {
      return 0;
    }
  }
}
