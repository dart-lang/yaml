// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

final _isDart2Enabled = _typeOf<String>() == String;
Type _typeOf<T>() => T;

void main() {
  test('read should return a primitive type', () {
    var yamlMap = new YamlMap.wrap({
      'x': 'Jill',
    });
    String name = yamlMap.read('x');
    expect(name, 'Jill');
  });

  test('read should throw on a List', () {
    var yamlMap = new YamlMap.wrap({
      'x': ['Jill'],
    });
    expect(() => yamlMap.read<List<String>>('x'), throwsUnsupportedError);
  }, skip: !_isDart2Enabled);

  test('read should throw on a Map', () {
    var yamlMap = new YamlMap.wrap({
      'x': {
        1: 'Jill',
      },
    });
    expect(() => yamlMap.read<Map<int, String>>('x'), throwsUnsupportedError);
  }, skip: !_isDart2Enabled);

  test('readList should return a reified List<T>', () {
    var yamlMap = new YamlMap.wrap({
      'x': ['Jill'],
    });
    List<String> value = yamlMap.readList('x');
    expect(value, const isInstanceOf<List<String>>());
  }, skip: !_isDart2Enabled);

  test('readMap should return a reified Map<K, V>', () {
    var yamlMap = new YamlMap.wrap({
      'x': {
        1: 'Jill',
      },
    });
    Map<int, String> value = yamlMap.readMap('x');
    expect(value, const isInstanceOf<Map<int, String>>());
  }, skip: !_isDart2Enabled);

  test('readMapList should return a reified Map<K, List<V>>', () {
    var yamlMap = new YamlMap.wrap({
      'x': {
        1: ['Jill'],
      },
    });
    Map<int, List<String>> value = yamlMap.readMapList('x');
    expect(value, const isInstanceOf<Map<int, List<String>>>());
  }, skip: !_isDart2Enabled);
}
