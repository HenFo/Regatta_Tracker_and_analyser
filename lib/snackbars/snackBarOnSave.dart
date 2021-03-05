import 'package:flutter/material.dart';
import "dart:developer" as dev;

class SnackBarOnSave extends StatelessWidget {
  final Function saveCallback;

  SnackBarOnSave(this.saveCallback);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text("Save"),
            onPressed: () {
              dev.log("Snackbar called", name: "snackbar");

              var text = "";
              if (saveCallback()) {
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
