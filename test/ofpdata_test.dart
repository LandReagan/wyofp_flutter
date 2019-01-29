import 'dart:io';
import 'dart:convert' show json;
import 'package:test/test.dart';
import 'package:wyofp_flutter/model/OfpData.dart';

void main() {
  test('OFP1 test', () {
    File input = File('test/OFP_examples/OFP1_data.txt');
    Map<String, dynamic> rawData = json.decode(input.readAsStringSync());
    OfpData ofpData = OfpData(rawData);
    print(ofpData);
  });
}
