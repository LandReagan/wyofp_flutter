import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:wyofp_flutter/ui/LandingPageCentralWidget.dart';

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

class _LandingPageState extends State<LandingPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: LandingPageCentralWidget(),
    );
  }
}
