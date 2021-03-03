import "dart:math";
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart";
import "package:proj4dart/proj4dart.dart";

class Regatta {
  final int ID;
  final String name;

  Topmark topmark;
  Startingline startingline;
  Gate gate;
  double gateRadius;
  LatLngBounds bbox;
  String location = "Earth";

  Regatta(this.ID, this.name);
}

class MyPoint extends Point {
  final double x;
  final double y;

  MyPoint(this.x, this.y);

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
    // var r = 6371e3; // metres
    // var phi1 = this.y * pi / 180; // phi, lambda in radians
    // var phi2 = otherPoint.y * pi / 180;
    // var deltaPhi = (otherPoint.y - this.y) * pi / 180;
    // var deltaLambda = (otherPoint.x - this.x) * pi / 180;

    // var a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
    //     cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    // var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // var d = r * c; // in metres
    // return d;

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

  Line transformProjection(ProjectionTuple projTuple, {bool inverse = false}) {
    var p1T = p1.transformProjection(projTuple, inverse: inverse);
    var p2T = p2.transformProjection(projTuple, inverse: inverse);

    return new Line(p1T, p2T);
  }

  bool isComplete() {
    return (p1 != null && p2 != null);
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
