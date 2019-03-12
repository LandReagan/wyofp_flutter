import 'package:flutter/material.dart';

import 'package:wyofp_flutter/connectors/SitaConnector.dart';
import 'package:wyofp_flutter/parser/Parser.dart';
import 'package:wyofp_flutter/ui/OfpWidget.dart';


class FlightScreen extends StatefulWidget {

  final String _flightNumber;
  final String _flightReference;
  final SitaConnector _connector;

  FlightScreen(this._flightNumber, this._flightReference, this._connector);

  _FlightScreenState createState() => _FlightScreenState();
}

class _FlightScreenState extends State<FlightScreen> {

  bool textReceived = false;
  bool parsingFinished = false;

  Map<String, dynamic> ofpRawData;

  @override
  void initState() {
    super.initState();
    getAndParseOFPData();
  }

  void getAndParseOFPData() async {
    print('Awaiting for the OFP text...');
    String content =
        await widget._connector.getFlightPlanText(widget._flightReference);
    setState((){
      textReceived = true;
    });
    print('OFP text found. Starting parsing...');
    Parser parser = Parser(content);
    await parser.parse();
    setState(() {
      parsingFinished = true;
    });
    print('OFP parsed.');
    ofpRawData = parser.ofpData;
  }

  Widget getMainWidget() {

    Widget fetchingWidget = textReceived ?
        Text('Done!', textScaleFactor: 1.5,) : CircularProgressIndicator();
    Widget parsingWidget = parsingFinished ?
        Text('Done!', textScaleFactor: 1.5,) : CircularProgressIndicator();

    if (ofpRawData == null) { // We wait...
      return GridView.count(
        crossAxisCount: 2,
        children: <Widget>[
          Text('Fetching OFP...', textScaleFactor: 1.5,),
          fetchingWidget,
          Text('Parsing OFP...', textScaleFactor: 1.5,),
          parsingWidget,
        ],
      );
    } else {
      return OfpWidget(ofpRawData);
    }
  }

  @override
  Widget build(BuildContext context) {
    String ofpReference = ofpRawData == null ? '' : ofpRawData['flight_plan_reference'];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._flightNumber + ' -REF: ' +  ofpReference),
      ),
      body: getMainWidget(),
    );
  }
}
