# Igloo Dio Logger 🎨

A beautiful HTTP request/response logger for Dio with ANSI colors, emojis, and advanced filtering options.

[![pub.dev](https://img.shields.io/pub/v/igloo_dio_logger.svg)](https://pub.dev/packages/igloo_dio_logger)
[![pub points](https://img.shields.io/pub/points/igloo_dio_logger)](https://pub.dev/packages/igloo_dio_logger/score)
[![likes](https://img.shields.io/pub/likes/igloo_dio_logger)](https://pub.dev/packages/igloo_dio_logger)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## 🆚 What makes it different?

Most Dio loggers just print request/response. `igloo_dio_logger` goes further:

| Capability | Support |
|---|:---:|
| ANSI colored output | ✅ |
| Emoji status indicators per HTTP code | ✅ |
| Filter by endpoint (regex include/exclude) | ✅ |
| Log only errors (4xx/5xx) | ✅ |
| Log only slow requests (threshold in ms) | ✅ |
| cURL command generation | ✅ |
| Array item annotations (`// [0]`, `// [1]`) | ✅ |
| Items count for list/paginated responses | ✅ |
| Smart JWT/long header wrapping | ✅ |
| Multipart form data preview (fields + files) | ✅ |
| Request ID tracking (correlate req ↔ res) | ✅ |
| GraphQL query + variables pretty-print | ✅ |
| Zero performance impact in release mode | ✅ |

## ✨ Features

- 🎨 **Beautiful colored output** with ANSI colors
- 😀 **Emoji status indicators** for HTTP status codes
- 📊 **Request/Response sizes** in human-readable format (B, KB, MB, GB)
- ⏱️ **Duration tracking** for each request
- 🔍 **Advanced filtering options**:
  - Filter by endpoints (include/exclude patterns)
  - Log only errors (4xx, 5xx)
  - Log only slow requests (minimum duration)
- 📦 **Pretty JSON formatting** with syntax highlighting
- 🔢 **Array item annotations** — each item labeled `// [0]`, `// [1]`, with nested array support
- 📋 **Items count** in the status line for List responses and common wrapper keys like `data`, `users`, `results` (`Items: 42`)
- 🎯 **Smart header wrapping** for long values (like JWT tokens)
- 📝 **Structured output** similar to Flutter's code folding comments
- 🔗 **cURL logging** — opt-in `logCurl: true` prints a copy-pasteable cURL command after each request
- 📋 **Multipart form data preview** — `FormData` bodies show a structured list of fields and files instead of raw text
- 🔑 **Request ID tracking** — each request/response/error pair shares a short `#xxxx` ID for easy correlation when requests run concurrently
- 🔮 **GraphQL support** — bodies with a `query` key are detected and printed as a dedicated `[GraphQL]` block with the query and `variables` formatted separately
- ⚡ **Zero performance impact** in release mode (only logs in debug mode)

## 📸 Screenshots

### Request Logging
![Request Logging](https://raw.githubusercontent.com/igloodev/igloo_dio_logger/master/screenshots/01_request.png)

### Response Logging
![Response Logging](https://raw.githubusercontent.com/igloodev/igloo_dio_logger/master/screenshots/02_response.png)

### List Response (with Items count)
![List Response](https://raw.githubusercontent.com/igloodev/igloo_dio_logger/master/screenshots/03_list_response.png)

### cURL Logging (opt-in)
![cURL Logging](https://raw.githubusercontent.com/igloodev/igloo_dio_logger/master/screenshots/04_curl.png)

### Multipart Form Data Preview
![FormData Preview](https://raw.githubusercontent.com/igloodev/igloo_dio_logger/master/screenshots/05_formdata.png)

### GraphQL Support
![GraphQL Support](https://raw.githubusercontent.com/igloodev/igloo_dio_logger/master/screenshots/06_graphql.png)

### Request ID Tracking

Every request automatically gets a short 4-hex-digit ID (e.g. `#a3f2`).
The **same ID appears on the request block, the response block, and any error block** for that call.

This is useful when multiple requests fire at the same time — without an ID, interleaved logs are hard to read:

![Request ID Tracking](https://raw.githubusercontent.com/igloodev/igloo_dio_logger/master/screenshots/07_concurrent_requests_id.png)

> **How to use it:** When you see an unexpected response in the console, note its `ID:` value and search upward for the matching request block with the same ID. No configuration needed — IDs are generated automatically.

### Error Logging
![Error Logging](https://raw.githubusercontent.com/igloodev/igloo_dio_logger/master/screenshots/08_error.png)

## 🚀 Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  igloo_dio_logger: ^1.3.0
```

Run:
```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:dio/dio.dart';
import 'package:igloo_dio_logger/igloo_dio_logger.dart';

final dio = Dio();

// Add the logger interceptor
dio.interceptors.add(IglooDioLogger());

// Make requests
final response = await dio.get('https://api.example.com/users');
```

### Advanced Configuration

```dart
dio.interceptors.add(
  IglooDioLogger(
    // Show/hide different parts of the log
    logRequestHeader: true,
    logRequestBody: true,
    logResponseHeader: false,
    logResponseBody: true,
    logErrors: true,
    
    // Control the width of the log output
    maxWidth: 90,
    
    // Filter by endpoints (regex patterns)
    includeEndpoints: [r'/api/v1/auth/.*', r'/api/v1/recipes/.*'],
    excludeEndpoints: [r'/api/v1/health'],
    
    // Only log errors (4xx, 5xx status codes)
    onlyErrors: false,
    
    // Only log slow requests (in milliseconds)
    slowRequestThresholdMs: 200, // Only log requests that take 200ms or more
  ),
);
```

## 🎯 Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `logRequestHeader` | `bool` | `true` | Show request headers |
| `logRequestBody` | `bool` | `true` | Show request body |
| `logResponseHeader` | `bool` | `false` | Show response headers |
| `logResponseBody` | `bool` | `true` | Show response body |
| `logErrors` | `bool` | `true` | Show errors |
| `logCurl` | `bool` | `false` | Print a copy-pasteable cURL command after each request |
| `maxWidth` | `int` | `90` | Maximum width of log output |
| `includeEndpoints` | `List<String>?` | `null` | Only log matching endpoints (regex) |
| `excludeEndpoints` | `List<String>?` | `null` | Exclude matching endpoints (regex) |
| `onlyErrors` | `bool` | `false` | Only log error responses (4xx, 5xx) |
| `slowRequestThresholdMs` | `int?` | `null` | Only log requests slower than X ms |

## 📋 Examples

### Filter Specific Endpoints

```dart
dio.interceptors.add(
  IglooDioLogger(
    // Only log authentication and user endpoints
    includeEndpoints: [r'/auth/.*', r'/users/.*'],
  ),
);
```

### Log Only Errors

```dart
dio.interceptors.add(
  IglooDioLogger(
    // Only show failed requests
    onlyErrors: true,
  ),
);
```

### Log Only Slow Requests

```dart
dio.interceptors.add(
  IglooDioLogger(
    // Only log requests that take more than 500ms
    slowRequestThresholdMs: 500,
  ),
);
```

### Log cURL Commands

Enable `logCurl: true` to print a ready-to-paste cURL command after every request.
The cURL block uses the same `╔═══ ... ╚═══` bordered style as request/response logs.

```dart
dio.interceptors.add(
  IglooDioLogger(logCurl: true),
);
```

**Body handling at a glance:**

| Body type | cURL output |
|---|---|
| `Map` / `List` / `String` | `-d '{"key":"value"}'` |
| `FormData` (text fields) | `--form 'key=value'` per field |
| `FormData` (file fields) | `--form 'key=@"filename"'` — replace with full path |
| `Uint8List` / `List<int>` | Body omitted + `⚠️` note to use `--data-binary '@/path'` |
| Other / unknown | Body omitted + `⚠️` note with the runtime type |

> **Windows users:** cURL syntax uses bash `\` line continuation and single-quoted values.
> Run in WSL, Git Bash, or adapt manually: `\` → `^`, `'...'` → `"..."` with `\"` escaping.

### Production-Safe Setup

```dart
import 'package:flutter/foundation.dart';

dio.interceptors.add(
  IglooDioLogger(
    // Minimal logging for production debugging
    logRequestBody: kDebugMode,
    logResponseBody: kDebugMode,
    onlyErrors: !kDebugMode, // In release, only log errors
  ),
);
```

## 🎨 Status Code Emojis

The logger uses specific emojis for different HTTP status codes:

### 2xx Success
- ✅ 200 OK
- ✨ 201 Created
- ⏳ 202 Accepted
- ⭕ 204 No Content

### 3xx Redirection
- ↪️ 301 Moved Permanently
- 🔄 302 Found
- 📦 304 Not Modified

### 4xx Client Errors
- ⚠️ 400 Bad Request
- 🔒 401 Unauthorized
- 🚫 403 Forbidden
- 🔍 404 Not Found
- 🚷 405 Method Not Allowed
- ⏱️ 408 Request Timeout
- ⚔️ 409 Conflict
- 📋 422 Unprocessable Entity
- 🚦 429 Too Many Requests

### 5xx Server Errors
- 💥 500 Internal Server Error
- 🚧 502 Bad Gateway
- 🔴 503 Service Unavailable
- ⌛ 504 Gateway Timeout

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Created with ❤️ by [Akhilesh](https://igloodev.github.io/)


## 🙏 Acknowledgments

- Inspired by the need for better HTTP logging in Flutter/Dio projects
- ANSI color codes for beautiful terminal output
- Emojis for quick visual status recognition

## 📚 Additional Resources

- [Dio Documentation](https://pub.dev/packages/dio)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

---

If you find this package useful, please give it a ⭐ on [GitHub](https://github.com/igloodev/igloo_dio_logger) and a 👍 on [pub.dev](https://pub.dev/packages/igloo_dio_logger)!
