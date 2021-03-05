import "dart:math";
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart";
import "package:proj4dart/proj4dart.dart";

class Regatta {
  final int id;
  final String name;

  Topmark topmark;
  Startingline startingline = new Startingline(null, null);
  Gate gate = new Gate(null, null);
  double gateRadius;
  String location = "Earth";

  RegattaOptions options = new RegattaOptions();

  Regatta(this.id, this.name);

  LatLngBounds calculateBbox() {
    var points = <LatLng>[];
    if (topmark != null) {
      points.add(topmark.toLatLng());
    }

    points.addAll(startingline.toLatLng());
    points.addAll(gate.toLatLng());

    var bounds = LatLngBounds.fromPoints(points);
    return bounds;
  }
}

class RegattaOptions {
  double gateRadius = 7;
  double startinglineRadius = 3;
  double centerlineLength = 300.0;
  bool visibilitySlCenterline = true;
  bool visibilityGateCenterline = false;
  LatLng center = new LatLng(51.956074, 7.614565);
  // int zoomLevel = 17;
  // LatLngBounds bbox = new LatLngBounds(
  //     LatLng(51.958333, 7.611466), LatLng(51.954324, 7.618302));

  RegattaOptions clone() {
    var options = new RegattaOptions();
    // options.bbox = this.bbox;
    options.centerlineLength = this.centerlineLength;
    options.gateRadius = this.gateRadius;
    options.startinglineRadius = this.startinglineRadius;
    options.visibilityGateCenterline = this.visibilityGateCenterline;
    options.visibilitySlCenterline = this.visibilitySlCenterline;
    options.center = this.center;
    // options.zoomLevel = this.zoomLevel;

    return options;
  }
}

class MyPoint extends Point {
  final double x;
  final double y;

  MyPoint(this.x, this.y);

  bool equals(MyPoint otherPoint) {
    return (this.x == otherPoint.x) && (this.y == otherPoint.y);
  }

  MyPoint transformProjection(ProjectionTuple projTuple,
      {bool inverse = false}) {
    var transformed =
        inverse ? projTuple.inverse(this) : projTuple.forward(this);
    return new MyPoint(transformed.x, transformed.y);
  }

  double getEuclideanDistanceToPoint(MyPoint otherPoint) {
    return sqrt(pow(otherPoint.x - this.x, 2) + pow(otherPoint.y - this.y, 2));
  }

  double getGreatCircleDistanceToPoint(MyPoint otherPoint) {
    var p1 = this.toLatLng();
    var p2 = otherPoint.toLatLng();
    var distance = Distance(calculator: Haversine());

    return distance.as(LengthUnit.Meter, p1, p2);
  }

  LatLng toLatLng() {
    return new LatLng(y, x);
  }
}

class Vector {
  MyPoint start;
  MyPoint normDirection;

  Vector(this.start, MyPoint end) {
    var dx = end.x - start.x;
    var dy = end.y - start.y;

    var normFactor = 1 / (sqrt(pow(dx, 2) + pow(dy, 2)));
    dx = normFactor * dx;
    dy = normFactor * dy;

    this.normDirection = new MyPoint(dx, dy);
  }

  void setStart(MyPoint pStart) {
    start = pStart;
  }

  MyPoint getPointOnLine(double distFromStart) {
    var x = start.x + distFromStart * normDirection.x;
    var y = start.y + distFromStart * normDirection.y;

    return new MyPoint(x, y);
  }

  Vector getOrthogonalVector() {
    var hStart = new MyPoint(0, 0);
    var hDir = new MyPoint(-this.normDirection.y, this.normDirection.x);
    return new Vector(hStart, hDir);
  }

  double getDistanceToPoint(MyPoint p) {
    Vector orthoVector = getOrthogonalVector();
    orthoVector.setStart(p);

    var denominator = start.x +
        ((start.x - orthoVector.start.x) / normDirection.x) * normDirection.y -
        orthoVector.start.y;

    var numerator = orthoVector.normDirection.y -
        ((orthoVector.normDirection.x * normDirection.y) / normDirection.x);

    var scalar = denominator / numerator;

    return scalar.abs();

    // Point intersect = orthoVector.getPointOnLine(scalar);
    // Line connection = new Line(p, intersect);

    // return connection.getDistance();
  }
}

class Line {
  MyPoint p1;
  MyPoint p2;

  Line(this.p1, this.p2);

  bool equals(Line otherLine) {
    var a = this.p1.equals(otherLine.p1);
    var a2 = this.p1.equals(otherLine.p2);
    var b = this.p2.equals(otherLine.p2);
    var b2 = this.p2.equals(otherLine.p1);

    return (a && b) || (a2 && b2);
  }

  bool isActualLine() {
    return !this.p1.equals(this.p2);
  }

  Line transformProjection(ProjectionTuple projTuple, {bool inverse = false}) {
    var p1T = p1.transformProjection(projTuple, inverse: inverse);
    var p2T = p2.transformProjection(projTuple, inverse: inverse);

    return new Line(p1T, p2T);
  }

  bool isComplete() {
    return (p1 != null && p2 != null);
  }

  MyPoint getCenter() {
    Vector v = new Vector(p1, p2);
    return v.getPointOnLine(this.getEuclideanDistance() / 2);
  }

  Line getOrthogonalLine(
    double length, {
    bool centered = true,
    double distFromP1 = 0,
    bool symetric = true,
  }) {
    if (isComplete()) {
      Vector lineAsVector = new Vector(p1, p2);
      Vector orthoVector = lineAsVector.getOrthogonalVector();
      MyPoint startOfOrtho = centered
          ? lineAsVector.getPointOnLine(getEuclideanDistance() / 2)
          : lineAsVector.getPointOnLine(distFromP1);

      orthoVector.setStart(startOfOrtho);

      MyPoint lineEnd = orthoVector.getPointOnLine(length);
      MyPoint lineStart =
          symetric ? orthoVector.getPointOnLine(-length) : startOfOrtho;

      return new Line(lineStart, lineEnd);
    }

    if (p1 != null)
      return new Line(p1, p1);
    else if (p2 != null)
      return new Line(p2, p2);
    else
      return new Line(new MyPoint(0, 0), new MyPoint(0, 0));
  }

  double getEuclideanDistance() {
    if (isComplete()) {
      return p1.getEuclideanDistanceToPoint(p2);
    }

    return 0;
  }

  double getGreatCircleDistance() {
    if (isComplete()) {
      return p1.getGreatCircleDistanceToPoint(p2);
    }
    return 0;
  }

  List<LatLng> toLatLng() {
    var ret = <LatLng>[];
    if (p1 != null) {
      ret.add(p1.toLatLng());
    }
    if (p2 != null) {
      ret.add(p2.toLatLng());
    }

    return ret;
  }
}

class Startingline extends Line {
  Startingline(MyPoint p1, MyPoint p2) : super(p1, p2);
}

class Gate extends Line {
  double radius;
  Gate(MyPoint p1, MyPoint p2, {this.radius = 0}) : super(p1, p2);
}

class Topmark extends MyPoint {
  Topmark(double x, double y) : super(x, y);
}
