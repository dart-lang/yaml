// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
