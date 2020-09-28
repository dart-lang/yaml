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
  return _yamlNode.value as YamlMap;
}

void main() {
  final _yamlMap = yamlMap;
  {
    /// this reads a [String] from [YamlMap] providing a [key]
    final _message = _yamlMap['message'] as String;
    print(_message);
  }
  {
    /// this reads a [YamlMap] from [YamlMap] providing a [key]
    final _map = _yamlMap['map'] as YamlMap;
    final _message = _map['message'] as String;
    final _another = _map['another'] as String;
    print(_message);
    print(_another);
  }
  {
    /// this reads a [YamlList] from [YamlMap] providing a [key]
    final yamlList = _yamlMap['list'] as YamlList;
    final _integers = <int>[for (YamlNode i in yamlList.nodes) i.value as int];
    print('$_integers');
  }
  {
    /// gets from [YamlMap] a [YamlMap] which has as values
    /// a [String] and a [List<int>]
    final _complex = _yamlMap['complex'] as YamlMap;
    final _message = _complex['message'] as String;
    print(_message);
    final yamlList = _complex['list'] as YamlList;
    final _integers = <int>[for (YamlNode i in yamlList.nodes) i.value as int];
    print('$_integers');
  }
  {
    /// gets from [YamlMap] a [List<YamlMap>] each of those have as values
    /// a [String] and a [List<int>]
    final _moreComplex = _yamlMap['morecomplex'] as YamlList;
    final _maps = <YamlMap>[
      for (YamlNode d in _moreComplex.nodes) d.value['complex'] as YamlMap
    ];
    for (var complex in _maps) {
      final _message = complex['message'] as String;
      print(_message);
      final _yamlList = complex['list'] as YamlList;
      final _integers = <int>[
        for (YamlNode i in _yamlList.nodes) i.value as int
      ];
      print('$_integers');
    }
  }
}
