// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import 'style.dart';
import 'yaml_document.dart';

/// An event emitted by a [Parser].
class Event {
  /// The event type.
  final EventType type;

  /// The span associated with the event.
  final FileSpan span;

  Event(this.type, this.span);

  @override
  String toString() => type.toString();
}

/// An event indicating the beginning of a YAML document.
class DocumentStartEvent implements Event {
  @override
  EventType get type => EventType.DOCUMENT_START;
  @override
  final FileSpan span;

  /// The document's `%YAML` directive, or `null` if there was none.
  final VersionDirective versionDirective;

  /// The document's `%TAG` directives, if any.
  final List<TagDirective> tagDirectives;

  /// Whether the document started implicitly (that is, without an explicit
  /// `===` sequence).
  final bool isImplicit;

  DocumentStartEvent(this.span,
      {this.versionDirective,
      List<TagDirective> tagDirectives,
      this.isImplicit = true})
      : tagDirectives = tagDirectives ?? [];

  @override
  String toString() => 'DOCUMENT_START';
}

/// An event indicating the end of a YAML document.
class DocumentEndEvent implements Event {
  @override
  EventType get type => EventType.DOCUMENT_END;
  @override
  final FileSpan span;

  /// Whether the document ended implicitly (that is, without an explicit
  /// `...` sequence).
  final bool isImplicit;

  DocumentEndEvent(this.span, {this.isImplicit = true});

  @override
  String toString() => 'DOCUMENT_END';
}

/// An event indicating that an alias was referenced.
class AliasEvent implements Event {
  @override
  EventType get type => EventType.ALIAS;
  @override
  final FileSpan span;

  /// The name of the anchor.
  final String name;

  AliasEvent(this.span, this.name);

  @override
  String toString() => 'ALIAS $name';
}

/// A base class for events that can have anchor and tag properties associated
/// with them.
abstract class _ValueEvent implements Event {
  /// The name of the value's anchor, or `null` if it wasn't anchored.
  String get anchor;

  /// The text of the value's tag, or `null` if it wasn't tagged.
  String get tag;

  @override
  String toString() {
    var buffer = StringBuffer('$type');
    if (anchor != null) buffer.write(' &$anchor');
    if (tag != null) buffer.write(' $tag');
    return buffer.toString();
  }
}

/// An event indicating a single scalar value.
class ScalarEvent extends _ValueEvent {
  @override
  EventType get type => EventType.SCALAR;
  @override
  final FileSpan span;
  @override
  final String anchor;
  @override
  final String tag;

  /// The contents of the scalar.
  final String value;

  /// The style of the scalar in the original source.
  final ScalarStyle style;

  ScalarEvent(this.span, this.value, this.style, {this.anchor, this.tag});

  @override
  String toString() => '${super.toString()} "$value"';
}

/// An event indicating the beginning of a sequence.
class SequenceStartEvent extends _ValueEvent {
  @override
  EventType get type => EventType.SEQUENCE_START;
  @override
  final FileSpan span;
  @override
  final String anchor;
  @override
  final String tag;

  /// The style of the collection in the original source.
  final CollectionStyle style;

  SequenceStartEvent(this.span, this.style, {this.anchor, this.tag});
}

/// An event indicating the beginning of a mapping.
class MappingStartEvent extends _ValueEvent {
  @override
  EventType get type => EventType.MAPPING_START;
  @override
  final FileSpan span;
  @override
  final String anchor;
  @override
  final String tag;

  /// The style of the collection in the original source.
  final CollectionStyle style;

  MappingStartEvent(this.span, this.style, {this.anchor, this.tag});
}

/// An enum of types of [Event] object.
enum EventType {
  STREAM_START,
  STREAM_END,
  DOCUMENT_START,
  DOCUMENT_END,
  ALIAS,
  SCALAR,
  SEQUENCE_START,
  SEQUENCE_END,
  MAPPING_START,
  MAPPING_END
}
