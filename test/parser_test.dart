import 'dart:io';

import 'package:test/test.dart';
import 'package:wyofp_flutter/parser/Parser.dart';

void main() {

  test('Parser.ofpDataAsJson property test', () {
    Parser parser = Parser('Anything');
    parser.ofpData = {
      'a data': 'data1',
      'another data': 56,
    };
    String expectedString = r'{"a data":"data1","another data":56}';
    expect(parser.ofpDataAsJson, expectedString);
  });

  test('OFP1 parsing', () {
    final String ofp1String = File('test/OFP_examples/OFP1.txt').readAsStringSync();
    Parser parser = Parser(ofp1String);
    expect(parser.content.length, 374769);
  });
}
