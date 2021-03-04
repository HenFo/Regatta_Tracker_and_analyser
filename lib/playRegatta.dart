import 'package:flutter/material.dart';

class PlayRegatta extends StatefulWidget {
  @override
  _PlayRegattaState createState() => _PlayRegattaState();
}

class _PlayRegattaState extends State<PlayRegatta> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Create your course"),
          // actions: <Widget>[_optionsMenu()],
        ),
        endDrawer: Drawer(
            // child: _drawerContent(),
            ),
        body: Column(
            // children: <Widget>[_showMap(), _showButtons()],
            ));
  }
}
