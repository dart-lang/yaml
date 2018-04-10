// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.benchmark.benchmark;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:yaml/yaml.dart';

const numTrials = 100;
const runsPerTrial = 1000;

final source = loadFile("input.yaml");
final expected = loadFile("output.json");

void main(List<String> args) {
  var best = double.infinity;

  // Run the benchmark several times. This ensures the VM is warmed up and lets
  // us see how much variance there is.
  for (var i = 0; i <= numTrials; i++) {
    var start = new DateTime.now();

    // For a single benchmark, convert the source multiple times.
    var result;
    for (var j = 0; j < runsPerTrial; j++) {
      result = loadYaml(source);
    }

    var elapsed =
        new DateTime.now().difference(start).inMilliseconds / runsPerTrial;

    // Keep track of the best run so far.
    if (elapsed >= best) continue;
    best = elapsed;

    // Sanity check to make sure the output is what we expect and to make sure
    // the VM doesn't optimize "dead" code away.
    if (jsonEncode(result) != expected) {
      print("Incorrect output:\n${jsonEncode(result)}");
      exit(1);
    }

    // Don't print the first run. It's always terrible since the VM hasn't
    // warmed up yet.
    if (i == 0) continue;
    printResult("Run ${padLeft('#$i', 3)}", elapsed);
  }

  printResult("Best   ", best);
}

String loadFile(String name) {
  var path = p.join(p.dirname(p.fromUri(Platform.script)), name);
  return new File(path).readAsStringSync();
}

void printResult(String label, double time) {
  print("$label: ${padLeft(time.toStringAsFixed(3), 4)}ms "
      "${'=' * ((time * 100).toInt())}");
}

String padLeft(input, int length) {
  var result = input.toString();
  if (result.length < length) {
    result = " " * (length - result.length) + result;
  }

  return result;
}
