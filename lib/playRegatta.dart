import 'package:flutter/material.dart';
import 'package:flutter_application_1/raceSettings.dart';
import 'package:flutter_application_1/slidingRowsWidget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';
import 'informationWidget.dart';
import 'map.dart';
import 'helperClasses.dart';
import 'mapDrawer.dart';
import "regattaDatabase.dart";
import "dart:developer" as dev;

class PlayRegatta extends StatefulWidget {
  final Regatta regatta;
  final Boat boat;

  PlayRegatta(this.regatta, this.boat);

  @override
  _PlayRegattaState createState() => _PlayRegattaState();
}

class _PlayRegattaState extends State<PlayRegatta> {
  late MapController mapController;
  late MapDrawer mapDrawer;
  late RegattaOptions localOptions;
  DatabaseHelper dbHelper = DatabaseHelper();
  LocationData? locationData;
  late int round;

  double distanceTraveled = 0;

  final List<Trackingdata> trackingData = [];

  @override
  void initState() {
    super.initState();
    this.mapController = new MapController();
    this.localOptions = widget.regatta.options.clone();
    this.mapDrawer = MapDrawer(regatta: widget.regatta, localOptions: localOptions);
    _getRoundsCount();
  }

  void _getRoundsCount() async {
    round = await dbHelper.getNumberRounds(widget.regatta.id!);
  }

  void setOptions(RegattaOptions newOptions) {
    setState(() {
      this.localOptions = newOptions;
      mapDrawer.update(widget.regatta, this.localOptions);
    });
  }

  void setLocationData(LocationData data) {
    setState(() => this.locationData = data);
  }

  int _getTrailingIndex(int trailingLength) {
    if (this.trackingData.length > trailingLength)
      return this.trackingData.length - trailingLength;
    else
      return 0;
  }

  void onTick(int tick) {
    // dev.log("onTick", name: "tick");
    if (locationData != null) {
      if (trackingData.isNotEmpty) {
        distanceTraveled += MyPoint.fromLatLng(trackingData.last.toLatLng())
            .getGreatCircleDistanceToPoint(MyPoint(
            locationData!.latitude, locationData!.longitude));
      }
      trackingData.add(Trackingdata.fromOrigin(tick, locationData!));
    }
  }

  void onRaceStart() {
    dev.log("onRaceStart", name: "start");
  }

  void onRaceStop() {
    dev.log("onRaceStop", name: "stop");
    Track track =
        Track(widget.regatta.id!, round, widget.boat.boatID!, trackingData);
    dbHelper.insertTrack(track).then((_) => trackingData.clear());
    round++;
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
          return SlidingRows(
              constraints: constraints,
              topChild: RegattaMap(
                this.mapController,
                this.mapDrawer,
                widget.regatta,
                localOptions: this.localOptions,
                gpsInformationCallback: setLocationData,
                trailingLine: trackingData.sublist(_getTrailingIndex(10)),
              ),
              bottomChild: Informations(this.locationData, this.onRaceStart,
                  this.onTick, this.onRaceStop));
        }));
  }
}
