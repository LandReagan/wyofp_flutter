import 'package:flutter/material.dart';


class TextBox extends StatelessWidget {

  final String _content;

  TextBox(this._content);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      child: Text(_content),
    );
  }
}
