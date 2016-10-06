// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';
import 'package:string_scanner/string_scanner.dart';

import 'event.dart';
import 'scanner.dart';
import 'style.dart';
import 'token.dart';
import 'utils.dart';
import 'yaml_document.dart';
import 'yaml_exception.dart';

/// A parser that reads [Token]s emitted by a [Scanner] and emits [Event]s.
///
/// This is based on the libyaml parser, available at
/// https://github.com/yaml/libyaml/blob/master/src/parser.c. The license for
/// that is available in ../../libyaml-license.txt.
class Parser {
  /// The underlying [Scanner] that generates [Token]s.
  final Scanner _scanner;

  /// The stack of parse states for nested contexts.
  final _states = new List<_State>();

  /// The current parse state.
  var _state = _State.STREAM_START;

  /// The custom tag directives, by tag handle.
  final _tagDirectives = new Map<String, TagDirective>();

  /// Whether the parser has finished parsing.
  bool get isDone => _state == _State.END;

  /// Creates a parser that parses [source].
  ///
  /// [sourceUrl] can be a String or a [Uri].
  Parser(String source, {sourceUrl})
      : _scanner = new Scanner(source, sourceUrl: sourceUrl);

  /// Consumes and returns the next event.
  Event parse() {
    try {
      if (isDone) throw new StateError("No more events.");
      var event = _stateMachine();
      return event;
    } on StringScannerException catch (error) {
      throw new YamlException(error.message, error.span);
    }
  }

  /// Dispatches parsing based on the current state.
  Event _stateMachine() {
    switch (_state) {
      case _State.STREAM_START:
        return _parseStreamStart();
      case _State.DOCUMENT_START:
        return _parseDocumentStart();
      case _State.DOCUMENT_CONTENT:
        return _parseDocumentContent();
      case _State.DOCUMENT_END:
        return _parseDocumentEnd();
      case _State.BLOCK_NODE:
        return _parseNode(block: true);
      case _State.BLOCK_NODE_OR_INDENTLESS_SEQUENCE:
        return _parseNode(block: true, indentlessSequence: true);
      case _State.FLOW_NODE:
        return _parseNode();
      case _State.BLOCK_SEQUENCE_FIRST_ENTRY:
        // Scan past the `BLOCK-SEQUENCE-FIRST-ENTRY` token to the
        // `BLOCK-SEQUENCE-ENTRY` token.
        _scanner.scan();
        return _parseBlockSequenceEntry();
      case _State.BLOCK_SEQUENCE_ENTRY:
        return _parseBlockSequenceEntry();
      case _State.INDENTLESS_SEQUENCE_ENTRY:
        return _parseIndentlessSequenceEntry();
      case _State.BLOCK_MAPPING_FIRST_KEY:
        // Scan past the `BLOCK-MAPPING-FIRST-KEY` token to the
        // `BLOCK-MAPPING-KEY` token.
        _scanner.scan();
        return _parseBlockMappingKey();
      case _State.BLOCK_MAPPING_KEY:
        return _parseBlockMappingKey();
      case _State.BLOCK_MAPPING_VALUE:
        return _parseBlockMappingValue();
      case _State.FLOW_SEQUENCE_FIRST_ENTRY:
        return _parseFlowSequenceEntry(first: true);
      case _State.FLOW_SEQUENCE_ENTRY:
        return _parseFlowSequenceEntry();
      case _State.FLOW_SEQUENCE_ENTRY_MAPPING_KEY:
        return _parseFlowSequenceEntryMappingKey();
      case _State.FLOW_SEQUENCE_ENTRY_MAPPING_VALUE:
        return _parseFlowSequenceEntryMappingValue();
      case _State.FLOW_SEQUENCE_ENTRY_MAPPING_END:
        return _parseFlowSequenceEntryMappingEnd();
      case _State.FLOW_MAPPING_FIRST_KEY:
        return _parseFlowMappingKey(first: true);
      case _State.FLOW_MAPPING_KEY:
        return _parseFlowMappingKey();
      case _State.FLOW_MAPPING_VALUE:
        return _parseFlowMappingValue();
      case _State.FLOW_MAPPING_EMPTY_VALUE:
        return _parseFlowMappingValue(empty: true);
      default:
        throw "Unreachable";
    }
  }

  /// Parses the production:
  ///
  ///     stream ::=
  ///       STREAM-START implicit_document? explicit_document* STREAM-END
  ///       ************
  Event _parseStreamStart() {
    var token = _scanner.scan();
    assert(token.type == TokenType.STREAM_START);

    _state = _State.DOCUMENT_START;
    return new Event(EventType.STREAM_START, token.span);
  }

  /// Parses the productions:
  ///
  ///     implicit_document    ::= block_node DOCUMENT-END*
  ///                              *
  ///     explicit_document    ::=
  ///       DIRECTIVE* DOCUMENT-START block_node? DOCUMENT-END*
  ///       *************************
  Event _parseDocumentStart() {
    var token = _scanner.peek();

    // libyaml requires any document beyond the first in the stream to have an
    // explicit document start indicator, but the spec allows it to be omitted
    // as long as there was an end indicator.

    // Parse extra document end indicators.
    while (token.type == TokenType.DOCUMENT_END) {
      token = _scanner.advance();
    }

    if (token.type != TokenType.VERSION_DIRECTIVE &&
        token.type != TokenType.TAG_DIRECTIVE &&
        token.type != TokenType.DOCUMENT_START &&
        token.type != TokenType.STREAM_END) {
      // Parse an implicit document.
      _processDirectives();
      _states.add(_State.DOCUMENT_END);
      _state = _State.BLOCK_NODE;
      return new DocumentStartEvent(token.span.start.pointSpan());
    }

    if (token.type == TokenType.STREAM_END) {
      _state = _State.END;
      _scanner.scan();
      return new Event(EventType.STREAM_END, token.span);
    }

    // Parse an explicit document.
    var start = token.span;
    var pair = _processDirectives();
    var versionDirective = pair.first;
    var tagDirectives = pair.last;
    token = _scanner.peek();
    if (token.type != TokenType.DOCUMENT_START) {
      throw new YamlException("Expected document start.", token.span);
    }

    _states.add(_State.DOCUMENT_END);
    _state = _State.DOCUMENT_CONTENT;
    _scanner.scan();
    return new DocumentStartEvent(start.expand(token.span),
        versionDirective: versionDirective,
        tagDirectives: tagDirectives,
        isImplicit: false);
  }

  /// Parses the productions:
  ///
  ///     explicit_document    ::=
  ///       DIRECTIVE* DOCUMENT-START block_node? DOCUMENT-END*
  ///                                 ***********
  Event _parseDocumentContent() {
    var token = _scanner.peek();

    switch (token.type) {
      case TokenType.VERSION_DIRECTIVE:
      case TokenType.TAG_DIRECTIVE:
      case TokenType.DOCUMENT_START:
      case TokenType.DOCUMENT_END:
      case TokenType.STREAM_END:
        _state = _states.removeLast();
        return _processEmptyScalar(token.span.start);
      default:
        return _parseNode(block: true);
    }
  }

  /// Parses the productions:
  ///
  ///     implicit_document    ::= block_node DOCUMENT-END*
  ///                                         *************
  ///     explicit_document    ::=
  ///       DIRECTIVE* DOCUMENT-START block_node? DOCUMENT-END*
  ///                                             *************
  Event _parseDocumentEnd() {
    _tagDirectives.clear();
    _state = _State.DOCUMENT_START;

    var token = _scanner.peek();
    if (token.type == TokenType.DOCUMENT_END) {
      _scanner.scan();
      return new DocumentEndEvent(token.span, isImplicit: false);
    } else {
      return new DocumentEndEvent(
          token.span.start.pointSpan(), isImplicit: true);
    }
  }

  /// Parses the productions:
  ///
  ///     block_node_or_indentless_sequence    ::=
  ///       ALIAS
  ///       *****
  ///       | properties (block_content | indentless_block_sequence)?
  ///         **********  *
  ///       | block_content | indentless_block_sequence
  ///         *
  ///     block_node           ::= ALIAS
  ///                              *****
  ///                              | properties block_content?
  ///                                ********** *
  ///                              | block_content
  ///                                *
  ///     flow_node            ::= ALIAS
  ///                              *****
  ///                              | properties flow_content?
  ///                                ********** *
  ///                              | flow_content
  ///                                *
  ///     properties           ::= TAG ANCHOR? | ANCHOR TAG?
  ///                              *************************
  ///     block_content        ::= block_collection | flow_collection | SCALAR
  ///                                                                   ******
  ///     flow_content         ::= flow_collection | SCALAR
  ///                                                ******
  Event _parseNode({bool block: false, bool indentlessSequence: false}) {
    var token = _scanner.peek();

    if (token is AliasToken) {
      _scanner.scan();
      _state = _states.removeLast();
      return new AliasEvent(token.span, token.name);
    }

    var anchor;
    var tagToken;
    var span = token.span.start.pointSpan();
    parseAnchor(token) {
      anchor = token.name;
      span = span.expand(token.span);
      return _scanner.advance();
    }

    parseTag(token) {
      tagToken = token;
      span = span.expand(token.span);
      return _scanner.advance();
    }

    if (token is AnchorToken) {
      token = parseAnchor(token);
      if (token is TagToken) token = parseTag(token);
    } else if (token is TagToken) {
      token = parseTag(token);
      if (token is AnchorToken) token = parseAnchor(token);
    }

    var tag;
    if (tagToken != null) {
      if (tagToken.handle == null) {
        tag = tagToken.suffix;
      } else {
        var tagDirective = _tagDirectives[tagToken.handle];
        if (tagDirective == null) {
          throw new YamlException("Undefined tag handle.", tagToken.span);
        }

        tag = tagDirective.prefix + tagToken.suffix;
      }
    }

    if (indentlessSequence && token.type == TokenType.BLOCK_ENTRY) {
      _state = _State.INDENTLESS_SEQUENCE_ENTRY;
      return new SequenceStartEvent(
          span.expand(token.span), CollectionStyle.BLOCK,
          anchor: anchor, tag: tag);
    }

    if (token is ScalarToken) {
      // All non-plain scalars have the "!" tag by default.
      if (tag == null && token.style != ScalarStyle.PLAIN) tag = "!";

      _state = _states.removeLast();
      _scanner.scan();
      return new ScalarEvent(
          span.expand(token.span), token.value, token.style,
          anchor: anchor, tag: tag);
    }

    if (token.type == TokenType.FLOW_SEQUENCE_START) {
      _state = _State.FLOW_SEQUENCE_FIRST_ENTRY;
      return new SequenceStartEvent(
          span.expand(token.span), CollectionStyle.FLOW,
          anchor: anchor, tag: tag);
    }

    if (token.type == TokenType.FLOW_MAPPING_START) {
      _state = _State.FLOW_MAPPING_FIRST_KEY;
      return new MappingStartEvent(
          span.expand(token.span), CollectionStyle.FLOW,
          anchor: anchor, tag: tag);
    }

    if (block && token.type == TokenType.BLOCK_SEQUENCE_START) {
      _state = _State.BLOCK_SEQUENCE_FIRST_ENTRY;
      return new SequenceStartEvent(
          span.expand(token.span), CollectionStyle.BLOCK,
          anchor: anchor, tag: tag);
    }


    if (block && token.type == TokenType.BLOCK_MAPPING_START) {
      _state = _State.BLOCK_MAPPING_FIRST_KEY;
      return new MappingStartEvent(
          span.expand(token.span), CollectionStyle.BLOCK,
          anchor: anchor, tag: tag);
    }

    if (anchor != null || tag != null) {
      _state = _states.removeLast();
      return new ScalarEvent(
          span, '', ScalarStyle.PLAIN,
          anchor: anchor, tag: tag);
    }

    throw new YamlException("Expected node content.", span);
  }

  /// Parses the productions:
  ///
  ///     block_sequence ::=
  ///       BLOCK-SEQUENCE-START (BLOCK-ENTRY block_node?)* BLOCK-END
  ///       ********************  *********** *             *********
  Event _parseBlockSequenceEntry() {
    var token = _scanner.peek();

    if (token.type == TokenType.BLOCK_ENTRY) {
      token = _scanner.advance();

      if (token.type == TokenType.BLOCK_ENTRY ||
          token.type == TokenType.BLOCK_END) {
        _state = _State.BLOCK_SEQUENCE_ENTRY;
        return _processEmptyScalar(token.span.end);
      } else {
        _states.add(_State.BLOCK_SEQUENCE_ENTRY);
        return _parseNode(block: true);
      }
    }

    if (token.type == TokenType.BLOCK_END) {
      _scanner.scan();
      _state = _states.removeLast();
      return new Event(EventType.SEQUENCE_END, token.span);
    }

    throw new YamlException("While parsing a block collection, expected '-'.",
        token.span.start.pointSpan());
  }

  /// Parses the productions:
  ///
  ///     indentless_sequence  ::= (BLOCK-ENTRY block_node?)+
  ///                               *********** *
  Event _parseIndentlessSequenceEntry() {
    var token = _scanner.peek();

    if (token.type != TokenType.BLOCK_ENTRY) {
      _state = _states.removeLast();
      return new Event(EventType.SEQUENCE_END, token.span.start.pointSpan());
    }

    var start = token.span.start;
    token = _scanner.advance();

    if (token.type == TokenType.BLOCK_ENTRY ||
        token.type == TokenType.KEY ||
        token.type == TokenType.VALUE ||
        token.type == TokenType.BLOCK_END) {
      _state = _State.INDENTLESS_SEQUENCE_ENTRY;
      return _processEmptyScalar(start);
    } else {
      _states.add(_State.INDENTLESS_SEQUENCE_ENTRY);
      return _parseNode(block: true);
    }
  }

  /// Parses the productions:
  ///
  ///     block_mapping        ::= BLOCK-MAPPING_START
  ///                              *******************
  ///                              ((KEY block_node_or_indentless_sequence?)?
  ///                                *** *
  ///                              (VALUE block_node_or_indentless_sequence?)?)*
  ///
  ///                              BLOCK-END
  ///                              *********
  Event _parseBlockMappingKey() {
    var token = _scanner.peek();
    if (token.type == TokenType.KEY) {
      var start = token.span.start;
      token = _scanner.advance();

      if (token.type == TokenType.KEY ||
          token.type == TokenType.VALUE ||
          token.type == TokenType.BLOCK_END) {
        _state = _State.BLOCK_MAPPING_VALUE;
        return _processEmptyScalar(start);
      } else {
        _states.add(_State.BLOCK_MAPPING_VALUE);
        return _parseNode(block: true, indentlessSequence: true);
      }
    }

    // libyaml doesn't allow empty keys without an explicit key indicator, but
    // the spec does. See example 8.18:
    // http://yaml.org/spec/1.2/spec.html#id2798896.
    if (token.type == TokenType.VALUE) {
      _state = _State.BLOCK_MAPPING_VALUE;
      return _processEmptyScalar(token.span.start);
    }

    if (token.type == TokenType.BLOCK_END) {
      _scanner.scan();
      _state = _states.removeLast();
      return new Event(EventType.MAPPING_END, token.span);
    }

    throw new YamlException("Expected a key while parsing a block mapping.",
        token.span.start.pointSpan());
  }

  /// Parses the productions:
  ///
  ///     block_mapping        ::= BLOCK-MAPPING_START
  ///
  ///                              ((KEY block_node_or_indentless_sequence?)?
  ///
  ///                              (VALUE block_node_or_indentless_sequence?)?)*
  ///                               ***** *
  ///                              BLOCK-END
  ///
  Event _parseBlockMappingValue() {
    var token = _scanner.peek();

    if (token.type != TokenType.VALUE) {
      _state = _State.BLOCK_MAPPING_KEY;
      return _processEmptyScalar(token.span.start);
    }

    var start = token.span.start;
    token = _scanner.advance();
    if (token.type == TokenType.KEY ||
        token.type == TokenType.VALUE ||
        token.type == TokenType.BLOCK_END) {
      _state = _State.BLOCK_MAPPING_KEY;
      return _processEmptyScalar(start);
    } else {
      _states.add(_State.BLOCK_MAPPING_KEY);
      return _parseNode(block: true, indentlessSequence: true);
    }
  }

  /// Parses the productions:
  ///
  ///     flow_sequence        ::= FLOW-SEQUENCE-START
  ///                              *******************
  ///                              (flow_sequence_entry FLOW-ENTRY)*
  ///                               *                   **********
  ///                              flow_sequence_entry?
  ///                              *
  ///                              FLOW-SEQUENCE-END
  ///                              *****************
  ///     flow_sequence_entry  ::=
  ///       flow_node | KEY flow_node? (VALUE flow_node?)?
  ///       *
  Event _parseFlowSequenceEntry({bool first: false}) {
    if (first) _scanner.scan();
    var token = _scanner.peek();

    if (token.type != TokenType.FLOW_SEQUENCE_END) {
      if (!first) {
        if (token.type != TokenType.FLOW_ENTRY) {
          throw new YamlException(
              "While parsing a flow sequence, expected ',' or ']'.",
              token.span.start.pointSpan());
        }

        token = _scanner.advance();
      }

      if (token.type == TokenType.KEY) {
        _state = _State.FLOW_SEQUENCE_ENTRY_MAPPING_KEY;
        _scanner.scan();
        return new MappingStartEvent(
            token.span, CollectionStyle.FLOW);
      } else if (token.type != TokenType.FLOW_SEQUENCE_END) {
        _states.add(_State.FLOW_SEQUENCE_ENTRY);
        return _parseNode();
      }
    }

    _scanner.scan();
    _state = _states.removeLast();
    return new Event(EventType.SEQUENCE_END, token.span);
  }

  /// Parses the productions:
  ///
  ///     flow_sequence_entry  ::=
  ///       flow_node | KEY flow_node? (VALUE flow_node?)?
  ///                   *** *
  Event _parseFlowSequenceEntryMappingKey() {
    var token = _scanner.peek();

    if (token.type == TokenType.VALUE ||
        token.type == TokenType.FLOW_ENTRY ||
        token.type == TokenType.FLOW_SEQUENCE_END) {
      // libyaml consumes the token here, but that seems like a bug, since it
      // always causes [_parseFlowSequenceEntryMappingValue] to emit an empty
      // scalar.

      var start = token.span.start;
      _state = _State.FLOW_SEQUENCE_ENTRY_MAPPING_VALUE;
      return _processEmptyScalar(start);
    } else {
      _states.add(_State.FLOW_SEQUENCE_ENTRY_MAPPING_VALUE);
      return _parseNode();
    }
  }

  /// Parses the productions:
  ///
  ///     flow_sequence_entry  ::=
  ///       flow_node | KEY flow_node? (VALUE flow_node?)?
  ///                                   ***** *
  Event _parseFlowSequenceEntryMappingValue() {
    var token = _scanner.peek();

    if (token.type == TokenType.VALUE) {
      token = _scanner.advance();
      if (token.type != TokenType.FLOW_ENTRY &&
          token.type != TokenType.FLOW_SEQUENCE_END) {
        _states.add(_State.FLOW_SEQUENCE_ENTRY_MAPPING_END);
        return _parseNode();
      }
    }

    _state = _State.FLOW_SEQUENCE_ENTRY_MAPPING_END;
    return _processEmptyScalar(token.span.start);
  }

  /// Parses the productions:
  ///
  ///     flow_sequence_entry  ::=
  ///       flow_node | KEY flow_node? (VALUE flow_node?)?
  ///                                                   *
  Event _parseFlowSequenceEntryMappingEnd() {
    _state = _State.FLOW_SEQUENCE_ENTRY;
    return new Event(EventType.MAPPING_END,
        _scanner.peek().span.start.pointSpan());
  }

  /// Parses the productions:
  ///
  ///     flow_mapping         ::= FLOW-MAPPING-START
  ///                              ******************
  ///                              (flow_mapping_entry FLOW-ENTRY)*
  ///                               *                  **********
  ///                              flow_mapping_entry?
  ///                              ******************
  ///                              FLOW-MAPPING-END
  ///                              ****************
  ///     flow_mapping_entry   ::=
  ///       flow_node | KEY flow_node? (VALUE flow_node?)?
  ///       *           *** *
  Event _parseFlowMappingKey({bool first: false}) {
    if (first) _scanner.scan();
    var token = _scanner.peek();

    if (token.type != TokenType.FLOW_MAPPING_END) {
      if (!first) {
        if (token.type != TokenType.FLOW_ENTRY) {
          throw new YamlException(
              "While parsing a flow mapping, expected ',' or '}'.",
              token.span.start.pointSpan());
        }

        token = _scanner.advance();
      }

      if (token.type == TokenType.KEY) {
        token = _scanner.advance();
        if (token.type != TokenType.VALUE &&
            token.type != TokenType.FLOW_ENTRY &&
            token.type != TokenType.FLOW_MAPPING_END) {
          _states.add(_State.FLOW_MAPPING_VALUE);
          return _parseNode();
        } else {
          _state = _State.FLOW_MAPPING_VALUE;
          return _processEmptyScalar(token.span.start);
        }
      } else if (token.type != TokenType.FLOW_MAPPING_END) {
        _states.add(_State.FLOW_MAPPING_EMPTY_VALUE);
        return _parseNode();
      }
    }

    _scanner.scan();
    _state = _states.removeLast();
    return new Event(EventType.MAPPING_END, token.span);
  }

  /// Parses the productions:
  ///
  ///     flow_mapping_entry   ::=
  ///       flow_node | KEY flow_node? (VALUE flow_node?)?
  ///                *                  ***** *
  Event _parseFlowMappingValue({bool empty: false}) {
    var token = _scanner.peek();

    if (empty) {
      _state = _State.FLOW_MAPPING_KEY;
      return _processEmptyScalar(token.span.start);
    }

    if (token.type == TokenType.VALUE) {
      token = _scanner.advance();
      if (token.type != TokenType.FLOW_ENTRY &&
          token.type != TokenType.FLOW_MAPPING_END) {
        _states.add(_State.FLOW_MAPPING_KEY);
        return _parseNode();
      }
    }

    _state = _State.FLOW_MAPPING_KEY;
    return _processEmptyScalar(token.span.start);
  }

  /// Generate an empty scalar event.
  Event _processEmptyScalar(SourceLocation location) =>
      new ScalarEvent(location.pointSpan(), '', ScalarStyle.PLAIN);

  /// Parses directives.
  Pair<VersionDirective, List<TagDirective>> _processDirectives() {
    var token = _scanner.peek();

    VersionDirective versionDirective;
    var tagDirectives = <TagDirective>[];
    while (token.type == TokenType.VERSION_DIRECTIVE ||
           token.type == TokenType.TAG_DIRECTIVE) {
      if (token is VersionDirectiveToken) {
        if (versionDirective != null) {
          throw new YamlException("Duplicate %YAML directive.", token.span);
        }

        if (token.major != 1 || token.minor == 0) {
          throw new YamlException(
              "Incompatible YAML document. This parser only supports YAML 1.1 "
                "and 1.2.",
              token.span);
        } else if (token.minor > 2) {
          // TODO(nweiz): Print to stderr when issue 6943 is fixed and dart:io
          // is available.
          warn("Warning: this parser only supports YAML 1.1 and 1.2.",
              token.span);
        }

        versionDirective = new VersionDirective(token.major, token.minor);
      } else if (token is TagDirectiveToken) {
        var tagDirective = new TagDirective(token.handle, token.prefix);
        _appendTagDirective(tagDirective, token.span);
        tagDirectives.add(tagDirective);
      }

      token = _scanner.advance();
    }

    _appendTagDirective(
        new TagDirective("!", "!"),
        token.span.start.pointSpan(),
        allowDuplicates: true);
    _appendTagDirective(
        new TagDirective("!!", "tag:yaml.org,2002:"),
        token.span.start.pointSpan(),
        allowDuplicates: true);

    return new Pair(versionDirective, tagDirectives);
  }

  /// Adds a tag directive to the directives stack.
  void _appendTagDirective(TagDirective newDirective, FileSpan span,
      {bool allowDuplicates: false}) {
    if (_tagDirectives.containsKey(newDirective.handle)) {
      if (allowDuplicates) return;
      throw new YamlException("Duplicate %TAG directive.", span);
    }

    _tagDirectives[newDirective.handle] = newDirective;
  }
}

/// The possible states for the parser.
class _State {
  /// Expect [TokenType.STREAM_START].
  static const STREAM_START = const _State("STREAM_START");

  /// Expect the beginning of an implicit document.
  static const IMPLICIT_DOCUMENT_START =
      const _State("IMPLICIT_DOCUMENT_START");

  /// Expect [TokenType.DOCUMENT_START].
  static const DOCUMENT_START = const _State("DOCUMENT_START");

  /// Expect the content of a document.
  static const DOCUMENT_CONTENT = const _State("DOCUMENT_CONTENT");

  /// Expect [TokenType.DOCUMENT_END].
  static const DOCUMENT_END = const _State("DOCUMENT_END");

  /// Expect a block node.
  static const BLOCK_NODE = const _State("BLOCK_NODE");

  /// Expect a block node or indentless sequence.
  static const BLOCK_NODE_OR_INDENTLESS_SEQUENCE =
      const _State("BLOCK_NODE_OR_INDENTLESS_SEQUENCE");

  /// Expect a flow node.
  static const FLOW_NODE = const _State("FLOW_NODE");

  /// Expect the first entry of a block sequence.
  static const BLOCK_SEQUENCE_FIRST_ENTRY =
      const _State("BLOCK_SEQUENCE_FIRST_ENTRY");

  /// Expect an entry of a block sequence.
  static const BLOCK_SEQUENCE_ENTRY = const _State("BLOCK_SEQUENCE_ENTRY");

  /// Expect an entry of an indentless sequence.
  static const INDENTLESS_SEQUENCE_ENTRY =
      const _State("INDENTLESS_SEQUENCE_ENTRY");

  /// Expect the first key of a block mapping.
  static const BLOCK_MAPPING_FIRST_KEY =
      const _State("BLOCK_MAPPING_FIRST_KEY");

  /// Expect a block mapping key.
  static const BLOCK_MAPPING_KEY = const _State("BLOCK_MAPPING_KEY");

  /// Expect a block mapping value.
  static const BLOCK_MAPPING_VALUE = const _State("BLOCK_MAPPING_VALUE");

  /// Expect the first entry of a flow sequence.
  static const FLOW_SEQUENCE_FIRST_ENTRY =
      const _State("FLOW_SEQUENCE_FIRST_ENTRY");

  /// Expect an entry of a flow sequence.
  static const FLOW_SEQUENCE_ENTRY = const _State("FLOW_SEQUENCE_ENTRY");

  /// Expect a key of an ordered mapping.
  static const FLOW_SEQUENCE_ENTRY_MAPPING_KEY =
      const _State("FLOW_SEQUENCE_ENTRY_MAPPING_KEY");

  /// Expect a value of an ordered mapping.
  static const FLOW_SEQUENCE_ENTRY_MAPPING_VALUE =
      const _State("FLOW_SEQUENCE_ENTRY_MAPPING_VALUE");

  /// Expect the and of an ordered mapping entry.
  static const FLOW_SEQUENCE_ENTRY_MAPPING_END =
      const _State("FLOW_SEQUENCE_ENTRY_MAPPING_END");

  /// Expect the first key of a flow mapping.
  static const FLOW_MAPPING_FIRST_KEY = const _State("FLOW_MAPPING_FIRST_KEY");

  /// Expect a key of a flow mapping.
  static const FLOW_MAPPING_KEY = const _State("FLOW_MAPPING_KEY");

  /// Expect a value of a flow mapping.
  static const FLOW_MAPPING_VALUE = const _State("FLOW_MAPPING_VALUE");

  /// Expect an empty value of a flow mapping.
  static const FLOW_MAPPING_EMPTY_VALUE =
      const _State("FLOW_MAPPING_EMPTY_VALUE");

  /// Expect nothing.
  static const END = const _State("END");

  final String name;

  const _State(this.name);

  String toString() => name;
}
