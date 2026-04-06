
## 🚀 1.1.0

### ✨ New Features
* 📋 Added `Items: N` to response status line when root response is a List
* 🔢 Array item closing comments now show zero-based index: `// [0]`, `// [1]`, etc.
* 🪜 Fixed nested array tracking — each array depth now tracked independently via stack

### 🐛 Bug Fixes
* 🏷️ Fixed error response body label showing class name instead of `"Response:"`
* 📦 Reordered `_calculateSize` checks — `Uint8List` now checked before `List<int>` (more specific first)

### ♻️ Refactoring
* ➕ Explicit `dart:typed_data` import added
* 🧹 Removed unused `lineIndex` variable in JSON printer loop
* ⚡ Simplified structural token check in colorizer using `const Set`
* 🗑️ Removed unused `textItemComment` constant

## 🐛 1.0.1

* 🔧 Fixed JSON array item comment bug (was showing `"LoggerConstants.textItemComment"` instead of `"// item"`)
* 📝 Renamed file from `colored_dio_logger.dart` to `igloo_dio_logger.dart` to match class name
* 📝 Renamed test file from `colored_dio_logger_test.dart` to `igloo_dio_logger_test.dart` for consistency

## 🎉 1.0.0

* 🎨 Initial release
* 🌈 Beautiful colored HTTP logging with ANSI colors
* 😀 Emoji status indicators for HTTP status codes
* 📊 Request/Response size tracking
* ⏱️ Duration tracking
* 🔍 Advanced filtering options (endpoints, errors, duration)
* 📦 Pretty JSON formatting with syntax highlighting
* 🎯 Smart header wrapping for long values
* ⚡ Production-safe (only logs in debug mode)
