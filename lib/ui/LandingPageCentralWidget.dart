import 'package:flutter/material.dart';

final TextStyle _textStyle = TextStyle(
    fontSize: 30.0
);

class LandingPageCentralWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ListView(
      children: <Widget>[
        OFPHistoryWidget(),
      ],
    );
  }
}

class OFPHistoryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(
        margin: EdgeInsets.all(10.0),
        padding: EdgeInsets.all(10.0),
        alignment: Alignment.center,
        child: Text('History', style: _textStyle,),
      ),
      trailing: Icon(Icons.arrow_forward_ios),
    );
  }
}

class CurrentOFPsWidgetGenerator extends StatelessWidget {

  final int ofpNumber;

  CurrentOFPsWidgetGenerator(this.ofpNumber);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}
