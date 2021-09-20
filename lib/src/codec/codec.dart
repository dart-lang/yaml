import 'dart:convert';

import 'decoder.dart';
import 'encoder.dart';

class YamlCodec extends Codec<Object?, String> {
  const YamlCodec();
  
  @override
  dynamic decode(String source) => YamlDecoder().convert(source);

  @override
  String  encode(Object? obj)   => YamlEncoder().convert(obj);
  
  @override
  YamlEncoder get encoder => const YamlEncoder();

  @override
  YamlDecoder get decoder => const YamlDecoder();
}

const YamlCodec yaml = YamlCodec();

Object? yamlDecode(String input) => yaml.decode(input);
String  yamlEncode(Object? obj)  => yaml.encode(obj);