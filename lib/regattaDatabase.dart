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

  bool equalLayout(Regatta otherRegatta) {
    if (this.topmark != null && otherRegatta.topmark != null) {
      return this.topmark!.equals(otherRegatta.topmark) &&
          this.gate.equals(otherRegatta.gate) &&
          this.startingline.equals(otherRegatta.startingline);
    }
    return false;
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

  bool equals(RegattaOptions options) {
    return this.visibilityGateCenterline == options.visibilityGateCenterline &&
        this.center == options.center &&
        this.centerlineLength == options.centerlineLength &&
        this.gateRadius == options.gateRadius &&
        this.startinglineRadius == options.startinglineRadius &&
        this.visibilitySlCenterline == options.visibilitySlCenterline;
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
  late final int _tick;
  late final double _time;
  late final double _lat;
  late final double _lon;
  late final double _accuracy;
  late final double _speed;
  late final double _speedAccuracy;
  late final double _heading;
  late final double _distance;

  Trackingdata.fromOrigin(int tick, LocationData locationData,
      {double distance = 0}) {
    this._tick = tick;
    this._time = locationData.time;
    this._lat = locationData.latitude;
    this._lon = locationData.longitude;
    this._accuracy = locationData.accuracy;
    this._speed = locationData.speed;
    this._speedAccuracy = locationData.speedAccuracy;
    this._heading = locationData.heading;
    this._distance = distance;
  }

  Trackingdata.fromText(String text) {
    var split = text.trim().split(",");
    this._tick = int.parse(split[0]);
    this._time = double.parse(split[1]);
    this._lat = double.parse(split[2]);
    this._lon = double.parse(split[3]);
    this._accuracy = double.parse(split[4]);
    this._speed = double.parse(split[5]);
    this._speedAccuracy = double.parse(split[6]);
    this._heading = double.parse(split[7]);
    this._distance = double.parse(split[8]);
  }

  static String getCSVHead() {
    return "tick,timestamp,lat,long,accuracyInM,speed,speedAccuracy,heading,distanceTraveled";
  }

  @override
  String toString() {
    return "$_tick,$_time,$_lat,$_lon,$_accuracy,$_speed,$_speedAccuracy,$_heading,$_distance";
  }

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
