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

/// Class holding the deferred message properties.
class DeferredMessage {
  /// The message text.
  final String text;

  /// The message kind.
  final CliLoggerKind kind;

  /// Creates a [DeferredMessage] instance with the given properties.
  const DeferredMessage(this.text, this.kind);
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
  /// Static list of deferred messages.
  static final List<DeferredMessage> _deferredMessages = [];

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
  static Never exitError(
    String message, {
    CliLoggerLevel level = CliLoggerLevel.one,
    int exitCode = 1,
  }) {
    CliLogger.error(message, level: level);
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

  /// Adds a message to the list of deferred messages.
  static void addDeferred(String message, {required CliLoggerKind kind}) {
    _deferredMessages.add(DeferredMessage(message, kind));
  }

  /// Prints all deferred messages and clears the list.
  static void flushDeferred() {
    // Print empty line to separate deferred messages from the rest of the output
    if (_deferredMessages.isNotEmpty) print("");

    // Print all deferred messages
    for (final message in _deferredMessages) {
      switch (message.kind) {
        case CliLoggerKind.warning:
          warning(message.text);
          break;
        case CliLoggerKind.error:
          error(message.text);
          break;
        case CliLoggerKind.success:
          success(message.text);
          break;
        default:
          info(message.text);
          break;
      }
    }

    // Clear the list of deferred messages
    _deferredMessages.clear();
  }
}

/// Enum for the different logging kinds.
enum CliLoggerKind {
  info,
  warning,
  error,
  success,
}
