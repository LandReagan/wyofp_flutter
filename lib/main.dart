import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wyofp_flutter/ui/CurrentFlightsWidget.dart';

void main() => runApp(WyOfp());

class WyOfp extends StatelessWidget {

  WyOfp() {
    print('Testing stuff...');
    Firestore firestore = Firestore();
    firestore.collection('sandbox').add({
      'test': 'Ça marche !',
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WY OFP',
      theme: ThemeData(
        // todo: to properly do
        primaryColor: Colors.white,
      ),
      home: LandingPage(title: 'WY OFP'),
    );
  }
}

class LandingPage extends StatefulWidget {
  LandingPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Text('Current flights', textScaleFactor: 1.5,),
            Text('Saved flights', textScaleFactor: 1.5,)
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          CurrentFlightsWidget(),
          Text('WORK IN PROGRESS...'),
        ],
      ),
    );
  }
}
