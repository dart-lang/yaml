// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('YamlMap() with no sourceUrl', () {
    var map = YamlMap();
    expect(map, isEmpty);
    expect(map.nodes, isEmpty);
    expect(map.span, isNullSpan(isNull));
  });

  test('YamlMap() with a sourceUrl', () {
    var map = YamlMap(sourceUrl: 'source');
    expect(map.span, isNullSpan(Uri.parse('source')));
  });

  test('YamlList() with no sourceUrl', () {
    var list = YamlList();
    expect(list, isEmpty);
    expect(list.nodes, isEmpty);
    expect(list.span, isNullSpan(isNull));
  });

  test('YamlList() with a sourceUrl', () {
    var list = YamlList(sourceUrl: 'source');
    expect(list.span, isNullSpan(Uri.parse('source')));
  });

  test('YamlMap.wrap() with no sourceUrl', () {
    var map = YamlMap.wrap({
      'list': [1, 2, 3],
      'map': {
        'foo': 'bar',
        'nested': [4, 5, 6]
      },
      'scalar': 'value'
    });

    expect(
        map,
        equals({
          'list': [1, 2, 3],
          'map': {
            'foo': 'bar',
            'nested': [4, 5, 6]
          },
          'scalar': 'value'
        }));

    expect(map.span, isNullSpan(isNull));
    expect(map['list'], TypeMatcher<YamlList>());
    expect(map['list'].nodes[0], TypeMatcher<YamlScalar>());
    expect(map['list'].span, isNullSpan(isNull));
    expect(map['map'], TypeMatcher<YamlMap>());
    expect(map['map'].nodes['foo'], TypeMatcher<YamlScalar>());
    expect(map['map']['nested'], TypeMatcher<YamlList>());
    expect(map['map'].span, isNullSpan(isNull));
    expect(map.nodes['scalar'], TypeMatcher<YamlScalar>());
    expect(map.nodes['scalar'].value, 'value');
    expect(map.nodes['scalar'].span, isNullSpan(isNull));
    expect(map['scalar'], 'value');
    expect(map.keys, unorderedEquals(['list', 'map', 'scalar']));
    expect(map.nodes.keys, everyElement(TypeMatcher<YamlScalar>()));
    expect(map.nodes[YamlScalar.wrap('list')], equals([1, 2, 3]));
  });

  test('YamlMap.wrap() with a sourceUrl', () {
    var map = YamlMap.wrap({
      'list': [1, 2, 3],
      'map': {
        'foo': 'bar',
        'nested': [4, 5, 6]
      },
      'scalar': 'value'
    }, sourceUrl: 'source');

    var source = Uri.parse('source');
    expect(map.span, isNullSpan(source));
    expect(map['list'].span, isNullSpan(source));
    expect(map['map'].span, isNullSpan(source));
    expect(map.nodes['scalar'].span, isNullSpan(source));
  });

  test('YamlList.wrap() with no sourceUrl', () {
    var list = YamlList.wrap([
      [1, 2, 3],
      {
        'foo': 'bar',
        'nested': [4, 5, 6]
      },
      'value'
    ]);

    expect(
        list,
        equals([
          [1, 2, 3],
          {
            'foo': 'bar',
            'nested': [4, 5, 6]
          },
          'value'
        ]));

    expect(list.span, isNullSpan(isNull));
    expect(list[0], TypeMatcher<YamlList>());
    expect(list[0].nodes[0], TypeMatcher<YamlScalar>());
    expect(list[0].span, isNullSpan(isNull));
    expect(list[1], TypeMatcher<YamlMap>());
    expect(list[1].nodes['foo'], TypeMatcher<YamlScalar>());
    expect(list[1]['nested'], TypeMatcher<YamlList>());
    expect(list[1].span, isNullSpan(isNull));
    expect(list.nodes[2], TypeMatcher<YamlScalar>());
    expect(list.nodes[2].value, 'value');
    expect(list.nodes[2].span, isNullSpan(isNull));
    expect(list[2], 'value');
  });

  test('YamlList.wrap() with a sourceUrl', () {
    var list = YamlList.wrap([
      [1, 2, 3],
      {
        'foo': 'bar',
        'nested': [4, 5, 6]
      },
      'value'
    ]);

    expect(list.span, isNullSpan(isNull));
    expect(list[0].span, isNullSpan(isNull));
    expect(list[1].span, isNullSpan(isNull));
    expect(list.nodes[2].span, isNullSpan(isNull));
  });

  test('re-wrapped objects equal one another', () {
    var list = YamlList.wrap([
      [1, 2, 3],
      {'foo': 'bar'}
    ]);

    expect(list[0] == list[0], isTrue);
    expect(list[0].nodes == list[0].nodes, isTrue);
    expect(list[0] == YamlList.wrap([1, 2, 3]), isFalse);
    expect(list[1] == list[1], isTrue);
    expect(list[1].nodes == list[1].nodes, isTrue);
    expect(list[1] == YamlMap.wrap({'foo': 'bar'}), isFalse);
  });
}

Matcher isNullSpan(sourceUrl) => predicate((span) {
      expect(span, TypeMatcher<SourceSpan>());
      expect(span.length, equals(0));
      expect(span.text, isEmpty);
      expect(span.start, equals(span.end));
      expect(span.start.offset, equals(0));
      expect(span.start.line, equals(0));
      expect(span.start.column, equals(0));
      expect(span.sourceUrl, sourceUrl);
      return true;
    });
