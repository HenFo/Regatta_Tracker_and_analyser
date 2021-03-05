import 'package:flutter/material.dart';
import 'package:flutter_application_1/regatta.dart';

class DrawerOptions extends StatefulWidget {
  final RegattaOptions options;
  final Function callback;

  DrawerOptions(this.options, this.callback);

  @override
  _DrawerOptionsState createState() => _DrawerOptionsState();
}

class _DrawerOptionsState extends State<DrawerOptions> {
  TextEditingController centerlineLengthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    centerlineLengthController.text =
        widget.options.centerlineLength.toString();
    return ListView(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(
            'Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        CheckboxListTile(
            title: Text("Mark centerline Startingline"),
            value: widget.options.visibilitySlCenterline,
            onChanged: (newValue) {
              setState(() {
                widget.options.visibilitySlCenterline = newValue;
              });
              widget.callback(widget.options);
            },
            controlAffinity: ListTileControlAffinity.leading),
        CheckboxListTile(
            title: Text("Mark centerline gate"),
            value: widget.options.visibilityGateCenterline,
            onChanged: (newValue) {
              setState(() {
                widget.options.visibilityGateCenterline = newValue;
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
              widget.options.centerlineLength = double.tryParse(val);
              widget.callback(widget.options);
            },
          ),
          trailing: Text("Length of Centerline"),
        )
      ],
    );
  }
}
