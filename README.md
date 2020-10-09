A parser for [YAML](https://yaml.org/).

[![Pub Package](https://img.shields.io/pub/v/yaml.svg)](https://pub.dev/packages/yaml)
[![Build Status](https://travis-ci.org/dart-lang/yaml.svg?branch=master)](https://travis-ci.org/dart-lang/yaml)

Use `loadYaml` to load a single document, or `loadYamlStream` to load a
stream of documents. For example:

```dart
import 'package:yaml/yaml.dart';

main() {
  var doc = loadYaml("YAML: YAML Ain't Markup Language");
  print(doc['YAML']);
}
```

This library currently doesn't support dumping to YAML. You should use
`json.encode` from `dart:convert` instead:

```dart
import 'dart:convert';
import 'package:yaml/yaml.dart';

main() {
  var doc = loadYaml("YAML: YAML Ain't Markup Language");
  print(json.encode(doc));
}
```
