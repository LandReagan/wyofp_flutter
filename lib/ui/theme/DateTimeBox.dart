import 'package:flutter/material.dart';


class DateTimeBox extends StatelessWidget {

  final DateTime _value;

  DateTimeBox(this._value);

  String _getDateTimeString() {
    return _value.toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      child: Text(_getDateTimeString()),
    );
  }
}
