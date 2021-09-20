// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  
  test('YamlCodec can encode test data', () {
    expect(yaml.encode(testData).trim(), testOutput.trim());
  });

  test('YamlCodec can decode test data', () {
    var decoded = yaml.decode(testOutput);
    
    expect(decoded,                isMap);
    expect(decoded.entries.length, testData.entries.length);
  });
  
  test('YamlCodec can encode list', () {
    expect(yaml.encode([1,2]).trim(), testList.trim());
  });

  test('YamlCodec can decode list', () {
    expect(yaml.decode(testList), isList);
  });
  
  test('YamlCodec can encode streams', () async {
    var tests = await testEncodeStream.transform(yaml.encoder).toList();

    expect(tests.length, 3);

    expect(tests[0].trim(), testOutput.trim());
    expect(tests[1].trim(), testOutput.trim());
    expect(tests[2].trim(), testOutput.trim());
  });

  test('YamlCodec can decode streams', () async {
    var tests = await testDecodeStream.transform(yaml.decoder).toList();

    expect(tests.length, 3);

    expect(tests[0], isMap); 
    expect((tests[0] as Map).entries.length, testData.entries.length);

    expect(tests[1], isMap);
    expect((tests[1] as Map).entries.length, testData.entries.length);

    expect(tests[2], isMap);
    expect((tests[1] as Map).entries.length, testData.entries.length);
  });

}

Stream<String> get testDecodeStream async * {
  var i = 3;

  while (i-- > 0) {
    yield testOutput;
    await Future.delayed(Duration(milliseconds: 25));
  }
}

Stream<Object?> get testEncodeStream async * {
  var i = 3;

  while (i-- > 0) {
    yield testData;
    await Future.delayed(Duration(milliseconds: 25));
  }
}

const String testList = '''
---
- 1
- 2
''';

const String testOutput = '''
---
string: 'One liner'
text: | 
  Some text:
  More or less
  multi line!

number: 0.0
bool: false
list:
  - 'a'
  - 'b'
map:
  a: 1
  b: 2
map-c:
  a:
    text: 'text'
    number: 0.0
    bool: false
    list:
      - 'a'
      - 'b'
    map:
      a: 1
      b: 2
  b:
    text: 'text'
    number: 0.0
    bool: false
    list:
      - 'a'
      - 'b'
    map:
      a: 1
      b: 2
list-c:
  -
    text: 'text'
    number: 0.0
    bool: false
    list:
      - 'a'
      - 'b'
    map:
      a: 1
      b: 2
  -
    text: 'text'
    number: 0.0
    bool: false
    list:
      - 'a'
      - 'b'
    map:
      a: 1
      b: 2
  - | 
      Some text:
      More or less
      multi line!
''';


const Map testData = {
  'string' : 'One liner',
  'text'   : '''
  Some text:
  More or less
  multi line!
''',
  'number' : 0.0,
  'bool'   : false,
  'list'   : [
    'a', 'b'
  ],
  'map' : {
    'a' : 1,
    'b' : 2
  },
  'map-c' : {
    'a' : {
      'text': 'text',
      'number' : 0.0,
      'bool'   : false,
      'list'   : [
        'a', 'b'
      ],
      'map' : {
        'a' : 1,
        'b' : 2
      }
    },
    'b' : {
      'text': 'text',
      'number' : 0.0,
      'bool'   : false,
      'list'   : [
        'a', 'b'
      ],
      'map' : {
        'a' : 1,
        'b' : 2
      }
    }
  },
  'list-c'   : [
    {
      'text': 'text',
      'number' : 0.0,
      'bool'   : false,
      'list'   : [
        'a', 'b'
      ],
      'map' : {
        'a' : 1,
        'b' : 2
      }
    },
    {
      'text': 'text',
      'number' : 0.0,
      'bool'   : false,
      'list'   : [
        'a', 'b'
      ],
      'map' : {
        'a' : 1,
        'b' : 2
      }
    },
    '''
      Some text:
      More or less
      multi line!
    '''
  ],
};