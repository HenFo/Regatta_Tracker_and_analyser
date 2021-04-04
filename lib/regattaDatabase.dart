import 'package:flutter_map/flutter_map.dart';
import "helperClasses.dart";
import "package:latlong/latlong.dart";
import "package:location/location.dart";

abstract class DatabaseObject {
  Map<String, dynamic> toMap();
}

class Regatta implements DatabaseObject {
  static final String dbID = "rID";
  static final String dbName = "name";
  static final String dbLocation = "location";
  static final String dbTopmark = "topmark";
  static final String dbGate = "gate";
  static final String dbStartingline = "startingline";

  final int localListID;
  final String name;

  int? id;
  String location = "Earth";

  Topmark? topmark;
  Startingline startingline = new Startingline(null, null);
  Gate gate = new Gate(null, null);
  late double gateRadius;

  RegattaOptions options = new RegattaOptions();

  Regatta(this.localListID, this.name);

  LatLngBounds calculateBbox() {
    var points = <LatLng>[];
    if (topmark != null) {
      points.add(topmark!.toLatLng());
    }

    points.addAll(startingline.toLatLng());
    points.addAll(gate.toLatLng());

    var bounds = LatLngBounds.fromPoints(points);
    return bounds;
  }

  @override
  Map<String, dynamic> toMap() {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}

class RegattaOptions {
  static final String dbGateRadius = "gateRadius";
  static final String dbStartinglineRadius = "slRadius";
  static final String dbCenterlineLength = "centerlineLength";
  static final String dbVisibilitySlCenterlineLength = "visibilitySlCenterline";
  static final String dbVisibilityGateCenterline = "visibilityGateCenterline";
  static final String dbCenter = "center";

  double gateRadius = 7;
  double startinglineRadius = 3;
  double centerlineLength = 300.0;
  bool visibilitySlCenterline = true;
  bool visibilityGateCenterline = false;
  LatLng center = new LatLng(51.956074, 7.614565);

  RegattaOptions clone() {
    var options = new RegattaOptions();
    options.centerlineLength = this.centerlineLength;
    options.gateRadius = this.gateRadius;
    options.startinglineRadius = this.startinglineRadius;
    options.visibilityGateCenterline = this.visibilityGateCenterline;
    options.visibilitySlCenterline = this.visibilitySlCenterline;
    options.center = this.center;

    return options;
  }
}

class RegattaInformation {
  static final String dbTitle = "title";
  static final String dbSubTitle = "subtitle";
  static final String dbInformation = "information";

  final String title;
  final String subtitle;
  final String information;

  RegattaInformation(this.title, this.subtitle, this.information);
}

class Trackingdata {
  final int tick;
  final LocationData locationData;

  Trackingdata(this.tick, this.locationData);
}

class Track implements DatabaseObject {
  final int round; // ID dependent on Regatta
  final int regattaID;
  final int boatID;
  final List<Trackingdata> trackingPoints;

  Track(this.regattaID, this.round, this.boatID, this.trackingPoints);

  @override
  Map<String, dynamic> toMap() {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}

class Boat implements DatabaseObject {
  static final String dbID = "bID";
  static final String dbName = "name";

  late final String name;
  int? boatID;

  Boat(this.name);
  Boat.fromMap(Map<String, dynamic> map) {
    name = map[dbName];
    boatID = map[dbID];
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = <String, dynamic>{dbName: name};

    if (boatID != null) {
      map[dbID] = boatID!;
    }

    return map;
  }
}
