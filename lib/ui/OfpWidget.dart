import 'package:flutter/material.dart';

import 'package:wyofp_flutter/model/OfpData.dart';
import 'package:wyofp_flutter/ui/theme/TextBox.dart';
import 'package:wyofp_flutter/ui/theme/DateTimeBox.dart';

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
    return HeaderWidget(
      widget.ofpData.data['flight_number'],
      widget.ofpData.data['flight_plan_reference'],
      widget.ofpData.data['computation_time']
    );
  }
}

class HeaderWidget extends StatelessWidget {

  final String flightNumber;
  final String flightReference;
  final DateTime computationTime;

  HeaderWidget(this.flightNumber, this.flightReference, this.computationTime);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row( // first line
          children: <Widget>[
            Expanded(child: TextBox(flightNumber),),
            Expanded(child: TextBox(flightReference),),
            Expanded(child: DateTimeBox(computationTime),)
          ],
        )
      ],
    );
  }
}
