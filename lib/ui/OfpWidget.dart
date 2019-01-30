import 'package:flutter/material.dart';

import 'package:wyofp_flutter/model/OfpData.dart';
import 'package:wyofp_flutter/ui/theme/TextBox.dart';

class OfpWidget extends StatefulWidget {
  /// This widget is built out of raw data from the OFP (Map of strings) and
  /// uses the OfpData object to built a dart typed set of data. The State
  /// is used for user records linked to certain fields.

  final Map<String, dynamic> rawData;
  final OfpData ofpData;

  OfpWidget(this.rawData) : this.ofpData = OfpData(rawData);

  @override
  _OfpWidgetState createState() => _OfpWidgetState();
}

class _OfpWidgetState extends State<OfpWidget> {

  @override
  Widget build(BuildContext context) {
    return TextBox(widget.ofpData.data['flight_number']);
  }
}
