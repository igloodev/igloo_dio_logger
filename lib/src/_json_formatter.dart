part of 'igloo_dio_logger.dart';

extension _IglooDioLoggerFormatter on IglooDioLogger {
  // =========================================================================
  // FORMAT JSON
  // =========================================================================

  String _formatJson(dynamic data) {
    try {
      if (data is Map || data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      }
      if (data is FormData) {
        // Show text fields as readable key=value pairs.
        // File fields show filename only (bytes not accessible synchronously).
        final buffer = StringBuffer();
        for (final field in data.fields) {
          buffer.writeln('${field.key} = ${field.value}');
        }
        for (final file in data.files) {
          buffer.writeln('${file.key} = [file: ${file.value.filename ?? 'unnamed'}]');
        }
        return buffer.toString().trimRight();
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  // =========================================================================
  // PRINT LONG TEXT (with closing comments + colorization)
  // =========================================================================

  /// Prints [text] line by line with border prefix, closing comments, and JSON colorization.
  void _printLongText(String text, String color) {
    final lines = text.split('\n');

    // Stack to track nested object/array names with their indent levels
    final stack = <MapEntry<String, int>>[];
    // Stack to track nested array depths — each entry is the current item index (-1 = not started)
    final arrayStack = <int>[];

    for (final originalLine in lines) {
      var line = originalLine;
      final indent = line.length - line.trimLeft().length;
      final trimmed = line.trim();

      // Track opening braces/brackets with their keys
      final openMatch = LoggerConstants.reOpenBrace.firstMatch(line);
      if (openMatch != null) {
        final key = openMatch.group(1)!;
        stack.add(MapEntry(key, indent));
        if (line.contains('[') && !line.contains('[]')) arrayStack.add(-1);
      }

      // Track standalone array opening
      if (trimmed == '[') arrayStack.add(-1);

      // Increment item index when a new object starts inside an array
      if (arrayStack.isNotEmpty && trimmed == '{') {
        arrayStack[arrayStack.length - 1]++;
      }

      // NOTE: _addClosingComments has intentional side effects —
      // it calls stack.removeLast() for named closings and reads arrayStack.last
      // for array item closings. Do not call it more than once per line.
      line = _addClosingComments(line, stack, arrayStack, indent);

      // Pop array stack on closing bracket
      if ((trimmed == ']' || trimmed == '],') && arrayStack.isNotEmpty) {
        arrayStack.removeLast();
      }

      final colorizedLine = _colorizeJsonLine(line, color);

      // Wrap at content width (maxWidth minus '║   ' prefix of 4 chars).
      // Use raw line length for comparison since colorizedLine contains invisible ANSI codes.
      if (line.length <= maxWidth - 4) {
        debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   $colorizedLine');
      } else {
        _printVeryLongLine(line, color);
      }
    }
  }

  // =========================================================================
  // CLOSING COMMENTS
  // =========================================================================

  /// Adds closing comments to `}` and `]` tokens.
  /// - Named closings  → cyan   `// keyName`
  /// - Array item closings → yellow `// [0]`, `// [1]`, etc.
  String _addClosingComments(
    String line,
    List<MapEntry<String, int>> stack,
    List<int> arrayStack,
    int currentIndent,
  ) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return line;
    final lineIndent = ' ' * currentIndent;

    if (trimmed == ']' || trimmed == '],') {
      final comma = trimmed.endsWith(',') ? ',' : '';
      if (stack.isNotEmpty && currentIndent == stack.last.value) {
        final name = stack.removeLast().key;
        return '$lineIndent]$comma ${LoggerConstants.colorCyan}// $name${LoggerConstants.colorReset}';
      }
    }

    if (trimmed == '}' || trimmed == '},') {
      final comma = trimmed.endsWith(',') ? ',' : '';
      if (stack.isNotEmpty && currentIndent == stack.last.value) {
        final name = stack.removeLast().key;
        return '$lineIndent}$comma ${LoggerConstants.colorCyan}// $name${LoggerConstants.colorReset}';
      }
      if (arrayStack.isNotEmpty) {
        final itemIndex = arrayStack.last;
        return '$lineIndent}$comma ${LoggerConstants.colorYellow}// [$itemIndex]${LoggerConstants.colorReset}';
      }
    }

    return line;
  }

  // =========================================================================
  // JSON LINE COLORIZATION
  // =========================================================================

  /// Colorizes JSON keys (dim grey) and values (by type) with ANSI codes.
  String _colorizeJsonLine(String line, String color) {
    const structuralTokens = {'{', '}', '[', ']', '},', '],', '{}', '[]'};
    if (structuralTokens.contains(line.trim())) {
      return '${LoggerConstants.colorDim}$line${LoggerConstants.colorReset}';
    }

    final match = LoggerConstants.reKeyValue.firstMatch(line);

    if (match != null) {
      final indentStr = match.group(1) ?? '';
      final key = match.group(2) ?? '';
      final value = (match.group(3) ?? '').trimRight();

      final String colorizedValue;
      if (value.startsWith('"')) {
        colorizedValue = '${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}';
      } else if (LoggerConstants.reNumber.hasMatch(value)) {
        colorizedValue = '${LoggerConstants.colorMagenta}$value${LoggerConstants.colorReset}';
      } else if (value == 'true,' || value == 'false,' || value == 'null,' ||
                 value == 'true'  || value == 'false'  || value == 'null') {
        colorizedValue = '${LoggerConstants.colorCyan}$value${LoggerConstants.colorReset}';
      } else if (value == '{' || value == '[') {
        colorizedValue = '${LoggerConstants.colorDim}$value${LoggerConstants.colorReset}';
      } else {
        colorizedValue = '$color$value${LoggerConstants.colorReset}';
      }

      return '$indentStr${LoggerConstants.colorGrey}"$key"${LoggerConstants.colorReset}: $colorizedValue';
    }

    return line;
  }

  // =========================================================================
  // VERY LONG LINES
  // =========================================================================

  /// Wraps lines longer than [maxWidth] at word boundaries to stay within the border.
  /// The first chunk is colorized normally; continuation chunks use dim yellow
  /// to indicate they are overflow content of the same value.
  void _printVeryLongLine(String line, String color) {
    final contentWidth = maxWidth - 4; // '║   ' prefix is 4 chars
    var remaining = line;
    var isFirst = true;

    while (remaining.isNotEmpty) {
      final String chunk;
      final bool done;

      if (remaining.length <= contentWidth) {
        chunk = remaining;
        remaining = '';
        done = true;
      } else {
        var breakPoint = contentWidth;
        final searchStart = contentWidth - 20;
        for (var i = contentWidth - 1; i >= searchStart && i >= 0; i--) {
          if (remaining[i] == ' ' || remaining[i] == ',' || remaining[i] == ';' || remaining[i] == ':') {
            breakPoint = i + 1;
            break;
          }
        }
        chunk = remaining.substring(0, breakPoint).trimRight();
        remaining = remaining.substring(breakPoint).trimLeft();
        done = false;
      }

      if (isFirst) {
        // First chunk — colorize as a normal JSON line
        final colorized = _colorizeJsonLine(chunk, color);
        debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   $colorized');
        isFirst = false;
      } else {
        // Continuation chunk — dim yellow to indicate overflow content
        debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}${LoggerConstants.colorYellow}$chunk${LoggerConstants.colorReset}');
      }

      if (done) break;
    }
  }
}
