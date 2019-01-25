import 'package:flutter/material.dart';

import 'package:wyofp_flutter/connectors/SitaConnector.dart';
import 'package:wyofp_flutter/ui/FlightScreen.dart';

class CurrentFlightsWidget extends StatefulWidget {
  _CurrentFlightsWidgetState createState() => _CurrentFlightsWidgetState();
}

class _CurrentFlightsWidgetState extends State<CurrentFlightsWidget>
    with AutomaticKeepAliveClientMixin<CurrentFlightsWidget>{

  SitaConnector _connector = SitaConnector();
  bool loading = false;

  List<Map<String, String>> _flightNumberAndReference = [];

  @override
  bool get wantKeepAlive => true;

  void initState() {
    super.initState();
    _refreshConnector();
  }

  void _refreshConnector() async {

    String message = await _connector.init();
    if (message != 'Connection OK!') {
      print('ERROR while connecting to SITA:\n' + message);
      return;
    }
    _flightNumberAndReference = await _connector.getFlightPlanList();
    if (this.mounted) {
      setState(() {
        // State is reset after async work is finished.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_flightNumberAndReference.length == 0) {
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
