import 'dart:convert';

import 'package:yaml/yaml.dart';

void main() {
  var       iterations = 100000;
  Stopwatch timer;
  Duration  jsonTime, yamlTime;

  // Warmup
  for (var i = 0; i < iterations; i++) {
    json.encode(test);
    yaml.encode(test);
  }

  print('Test with $iterations iterations');

  timer = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    json.encode(test);
  }

  jsonTime = timer.elapsed;

  print('Json: $jsonTime');

  timer = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    yaml.encode(test);
  }

  yamlTime = timer.elapsed;

  print('Yaml: $yamlTime');

}

const Map test = {
  'string' : 'Test text.',
  'number' : 1337,
  'bool'   : false,
  'list'   : [1,2,3,4],
  'map'    : {
    'a' : 1,
    'b' : 2,
    'c' : 'text',
    'd' : ['a', 'b', 'c']
  }
};