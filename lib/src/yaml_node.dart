// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' as collection;
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';

import 'event.dart';
import 'null_span.dart';
import 'style.dart';
import 'yaml_node_wrapper.dart';

/// An interface for parsed nodes from a YAML source tree.
///
/// [YamlMap]s and [YamlList]s implement this interface in addition to the
/// normal [Map] and [List] interfaces, so any maps and lists will be
/// [YamlNode]s regardless of how they're accessed.
///
/// Scalars values like strings and numbers, on the other hand, don't have this
/// interface by default. Instead, they can be accessed as [YamlScalar]s via
/// [YamlMap.nodes] or [YamlList.nodes].
abstract class YamlNode {
  /// The source span for this node.
  ///
  /// [SourceSpan.message] can be used to produce a human-friendly message about
  /// this node.
  SourceSpan get span => _span;

  SourceSpan _span;

  /// The inner value of this node.
  ///
  /// For [YamlScalar]s, this will return the wrapped value. For [YamlMap] and
  /// [YamlList], it will return [this], since they already implement [Map] and
  /// [List], respectively.
  dynamic get value;

  String toStringShaped({int indentOverride, CollectionStyle styleOverride});
}

/// A read-only [Map] parsed from YAML.
class YamlMap extends YamlNode with collection.MapMixin, UnmodifiableMapMixin {
  /// A view of [this] where the keys and values are guaranteed to be
  /// [YamlNode]s.
  ///
  /// The key type is `dynamic` to allow values to be accessed using
  /// non-[YamlNode] keys, but [Map.keys] and [Map.forEach] will always expose
  /// them as [YamlNode]s. For example, for `{"foo": [1, 2, 3]}` [nodes] will be
  /// a map from a [YamlScalar] to a [YamlList], but since the key type is
  /// `dynamic` `map.nodes["foo"]` will still work.
  final Map<dynamic, YamlNode> nodes;

  /// The style used for the map in the original document.
  final CollectionStyle style;

  @override
  Map get value => this;

  @override
  Iterable get keys => nodes.keys.map((node) => node.value);

  /// Creates an empty YamlMap.
  ///
  /// This map's [span] won't have useful location information. However, it will
  /// have a reasonable implementation of [SourceSpan.message]. If [sourceUrl]
  /// is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlMap({sourceUrl}) => YamlMapWrapper(const {}, sourceUrl);

  /// Wraps a Dart map so that it can be accessed (recursively) like a
  /// [YamlMap].
  ///
  /// Any [SourceSpan]s returned by this map or its children will be dummies
  /// without useful location information. However, they will have a reasonable
  /// implementation of [SourceSpan.getLocationMessage]. If [sourceUrl] is
  /// passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlMap.wrap(Map dartMap, {sourceUrl}) =>
      YamlMapWrapper(dartMap, sourceUrl);

  /// Users of the library should not use this constructor.
  YamlMap.internal(Map<dynamic, YamlNode> nodes, SourceSpan span, this.style)
      : nodes = UnmodifiableMapView<dynamic, YamlNode>(nodes) {
    _span = span;
  }

  @override
  dynamic operator [](key) => nodes[key]?.value;

  @override
  String toString() {
    return toStringShaped();
  }

  @override
  String toStringShaped({int indentOverride, CollectionStyle styleOverride}) {
    var result = '';
    styleOverride ??= style;
    if (styleOverride == CollectionStyle.ANY) {
      styleOverride = CollectionStyle.BLOCK;
    }
    switch (styleOverride) {
      case CollectionStyle.BLOCK:
        for (var node in nodes.entries) {
          if (result.isNotEmpty) {
            result +=
                '\n' + ((indentOverride != null) ? '  ' * indentOverride : '');
          }
          if (node.key is YamlScalar) {
            result += (node.key as YamlScalar).toStringShaped(
                    indentOverride:
                        (indentOverride != null) ? indentOverride : 0) +
                ': ';
          } else if (node.key is YamlList) {
            result += '? ' +
                (node.key as YamlList).toStringShaped(
                    indentOverride:
                        (indentOverride != null) ? indentOverride + 1 : 1);
            result += '\n:\n' +
                ((indentOverride != null) ? '  ' * (indentOverride + 1) : '  ');
          } else if (node.key is YamlMap) {
            result += '? ' +
                (node.key as YamlMap).toStringShaped(
                    indentOverride:
                        (indentOverride != null) ? indentOverride + 1 : 1);
            result += '\n:\n' +
                ((indentOverride != null) ? '  ' * (indentOverride + 1) : '  ');
          }
          result += node.value.toStringShaped(
              indentOverride:
                  (indentOverride != null) ? indentOverride + 1 : 1);
        }
        break;
      case CollectionStyle.FLOW:
        result += '{' +
            nodes.entries
                .map((e) =>
                    (e.key as YamlNode)
                        .toStringShaped(styleOverride: CollectionStyle.FLOW) +
                    ': ' +
                    e.value.toStringShaped(styleOverride: CollectionStyle.FLOW))
                .join(', ') +
            '}';
        break;
      default:
        break;
    }
    return result;
  }
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// A read-only [List] parsed from YAML.
class YamlList extends YamlNode with collection.ListMixin {
  final List<YamlNode> nodes;

  /// The style used for the list in the original document.
  final CollectionStyle style;

  @override
  List get value => this;

  @override
  int get length => nodes.length;

  @override
  set length(int index) {
    throw UnsupportedError('Cannot modify an unmodifiable List');
  }

  /// Creates an empty YamlList.
  ///
  /// This list's [span] won't have useful location information. However, it
  /// will have a reasonable implementation of [SourceSpan.message]. If
  /// [sourceUrl] is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlList({sourceUrl}) => YamlListWrapper(const [], sourceUrl);

  /// Wraps a Dart list so that it can be accessed (recursively) like a
  /// [YamlList].
  ///
  /// Any [SourceSpan]s returned by this list or its children will be dummies
  /// without useful location information. However, they will have a reasonable
  /// implementation of [SourceSpan.getLocationMessage]. If [sourceUrl] is
  /// passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlList.wrap(List dartList, {sourceUrl}) =>
      YamlListWrapper(dartList, sourceUrl);

  /// Users of the library should not use this constructor.
  YamlList.internal(List<YamlNode> nodes, SourceSpan span, this.style)
      : nodes = UnmodifiableListView<YamlNode>(nodes) {
    _span = span;
  }

  @override
  dynamic operator [](int index) => nodes[index].value;

  @override
  operator []=(int index, value) {
    throw UnsupportedError('Cannot modify an unmodifiable List');
  }

  @override
  String toString() {
    return toStringShaped();
  }

  @override
  String toStringShaped({int indentOverride, CollectionStyle styleOverride}) {
    var result = '';
    styleOverride ??= style;
    if (styleOverride == CollectionStyle.ANY) {
      styleOverride = CollectionStyle.BLOCK;
    }
    switch (styleOverride) {
      case CollectionStyle.BLOCK:
        for (var node in nodes) {
          if (result.isNotEmpty) {
            result +=
                '\n' + ((indentOverride != null) ? '  ' * indentOverride : '');
          }
          result += '- ';
          if (node is YamlScalar) {
            result += node.toStringShaped(
                indentOverride: (indentOverride != null) ? indentOverride : 0);
          } else if (node is YamlList) {
            result += node.toStringShaped(
                indentOverride:
                    (indentOverride != null) ? indentOverride + 1 : 1);
          } else if (node is YamlMap) {
            result += node.toStringShaped(
                indentOverride:
                    (indentOverride != null) ? indentOverride + 1 : 1);
          }
        }
        break;
      case CollectionStyle.FLOW:
        result += '[' +
            nodes
                .map((e) =>
                    e.toStringShaped(styleOverride: CollectionStyle.FLOW))
                .join(', ') +
            ']';
        break;
      default:
        break;
    }
    return result;
  }
}

/// A wrapped scalar value parsed from YAML.
class YamlScalar extends YamlNode {
  @override
  final dynamic value;

  /// The style used for the scalar in the original document.
  final ScalarStyle style;

  /// Wraps a Dart value in a [YamlScalar].
  ///
  /// This scalar's [span] won't have useful location information. However, it
  /// will have a reasonable implementation of [SourceSpan.message]. If
  /// [sourceUrl] is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  YamlScalar.wrap(this.value, {sourceUrl}) : style = ScalarStyle.ANY {
    _span = NullSpan(sourceUrl);
  }

  /// Users of the library should not use this constructor.
  YamlScalar.internal(this.value, ScalarEvent scalar) : style = scalar.style {
    _span = scalar.span;
  }

  /// Users of the library should not use this constructor.
  YamlScalar.internalWithSpan(this.value, SourceSpan span)
      : style = ScalarStyle.ANY {
    _span = span;
  }

  @override
  String toString() {
    return toStringShaped();
  }

  @override
  String toStringShaped({int indentOverride, CollectionStyle styleOverride}) {
    String result;
    switch (style) {
      case ScalarStyle.ANY:
        result = value.toString();
        break;
      case ScalarStyle.PLAIN:
        result = value.toString();
        break;
      case ScalarStyle.LITERAL:
        result = '|';
        var lines = value.toString().split('\n');
        for (var line in lines) {
          result += '\n' +
              ((indentOverride != null) ? '  ' * (indentOverride + 1) : '  ') +
              line;
        }
        break;
      case ScalarStyle.FOLDED:
        result = '>';
        var lines = value.toString().split('\n');
        // Default limit from
        // https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/commands/format.dart
        var lineLimit =
            (80 - ((indentOverride != null) ? 2 * (indentOverride + 1) : 2));
        for (var line = 0; line < lines.length; line++) {
          if (lines[line].length > lineLimit && !lines[line].startsWith(' ')) {
            var newLines = <String>[];
            while (lines[line].length > lineLimit) {
              var initialWhitespace = 1;
              for (var i = 0; i < lines[line].length; i++) {
                if (lines[line][i] == ' ') {
                  initialWhitespace++;
                } else {
                  break;
                }
              }

              for (var i = math.max(lineLimit ~/ 2, initialWhitespace);
                  i < lineLimit;
                  i++) {
                if (lines[line][i] == ' ' &&
                    lines[line][i + 1] != ' ' &&
                    lines[line][i - 1] != ' ') {
                  newLines.add(lines[line].substring(0, i));
                  lines[line] =
                      lines[line].substring(i + 1, lines[line].length);
                  break;
                }
              }

              if (lines[line].length > lineLimit &&
                  !lines[line].substring(initialWhitespace).contains(' ')) {
                break;
              }
            }
            if (lines[line].isNotEmpty) {
              newLines.add(lines[line]);
            }

            if (newLines.isNotEmpty) {
              lines.replaceRange(line, line + 1, newLines);
            }
          }
        }
        for (var line in lines) {
          result += '\n' +
              ((indentOverride != null) ? '  ' * (indentOverride + 1) : '  ') +
              line;
        }
        break;
      case ScalarStyle.SINGLE_QUOTED:
        result = '\'' + value.toString() + '\'';
        break;
      case ScalarStyle.DOUBLE_QUOTED:
        result = '"' + value.toString() + '"';
        break;
      default:
        break;
    }

    if (styleOverride != null) {
      for (var i = 0; i < result.length; i++) {
        if (result[i] == '\n') {
          result = result.replaceRange(i, i + 1, '\\n');
        }
      }
    }

    return result;
  }
}

/// Sets the source span of a [YamlNode].
///
/// This method is not exposed publicly.
void setSpan(YamlNode node, SourceSpan span) {
  node._span = span;
}
