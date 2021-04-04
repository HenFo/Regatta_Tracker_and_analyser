import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter_map/flutter_map.dart";
import "package:latlong/latlong.dart";
import "dart:developer" as dev;
import 'helperClasses.dart';
import "regattaDatabase.dart";
import "package:proj4dart/proj4dart.dart" as proj4;
import 'package:location/location.dart';
import "dart:math";

class RegattaMap extends StatefulWidget {
  final MapController mapController;
  final Regatta regatta;
  final RegattaOptions localOptions;
  final Function? gpsInformationCallback;

  final Color slColor = Colors.amber;
  final Color gateColor = Colors.lightGreen;
  final Color tmColor = Colors.blueGrey;

  RegattaMap(this.mapController, this.regatta,
      {RegattaOptions? localOptions, this.gpsInformationCallback})
      : this.localOptions = localOptions ?? regatta.options;

  @override
  _RegattaMapState createState() => _RegattaMapState();
}

// 0 = fix to GPS
// 1 = free movement
// 2 = fix to course
enum ViewState { GPS, FREE, COURSE }

class _RegattaMapState extends State<RegattaMap> {
  double _courseOrientation = 0;
  final proj4.ProjectionTuple projTuple = new proj4.ProjectionTuple(
      fromProj: proj4.Projection.WGS84, toProj: proj4.Projection.GOOGLE);

  LocationData? _currentLocation;

  // bool _liveUpdate = false;
  var _viewState = ViewState.FREE;

  bool _permission = false;
  bool _northAlignment = false;

  String? _serviceError = '';
  late StreamSubscription _locationStream;

  var interActiveFlags = InteractiveFlag.all & ~InteractiveFlag.rotate;

  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    initLocationService();
  }

  @override
  void dispose() {
    dev.log("disposed", name: "dispose");
    _locationStream.cancel();
    super.dispose();
  }

  void initLocationService() async {
    await _locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
    );

    LocationData? location;
    bool serviceEnabled;
    bool serviceRequestResult;

    try {
      serviceEnabled = await _locationService.serviceEnabled();

      if (serviceEnabled) {
        var permission = await _locationService.requestPermission();
        _permission = permission == PermissionStatus.granted;

        if (_permission) {
          location = await _locationService.getLocation();
          _currentLocation = location;
          _locationStream = _locationService.onLocationChanged
              .listen((LocationData result) async {
            if (mounted) {
              setState(() {
                _currentLocation = result;

                if (widget.gpsInformationCallback != null) {
                  widget.gpsInformationCallback!(result);
                }

                // If Live Update is enabled, move map center
                if (_viewState == ViewState.GPS) {
                  widget.mapController.move(
                      LatLng(_currentLocation?.latitude,
                          _currentLocation?.longitude),
                      17);
                }
              });
            }
          });
        }
      } else {
        serviceRequestResult = await _locationService.requestService();
        if (serviceRequestResult) {
          initLocationService();
          return;
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        _serviceError = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        _serviceError = e.message;
      }
      location = null;
    }
  }

  void stopGps() {
    _locationStream.pause();
  }

  void continueGps() {
    _locationStream.resume();
  }

  @override
  Widget build(BuildContext context) {
    LatLng currentLatLng;
    double heading;

    if (_currentLocation != null) {
      currentLatLng =
          LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
      heading = _currentLocation!.heading * (pi / 180);
    } else {
      currentLatLng = widget.regatta.options.center;
      heading = 0;
    }

    this._courseOrientation = _getCourseOrientation();
    if (_northAlignment) {
      widget.mapController.rotate(this._courseOrientation);
    }

    Polyline mapLineS;
    Polyline? mapLineSCenter;

    Polyline mapLineG;
    Polyline? mapLineGCenter;

    List<CircleMarker> mapCircles = [];
    List<Polyline> mapLines = [];

    var markers = <Marker>[
      Marker(
          width: 80,
          height: 80,
          point: currentLatLng,
          builder: (ctx) => Container(
                child: Transform.rotate(
                    angle: heading,
                    child: Icon(
                      Icons.navigation,
                      color: Colors.deepPurple,
                      size: 30,
                    )),
              ),
          anchorPos: AnchorPos.align(AnchorAlign.center))
    ];

    // Map features for Startingline
    mapLineS = new Polyline(
        points: widget.regatta.startingline.toLatLng(),
        strokeWidth: 4,
        color: widget.slColor,
        borderColor: Colors.black);

    mapCircles.addAll(widget.regatta.startingline.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          color: widget.slColor.withOpacity(0.5),
          useRadiusInMeter: true,
          borderStrokeWidth: 1,
          borderColor: Colors.black26,
          radius: 3);
    }).toList());

    mapCircles.addAll(widget.regatta.startingline.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black);
    }).toList());

    //Center line start
    if (widget.regatta.startingline.isComplete() &&
        widget.regatta.startingline.isActualLine()) {
      mapLineSCenter = new Polyline(
          points: widget.regatta.startingline
              .transformProjection(this.projTuple)
              .getOrthogonalLine(widget.localOptions.centerlineLength)
              .transformProjection(this.projTuple, inverse: true)
              .toLatLng(),
          strokeWidth: 3,
          color: widget.slColor,
          isDotted: true,
          borderColor: Colors.black);
    }

    // Map features for Gate
    mapLineG = new Polyline(
        points: widget.regatta.gate.toLatLng(),
        strokeWidth: 3,
        color: widget.gateColor,
        borderColor: Colors.black,
        isDotted: true);

    mapCircles.addAll(widget.regatta.gate.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          color: widget.gateColor.withOpacity(0.5),
          useRadiusInMeter: true,
          borderStrokeWidth: 1,
          borderColor: Colors.black26,
          radius: 10);
    }).toList());

    mapCircles.addAll(widget.regatta.gate.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black);
    }).toList());

    // center line gate
    if (widget.regatta.gate.isComplete() &&
        widget.regatta.gate.isActualLine()) {
      mapLineGCenter = new Polyline(
          points: widget.regatta.gate
              .transformProjection(this.projTuple)
              .getOrthogonalLine(widget.localOptions.centerlineLength)
              .transformProjection(this.projTuple, inverse: true)
              .toLatLng(),
          strokeWidth: 2,
          color: widget.gateColor,
          borderColor: Colors.black,
          isDotted: true);
    }

    mapLines.addAll([mapLineS, mapLineG]);
    if (widget.localOptions.visibilitySlCenterline && mapLineSCenter != null)
      mapLines.add(mapLineSCenter);
    if (widget.localOptions.visibilityGateCenterline && mapLineGCenter != null)
      mapLines.add(mapLineGCenter);

    // Map features for Topmark
    if (widget.regatta.topmark != null) {
      LatLng point = widget.regatta.topmark!.toLatLng();
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

    return Flexible(
        child: Stack(children: [
      FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          center: currentLatLng,
          zoom: 17,
          onTap: (latlng) => dev.log(latlng.toString(), name: "taped at:"),
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
            tileProvider: NonCachingNetworkTileProvider(),
          ),
          // MarkerLayerOptions(markers: mapMarker),
          PolylineLayerOptions(polylines: mapLines),
          CircleLayerOptions(circles: mapCircles),
          MarkerLayerOptions(markers: markers),
        ],
      ),
      Row(
        children: [
          Padding(padding: EdgeInsets.only(left: 5), child: _viewButton()),
          Padding(padding: EdgeInsets.only(left: 5), child: _rotationButton()),
        ],
      ),
      _center()
    ]));
  }

  Widget _rotationButton() {
    bool _disabled = !(widget.regatta.startingline.isComplete() &&
        widget.regatta.topmark != null);

    if (_northAlignment) {
      return ElevatedButton.icon(
        icon: Icon(Icons.navigation_outlined),
        label: Text("Align to North"),
        onPressed: () {
          widget.mapController.rotate(0);
          setState(() => _northAlignment = !_northAlignment);
        },
      );
    } else {
      return ElevatedButton.icon(
        icon: Icon(Icons.near_me_outlined),
        label: Text("Align to Course"),
        onPressed: _disabled
            ? null
            : () {
                widget.mapController.rotate(this._courseOrientation);
                var bbox = widget.regatta.calculateBbox();
                widget.mapController.fitBounds(bbox);
                // var zoom = widget.mapController.zoom;
                // widget.mapController
                //     .move(widget.mapController.center, zoom);
                setState(() => _northAlignment = !_northAlignment);
              },
      );
    }
  }

  double _getCourseOrientation() {
    if (widget.regatta.startingline.isComplete() &&
        widget.regatta.topmark != null) {
      var sLine =
          widget.regatta.startingline.transformProjection(this.projTuple);
      Vector sLineVec = new Vector(sLine.p1!, sLine.p2!);
      Vector orthoLine = sLineVec.getOrthogonalVector();
      bool isPointRightToLine = sLineVec.compareToPoint(
              widget.regatta.topmark!.transformProjection(this.projTuple)) >
          0;

      Vector north = new Vector(MyPoint(0, 0), MyPoint(0, 1));
      var angle = north.getAngleToVector(orthoLine);

      if (isPointRightToLine) angle += 180;

      return angle;
    } else
      return 0;
  }

  Widget _viewButton() {
    switch (_viewState) {
      case ViewState.FREE:
        return ElevatedButton.icon(
            icon: Icon(Icons.gps_not_fixed),
            onPressed: _toggleView,
            label: Text("Fix position \n to GPS"));

      case ViewState.GPS:
        return ElevatedButton.icon(
            icon: Icon(Icons.gps_fixed),
            onPressed: _toggleView,
            label: Text("Fix position\nto course"));

      case ViewState.COURSE:
        return ElevatedButton.icon(
            icon: Icon(Icons.gps_not_fixed),
            onPressed: _toggleView,
            label: Text("Free movement"));
    }
  }

  Widget _center() {
    if (_viewState == ViewState.FREE) {
      return Center(child: Icon(Icons.add));
    } else {
      return Center();
    }
  }

  void _toggleView() {
    setState(() {
      // continueGps();

      switch (_viewState) {
        case ViewState.GPS:
          interActiveFlags =
              InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom;

          widget.mapController.move(
              LatLng(_currentLocation?.latitude, _currentLocation?.longitude),
              17);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('In GPS mode only zoom and rotation are enable'),
          ));
          _viewState = ViewState.FREE;
          break;

        case ViewState.FREE:
          interActiveFlags = InteractiveFlag.all;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Live update deactivated'),
          ));
          _viewState = ViewState.GPS;
          break;

        case ViewState.COURSE:
          // _viewState = ViewState.GPS;
          break;
      }
    });
  }
}
