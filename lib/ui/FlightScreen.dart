import 'package:flutter/material.dart';

class FlightScreen extends StatefulWidget {

  final String _flightReference;

  FlightScreen(this._flightReference);

  _FlightScreenState createState() => _FlightScreenState();
}

class _FlightScreenState extends State<FlightScreen> {

  @override
  Widget build(BuildContext context) {
    return Text(widget._flightReference);
  }
}
