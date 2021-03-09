import 'package:flutter/material.dart';
import '../playRegatta.dart';
import 'mainList.dart';
import "../regatta.dart";
import "../createing_and_editing_regatta/createRegatta.dart";
import "dart:developer" as dev;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Regatta> regattas = [];

  void newRegatta(Regatta regatta) {
    dev.log("Save to List", name: "HomePage");
    setState(() => regattas.add(regatta));
  }

  void editRegatta(index) {
    var regatta = regattas[index];

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CreateRegatta(regatta.id, regatta.name, null,
                regatta, this.updateRegattaInList)));
  }

  void updateRegattaInList(Regatta regatta) {
    setState(() => regattas[regatta.id] = regatta);
  }

  void playRegatta(int indexOfRegatta) {
    var regatta = regattas[indexOfRegatta];
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => PlayRegatta(regatta)));
  }

  TextEditingController _regattaNameController = TextEditingController();
  String newName;

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
    return Scaffold(
        appBar: AppBar(title: Text("Your regatta courses")),
        body: MainList(this.regattas, this.editRegatta, this.playRegatta),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            backgroundColor: Colors.amber,
            onPressed: () {
              _displayRegattaNameInputDialog(context);
            }));
  }
}
