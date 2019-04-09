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
  YamlMap yaml;

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

  test('first root key', () {
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

    test('first root key', () {
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

    test('first root key', () {
      _expectSpan(
        nestedMap.nodes['num'].span,
        r'''
line 5, column 10: message
  ╷
5 │     "num": 42
  │ ┌──────────^
6 │ │  },
  │ └─^
  ╵''',
      );
    });
  });
}
