import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../playRegatta.dart';
import 'mainList.dart';
import "../regattaDatabase.dart";
import "../createing_and_editing_regatta/createRegatta.dart";
import "dart:developer" as dev;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final List<Regatta> regattas = [];
  final Boat boat = Boat("OranJeton");

  @override
  void initState() {
    super.initState();
    initList();
    boat.boatID = 1;
  }

  void initList() async {
    dbHelper
        .getAllRegattas()
        .then((value) => setState(() => regattas.addAll(value)));
  }

  void newRegatta(Regatta regatta) async {
    dev.log("Save to List", name: "HomePage");
    regatta.id = await dbHelper.insertRegatta(regatta);
    var dir = await getApplicationDocumentsDirectory();
    var regattaDir = Directory(dir.path + "/${regatta.id}");
    regattaDir.create();
    setState(() => regattas.add(regatta));
  }

  void editRegatta(index) {
    var regatta = regattas[index];

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CreateRegatta(regatta.localListID,
                regatta.name, null, regatta, this.updateRegattaInList)));
  }

  void updateRegattaInList(Regatta regatta) {
    dbHelper.updateRegatta(regatta);
    setState(() => regattas[regatta.localListID] = regatta);
  }

  void playRegatta(int indexOfRegatta) {
    var regatta = regattas[indexOfRegatta];
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => PlayRegatta(regatta, boat)));
  }

  TextEditingController _regattaNameController = TextEditingController();
  late String newName;

  Future<void> _displayRegattaNameInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text("Input new regatta name:"),
              content: TextField(
                onChanged: (value) {
                  setState(() {
                    newName = value;
                  });
                },
                controller: _regattaNameController,
                decoration: InputDecoration(
                  hintText: "Regatta",
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.green),
                  child: Text("Create"),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                      _regattaNameController.clear();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CreateRegatta(
                                  regattas.length, newName, this.newRegatta)));
                    });
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  child: Text('CANCEL'),
                  onPressed: () {
                    setState(() {
                      _regattaNameController.clear();
                      Navigator.pop(context);
                    });
                  },
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (regattas.isEmpty) {
      body = Center(
        child: Text("Add a new Regatta"),
      );
    } else {
      body = MainList(this.regattas, this.editRegatta, this.playRegatta);
    }
    return Scaffold(
        appBar: AppBar(title: Text("Your regatta courses")),
        body: body,
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            backgroundColor: Colors.amber,
            onPressed: () {
              _displayRegattaNameInputDialog(context);
            }));
  }
}
