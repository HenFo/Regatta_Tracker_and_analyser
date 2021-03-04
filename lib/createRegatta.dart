import 'package:flutter/material.dart';
import 'drawerOptions.dart';
import 'editButtons.dart';
import "regatta.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong/latlong.dart";
import "dart:developer" as dev;
import "package:proj4dart/proj4dart.dart" as proj4;
import "map.dart";

class CreateRegatta extends StatefulWidget {
  final String name;
  final int id;
  final Function saveCallback;
  final Function editCallback;
  final Regatta editRegatta;

  // final proj4.ProjectionTuple projTuple = new proj4.ProjectionTuple(
  //     fromProj: proj4.Projection.WGS84, toProj: proj4.Projection.GOOGLE);

  CreateRegatta(this.id, this.name,
      [this.saveCallback, this.editRegatta, this.editCallback]);

  @override
  _CreateRegattaState createState() => _CreateRegattaState();
}

class _CreateRegattaState extends State<CreateRegatta> {
  //Option variables:
  double centerlineLength = 300;
  TextEditingController centerlineLengthController = TextEditingController();

  MapController mapController;
  LatLngBounds lastPosition =
      new LatLngBounds(LatLng(51.95762, 7.612692), LatLng(51.955032, 7.617106));

  bool orthoSl = true;
  bool orthoGate = false;

  Topmark tm;

  Gate gate = new Gate(null, null);
  MyPoint gateStart;
  MyPoint gateEnd;

  Startingline sl = new Startingline(null, null);
  MyPoint slStart;
  MyPoint slEnd;

  void setCenterlineLength(double newLength) {
    setState(() => centerlineLength = newLength);
  }

  void setOrthoSl(bool newValue) {
    setState(() => orthoSl = newValue);
  }

  void setOrthoGate(bool newValue) {
    setState(() => orthoGate = newValue);
  }

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    if (widget.editRegatta != null) {
      tm = widget.editRegatta.topmark;
      sl = widget.editRegatta.startingline;
      gate = widget.editRegatta.gate;
      lastPosition = widget.editRegatta.bbox;
    }
  }

  bool _save() {
    dev.log("create Object", name: "_save start");
    if (gate.isComplete() && sl.isComplete()) {
      try {
        Regatta regattaSaveObject = new Regatta(widget.id, widget.name);
        regattaSaveObject.topmark = tm;
        regattaSaveObject.startingline = sl;
        regattaSaveObject.gate = gate;

        var points = <LatLng>[];
        points.add(tm.toLatLng());
        points.addAll(sl.toLatLng());
        points.addAll(gate.toLatLng());

        regattaSaveObject.bbox = LatLngBounds.fromPoints(points);

        if (widget.editCallback != null) {
          widget.editCallback(regattaSaveObject);
        } else if (widget.saveCallback != null) {
          widget.saveCallback(regattaSaveObject);
        }

        // Navigator.pop(context);
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
          // actions: <Widget>[_optionsMenu()],
        ),
        endDrawer: Drawer(
          child: DrawerOptions(setCenterlineLength, setOrthoSl, setOrthoGate,
              centerlineLength, orthoSl, orthoGate),
        ),
        body: Column(
          children: <Widget>[
            Map(mapController, lastPosition, tm, sl, gate, centerlineLength,
                orthoSl, orthoGate),
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
          tm = new Topmark(pos.longitude, pos.latitude);
          break;

        case 1:
          slStart = new MyPoint(pos.longitude, pos.latitude);
          sl = new Startingline(slStart, slEnd);
          break;

        case 2:
          slEnd = new MyPoint(pos.longitude, pos.latitude);
          sl = new Startingline(slStart, slEnd);
          break;

        case 3:
          gateStart = new MyPoint(pos.longitude, pos.latitude);
          gate = new Gate(gateStart, gateEnd, radius: 5);
          break;

        case 4:
          gateEnd = new MyPoint(pos.longitude, pos.latitude);
          gate = new Gate(gateStart, gateEnd, radius: 5);
          break;
      }
    });
  }
}
