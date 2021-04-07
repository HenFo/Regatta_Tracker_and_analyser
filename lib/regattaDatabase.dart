import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import "helperClasses.dart";
import "package:latlong/latlong.dart";
import "package:location/location.dart";

abstract class DatabaseObject {
  Map<String, dynamic> toMap();
}

class Regatta implements DatabaseObject {
  static final String dbTableName = "regatta";
  static final String dbID = "rID";
  static final String dbListID = "lID";
  static final String dbName = "name";
  static final String dbLocation = "location";
  static final String dbTopmark = "topmark";
  static final String dbGate = "gate";
  static final String dbStartingline = "startingline";

  late final int localListID;
  late final String name;

  int? id;
  String location = "Earth";

  Topmark? topmark;
  Startingline startingline = new Startingline(null, null);
  Gate gate = new Gate(null, null);

  RegattaOptions options = new RegattaOptions();
  // RegattaInformation informations; //TODOOOOOOOOOOOOOO

  Regatta(this.localListID, this.name);
  Regatta.fromMap(Map<String, dynamic> map) {
    localListID = map[dbListID];
    id = map[dbID];

    location = map[dbLocation];
    name = map[dbName];

    options = RegattaOptions.fromMap(map);

    topmark = Topmark.fromText(map[dbTopmark]);
    startingline = Startingline.fromText(map[dbStartingline]);
    gate = Gate.fromText(map[dbGate], radius: options.gateRadius);
  }

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
    var map = <String, dynamic>{
      dbName: this.name,
      dbListID: this.localListID,
      dbLocation: this.location,
      dbTopmark: this.topmark.toString(),
      dbStartingline: this.startingline.toString(),
      dbGate: this.gate.toString(),
      RegattaOptions.dbCenter:
          "${options.center.latitude},${options.center.longitude}",
      RegattaOptions.dbCenterlineLength: options.centerlineLength,
      RegattaOptions.dbGateRadius: options.gateRadius,
      RegattaOptions.dbStartinglineRadius: options.startinglineRadius,
      RegattaOptions.dbVisibilityGateCenterline:
          options.visibilityGateCenterline ? 1 : 0,
      RegattaOptions.dbVisibilitySlCenterlineLength:
          options.visibilitySlCenterline ? 1 : 0
    };

    if (id != null) {
      map[dbID] = this.id;
    }

    return map;
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

  RegattaOptions();
  RegattaOptions.fromMap(Map<String, dynamic> map) {
    gateRadius = map[dbGateRadius];
    startinglineRadius = map[dbStartinglineRadius];
    centerlineLength = map[dbCenterlineLength];
    visibilitySlCenterline = map[dbVisibilitySlCenterlineLength] == 1;
    visibilityGateCenterline = map[dbVisibilityGateCenterline] == 1;
    String centerText = map[dbCenter];
    var centerSplit = centerText.split(",");
    center = LatLng(double.parse(centerSplit[0]), double.parse(centerSplit[1]));
  }

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

abstract class Trackingdata {
  factory Trackingdata(int tick, LocationData locationData) {
    return _TrackingdataOrigin(tick, locationData);
  }

  factory Trackingdata.fromText(String text) {
    var split = text.trim().split(",");
    return _TrackingdataFromText(
        int.parse(split[0]),
        double.parse(split[1]),
        double.parse(split[2]),
        double.parse(split[3]),
        double.parse(split[4]),
        double.parse(split[5]),
        double.parse(split[6]),
        double.parse(split[7]));
  }

  static String getCSVHead() {
    return "tick,timestamp,lat,long,accuracyInM,speed,speedAccuracy,heading";
  }

  String toString();
  LatLng toLatLng();
  int getTick();
  double getTime();
  double getLatitude();
  double getLongitude();
  double getAccuracy();
  double getSpeed();
  double getSpeedAccuracy();
  double getHeading();
}

class _TrackingdataOrigin implements Trackingdata {
  final int _tick;
  final LocationData locationData;

  _TrackingdataOrigin(this._tick, this.locationData);

  @override
  String toString() {
    return "$_tick,${locationData.time},${locationData.latitude},${locationData.longitude},${locationData.accuracy},${locationData.speed},${locationData.speedAccuracy},${locationData.heading}";
  }

  @override
  double getAccuracy() {
    return locationData.accuracy;
  }

  @override
  double getHeading() {
    return locationData.heading;
  }

  @override
  double getLatitude() {
    return locationData.latitude;
  }

  @override
  double getLongitude() {
    return locationData.longitude;
  }

  @override
  double getSpeed() {
    return locationData.speed;
  }

  @override
  double getSpeedAccuracy() {
    return locationData.speedAccuracy;
  }

  @override
  int getTick() {
    return _tick;
  }

  @override
  double getTime() {
    return locationData.time;
  }

  @override
  LatLng toLatLng() {
    return LatLng(locationData.latitude, locationData.longitude);
  }
}

class _TrackingdataFromText implements Trackingdata {
  final int _tick;
  final double _time;
  final double _lat;
  final double _lon;
  final double _accuracy;
  final double _speed;
  final double _speedAccuracy;
  final double _heading;

  _TrackingdataFromText(this._tick, this._time, this._lat, this._lon,
      this._accuracy, this._speed, this._speedAccuracy, this._heading);

  @override
  String toString() {
    return "$_tick,$_time,$_lat,$_lon,$_accuracy,$_speed,$_speedAccuracy,$_heading";
  }

  @override
  double getAccuracy() {
    return _accuracy;
  }

  @override
  double getHeading() {
    return _heading;
  }

  @override
  double getLatitude() {
    return _lat;
  }

  @override
  double getLongitude() {
    return _lon;
  }

  @override
  double getSpeed() {
    return _speed;
  }

  @override
  double getSpeedAccuracy() {
    return _speedAccuracy;
  }

  @override
  int getTick() {
    return _tick;
  }

  @override
  double getTime() {
    return _time;
  }

  @override
  LatLng toLatLng() {
    return LatLng(_lat, _lon);
  }
}

class Track implements DatabaseObject {
  static final String dbTableName = "track";
  static final String dbID = "round";
  static final String dbRID = "rID";
  static final String dbBID = "bID";
  static final String dbTrackFilePath = "path";

  late final int round; // ID dependent on Regatta
  late final int regattaID;
  late final int boatID;
  late final List<Trackingdata> trackingPoints;
  String? filepath;

  Track(this.regattaID, this.round, this.boatID, this.trackingPoints);
  Track.fromMap(Map<String, dynamic> map) {
    round = map[dbID];
    regattaID = map[dbRID];
    boatID = map[dbBID];
    filepath = map[dbTrackFilePath];
    trackingPoints = <Trackingdata>[];
  }

  void loadTrackingpoints() async {
    try {
      final fileName = "$round-$boatID";
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$regattaID/$fileName.csv');

      String text = await file.readAsString();
      var rows = text.split("\n");
      rows.removeAt(0);

      rows.forEach((row) {
        trackingPoints.add(Trackingdata.fromText(row));
      });
    } catch (e) {
      print("Couldn't read file");
    }
  }

  @override
  Map<String, dynamic> toMap({String? pFilepath}) {
    if (filepath == null && pFilepath == null) {
      throw Exception("Filepath missing");
    }

    Map<String, dynamic> map = <String, dynamic>{
      dbRID: regattaID,
      dbID: round,
      dbBID: boatID,
      dbTrackFilePath: filepath ?? pFilepath
    };

    return map;
  }

  Future<String> saveTrackToCSV() async {
    final fileName = "$round-$boatID";
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$regattaID/$fileName.csv');

    var csvText = Trackingdata.getCSVHead() + "\n";
    for (var point in this.trackingPoints) {
      csvText += point.toString() + "\n";
    }

    await file.writeAsString(csvText);

    this.filepath = file.path;
    return file.path;
  }
}

class Boat implements DatabaseObject {
  static final String dbTableName = "boat";
  static final String dbID = "bID";
  static final String dbName = "name";

  late final String name;
  int? boatID;
  Color boatColor = Color.fromRGBO(
      Random().nextInt(256), Random().nextInt(256), Random().nextInt(256), 1);

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

class DatabaseHelper {
  static final String _databaseName = "RegattaDatabase.db";
  static final int _databaseVersion = 1;
  Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory docDir = await getApplicationDocumentsDirectory();
    String path = "${docDir.path}/$_databaseName";
    print(path);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    String createRegatta = """
    CREATE TABLE ${Regatta.dbTableName} (
      ${Regatta.dbID} INTEGER PRIMARY KEY,
      ${Regatta.dbListID} INTEGER NOT NULL,
      ${Regatta.dbName} TEXT NOT NULL,
      ${Regatta.dbLocation} TEXT NOT NULL,
      ${Regatta.dbTopmark} TEXT NOT NULL,
      ${Regatta.dbStartingline} TEXT NOT NULL,
      ${Regatta.dbGate} TEXT NOT NULL,
      ${RegattaOptions.dbCenter} TEXT NOT NULL,
      ${RegattaOptions.dbCenterlineLength} REAL NOT NULL,
      ${RegattaOptions.dbGateRadius} REAL NOT NULL,
      ${RegattaOptions.dbStartinglineRadius} REAL NOT NULL,
      ${RegattaOptions.dbVisibilityGateCenterline} INTEGER NOT NULL,
      ${RegattaOptions.dbVisibilitySlCenterlineLength} INTEGER NOT NULL
    );""";

    String createBoat = """
    CREATE TABLE ${Boat.dbTableName} (
      ${Boat.dbID} INTEGER PRIMARY KEY,
      ${Boat.dbName} TEXT NOT NULL
    );""";

    String createTrack = """
    CREATE TABLE ${Track.dbTableName} (
      ${Track.dbID} INTEGER NOT NULL,
      ${Track.dbBID} INTEGER NOT NULL,
      ${Track.dbRID} INTEGER NOT NULL,
      ${Track.dbTrackFilePath} TEXT,
      PRIMARY KEY(${Track.dbID}, ${Track.dbBID}, ${Track.dbRID}),

      FOREIGN KEY(${Track.dbBID}) REFERENCES ${Boat.dbTableName}(${Boat.dbID})
        ON UPDATE CASCADE
        ON DELETE SET NULL,

      FOREIGN KEY(${Track.dbRID}) REFERENCES ${Regatta.dbTableName}(${Regatta.dbID})
        ON UPDATE CASCADE
        ON DELETE SET NULL
    );

    """;

    Batch batch = db.batch();
    batch.execute(createRegatta);
    batch.execute(createBoat);
    batch.execute(createTrack);
    batch.insert(Boat.dbTableName, Boat("OranJeton").toMap());

    await batch.commit(noResult: true);
  }

  Future<int> insertRegatta(Regatta regatta) async {
    Database db = await getDatabase();
    int id = await db.insert(Regatta.dbTableName, regatta.toMap());
    return id;
  }

  Future<int> insertBoat(Boat boat) async {
    Database db = await getDatabase();
    int id = await db.insert(Boat.dbTableName, boat.toMap());
    return id;
  }

  Future<int> insertTrack(Track track) async {
    Database db = await getDatabase();
    await track.saveTrackToCSV();
    int id = await db.insert(Track.dbTableName, track.toMap());
    return id;
  }

  Future<Regatta> getRegattaByID(int id) async {
    Database db = await getDatabase();
    var result = await db.query(Regatta.dbTableName,
        where: "${Regatta.dbID} = ?", whereArgs: [id]);

    return Regatta.fromMap(result.first);
  }

  Future<List<Regatta>> getAllRegattas() async {
    Database db = await getDatabase();
    var results = await db.query(Regatta.dbTableName, orderBy: Regatta.dbID);

    return results.map((row) {
      return Regatta.fromMap(row);
    }).toList();
  }

  Future<int> updateRegatta(Regatta regatta) async {
    Database db = await getDatabase();
    int id = await db.update(Regatta.dbTableName, regatta.toMap(),
        where: "${Regatta.dbID} = ?", whereArgs: [regatta.id]);
    return id;
  }

  Future<int> getNumberRounds(int regattaID) async {
    Database db = await getDatabase();
    String roundsName = "rounds";
    var countRow = await db.rawQuery("""
      SELECT count(distinct ${Track.dbID}) as $roundsName
      FROM ${Track.dbTableName}
      WHERE ${Track.dbRID} = $regattaID;
       """);
    return countRow.first[roundsName] as int;
  }
}
