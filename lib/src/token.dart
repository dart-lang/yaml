// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import 'style.dart';

/// A token emitted by a [Scanner].
class Token {
  /// The token type.
  final TokenType type;

  /// The span associated with the token.
  final FileSpan span;

  Token(this.type, this.span);

  @override
  String toString() => type.toString();
}

/// A token representing a `%YAML` directive.
class VersionDirectiveToken implements Token {
  @override
  TokenType get type => TokenType.VERSION_DIRECTIVE;
  @override
  final FileSpan span;

  /// The declared major version of the document.
  final int major;

  /// The declared minor version of the document.
  final int minor;

  VersionDirectiveToken(this.span, this.major, this.minor);

  @override
  String toString() => 'VERSION_DIRECTIVE $major.$minor';
}

/// A token representing a `%TAG` directive.
class TagDirectiveToken implements Token {
  @override
  TokenType get type => TokenType.TAG_DIRECTIVE;
  @override
  final FileSpan span;

  /// The tag handle used in the document.
  final String handle;

  /// The tag prefix that the handle maps to.
  final String prefix;

  TagDirectiveToken(this.span, this.handle, this.prefix);

  @override
  String toString() => 'TAG_DIRECTIVE $handle $prefix';
}

/// A token representing an anchor (`&foo`).
class AnchorToken implements Token {
  @override
  TokenType get type => TokenType.ANCHOR;
  @override
  final FileSpan span;

  /// The name of the anchor.
  final String name;

  AnchorToken(this.span, this.name);

  @override
  String toString() => 'ANCHOR $name';
}

/// A token representing an alias (`*foo`).
class AliasToken implements Token {
  @override
  TokenType get type => TokenType.ALIAS;
  @override
  final FileSpan span;

  /// The name of the anchor.
  final String name;

  AliasToken(this.span, this.name);

  @override
  String toString() => 'ALIAS $name';
}

/// A token representing a tag (`!foo`).
class TagToken implements Token {
  @override
  TokenType get type => TokenType.TAG;
  @override
  final FileSpan span;

  /// The tag handle.
  final String handle;

  /// The tag suffix, or `null`.
  final String suffix;

  TagToken(this.span, this.handle, this.suffix);

  @override
  String toString() => 'TAG $handle $suffix';
}

/// A tkoen representing a scalar value.
class ScalarToken implements Token {
  @override
  TokenType get type => TokenType.SCALAR;
  @override
  final FileSpan span;

  /// The contents of the scalar.
  final String value;

  /// The style of the scalar in the original source.
  final ScalarStyle style;

  ScalarToken(this.span, this.value, this.style);

  @override
  String toString() => 'SCALAR $style "$value"';
}

/// An enum of types of [Token] object.
enum TokenType {
  STREAM_START,
  STREAM_END,

  VERSION_DIRECTIVE,
  TAG_DIRECTIVE,
  DOCUMENT_START,
  DOCUMENT_END,

  BLOCK_SEQUENCE_START,
  BLOCK_MAPPING_START,
  BLOCK_END,

  FLOW_SEQUENCE_START,
  FLOW_SEQUENCE_END,
  FLOW_MAPPING_START,
  FLOW_MAPPING_END,

  BLOCK_ENTRY,
  FLOW_ENTRY,
  KEY,
  VALUE,

  ALIAS,
  ANCHOR,
  TAG,
  SCALAR
}
