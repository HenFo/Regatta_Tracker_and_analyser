import 'package:flutter/material.dart';
import 'package:flutter_application_1/raceSettings.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart";
import 'package:location/location.dart';
import 'informationWidget.dart';
import 'map.dart';
import 'helperClasses.dart';
import "regattaDatabase.dart";
import "dart:developer" as dev;

class PlayRegatta extends StatefulWidget {
  final Regatta regatta;

  PlayRegatta(this.regatta);

  @override
  _PlayRegattaState createState() => _PlayRegattaState();
}

class _PlayRegattaState extends State<PlayRegatta> {
  late MapController mapController;
  late RegattaOptions localOptions;
  LocationData? locationData;

  final List trackingData = <Trackingdata>[];

  @override
  void initState() {
    super.initState();
    this.mapController = new MapController();
    this.localOptions = widget.regatta.options.clone();
  }

  void setOptions(RegattaOptions newOptions) {
    setState(() => this.localOptions = newOptions);
  }

  void setLocationData(LocationData data) {
    setState(() => this.locationData = data);
  }

  void onTick(int tick) {
    // dev.log("onTick", name: "tick");
    if (locationData != null) {
      trackingData.add(Trackingdata(tick, locationData!));
    }
  }

  void onRaceStart() {
    dev.log("onRaceStart", name: "start");
  }

  void onRaceStop() {
    dev.log("onRaceStop", name: "stop");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Race"),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RaceSettings(
                              localOptions, widget.regatta.name, setOptions)));
                })
          ],
        ),
        body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return Column(children: <Widget>[
            RegattaMap(
              this.mapController,
              widget.regatta,
              localOptions: this.localOptions,
              gpsInformationCallback: setLocationData,
            ),
            Informations(constraints, this.locationData, this.onRaceStart,
                this.onTick, this.onRaceStop)
          ]);
        }));
  }
}
