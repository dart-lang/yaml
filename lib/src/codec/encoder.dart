import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'codec.dart';

class _YamlEncoderSink extends ChunkedConversionSink<Object?> {
  final Sink<String> sink;

  _YamlEncoderSink(this.sink);
  
  @override
  void add(Object? obj) => sink.add(yaml.encode(obj));

  @override
  void close()          => sink.close();
}

class YamlEncoder extends Converter<Object?, String> {
  const YamlEncoder();
  
  @override
  ChunkedConversionSink<Object?> startChunkedConversion(Sink<String> sink) {
    return _YamlEncoderSink(sink);
  }
  
  @override
  String convert(Object? obj) {
    final buffer = StringBuffer('---\n');

    if (_convertable(obj)) {
      _objectToBuffer(obj, buffer);
    }

    return buffer.toString();
  }

  bool _convertable(Object? obj) => obj is List || obj is Map;

  void _objectToBuffer(dynamic obj, StringBuffer buffer, [int indent = 0]) {
    var p = ' ' * indent;
    
    if (obj is List) {

      for (dynamic v in obj) {
        buffer.write('$p-');

        if (_convertable(v)) {
          buffer.write('\n');
        } else if (v is String && v.contains('\n')) {
          buffer.write(' | \n');
        }

        _objectToBuffer(v, buffer, indent + 2);

      }

    } else if (obj is Map) {

      for (var k in obj.keys) {
        buffer.write('$p$k:');

        if (_convertable(obj[k])) {
          buffer.write('\n');
        } else if (obj[k] is String && (obj[k] as String).contains('\n')) {
          buffer.write(' | \n');
        }

        _objectToBuffer(obj[k], buffer, indent + 2);
      }

    } else if (obj == double.infinity) {
      buffer.writeln(' .inf');
    } else if (obj == -double.infinity) {
      buffer.writeln(' -.inf');
    } else {
      
      if (obj == null || obj is num || obj is bool) {
        buffer.writeln(' $obj');
      } else {

        if (obj is String && obj.contains('\n')) {
          buffer.writeln('$obj');
        } else {
          buffer.writeln(' \'$obj\'');
        }     
      }
    }
  }
}