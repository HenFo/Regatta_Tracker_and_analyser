import 'package:flutter/material.dart';
import "package:flutter_map/flutter_map.dart";
import "package:latlong/latlong.dart";
import "dart:developer" as dev;
import "regatta.dart";
import "package:proj4dart/proj4dart.dart" as proj4;

class Map extends StatelessWidget {
  final MapController mapController;
  final LatLngBounds bounds;

  final double centerlineLength;
  final bool orthoSl;
  final bool orthoGate;

  final Topmark tm;
  final Startingline sl;
  final Gate gate;

  final Color slColor = Colors.amber;
  final Color gateColor = Colors.lightGreen;
  final Color tmColor = Colors.blueGrey;

  final proj4.ProjectionTuple projTuple = new proj4.ProjectionTuple(
      fromProj: proj4.Projection.WGS84, toProj: proj4.Projection.GOOGLE);

  Map(this.mapController, this.bounds, this.tm, this.sl, this.gate,
      this.centerlineLength, this.orthoSl, this.orthoGate);

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
        color: this.slColor,
        borderColor: Colors.black);

    mapCircles.addAll(sl.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          color: this.slColor.withOpacity(0.5),
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
              .transformProjection(this.projTuple)
              .getOrthogonalLine(centerlineLength)
              .transformProjection(this.projTuple, inverse: true)
              .toLatLng(),
          strokeWidth: 3,
          color: this.slColor,
          isDotted: true,
          borderColor: Colors.black);
    }

    // Map features for Gate
    mapLineG = new Polyline(
        points: gate.toLatLng(),
        strokeWidth: 3,
        color: this.gateColor,
        borderColor: Colors.black,
        isDotted: true);

    mapCircles.addAll(gate.toLatLng().map((latlng) {
      return CircleMarker(
          point: latlng,
          color: this.gateColor.withOpacity(0.5),
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
              .transformProjection(this.projTuple)
              .getOrthogonalLine(centerlineLength)
              .transformProjection(this.projTuple, inverse: true)
              .toLatLng(),
          strokeWidth: 2,
          color: this.gateColor,
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
          color: this.tmColor.withOpacity(0.5)));
      mapCircles.add(new CircleMarker(
          point: point,
          useRadiusInMeter: true,
          radius: 1,
          color: Colors.black));
    }

    return Flexible(
        child: FlutterMap(
      mapController: this.mapController,
      options: MapOptions(
          bounds: this.bounds,
          zoom: 17,
          onTap: (latlng) => dev.log(latlng.toString(), name: "taped at:")),
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
