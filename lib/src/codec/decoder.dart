
import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'codec.dart';

class _YamlDecoderSink extends ChunkedConversionSink<String> {
  final Sink<Object?> sink;

  _YamlDecoderSink(this.sink);
  
  @override
  void add(String source) => sink.add(yaml.decode(source));

  @override
  void close()            => sink.close();
}

class YamlDecoder extends Converter<String, Object?> {
  const YamlDecoder();

  @override
  ChunkedConversionSink<String> startChunkedConversion(Sink<Object?> sink) {
    return _YamlDecoderSink(sink);
  }
  
  @override
  Object? convert(String input) => loadYaml(input);
}