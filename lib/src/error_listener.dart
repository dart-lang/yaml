import 'yaml_exception.dart';

/// A listener that is notified of [YamlError]s during scanning/parsing.
abstract class ErrorListener {
  /// This method is invoked when an [error] has been found in the YAML.
  void onError(YamlException error);
}

/// An [ErrorListener] that collects all errors into [errors].
class ErrorCollector extends ErrorListener {
  final List<YamlException> errors = [];

  @override
  void onError(YamlException error) => errors.add(error);
}
