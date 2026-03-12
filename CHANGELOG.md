## 1.0.1

* Fixed JSON array item comment bug (was showing "LoggerConstants.textItemComment" instead of "// item")
* Renamed file from `colored_dio_logger.dart` to `igloo_dio_logger.dart` to match class name
* Renamed test file from `colored_dio_logger_test.dart` to `igloo_dio_logger_test.dart` for consistency

## 1.0.0

* Initial release
* Beautiful colored HTTP logging with ANSI colors
* Emoji status indicators for HTTP status codes
* Request/Response size tracking
* Duration tracking
* Advanced filtering options (endpoints, errors, duration)
* Pretty JSON formatting with syntax highlighting
* Smart header wrapping for long values
* Production-safe (only logs in debug mode)
