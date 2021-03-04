import 'package:flutter/material.dart';
import "package:flutter_map/flutter_map.dart";
import "dart:developer" as dev;

class Map extends StatelessWidget {

  final MapController mapController;
  final List<Polyline> mapLines;
  final List<CircleMarker> mapCircles;
  final LatLngBounds bounds;

  Map(this.mapController, this.mapLines, this.mapCircles, this.bounds);

  @override
  Widget build(BuildContext context) {
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
        PolylineLayerOptions(polylines: this.mapLines),
        CircleLayerOptions(circles: this.mapCircles),
      ],
    ));
  }
}
