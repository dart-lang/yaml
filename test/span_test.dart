// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:source_span/source_span.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void _expectSpan(SourceSpan source, String expected) {
  final result = source.message('message');
  printOnFailure("r'''\n$result'''");

  expect(result, expected);
}

void main() {
  YamlMap yaml, yaml_n0, yaml_n1, yaml_n2, yaml_n3;

  setUpAll(() {
    yaml = loadYaml(const JsonEncoder.withIndent(' ').convert({
      'num': 42,
      'nested': {
        'null': null,
        'num': 42,
      },
      'null': null,
    })) as YamlMap;
  });

  test('first root key', () {
    _expectSpan(
      yaml.nodes['num'].span,
      r'''
line 2, column 9: message
  ╷
2 │  "num": 42,
  │         ^^
  ╵''',
    );
  });

  test('last root key', () {
    _expectSpan(
      yaml.nodes['null'].span,
      r'''
line 7, column 10: message
  ╷
7 │  "null": null
  │          ^^^^
  ╵''',
    );
  });

  group('nested', () {
    YamlMap nestedMap;

    setUpAll(() {
      nestedMap = yaml.nodes['nested'] as YamlMap;
    });

    test('first nested key', () {
      _expectSpan(
        nestedMap.nodes['null'].span,
        r'''
line 4, column 11: message
  ╷
4 │   "null": null,
  │           ^^^^
  ╵''',
      );
    });

    test('last nested key', () {
      _expectSpan(
        nestedMap.nodes['num'].span,
        r'''
line 5, column 10: message
  ╷
5 │   "num": 42
  │          ^^
  ╵''',
      );
    });
  });

  group('all nested', () {
    setUpAll(() {
      const dtr = '''
  'nested_0': {
    'nested_1': {
      'nested_2': {
        'n2k1': null
        ,
        'n2k2': a
        ,
        'n2k3':                        4     
      },
      'n1k2': 425
    },
    'n0k2': aval      

                      ,
  }
  'rk2': 44
        ,
  ''';

      yaml_n0 = loadYaml(dtr) as YamlMap;
      yaml_n1 = yaml_n0.nodes['nested_0'] as YamlMap;
      yaml_n2 = yaml_n1.nodes['nested_1'] as YamlMap;
      yaml_n3 = yaml_n2.nodes['nested_2'] as YamlMap;
    });

    test('root last key', () {
      _expectSpan(yaml_n0.nodes['rk2'].span, r'''
line 16, column 10: message
   ╷
16 │     'rk2': 44
   │ ┌──────────^
17 │ └         ,
   ╵''');
    });

    test('nested level 1 last key', () {
      _expectSpan(yaml_n1.nodes['n0k2'].span, r'''
line 12, column 13: message
   ╷
12 │       'n0k2': aval      
   │ ┌─────────────^
13 │ │ 
14 │ │                       ,
   │ └──────────────────────^
   ╵''');
    });

    test('nested level 2 last key', () {
      _expectSpan(yaml_n2.nodes['n1k2'].span, r'''
line 10, column 15: message
   ╷
10 │       'n1k2': 425
   │               ^^^
   ╵''');
    });

    test('nested level 3 first key', () {
      _expectSpan(yaml_n3.nodes['n2k1'].span, r'''
line 4, column 17: message
  ╷
4 │           'n2k1': null
  │ ┌─────────────────^
5 │ │         ,
  │ └────────^
  ╵''');
    });

    test('nested level 3 mid key', () {
      _expectSpan(yaml_n3.nodes['n2k2'].span, r'''
line 6, column 17: message
  ╷
6 │           'n2k2': a
  │ ┌─────────────────^
7 │ │         ,
  │ └────────^
  ╵''');
    });

    test('nested level 3 last key', () {
      _expectSpan(yaml_n3.nodes['n2k3'].span, r'''
line 8, column 40: message
  ╷
8 │         'n2k3':                        4     
  │                                        ^
  ╵''');
    });
  });
}
