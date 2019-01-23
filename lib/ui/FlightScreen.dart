import 'dart:async';
import 'package:flutter/material.dart';


class FlightScreen extends StatefulWidget {

  final String _flightReference;

  FlightScreen(this._flightReference);

  _FlightScreenState createState() => _FlightScreenState();
}

class _FlightScreenState extends State<FlightScreen> {

  bool textReceived = false;
  bool parsingFinished = false;

  Map<String, String> ofpRawData;

  void getAndParseOFPData() async {

  }

  Widget getMainWidget() {

    Widget fetchingWidget = textReceived ? Text('Done!') : CircularProgressIndicator();
    Widget parsingWidget = parsingFinished ? Text('Done!') : CircularProgressIndicator();

    if (ofpRawData == null) { // We wait...
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Fetching OFP...'),
              fetchingWidget,
            ],
          ),
          Row(
            children: <Widget>[
              Text('Parsing OFP...'),
              parsingWidget,
            ],
          )
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._flightReference),
      ),
      body: getMainWidget(),
    );
  }
}
