// Copyright (c) 2013, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:source_span/source_span.dart';

/// A pair of values.
class Pair<E, F> {
  final E first;
  final F last;

  Pair(this.first, this.last);

  @override
  String toString() => '($first, $last)';
}

/// Print a warning.
///
/// If [span] is passed, associates the warning with that span.
void warn(String message, [SourceSpan? span]) =>
    yamlWarningCallback(message, span);

/// A callback for emitting a warning.
///
/// [message] is the text of the warning. If [span] is passed, it's the portion
/// of the document that the warning is associated with and should be included
/// in the printed warning.
typedef YamlWarningCallback = void Function(String message, [SourceSpan? span]);

/// A callback for emitting a warning.
///
/// In a very few cases, the YAML spec indicates that an implementation should
/// emit a warning. To do so, it calls this callback. The default implementation
/// prints a message using [print].
// ignore: prefer_function_declarations_over_variables
YamlWarningCallback yamlWarningCallback = (message, [SourceSpan? span]) {
  // TODO(nweiz): Print to stderr with color when issue 6943 is fixed and
  // dart:io is available.
  if (span != null) message = span.message(message);
  print(message);
};

// The following utility functions are copied from the string_scanner package.
//
// See https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
// for documentation on how UTF-16 encoding works and definitions of various
// related terms.

/// The inclusive lower bound of Unicode's supplementary plane.
const _supplementaryPlaneLowerBound = 0x10000;

/// The inclusive upper bound of Unicode's supplementary plane.
const _supplementaryPlaneUpperBound = 0x10FFFF;

/// The inclusive lower bound of the UTF-16 high surrogate block.
const _highSurrogateLowerBound = 0xD800;

/// The inclusive lower bound of the UTF-16 low surrogate block.
const _lowSurrogateLowerBound = 0xDC00;

/// The number of low bits in each code unit of a surrogate pair that goes into
/// determining which code point it encodes.
const _surrogateBits = 10;

/// A bit mask that covers the lower [_surrogateBits] of a code point, which can
/// be used to extract the value of a surrogate or the low surrogate value of a
/// code unit.
const _surrogateValueMask = (1 << _surrogateBits) - 1;

/// Returns whether [codePoint] is in the Unicode supplementary plane, and thus
/// must be represented as a surrogate pair in UTF-16.
bool inSupplementaryPlane(int codePoint) =>
    codePoint >= _supplementaryPlaneLowerBound &&
    codePoint <= _supplementaryPlaneUpperBound;

/// Returns whether [codeUnit] is a UTF-16 high surrogate.
bool isHighSurrogate(int codeUnit) =>
    (codeUnit & ~_surrogateValueMask) == _highSurrogateLowerBound;

/// Returns whether [codeUnit] is a UTF-16 low surrogate.
bool isLowSurrogate(int codeUnit) =>
    (codeUnit >> _surrogateBits) == (_lowSurrogateLowerBound >> _surrogateBits);

/// Converts a UTF-16 surrogate pair into the Unicode code unit it represents.
int decodeSurrogatePair(int highSurrogate, int lowSurrogate) {
  assert(isHighSurrogate(highSurrogate));
  assert(isLowSurrogate(lowSurrogate));
  return _supplementaryPlaneLowerBound +
      (((highSurrogate & _surrogateValueMask) << _surrogateBits) |
          (lowSurrogate & _surrogateValueMask));
}
