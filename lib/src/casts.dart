// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A mixin that adds [read], [readList], [readMap], [readMapList] methods.
abstract class CoerceReadMap implements Map {
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

/// Returns [any], coerced to the expected type [T].
///
/// If [any] is a common collection type (`Iterable` or `Map`), and the user
/// expects [T] to be a collection type, then an [UnsupportedError] is thrown.
T coercePrimitive<T>(dynamic any) {
  if (any is Iterable && T != dynamic) {
    throw new UnsupportedError('$any is an Iterable. Use castList instead.');
  }
  if (any is Map && T != dynamic) {
    throw new UnsupportedError('$any is an Iterable. Use castMap instead.');
  }
  return any as T;
}

/// Returns [any], coerced to the expected `List<T>`.
///
/// **NOTE**: [T] must be non-generic, otherwise runtime cast errors may occur.
List<T> coerceList<T>(dynamic any) {
  if (T != dynamic) {
    final untypedList = any as List;
    return untypedList.cast<T>();
  }
  return any as List<T>;
}

/// Returns [any], coerced to the expected `Map<K, V>`.
///
/// **NOTE**: [K], [V] must be non-generic, otherwise runtime cast errors may
/// occur. The [coerceMapList] method may be used when [V] is expected to be a
/// list type.
Map<K, V> coerceMap<K, V>(dynamic any) {
  if (K != dynamic && V != dynamic) {
    final untypedMap = any as Map;
    return untypedMap.cast<K, V>();
  }
  return any as Map<K, V>;
}

/// Returns [any], coerced to the expected `Map<K, List<V>>`.
///
/// This may return a _new_ instance of the [Map], not the existing one.
///
/// **NOTE**: [K], [V] must be non-generic, otherwise runtime cast errors may
/// occur.
Map<K, List<V>> coerceMapList<K, V>(dynamic any) {
  final untypedMap = any as Map;
  return untypedMap.map((k, v) {
    return new MapEntry<K, List<V>>(k as K, (v as List).cast<V>());
  });
}
