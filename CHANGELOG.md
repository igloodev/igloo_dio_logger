
## 📝 1.3.1

### 📝 Documentation
* Fixed screenshot URLs in README — changed `main` → `master` branch so images load correctly on pub.dev

## 🆕 1.3.0

### ✨ New Features
* 📋 **Multipart form data preview** — `FormData` request bodies now display a structured breakdown instead of raw text:
  * `Fields (N):` section lists each text field as `key: value`
  * `Files (N):` section lists each file field as `key → filename (content-type)`
* 🔑 **Request ID tracking** — each request is assigned a short 4-hex-digit ID (e.g. `#a3f2`) shown on the first line of the request, its matching response, and any error block — makes it easy to correlate concurrent requests at a glance
* 🔮 **GraphQL support** — bodies with a `query` string key are detected and rendered with a dedicated `[GraphQL]` block:
  * The query string is printed line-by-line with syntax highlighting
  * `variables` (if present) are pretty-printed as JSON below

### 🐛 Bug Fixes
* 📐 Long content lines now wrap at `maxWidth` instead of overflowing the border — continuation lines are styled in dim yellow to indicate overflow content
* 🔇 Verbose Dio error message suppressed for `badResponse` type — status code and response body already tell the full story; message still shown for other error types (timeout, connection error, etc.)

## 🔗 1.2.0

### ✨ New Features
* 🔗 Added `logCurl: false` — opt-in cURL command logging after each request
  * Printed as a full bordered block (`╔═══ 🔗 cURL ═══...`) consistent with request/response style
  * `FormData` → `--form` flags per field; files use `--form 'key=@"filename"'` placeholder
  * Binary body (`Uint8List` / `List<int>`) → body omitted with a `⚠️` note: _"save bytes to a file and use `--data-binary '@/path'`"_
  * Unknown body type → body omitted with a note showing the runtime type
  * Single quotes are safely escaped (`'` → `'\''`) for valid bash syntax
  * Includes `-L` for redirect following (matches Dio default behaviour)
  * Syntax is bash/zsh/fish; a `# bash/zsh/fish` hint is shown for clarity
* 🌍 `LoggerConstants` is now exported as public API — allows access to `startTimeKey` and other constants from outside the package

### 🐛 Bug Fixes
* 🔍 `includeEndpoints` / `excludeEndpoints` now match against the **URL path only** — anchored patterns like `r'^/api'` now work correctly whether a full URL or bare path is passed to Dio
* 🗂️ `_calculateSize` now correctly computes size for `FormData` (sums text field bytes instead of returning `"Instance of 'FormData'".length`)
* 🖨️ `_formatJson` now renders `FormData` as readable `key = value` pairs instead of `Instance of 'FormData'`
* 🔑 Request start time key namespaced to `_igloo_dio_logger_start_time` — prevents collision with other interceptors using `options.extra`
* 🔀 Separator `│` in error block now uses `LoggerConstants.separator` — consistent with response block

## ✨ 1.1.3

### 🐛 Bug Fixes
* 🛡️ When multiple wrapper keys match in a response, `Items:` is now hidden to avoid showing an ambiguous count

## ✨ 1.1.2

### ✨ New Features
* 📋 `Items:` count now also detects common wrapper keys (`data`, `items`, `results`, `users`, `posts`, `products`, `records`, `list`, `content`, `entries`) — works with most real-world APIs, not just plain root arrays

## 🔧 1.1.1

### 🐛 Bug Fixes
* 🧹 Removed redundant `dart:typed_data` import (already provided by `flutter/foundation.dart`)
* 📦 Tightened `dio` dependency constraint to `^5.9.2` to fix lower bound compatibility issue

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
