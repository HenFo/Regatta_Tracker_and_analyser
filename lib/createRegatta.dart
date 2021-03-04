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

  final Color slColor = Colors.amber;
  final Color gateColor = Colors.lightGreen;
  final Color tmColor = Colors.blueGrey;

  final proj4.ProjectionTuple projTuple = new proj4.ProjectionTuple(
      fromProj: proj4.Projection.WGS84, toProj: proj4.Projection.GOOGLE);

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
    Polyline mapLineS;
    Polyline mapLineSCenter;

    Polyline mapLineG;
    Polyline mapLineGCenter;

    List<CircleMarker> mapCircles = [];
    List<Polyline> mapLines = [];

    // Map features for Startingline
    mapLineS = new Polyline(
        points: sl.toLatLng(),
        strokeWidth: 4,
        color: widget.slColor,
        borderColor: Colors.black);

    mapCircles.addAll(sl.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          color: widget.slColor.withOpacity(0.5),
          useRadiusInMeter: true,
          borderStrokeWidth: 1,
          borderColor: Colors.black26,
          radius: 3);
    }).toList());

    mapCircles.addAll(sl.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black);
    }).toList());

    //Center line start
    if (sl.isComplete()) {
      mapLineSCenter = new Polyline(
          points: sl
              .transformProjection(widget.projTuple)
              .getOrthogonalLine(centerlineLength)
              .transformProjection(widget.projTuple, inverse: true)
              .toLatLng(),
          strokeWidth: 3,
          color: widget.slColor,
          isDotted: true,
          borderColor: Colors.black);
    }

    // Map features for Gate
    mapLineG = new Polyline(
        points: gate.toLatLng(),
        strokeWidth: 3,
        color: widget.gateColor,
        borderColor: Colors.black,
        isDotted: true);

    mapCircles.addAll(gate.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          color: widget.gateColor.withOpacity(0.5),
          useRadiusInMeter: true,
          borderStrokeWidth: 1,
          borderColor: Colors.black26,
          radius: 10);
    }).toList());

    mapCircles.addAll(gate.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black);
    }).toList());

    // center line gate
    if (gate.isComplete()) {
      mapLineGCenter = new Polyline(
          points: gate
              .transformProjection(widget.projTuple)
              .getOrthogonalLine(centerlineLength)
              .transformProjection(widget.projTuple, inverse: true)
              .toLatLng(),
          strokeWidth: 2,
          color: widget.gateColor,
          borderColor: Colors.black,
          isDotted: true);
    }

    mapLines.addAll([mapLineS, mapLineG]);
    if (orthoSl && mapLineSCenter != null) mapLines.add(mapLineSCenter);
    if (orthoGate && mapLineGCenter != null) mapLines.add(mapLineGCenter);

    // Map features for Topmark
    if (tm != null) {
      LatLng point = tm.toLatLng();
      mapCircles.add(new CircleMarker(
          point: point,
          useRadiusInMeter: true,
          radius: 14,
          borderColor: Colors.black26,
          borderStrokeWidth: 1,
          color: widget.tmColor.withOpacity(0.5)));
      mapCircles.add(new CircleMarker(
          point: point,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black));
    }

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
            Map(mapController, mapLines, mapCircles, lastPosition),
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
