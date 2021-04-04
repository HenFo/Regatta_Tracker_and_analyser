import 'package:flutter/material.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import '../raceSettings.dart';
import 'editButtons.dart';
import '../helperClasses.dart';
import "../regattaDatabase.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong/latlong.dart";
import "dart:developer" as dev;
import "../Map.dart";

class CreateRegatta extends StatefulWidget {
  final String name;
  final int id;
  final Function? saveCallback;
  final Function? editCallback;
  final Regatta? editRegatta;

  CreateRegatta(this.id, this.name,
      [this.saveCallback, this.editRegatta, this.editCallback]);

  @override
  _CreateRegattaState createState() => _CreateRegattaState();
}

class _CreateRegattaState extends State<CreateRegatta> {
  //Option variables:
  late Regatta regatta;
  late RegattaOptions localOptions;

  late MapController mapController;

  MyPoint? gateStart;
  MyPoint? gateEnd;

  MyPoint? slStart;
  MyPoint? slEnd;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    regatta = new Regatta(widget.id, widget.name);

    if (widget.editRegatta != null) {
      regatta.topmark = widget.editRegatta!.topmark;
      regatta.startingline = widget.editRegatta!.startingline;
      regatta.gate = widget.editRegatta!.gate;
      regatta.options = widget.editRegatta!.options;

      gateStart = regatta.gate.p1;
      gateEnd = regatta.gate.p2;
      slStart = regatta.startingline.p1;
      slEnd = regatta.startingline.p2;
    }

    localOptions = regatta.options.clone();
  }

  void setRegattaOptions(RegattaOptions newOptions) {
    setState(() => localOptions = newOptions);
  }

  bool _save() {
    dev.log("create Object", name: "_save start");
    if (regatta.gate.isComplete() && regatta.startingline.isComplete()) {
      try {
        // var bounds = regatta.calculateBbox();
        var proj = proj4.ProjectionTuple(
            fromProj: proj4.Projection.WGS84, toProj: proj4.Projection.GOOGLE);

        localOptions.center = regatta.startingline
            .transformProjection(proj)
            .getCenter()!
            .transformProjection(proj, inverse: true)
            .toLatLng();
        regatta.options = localOptions;

        if (widget.editCallback != null) {
          widget.editCallback!(regatta);
        } else if (widget.saveCallback != null) {
          widget.saveCallback!(regatta);
        }

        Navigator.pop(context);
        return true;
      } catch (e) {
        dev.log(e.toString());
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Create your course"),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RaceSettings(localOptions,
                              widget.name, this.setRegattaOptions)));
                })
          ],
        ),
        body: Column(
          children: <Widget>[
            RegattaMap(mapController, regatta, localOptions: localOptions),
            EditButtons(mapController, _addToMap, _save)
          ],
        ));
  }

  void _addToMap(int type, LatLng pos) {
    /*
    0 = Topmark
    1 = StartStart
    2 = StartEnd
    3 = GateStart
    4 = GateEnd
    */
    setState(() {
      switch (type) {
        case 0:
          regatta.topmark = new Topmark(pos.longitude, pos.latitude);
          break;

        case 1:
          slStart = new MyPoint(pos.longitude, pos.latitude);
          regatta.startingline = new Startingline(slStart, slEnd);
          break;

        case 2:
          slEnd = new MyPoint(pos.longitude, pos.latitude);
          regatta.startingline = new Startingline(slStart, slEnd);
          break;

        case 3:
          gateStart = new MyPoint(pos.longitude, pos.latitude);
          regatta.gate = new Gate(gateStart, gateEnd, radius: 5);
          break;

        case 4:
          gateEnd = new MyPoint(pos.longitude, pos.latitude);
          regatta.gate = new Gate(gateStart, gateEnd, radius: 5);
          break;
      }
    });
  }
}
