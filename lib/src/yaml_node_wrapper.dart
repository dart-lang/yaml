// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart' as pkg_collection;
import 'package:source_span/source_span.dart';

import 'casts.dart';
import 'null_span.dart';
import 'style.dart';
import 'yaml_node.dart';

/// A wrapper that makes a normal Dart map behave like a [YamlMap].
class YamlMapWrapper extends MapBase
    with CoerceReadMap, pkg_collection.UnmodifiableMapMixin
    implements YamlMap {
  final CollectionStyle style = CollectionStyle.ANY;

  final Map _dartMap;

  final SourceSpan span;

  final Map<dynamic, YamlNode> nodes;

  Map get value => this;

  Iterable get keys => _dartMap.keys;

  YamlMapWrapper(Map dartMap, sourceUrl)
      : this._(dartMap, new NullSpan(sourceUrl));

  YamlMapWrapper._(Map dartMap, SourceSpan span)
      : _dartMap = dartMap,
        span = span,
        nodes = new _YamlMapNodes(dartMap, span);

  operator [](Object key) {
    var value = _dartMap[key];
    if (value is Map) return new YamlMapWrapper._(value, span);
    if (value is List) return new YamlListWrapper._(value, span);
    return value;
  }

  int get hashCode => _dartMap.hashCode;

  operator ==(Object other) =>
      other is YamlMapWrapper && other._dartMap == _dartMap;

  /// Reads the value of [key], and returns as the expected type [T].
  ///
  /// If [any] is a common collection type (`Iterable` or `Map`), and the user
  /// expects [T] to be a collection type, then an [UnsupportedError] is thrown.
  T read<T>(dynamic key) => coercePrimitive(this[key]);

  /// Reads the value of [key], coerced to the expected `List<T>`.
  ///
  /// **NOTE**: [T] must be non-generic, otherwise runtime cast errors may
  /// occur.
  List<T> readList<T>(dynamic key) => coerceList(this[key]);

  /// Reads the value of [key], coerced to the expected `Map<K, V>`.
  ///
  /// **NOTE**: [K], [V] must be non-generic, otherwise runtime cast errors may
  /// occur. The [coerceMapList] method may be used when [V] is expected to be a
  /// list type.
  Map<K, V> readMap<K, V>(dynamic key) => coerceMap(this[key]);

  /// Reads the value of [key], coerced to the expected `Map<K, List<V>>`.
  ///
  /// This may return a _new_ instance of the [Map], not the existing one.
  ///
  /// **NOTE**: [K], [V] must be non-generic, otherwise runtime cast errors may
  /// occur.
  Map<K, List<V>> readMapList<K, V>(dynamic key) => coerceMapList(this[key]);
}

/// The implementation of [YamlMapWrapper.nodes] as a wrapper around the Dart
/// map.
class _YamlMapNodes extends MapBase<dynamic, YamlNode>
    with pkg_collection.UnmodifiableMapMixin<dynamic, YamlNode> {
  final Map _dartMap;

  final SourceSpan _span;

  Iterable get keys =>
      _dartMap.keys.map((key) => new YamlScalar.internalWithSpan(key, _span));

  _YamlMapNodes(this._dartMap, this._span);

  YamlNode operator [](Object key) {
    // Use "as" here because key being assigned to invalidates type propagation.
    if (key is YamlScalar) key = (key as YamlScalar).value;
    if (!_dartMap.containsKey(key)) return null;
    return _nodeForValue(_dartMap[key], _span);
  }

  int get hashCode => _dartMap.hashCode;

  operator ==(Object other) =>
      other is _YamlMapNodes && other._dartMap == _dartMap;
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// A wrapper that makes a normal Dart list behave like a [YamlList].
class YamlListWrapper extends ListBase implements YamlList {
  final CollectionStyle style = CollectionStyle.ANY;

  final List _dartList;

  final SourceSpan span;

  final List<YamlNode> nodes;

  List get value => this;

  int get length => _dartList.length;

  set length(int index) {
    throw new UnsupportedError("Cannot modify an unmodifiable List.");
  }

  YamlListWrapper(List dartList, sourceUrl)
      : this._(dartList, new NullSpan(sourceUrl));

  YamlListWrapper._(List dartList, SourceSpan span)
      : _dartList = dartList,
        span = span,
        nodes = new _YamlListNodes(dartList, span);

  operator [](int index) {
    var value = _dartList[index];
    if (value is Map) return new YamlMapWrapper._(value, span);
    if (value is List) return new YamlListWrapper._(value, span);
    return value;
  }

  operator []=(int index, value) {
    throw new UnsupportedError("Cannot modify an unmodifiable List.");
  }

  int get hashCode => _dartList.hashCode;

  operator ==(Object other) =>
      other is YamlListWrapper && other._dartList == _dartList;
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// The implementation of [YamlListWrapper.nodes] as a wrapper around the Dart
/// list.
class _YamlListNodes extends ListBase<YamlNode> {
  final List _dartList;

  final SourceSpan _span;

  int get length => _dartList.length;

  set length(int index) {
    throw new UnsupportedError("Cannot modify an unmodifiable List.");
  }

  _YamlListNodes(this._dartList, this._span);

  YamlNode operator [](int index) => _nodeForValue(_dartList[index], _span);

  operator []=(int index, value) {
    throw new UnsupportedError("Cannot modify an unmodifiable List.");
  }

  int get hashCode => _dartList.hashCode;

  operator ==(Object other) =>
      other is _YamlListNodes && other._dartList == _dartList;
}

YamlNode _nodeForValue(value, SourceSpan span) {
  if (value is Map) return new YamlMapWrapper._(value, span);
  if (value is List) return new YamlListWrapper._(value, span);
  return new YamlScalar.internalWithSpan(value, span);
}
