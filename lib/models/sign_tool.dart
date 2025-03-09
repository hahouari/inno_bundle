/// A class that holds the properties related to the signing tool used by Inno Setup,
/// based on the directives in the Setup section.
///
/// The [SignTool] class encapsulates details such as the tool's name, the command
/// used to invoke it, additional parameters, and retry configurations. It also provides
/// methods for validating and parsing configuration options to create an instance of [SignTool].
///
/// Example usage:
/// ```dart
/// var signTool = SignTool(
///   name: "MySignTool",
///   command: "signtool.exe $p",
///   params: "/a /tr http://timestamp.url",
///   retryCount: 2,
///   retryDelay: 200,
/// );
///
/// print(signTool.inno);
/// // Outputs:
/// // SignTool=MySignTool /a /tr http://timestamp.url
/// // SignToolRetryCount=2
/// // SignToolRetryDelay=200
/// ```
///
/// Properties:
/// - [name]: The name of the signing tool.
/// - [command]: The command used to invoke the signing tool.
/// - [params]: Additional parameters passed to the signing tool.
/// - [retryCount]: The number of times to retry the signing operation on failure.
/// - [retryDelay]: The delay in milliseconds between retry attempts.
///
/// Methods:
/// - [validateConfig]: Validates the configuration option for [SignTool]. Returns a string describing the error, or `null` if valid.
/// - [fromOption]: Parses the configuration option into a [SignTool] instance. Accepts both string and map formats.
/// - [inno]: Generates the Inno Setup script directives for the signing tool configuration.
library;

/// Class holding the sign tool properties based on Inno Setup approach and Setup section directives
class SignTool {
  /// The name of the signing tool.
  final String name;

  /// The command used to invoke the signing tool.
  final String command;

  /// Additional parameters passed to the signing tool.
  final String params;

  /// The number of times to retry the signing operation on failure.
  final int retryCount;

  /// The delay in milliseconds between retry attempts.
  final int retryDelay;

  const SignTool({
    required this.name,
    required this.command,
    required this.params,
    required this.retryCount,
    required this.retryDelay,
  });

  /// Validate configuration option for [SignTool]
  static String? validateConfig(
    dynamic option, {
    String? signToolName,
    String? signToolCommand,
    String? signToolParams,
  }) {
    if (option == null || option is String) return null;
    if (option is Map<String, dynamic>) {
      if ((signToolName ?? option['name']) == null &&
          (signToolCommand ?? option['command']) == null) {
        return "inno_bundle.sign_tool on pubspec.yaml is expected to be "
            "of type String or to at least have name or command fields.";
      }
      return null;
    }

    return "inno_bundle.sign_tool attribute is invalid in pubspec.yaml.";
  }

  /// Parses configuration option to the desired [SignTool].
  static SignTool? fromOption(
    dynamic option, {
    String? signToolName,
    String? signToolCommand,
    String? signToolParams,
  }) {
    if (option == null) {
      if (signToolName != null ||
          signToolCommand != null ||
          signToolParams != null) {
        return SignTool(
          name: signToolName ?? "InnoBundleTool",
          command: signToolCommand ?? "",
          params: signToolParams ?? "",
          retryCount: 2,
          retryDelay: 500,
        );
      } else {
        return null;
      }
    }
    if (option is String) {
      return SignTool(
        name: signToolName ?? "InnoBundleTool",
        command: signToolCommand ?? option,
        params: signToolParams ?? "",
        retryCount: 2,
        retryDelay: 500,
      );
    }
    final map = option as Map<String, dynamic>;
    return SignTool(
      name: signToolName ?? map['name'] ?? "InnoBundleTool",
      command: signToolCommand ?? map["command"] ?? "",
      params: signToolParams ?? map["params"] ?? "",
      retryCount: map["retry_count"] ?? 2,
      retryDelay: map["retry_delay"] ?? 500,
    );
  }

  /// Get inno setup code based on this [SignTool] values.
  String toInnoCode() {
    return """
SignTool=$name $params
SignToolRetryCount=$retryCount
SignToolRetryDelay=$retryDelay
""";
  }
}
