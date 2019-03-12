import 'package:flutter/material.dart';

import 'package:wyofp_flutter/connectors/SitaConnector.dart';
import 'package:wyofp_flutter/ui/FlightScreen.dart';

class CurrentFlightsWidget extends StatefulWidget {
  _CurrentFlightsWidgetState createState() => _CurrentFlightsWidgetState();
}

class _CurrentFlightsWidgetState extends State<CurrentFlightsWidget>
    with AutomaticKeepAliveClientMixin<CurrentFlightsWidget>{

  SitaConnector _connector = SitaConnector();
  String connectorMessage = '';
  bool loading = false;

  List<Map<String, String>> _flightNumberAndReference = [];

  @override
  bool get wantKeepAlive => true;

  void initState() {
    super.initState();
    _refreshConnector();
  }

  void _refreshConnector() async {

    loading = true;

    connectorMessage = await _connector.init();
    if (connectorMessage != 'Connection OK!') {
      print('ERROR while connecting to SITA:\n' + connectorMessage);
      loading = false;
      return;
    }
    _flightNumberAndReference = await _connector.getFlightPlanList();
    loading = false;
    if (this.mounted) {
      setState(() {
        // State is reset after async work is finished!
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(_flightNumberAndReference);
    // While loading data
    if (loading == true) {
      return Column(
        children: <Widget>[
          Text('Fetching flight plans, please wait...',
            textScaleFactor: 1.5,
            textAlign: TextAlign.center,
          ),
          CircularProgressIndicator(),
        ],
      );
    }
    // In case of error
    if (_flightNumberAndReference.length == 0) {
      return Text(connectorMessage);
    }

    // Otherwise, show the stuff!
    return ListView.builder(
      itemCount: _flightNumberAndReference.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          child: _FlightWidget(_flightNumberAndReference[index]),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return FlightScreen(
                    _flightNumberAndReference[index]['flight_number'],
                    _flightNumberAndReference[index]['flight_reference'],
                    _connector
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _FlightWidget extends StatelessWidget {

  final Map<String, String> _flightData;

  _FlightWidget(this._flightData);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Row(
        children: <Widget>[
          Icon(Icons.flight),
          Expanded(
            child: Text(_flightData['flight_number'], textScaleFactor: 1.5,),
          ),
          Icon(Icons.arrow_forward_ios)
        ],
      )
    );
  }
}
