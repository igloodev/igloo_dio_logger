# Colored Dio Logger 🎨

A beautiful HTTP request/response logger for Dio with ANSI colors, emojis, and advanced filtering options.

![Colored Dio Logger](https://img.shields.io/pub/v/igloo_dio_logger.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

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
- 🎯 **Smart header wrapping** for long values (like JWT tokens)
- 📝 **Structured output** similar to Flutter's code folding comments
- ⚡ **Zero performance impact** in release mode (only logs in debug mode)

## 📸 Screenshots

### Request Logging
```
╔═══ 🚀 HTTP REQUEST ═══════════════════════════════════════════════
║ POST /api/v1/auth/login │ 156B
║
║ Headers:
║   content-type: application/json
║   authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
║
║ Body:
║   {
║     "email": "user@example.com",
║     "password": "********"
║   }
╚═══════════════════════════════════════════════════════════════════
```

### Response Logging
```
╔═══ ✅ HTTP RESPONSE ══════════════════════════════════════════════
║ POST /api/v1/auth/login
║ Status: 200 ✅ │ Duration: 245ms │ Size: 1.24KB
║
║ Body:
║   {
║     "success": true,
║     "data": {
║       "user": {
║         "id": "123",
║         "email": "user@example.com"
║       }, // user
║       "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
║     } // data
║   }
╚═══════════════════════════════════════════════════════════════════
```

### Error Logging
```
╔═══ ❌ HTTP ERROR ═════════════════════════════════════════════════
║ GET /api/v1/recipes/999
║ DioExceptionType.badResponse │ Duration: 89ms
║ The request returned an invalid status code of 404
║
║ Status: 404
║
║ Response:
║   {
║     "success": false,
║     "message": "Recipe not found"
║   }
╚═══════════════════════════════════════════════════════════════════
```

## 🚀 Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  igloo_dio_logger: ^1.0.0
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
dio.interceptors.add(ColoredDioLogger());

// Make requests
final response = await dio.get('https://api.example.com/users');
```

### Advanced Configuration

```dart
dio.interceptors.add(
  ColoredDioLogger(
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
| `maxWidth` | `int` | `90` | Maximum width of log output |
| `includeEndpoints` | `List<String>?` | `null` | Only log matching endpoints (regex) |
| `excludeEndpoints` | `List<String>?` | `null` | Exclude matching endpoints (regex) |
| `onlyErrors` | `bool` | `false` | Only log error responses (4xx, 5xx) |
| `slowRequestThresholdMs` | `int?` | `null` | Only log requests slower than X ms |

## 📋 Examples

### Filter Specific Endpoints

```dart
dio.interceptors.add(
  ColoredDioLogger(
    // Only log authentication and user endpoints
    includeEndpoints: [r'/auth/.*', r'/users/.*'],
  ),
);
```

### Log Only Errors

```dart
dio.interceptors.add(
  ColoredDioLogger(
    // Only show failed requests
    onlyErrors: true,
  ),
);
```

### Log Only Slow Requests

```dart
dio.interceptors.add(
  ColoredDioLogger(
    // Only log requests that take more than 500ms
    slowRequestThresholdMs: 500,
  ),
);
```

### Production-Safe Setup

```dart
import 'package:flutter/foundation.dart';

dio.interceptors.add(
  ColoredDioLogger(
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

If you find this package useful, please give it a ⭐ on [GitHub](https://github.com/yourusername/igloo_dio_logger)!
