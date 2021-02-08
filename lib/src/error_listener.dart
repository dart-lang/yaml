import 'package:source_span/source_span.dart';

import 'yaml_exception.dart';

/// A listener that is notified of [YamlError]s during scanning/parsing.
abstract class ErrorListener {
  /// This method is invoked when an [error] has been found in the YAML.
  void onError(YamlError error);
}

/// An error found in the YAML.
class YamlError {
  /// A message describing the exception.
  final String message;

  /// The span associated with this exception.
  final FileSpan span;

  YamlError(this.message, this.span);
}

extension YamlErrorExtensions on YamlError {
  /// Creates a [YamlException] from a [YamlError].
  YamlException toException() => YamlException(message, span);
}

/// An [ErrorListener] that collects all errors into [errors].
class ErrorCollector extends ErrorListener {
  final List<YamlError> errors = [];

  @override
  void onError(YamlError error) => errors.add(error);
}
