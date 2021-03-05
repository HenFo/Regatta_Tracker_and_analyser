import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter_map/flutter_map.dart";
import "package:latlong/latlong.dart";
import "dart:developer" as dev;
import "regatta.dart";
import "package:proj4dart/proj4dart.dart" as proj4;
import 'package:location/location.dart';

class RegattaMap extends StatefulWidget {
  final MapController mapController;
  final Regatta regatta;
  final RegattaOptions localOptions;

  final Color slColor = Colors.amber;
  final Color gateColor = Colors.lightGreen;
  final Color tmColor = Colors.blueGrey;

  final proj4.ProjectionTuple projTuple = new proj4.ProjectionTuple(
      fromProj: proj4.Projection.WGS84, toProj: proj4.Projection.GOOGLE);

  RegattaMap(this.mapController, this.regatta, [RegattaOptions localOptions])
      : this.localOptions =
            localOptions == null ? regatta.options : localOptions;

  @override
  _RegattaMapState createState() => _RegattaMapState();
}

class _RegattaMapState extends State<RegattaMap> {
  LocationData _currentLocation;

  bool _liveUpdate = false;
  bool _permission = false;

  String _serviceError = '';

  var interActiveFlags = InteractiveFlag.all;

  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    initLocationService();
  }

  void initLocationService() async {
    await _locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
    );

    LocationData location;
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
          _locationService.onLocationChanged
              .listen((LocationData result) async {
            if (mounted) {
              setState(() {
                _currentLocation = result;

                // If Live Update is enabled, move map center
                if (_liveUpdate) {
                  widget.mapController.move(
                      LatLng(_currentLocation.latitude,
                          _currentLocation.longitude),
                      widget.mapController.zoom);
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

  @override
  Widget build(BuildContext context) {
    LatLng currentLatLng;

    // Until currentLocation is initially updated, Widget can locate to 0, 0
    // by default or store previous location value to show.
    if (_currentLocation != null) {
      currentLatLng =
          LatLng(_currentLocation.latitude, _currentLocation.longitude);
    } else {
      currentLatLng = widget.regatta.options.center; //widget.regatta.topmark.toLatLng();
    }

    Polyline mapLineS;
    Polyline mapLineSCenter;

    Polyline mapLineG;
    Polyline mapLineGCenter;

    List<CircleMarker> mapCircles = [];
    List<Polyline> mapLines = [];

    mapCircles.add(new CircleMarker(
        radius: 5, useRadiusInMeter: true, color: Colors.deepPurple, point: currentLatLng));

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
              .transformProjection(widget.projTuple)
              .getOrthogonalLine(widget.localOptions.centerlineLength)
              .transformProjection(widget.projTuple, inverse: true)
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
              .transformProjection(widget.projTuple)
              .getOrthogonalLine(widget.localOptions.centerlineLength)
              .transformProjection(widget.projTuple, inverse: true)
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
      LatLng point = widget.regatta.topmark.toLatLng();
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
        child: FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
          center: currentLatLng,
          zoom: 17,
          onTap: (latlng) => dev.log(latlng.toString(), name: "taped at:"),
          onLongPress: (latLng) {
            setState(() {
              _liveUpdate = !_liveUpdate;

              if (_liveUpdate) {
                interActiveFlags = InteractiveFlag.rotate |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom;

                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'In live update mode only zoom and rotation are enable'),
                ));
              } else {
                interActiveFlags = InteractiveFlag.all;
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text('Live update deactivated'),
                ));
              }
            });
          }),
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
}
