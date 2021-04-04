import 'package:flutter/material.dart';
import "regattaDatabase.dart";


class RaceSettings extends StatefulWidget {
  final RegattaOptions options;
  final Function callback;
  final String name;

  RaceSettings(this.options, this.name, this.callback);

  @override
  _RaceSettingsState createState() => _RaceSettingsState();
}

class _RaceSettingsState extends State<RaceSettings> {
  TextEditingController centerlineLengthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    centerlineLengthController.text =
        widget.options.centerlineLength.toString();

    return Scaffold(
        appBar: AppBar(title: Text("Settings for Race '${widget.name}'")),
        body: ListView(
          children: [
            CheckboxListTile(
                title: Text("Mark centerline Startingline"),
                value: widget.options.visibilitySlCenterline,
                onChanged: (newValue) {
                  setState(() {
                    widget.options.visibilitySlCenterline = newValue!;
                  });
                  widget.callback(widget.options);
                },
                controlAffinity: ListTileControlAffinity.leading),
            CheckboxListTile(
                title: Text("Mark centerline gate"),
                value: widget.options.visibilityGateCenterline,
                onChanged: (newValue) {
                  setState(() {
                    widget.options.visibilityGateCenterline = newValue!;
                  });
                  widget.callback(widget.options);
                },
                controlAffinity: ListTileControlAffinity.leading),
            ListTile(
              title: TextField(
                controller: centerlineLengthController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(suffixText: "m"),
                onSubmitted: (val) {
                  widget.options.centerlineLength = double.tryParse(val) ?? 0.0;
                  widget.callback(widget.options);
                },
              ),
              trailing: Text("Length of Centerline"),
            )
          ],
        ));
  }
}
