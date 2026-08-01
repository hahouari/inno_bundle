/// Error thrown by inno_bundle internal validation when input is invalid or
/// a precondition is not met.
///
/// The `bin/` entry points catch this and call [CliLogger.exitError] to print
/// the message and exit with a non-zero code. Tests catch it directly to
/// assert validation failures without forking a process.
class InnoBundleError extends Error {
  /// Human-readable description of what went wrong.
  final String message;

  /// Creates an error with the given [message].
  InnoBundleError(this.message);

  @override
  String toString() => message;
}
