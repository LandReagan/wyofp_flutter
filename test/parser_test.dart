import 'dart:io';
import 'dart:convert' show json;

import 'package:test/test.dart';
import 'package:wyofp_flutter/parser/Parser.dart';

void main() {

  test('OFP1 parsing', () async {
    final String ofp1String = File('test/OFP_examples/OFP1.txt').readAsStringSync();
    Parser parser = Parser(ofp1String);
    await parser.parse();
    File out = File('test/OFP_examples/OFP1_data.txt');
    out.writeAsString(json.encode(parser.ofpData));
    /*
    parser.ofpData.forEach((key, value) {
      print(key + ' : ' + value);
    });
    */
  });

  test('OFP2 parsing', () async {
    final String ofp2String = File('test/OFP_examples/OFP2.txt').readAsStringSync();
    Parser parser = Parser(ofp2String);
    await parser.parse();
    /*
    parser.ofpData.forEach((key, value) {
      print(key + ' : ' + value);
    });
    */
  });

  test('OFP3 parsing', () async {
    final String ofp3String = File('test/OFP_examples/OFP3.txt').readAsStringSync();
    Parser parser = Parser(ofp3String);
    await parser.parse();
    /*
    parser.ofpData.forEach((key, value) {
      print(key + ' : ' + value);
    });
    */
  });

  test('OFP4 parsing', () async {
    final String ofp4String = File('test/OFP_examples/OFP4.txt').readAsStringSync();
    Parser parser = Parser(ofp4String);
    await parser.parse();
    /*
    parser.ofpData.forEach((key, value) {
      print(key + ' : ' + value);
    });
    */
  });

  test('OFP5 parsing', () async {
    final String ofp4String = File('test/OFP_examples/OFP5.txt').readAsStringSync();
    Parser parser = Parser(ofp4String);
    await parser.parse();

    parser.ofpData.forEach((key, value) {
      if (key.contains('etops')) print(key + ' : ' + value);
    });
  });

  test('OFP8 parsing', () async {
    final String ofp8String = File('test/OFP_examples/OFP8.txt').readAsStringSync();
    Parser parser = Parser(ofp8String);
    await parser.parse();

    parser.ofpData.forEach((key, value) {
      if (key.contains('etops')) print(key + ' : ' + value);
    });
  });
}
