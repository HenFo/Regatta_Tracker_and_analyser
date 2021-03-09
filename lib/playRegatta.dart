import 'package:flutter/material.dart';
import 'package:flutter_application_1/drawerOptions.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart";
import 'informationWidget.dart';
import 'map.dart';
import 'regatta.dart';

class PlayRegatta extends StatefulWidget {
  final Regatta regatta;

  PlayRegatta(this.regatta);

  @override
  _PlayRegattaState createState() => _PlayRegattaState();
}

class _PlayRegattaState extends State<PlayRegatta> {
  MapController mapController;
  RegattaOptions localOptions;

  @override
  void initState() {
    super.initState();
    mapController = new MapController();
    localOptions = widget.regatta.options.clone();
  }

  void setOptions(RegattaOptions newOptions) {
    setState(() => localOptions = newOptions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Race"),
          // actions: <Widget>[_optionsMenu()],
        ),
        endDrawer: Drawer(
          child: DrawerOptions(localOptions, setOptions),
        ),
        body: Column(
          children: <Widget>[
            RegattaMap(this.mapController, widget.regatta, this.localOptions),
            Informations()
          ],
        ));
  }
}
