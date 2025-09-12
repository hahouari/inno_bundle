/// Provides a CLI logging utility with various log levels and colored output.
///
/// The `CliLogger` class offers methods for logging messages with different severity levels,
/// including `info`, `error`, `warning`, `success`, and `sLink` for logging links. It supports
/// customizable log levels and provides color-coded output using ANSI escape codes.
library;

import 'dart:io';

/// Log levels
enum CliLoggerLevel {
  /// Level one
  one,

  /// Level two
  two,

  /// Level three
  three,
}

// Reset:   \x1B[0m
// Black:   \x1B[30m
// White:   \x1B[37m
// Red:     \x1B[31m
// Green:   \x1B[32m
// Yellow:  \x1B[33m
// Blue:    \x1B[34m
// Cyan:    \x1B[36m

/// Cli Logger
class CliLogger {
  /// Constructor
  CliLogger();

  /// Log info
  static void info(
    String message, {
    CliLoggerLevel level = CliLoggerLevel.one,
  }) {
    final space = _getSpace(level);
    print('\x1B[34m$space🌱  $message\x1B[0m');
  }

  /// Logs a error message at the given level.
  static void error(
    String message, {
    CliLoggerLevel level = CliLoggerLevel.one,
  }) {
    final space = _getSpace(level);
    print('$space❌  $message');
  }

  /// Logs a error message at the given level and exits with given code.
  static void exitError(
    String message, {
    CliLoggerLevel level = CliLoggerLevel.one,
    int exitCode = 1,
  }) {
    final space = _getSpace(level);
    print('$space❌  $message');
    exit(exitCode);
  }

  /// Logs a warning message at the given level.
  static void warning(
    String message, {
    CliLoggerLevel level = CliLoggerLevel.one,
  }) {
    final space = _getSpace(level);
    print('\x1B[33m$space🚧  $message\x1B[0m');
  }

  /// Logs a success message at the given level.
  static void success(
    String message, {
    CliLoggerLevel level = CliLoggerLevel.one,
  }) {
    final space = _getSpace(level);
    print('\x1B[32m$space✅  $message\x1B[0m');
  }

  /// Logs a link as a underlined text.
  static String sLink(
    String link, {
    CliLoggerLevel level = CliLoggerLevel.one,
  }) {
    final space = _getSpace(level);
    return '\x1B[34m$space🔗  $link\x1B[0m';
  }

  static String _getSpace(CliLoggerLevel level) {
    var space = '';
    switch (level) {
      case CliLoggerLevel.one:
        space = '';
        break;
      case CliLoggerLevel.two:
        space = '      ';
        break;
      case CliLoggerLevel.three:
        space = '         ';
        break;
    }
    return space;
  }
}
