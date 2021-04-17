import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/regattaDatabase.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'helperClasses.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

abstract class MapDrawer {
  factory MapDrawer(
      {required Regatta regatta,
      required RegattaOptions localOptions,
      bool editSession = false}) {
    // return editSession
    //     ? _MapDrawerEdit(regatta, localOptions)
    //     : _LazyMapDrawer(regatta, localOptions);
    return _LazyMapDrawer(regatta, localOptions);
  }

  double getCourseOrientation();
  List<Polyline> getMapLines({List<Trackingdata> trailing = const []});
  List<CircleMarker> getCircleMarker();
  List<Marker> getPositionMarker(LatLng pos, double heading);
  void reset();
  void update(Regatta regatta, RegattaOptions localOptions);
}

abstract class AbstractMapDrawer implements MapDrawer {
  final proj4.ProjectionTuple _projTuple = new proj4.ProjectionTuple(
      fromProj: proj4.Projection.WGS84, toProj: proj4.Projection.GOOGLE);

  final Color _boatColor = Color.fromRGBO(
      Random().nextInt(256), Random().nextInt(256), Random().nextInt(256), 1);
  final Color _slColor = Colors.amber;
  final Color _gateColor = Colors.lightGreen;
  final Color _tmColor = Colors.blueGrey;

  List<Marker> getPositionMarker(LatLng pos, double heading) {
    return <Marker>[
      Marker(
          width: 80,
          height: 80,
          point: pos,
          builder: (ctx) => Container(
                child: Transform.rotate(
                    angle: heading,
                    child: Icon(
                      Icons.navigation,
                      color: _boatColor,
                      size: 30,
                    )),
              ),
          anchorPos: AnchorPos.align(AnchorAlign.center))
    ];
  }
}

class _MapDrawerEdit extends AbstractMapDrawer implements MapDrawer {
  late Regatta regatta;
  late RegattaOptions localOptions;

  _MapDrawerEdit(this.regatta, this.localOptions);

  @override
  void reset() {}
  void update(Regatta regatta, RegattaOptions localOptions) {
    this.regatta = regatta;
    this.localOptions = localOptions;
  }

  @override
  double getCourseOrientation() {
    if (regatta.startingline.isComplete() && regatta.topmark != null) {
      var sLine = regatta.startingline.transformProjection(this._projTuple);
      Vector sLineVec = new Vector(sLine.p1!, sLine.p2!);
      Vector orthoLine = sLineVec.getOrthogonalVector();
      bool isPointRightToLine = sLineVec.compareToPoint(
              regatta.topmark!.transformProjection(this._projTuple)) >
          0;

      Vector north = new Vector(MyPoint(0, 0), MyPoint(0, 1));
      var angle = north.getAngleToVector(orthoLine);

      if (isPointRightToLine) angle += 180;

      return angle;
    } else
      return 0;
  }

  @override
  List<Polyline> getMapLines({List<Trackingdata> trailing = const []}) {
    Polyline mapLineS;
    Polyline? mapLineSCenter;

    Polyline mapLineG;
    Polyline? mapLineGCenter;

    List<Polyline> mapLines = [];

    mapLineS = new Polyline(
        points: this.regatta.startingline.toLatLng(),
        strokeWidth: 4,
        color: this._slColor,
        borderColor: Colors.black);

    //Center line start
    if (this.regatta.startingline.isComplete() &&
        this.regatta.startingline.isActualLine()) {
      mapLineSCenter = new Polyline(
          points: this
              .regatta
              .startingline
              .transformProjection(this._projTuple)
              .getOrthogonalLine(this.localOptions.centerlineLength)
              .transformProjection(this._projTuple, inverse: true)
              .toLatLng(),
          strokeWidth: 3,
          color: this._slColor,
          isDotted: true,
          borderColor: Colors.black);
    }

// Map features for Gate
    mapLineG = new Polyline(
        points: this.regatta.gate.toLatLng(),
        strokeWidth: 3,
        color: this._gateColor,
        borderColor: Colors.black,
        isDotted: true);

    // center line gate
    if (this.regatta.gate.isComplete() && this.regatta.gate.isActualLine()) {
      mapLineGCenter = new Polyline(
          points: this
              .regatta
              .gate
              .transformProjection(this._projTuple)
              .getOrthogonalLine(this.localOptions.centerlineLength)
              .transformProjection(this._projTuple, inverse: true)
              .toLatLng(),
          strokeWidth: 2,
          color: this._gateColor,
          borderColor: Colors.black,
          isDotted: true);
    }

    Polyline trailingPolyline = new Polyline(
        points: trailing.map((e) => e.toLatLng()).toList(),
        color: this._boatColor,
        strokeWidth: 3);

    mapLines.addAll([mapLineS, mapLineG, trailingPolyline]);
    if (this.localOptions.visibilitySlCenterline && mapLineSCenter != null)
      mapLines.add(mapLineSCenter);
    if (this.localOptions.visibilityGateCenterline && mapLineGCenter != null)
      mapLines.add(mapLineGCenter);

    return mapLines;
  }

  @override
  List<CircleMarker> getCircleMarker() {
    List<CircleMarker> mapCircles = [];

    mapCircles.addAll(this.regatta.startingline.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          color: this._slColor.withOpacity(0.5),
          useRadiusInMeter: true,
          borderStrokeWidth: 1,
          borderColor: Colors.black26,
          radius: 3);
    }).toList());

    mapCircles.addAll(this.regatta.startingline.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black);
    }).toList());

    mapCircles.addAll(this.regatta.gate.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          color: this._gateColor.withOpacity(0.5),
          useRadiusInMeter: true,
          borderStrokeWidth: 1,
          borderColor: Colors.black26,
          radius: 10);
    }).toList());

    mapCircles.addAll(this.regatta.gate.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black);
    }).toList());

    // Map features for Topmark
    if (this.regatta.topmark != null) {
      LatLng point = this.regatta.topmark!.toLatLng();
      mapCircles.add(new CircleMarker(
          point: point,
          useRadiusInMeter: true,
          radius: 14,
          borderColor: Colors.black26,
          borderStrokeWidth: 1,
          color: this._tmColor.withOpacity(0.5)));
      mapCircles.add(new CircleMarker(
          point: point,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black));
    }

    return mapCircles;
  }
}

class _LazyMapDrawer implements MapDrawer {
  double? _courseOrientation;
  List<Polyline>? _polylines;
  List<CircleMarker>? _circleMarker;
  late _MapDrawerEdit _mapDrawerEdit;

  _LazyMapDrawer(Regatta regatta, RegattaOptions localOptions) {
    _mapDrawerEdit = _MapDrawerEdit(regatta, localOptions);
  }

  @override
  void reset() {
    _courseOrientation = null;
    _polylines = null;
    _circleMarker = null;
  }

  @override
  void update(Regatta regatta, RegattaOptions localOptions) {
    reset();
    _mapDrawerEdit = _MapDrawerEdit(regatta, localOptions);
  }

  @override
  double getCourseOrientation() {
    if (this._courseOrientation == null)
      this._courseOrientation = _mapDrawerEdit.getCourseOrientation();

    return this._courseOrientation!;
  }

  @override
  List<Polyline> getMapLines({List<Trackingdata> trailing = const []}) {
    if (this._polylines == null) this._polylines = _mapDrawerEdit.getMapLines();
    return this._polylines!;
  }

  @override
  List<CircleMarker> getCircleMarker() {
    if (_circleMarker == null) _circleMarker = _mapDrawerEdit.getCircleMarker();
    return _circleMarker!;
  }

  @override
  List<Marker> getPositionMarker(LatLng pos, double heading) {
    return _mapDrawerEdit.getPositionMarker(pos, heading);
  }
}
