// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:yaml/yaml.dart';

const String _yaml = '''
message: this is a message
 
map: 
  message: this is the map message
  another: this is another

list:
  - 1
  - 2  
  - 3 

complex:
  message: this is more complex
  list:
    - 1
    - 2
    - 3

morecomplex:
  - complex:
      message: this is even more complex
      list:
        - 1
        - 2
        - 3
  - complex:
      message: this also
      list:
        - 1
        - 2
        - 3
''';

/// this boilerplate-y code illustrate how to access a [YamlDocument]
/// and the [YamlMap] through the [YamlNode]

YamlMap get yamlMap {
  final _yamlDocument = loadYamlDocument(_yaml);
  final _yamlNode = _yamlDocument.contents;
  return _yamlNode.value;
}

void main() {
  final _yamlMap = yamlMap;
  {
    /// this reads a [String] from [YamlMap] providing a [key]
    final String _message = _yamlMap['message'];
    print(_message);
  }
  {
    /// this reads a [YamlMap] from [YamlMap] providing a [key]
    final YamlMap _map = _yamlMap['map'];
    final String _message = _map['message'];
    final String _another = _map['another'];
    print(_message);
    print(_another);
  }
  {
    /// this reads a [YamlList] from [YamlMap] providing a [key]
    final YamlList yamlList = _yamlMap['list'];
    final _integers = <int>[for (int i in yamlList) i];
    print('${_integers}');
  }
  {
    /// gets from [YamlMap] a [YamlMap] which has as values
    /// a [String] and a [List<int>]
    final YamlMap _complex = _yamlMap['complex'];
    final String _message = _complex['message'];
    print(_message);
    final YamlList _yamlList = _complex['list'];
    final _integers = <int>[for (int i in _yamlList) i];
    print('${_integers}');
  }
  {
    /// gets from [YamlMap] a [List<YamlMap>] each of those have as values
    /// a [String] and a [List<int>]
    final YamlList _moreComplex = _yamlMap['morecomplex'];
    final _maps = <YamlMap>[for (dynamic d in _moreComplex) d['complex']];
    for (var complex in _maps) {
      final String _message = complex['message'];
      print(_message);
      final YamlList _yamlList = complex['list'];
      final _integers = <int>[for (int i in _yamlList) i];
      print('${_integers}');
    }
  }
}
