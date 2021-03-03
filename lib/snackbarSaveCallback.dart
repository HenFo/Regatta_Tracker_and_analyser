import 'package:flutter/material.dart';
import "dart:developer" as dev;

class SnackBarPage extends StatelessWidget {
  final Function callback;

  SnackBarPage(this.callback);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text("Save"),
            onPressed: () {
              dev.log("Snackbar called", name: "snackbar");

              var text = "";
              if (callback()) {
                text = "Saved successfully";
              } else {
                text = "An Error accoured";
              }

              final snackBar = SnackBar(
                content: Text(text),
              );
              Scaffold.of(context).showSnackBar(snackBar);
            }));
  }
}
