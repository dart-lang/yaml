A parser for [YAML](http://www.yaml.org/).

[![Pub Package](https://img.shields.io/pub/v/yaml.svg)](https://pub.dev/packages/yaml)
[![Build Status](https://travis-ci.org/dart-lang/yaml.svg?branch=master)](https://travis-ci.org/dart-lang/yaml)

Use `loadYaml` to load a single document, or `loadYamlStream` to load a
stream of documents. For example:

```dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

void main() {
  String pathToYaml =
      join(dirname(Platform.script.toFilePath()), '../pubspec.yaml');
  File f = new File(pathToYaml);
  String yamlText = f.readAsStringSync();
  // print(yamlText);
  Map yaml = loadYaml(yamlText) as Map;
  Map _yaml = yaml['dependencies'] as Map;
  _yaml.forEach((k, v) =>
      print('$k: $v')); // printing subsets and this is without comments.
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
