import "dart:math" as math;
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart";
import 'package:location/location.dart';
import "package:proj4dart/proj4dart.dart";
import "package:sqflite/sqflite.dart";
import "package:path_provider/path_provider.dart";


class MyPoint extends Point {
  final double x;
  final double y;

  MyPoint(this.x, this.y);

  bool equals(MyPoint? otherPoint) {
    if (otherPoint != null)
      return (this.x == otherPoint.x) && (this.y == otherPoint.y);
    return false;
  }

  MyPoint transformProjection(ProjectionTuple projTuple,
      {bool inverse = false}) {
    var transformed =
        inverse ? projTuple.inverse(this) : projTuple.forward(this);
    return new MyPoint(transformed.x, transformed.y);
  }

  double getEuclideanDistanceToPoint(MyPoint otherPoint) {
    return math.sqrt(math.pow(otherPoint.x - this.x, 2) +
        math.pow(otherPoint.y - this.y, 2));
  }

  double getGreatCircleDistanceToPoint(MyPoint otherPoint) {
    var p1 = this.toLatLng();
    var p2 = otherPoint.toLatLng();
    var distance = Distance(calculator: Haversine());

    return distance.as(LengthUnit.Meter, p1, p2) as double;
  }

  LatLng toLatLng() {
    return new LatLng(y, x);
  }
}

class Vector {
  MyPoint start;
  late MyPoint normDirection;

  Vector(this.start, MyPoint end) {
    var dx = end.x - start.x;
    var dy = end.y - start.y;

    var normFactor = 1 / (math.sqrt(math.pow(dx, 2) + math.pow(dy, 2)));
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

  double getDistanceToPoint(MyPoint p, {bool onlyPositiveValue = true}) {
    Vector orthoVector = getOrthogonalVector();
    orthoVector.setStart(p);

    var a = this.start.x;
    var b = this.start.y;
    var c = this.normDirection.x;
    var d = this.normDirection.y;
    var e = orthoVector.start.x;
    var f = orthoVector.start.y;
    var g = orthoVector.normDirection.x;
    var h = orthoVector.normDirection.y;

    // var denominator = start.x +
    //     ((start.x - orthoVector.start.x) / normDirection.x) * normDirection.y -
    //     orthoVector.start.y;

    // var numerator = orthoVector.normDirection.y -
    //     ((orthoVector.normDirection.x * normDirection.y) / normDirection.x);

    var denominator = -b * c - e * d + a * d + f * c;
    var numerator = g * d - h * c;

    var scalar = denominator / numerator;

    if (onlyPositiveValue)
      return scalar.abs();
    else
      return scalar;
  }

  double getAngleToVector(Vector otherVector) {
    var angle =
        math.atan2(otherVector.normDirection.y, otherVector.normDirection.x) -
            math.atan2(this.normDirection.y, this.normDirection.x);
    return angle * (180 / math.pi);
  }

  /// Returns -1 if point is to the left of this vector
  /// Returns 0 if point is in this vector
  /// Returns 1 if point is to the right of this vector
  int compareToPoint(MyPoint point) {
    Vector v = new Vector(this.start, point);
    var angle = this.getAngleToVector(v);
    if (angle > 0) return -1;
    if (angle < 0)
      return 1;
    else
      return 0;
  }
}

class Line {
  MyPoint? p1;
  MyPoint? p2;

  Line(this.p1, this.p2);

  bool equals(Line otherLine) {
    if (this.isComplete() && otherLine.isComplete()) {
      var a = this.p1!.equals(otherLine.p1!);
      var a2 = this.p1!.equals(otherLine.p2!);
      var b = this.p2!.equals(otherLine.p2!);
      var b2 = this.p2!.equals(otherLine.p1!);

      return (a && b) || (a2 && b2);
    }
    return false;
  }

  bool isActualLine() {
    return !(this.p1?.equals(this.p2) ?? false);
  }

  Line transformProjection(ProjectionTuple projTuple, {bool inverse = false}) {
    if (this.isComplete()) {
      var p1T = p1!.transformProjection(projTuple, inverse: inverse);
      var p2T = p2!.transformProjection(projTuple, inverse: inverse);

      return new Line(p1T, p2T);
    }
    return new Line(null, null);
  }

  bool isComplete() {
    return (p1 != null && p2 != null);
  }

  MyPoint? getCenter() {
    if (this.isComplete()) {
      Vector v = new Vector(p1!, p2!);
      return v.getPointOnLine(this.getEuclideanDistance() / 2);
    }
    return null;
  }

  Line getOrthogonalLine(
    double length, {
    bool centered = true,
    double distFromP1 = 0,
    bool symetric = true,
  }) {
    if (isComplete()) {
      Vector lineAsVector = new Vector(p1!, p2!);
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
      return p1!.getEuclideanDistanceToPoint(p2!);
    }

    return 0;
  }

  double getGreatCircleDistance() {
    if (isComplete()) {
      return p1!.getGreatCircleDistanceToPoint(p2!);
    }
    return 0;
  }

  List<LatLng> toLatLng() {
    var ret = <LatLng>[];
    if (p1 != null) {
      ret.add(p1!.toLatLng());
    }
    if (p2 != null) {
      ret.add(p2!.toLatLng());
    }

    return ret;
  }
}

class Startingline extends Line {
  Startingline(MyPoint? p1, MyPoint? p2) : super(p1, p2);
}

class Gate extends Line {
  double radius;
  Gate(MyPoint? p1, MyPoint? p2, {this.radius = 0}) : super(p1, p2);
}

class Topmark extends MyPoint {
  Topmark(double x, double y) : super(x, y);
}
