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
