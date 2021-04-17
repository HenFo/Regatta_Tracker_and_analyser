import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/mapDrawer.dart';
import "package:flutter_map/flutter_map.dart";
import "package:latlong/latlong.dart";
import "dart:developer" as dev;
import "regattaDatabase.dart";
import 'package:location/location.dart';
import "dart:math";

class RegattaMap extends StatefulWidget {
  final MapController mapController;
  final MapDrawer mapDrawer;
  final Regatta regatta;
  late final RegattaOptions localOptions;
  final Function? gpsInformationCallback;
  final List<Trackingdata> trailingLine;

  final Color slColor = Colors.amber;
  final Color gateColor = Colors.lightGreen;
  final Color tmColor = Colors.blueGrey;
  // final Color boatColor = Colors.deepPurple;

  RegattaMap(this.mapController, this.mapDrawer, this.regatta,
      {RegattaOptions? localOptions,
      this.gpsInformationCallback,
      this.trailingLine = const []})
      : localOptions = localOptions ?? regatta.options;

  @override
  _RegattaMapState createState() => _RegattaMapState();
}

// 0 = fix to GPS
// 1 = free movement
// 2 = fix to course
enum ViewState { GPS, FREE, COURSE }

class _RegattaMapState extends State<RegattaMap> {
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
    dev.log("init map");
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
        print(_serviceError);
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        _serviceError = e.message;
        print(_serviceError);
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

    if (_northAlignment) {
      widget.mapController.rotate(widget.mapDrawer.getCourseOrientation());
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
          PolylineLayerOptions(polylines: widget.mapDrawer.getMapLines(trailing: widget.trailingLine)),
          CircleLayerOptions(circles: widget.mapDrawer.getCircleMarker()),
          MarkerLayerOptions(markers: widget.mapDrawer.getPositionMarker(currentLatLng, heading)),
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
                widget.mapController.rotate(widget.mapDrawer.getCourseOrientation());
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
            content: Text('Live update deactivated'),
          ));
          _viewState = ViewState.FREE;
          break;

        case ViewState.FREE:
          interActiveFlags = InteractiveFlag.all;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('In GPS mode only zoom and rotation are enable'),
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
