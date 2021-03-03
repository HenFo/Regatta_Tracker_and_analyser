import 'package:flutter/material.dart';
import "regatta.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong/latlong.dart";
import "dart:developer" as dev;
import "package:proj4dart/proj4dart.dart" as proj4;
import "snackbarSaveCallback.dart";

class CreateRegatta extends StatefulWidget {
  final String name;
  final int ID;
  final Function saveCallback;
  final Function editCallback;
  final Regatta editRegatta;

  final Color slColor = Colors.amber;
  final Color gateColor = Colors.lightGreen;
  final Color tmColor = Colors.blueGrey;

  final proj4.ProjectionTuple projTuple = new proj4.ProjectionTuple(
      fromProj: proj4.Projection.WGS84, toProj: proj4.Projection.GOOGLE);

  CreateRegatta(this.ID, this.name,
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
        Regatta regattaSaveObject = new Regatta(widget.ID, widget.name);
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

      // mapMarker.add(new Marker(point: point, width: 30, height: 30));
    }

    Widget _showMap() {
      return Flexible(
          child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
            bounds: lastPosition,
            zoom: 17,
            onTap: (latlng) => dev.log(latlng.toString(), name: "taped at:"),
            onLongPress: (latlng) => dev.log(
                mapController.bounds.northWest.toString() +
                    mapController.bounds.southEast.toString())),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
            tileProvider: NonCachingNetworkTileProvider(),
          ),
          // MarkerLayerOptions(markers: mapMarker),
          PolylineLayerOptions(polylines: mapLines),
          CircleLayerOptions(circles: mapCircles),
        ],
      ));
    }

    Widget _showButtons() {
      return Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              child: Text("Topmark", textAlign: TextAlign.center),
              style: ElevatedButton.styleFrom(primary: Colors.blue),
              onPressed: () {
                _addToMap(0, mapController.center);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  child: Text(
                    "Startingline - Start",
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(primary: Colors.orange[700]),
                  onPressed: () {
                    _addToMap(1, mapController.center);
                  },
                ),
                ElevatedButton(
                  child: Text(
                    "Startingline - End",
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(primary: Colors.orange),
                  onPressed: () {
                    _addToMap(2, mapController.center);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  child: Text("Gate - Start", textAlign: TextAlign.center),
                  style: ElevatedButton.styleFrom(primary: Colors.green[700]),
                  onPressed: () {
                    _addToMap(3, mapController.center);
                  },
                ),
                ElevatedButton(
                  child: Text("Gate - End", textAlign: TextAlign.center),
                  style: ElevatedButton.styleFrom(primary: Colors.green[300]),
                  onPressed: () {
                    _addToMap(4, mapController.center);
                  },
                ),
              ],
            ),
            SnackBarPage(_save)
          ],
        ),
      );
    }

    Widget _drawerContent() {
      centerlineLengthController.text = centerlineLength.toString();
      return ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateCheckbox) {
            return CheckboxListTile(
                title: Text("Mark centerline Startingline"),
                value: orthoSl,
                onChanged: (newValue) {
                  setStateCheckbox(() {
                    setState(() => orthoSl = newValue);
                  });
                },
                controlAffinity: ListTileControlAffinity.leading);
          }),
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateCheckbox) {
            return CheckboxListTile(
                title: Text("Mark centerline gate"),
                value: orthoGate,
                onChanged: (newValue) {
                  setStateCheckbox(() {
                    setState(() => orthoGate = newValue);
                  });
                },
                controlAffinity: ListTileControlAffinity.leading);
          }),
          ListTile(
            title: TextField(
              controller: centerlineLengthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(suffixText: "m"),
              onSubmitted: (val) {
                setState(() => centerlineLength = double.tryParse(val));
              },
            ),
            trailing: Text("Length of Centerline"),
          )
        ],
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Create your course"),
          // actions: <Widget>[_optionsMenu()],
        ),
        endDrawer: Drawer(
          child: _drawerContent(),
        ),
        body: Column(
          children: <Widget>[_showMap(), _showButtons()],
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
