part of 'igloo_dio_logger.dart';

extension _IglooDioLoggerCurl on IglooDioLogger {
  // =========================================================================
  // PRINT CURL
  // =========================================================================

  /// Prints a cURL command for [options] in a full bordered block,
  /// consistent with the request/response block style.
  ///
  /// A placeholder note is shown when the body cannot be represented as a
  /// cURL argument:
  /// - Binary body ([Uint8List] / `List<int>`) → instructs to use `--data-binary '@/path'`
  /// - Unknown body type → shows the runtime type so the dev knows what was sent
  ///
  /// cURL syntax: bash/zsh/fish (`\` line continuation, single-quoted values).
  void _printCurl(RequestOptions options) {
    final data = options.data;
    final isBinary = data is Uint8List || data is List<int>;
    final isUnknown = data != null &&
        !isBinary &&
        data is! FormData &&
        data is! String &&
        data is! Map &&
        data is! List;

    const color = LoggerConstants.colorYellow;
    const border = '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}';

    // Top border
    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textCurl} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}$color$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    // bash/zsh/fish hint
    debugPrint('$border ${LoggerConstants.colorDim}# bash/zsh/fish${LoggerConstants.colorReset}');

    if (isBinary) {
      debugPrint(
        "$border ${LoggerConstants.colorDim}# ⚠️  Binary body — save bytes to a file and replace with: --data-binary '@/path/to/file'${LoggerConstants.colorReset}",
      );
    } else if (isUnknown) {
      debugPrint(
        '$border ${LoggerConstants.colorDim}# ⚠️  Body type ${data.runtimeType} — not representable as cURL${LoggerConstants.colorReset}',
      );
    }

    // cURL command lines
    final curl = _buildCurl(options);
    for (final line in curl.split('\n')) {
      debugPrint('$border ${LoggerConstants.colorGrey}$line${LoggerConstants.colorReset}');
    }

    // Bottom border
    debugPrint('$color${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // BUILD CURL
  // =========================================================================

  /// Builds the cURL command string from [options].
  ///
  /// - Skips `-X GET` (curl default).
  /// - Adds one `-H` flag per header.
  /// - Body:
  ///   - [FormData] → `--form` flags (text fields + file placeholders with filename)
  ///   - [Uint8List] / `List<int>` → body line omitted (caller shows placeholder note)
  ///   - [String] → `-d '...'`
  ///   - [Map] / [List] → `-d '<compacted json>'`
  ///   - Other → body line omitted
  String _buildCurl(RequestOptions options) {
    final method = options.method.toUpperCase();
    final lines = <String>['curl'];

    lines.add('  -L'); // follow redirects — matches Dio default behaviour
    if (method != 'GET') lines.add('  -X $method');

    options.headers.forEach((key, value) {
      lines.add("  -H '${_sq(key)}: ${_sq(value.toString())}'");
    });

    final data = options.data;
    if (data != null && data is! Uint8List && data is! List<int>) {
      if (data is FormData) {
        // Text fields
        for (final field in data.fields) {
          lines.add("  --form '${_sq(field.key)}=${_sq(field.value)}'");
        }
        // File fields — filename only (full path not available at runtime)
        for (final file in data.files) {
          lines.add("  --form '${_sq(file.key)}=@\"${file.value.filename ?? 'file'}\"'");
        }
      } else if (data is String) {
        if (data.isNotEmpty) lines.add("  -d '${_sq(data)}'");
      } else if (data is Map || data is List) {
        try {
          lines.add("  -d '${_sq(jsonEncode(data))}'");
        } catch (_) {
          // Could not serialize — skip body silently
        }
      }
      // Unknown type — body silently omitted (note already shown by _printCurl)
    }

    lines.add("  '${_sq(options.uri.toString())}'");
    return lines.join(' \\\n');
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  /// Escapes single quotes for safe use inside bash single-quoted strings.
  ///
  /// In bash, a single-quoted string cannot contain a literal `'`.
  /// The standard workaround is to close the string, append `\'`, then reopen:
  /// `'` → `'\''`
  ///
  /// Example: `it's` becomes `it'\''s`, so `curl -d 'it'\''s'` is valid bash.
  String _sq(String value) => value.replaceAll("'", r"'\''");
}
