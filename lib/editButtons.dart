import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:flutter_application_1/snackbars/snackBarOnSave.dart";

class EditButtons extends StatelessWidget {
  final Function _addToMap;
  final Function _save;
  final MapController _mapController;

  EditButtons(this._mapController, this._addToMap, this._save);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          ElevatedButton(
            child: Text("Topmark", textAlign: TextAlign.center),
            style: ElevatedButton.styleFrom(primary: Colors.blue),
            onPressed: () {
              _addToMap(0, _mapController.center);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                child: Text(
                  "Startingline - Start",
                  textAlign: TextAlign.center,
                ),
                style: ElevatedButton.styleFrom(primary: Colors.orange[700]),
                onPressed: () {
                  _addToMap(1, _mapController.center);
                },
              ),
              ElevatedButton(
                child: Text(
                  "Startingline - End",
                  textAlign: TextAlign.center,
                ),
                style: ElevatedButton.styleFrom(primary: Colors.orange),
                onPressed: () {
                  _addToMap(2, _mapController.center);
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                child: Text("Gate - Start", textAlign: TextAlign.center),
                style: ElevatedButton.styleFrom(primary: Colors.green[700]),
                onPressed: () {
                  _addToMap(3, _mapController.center);
                },
              ),
              ElevatedButton(
                child: Text("Gate - End", textAlign: TextAlign.center),
                style: ElevatedButton.styleFrom(primary: Colors.green[300]),
                onPressed: () {
                  _addToMap(4, _mapController.center);
                },
              ),
            ],
          ),
          SnackBarOnSave(_save)
        ],
      ),
    );
  }
}
