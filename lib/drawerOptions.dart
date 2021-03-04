import 'package:flutter/material.dart';

class DrawerOptions extends StatefulWidget {
  final Function _setCenterLineLength;
  final Function _setOrthoSl;
  final Function _setOrthoGate;
  final double curCenterLineLength;
  final bool orthoSl;
  final bool orthoGate;

  DrawerOptions(this._setCenterLineLength, this._setOrthoSl, this._setOrthoGate,
      this.curCenterLineLength, this.orthoSl, this.orthoGate);

  @override
  _DrawerOptionsState createState() => _DrawerOptionsState();
}

class _DrawerOptionsState extends State<DrawerOptions> {
  TextEditingController centerlineLengthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    centerlineLengthController.text = widget.curCenterLineLength.toString();
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
            value: widget.orthoSl,
            onChanged: (newValue) {
              setState(() {
                widget._setOrthoSl(newValue);
              });
            },
            controlAffinity: ListTileControlAffinity.leading),
        CheckboxListTile(
            title: Text("Mark centerline gate"),
            value: widget.orthoGate,
            onChanged: (newValue) {
              setState(() {
                widget._setOrthoGate(newValue);
              });
            },
            controlAffinity: ListTileControlAffinity.leading),
        ListTile(
          title: TextField(
            controller: centerlineLengthController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(suffixText: "m"),
            onSubmitted: (val) {
              widget._setCenterLineLength(double.tryParse(val));
            },
          ),
          trailing: Text("Length of Centerline"),
        )
      ],
    );
  }
}
