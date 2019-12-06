// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

/// A [SourceSpan] with no location information.
///
/// This is used with [YamlMap.wrap] and [YamlList.wrap] to provide means of
/// accessing a non-YAML map that behaves transparently like a map parsed from
/// YAML.
class NullSpan extends SourceSpanMixin {
  @override
  final SourceLocation start;
  @override
  SourceLocation get end => start;
  @override
  final text = '';

  NullSpan(sourceUrl) : start = SourceLocation(0, sourceUrl: sourceUrl);
}
