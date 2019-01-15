import 'package:flutter/material.dart';

final TextStyle _textStyle = TextStyle(
    fontSize: 30.0
);

class LandingPageCentralWidget extends StatefulWidget {
  _LandingPageCentralWidgetState createState() => _LandingPageCentralWidgetState();
}

class _LandingPageCentralWidgetState extends State<LandingPageCentralWidget> {

  List<ListTile> _listItems;

  void initState() {
    super.initState();
    _listItems = [
      OFPHistoryWidget(),
      CurrentOFPsWidget(null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ListView(
      children: _listItems
    );
  }
}

class OFPHistoryWidget extends ListTile {

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Row(
          children: <Widget>[
            Icon(Icons.keyboard_arrow_down),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(10.0),
                padding: EdgeInsets.all(10.0),
                alignment: Alignment.center,
                child: Text('History', style: _textStyle,),
              ),
            ),
            Icon(Icons.keyboard_arrow_down),
          ],
        )
    );
  }
}

class CurrentOFPsWidget extends ListTile {

  final List<String> flightPlans;

  CurrentOFPsWidget(this.flightPlans);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(Icons.keyboard_arrow_down),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(10.0),
              padding: EdgeInsets.all(10.0),
              alignment: Alignment.center,
              child: Text('Current', style: _textStyle,),
            ),
          ),
          Icon(Icons.keyboard_arrow_down),
        ],
      )
    );
  }
}
