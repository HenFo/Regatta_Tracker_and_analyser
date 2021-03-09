import 'package:flutter/material.dart';
import 'package:flutter_application_1/informationList.dart';
import 'package:flutter_application_1/regatta.dart';
import "dart:developer" as dev;

class Informations extends StatefulWidget {
  @override
  _InformationsState createState() => _InformationsState();
}

class _InformationsState extends State<Informations> {
  List<RegattaInformation> list = [
    new RegattaInformation("test", "test2", "value"),
    new RegattaInformation("test", "test2", "value"),
    new RegattaInformation("test", "test2", "value"),
  ];

  Offset _offset = Offset.zero;
  double _maxHeight;
  final double _minHeight = 0;
  double _informationHeight;

  @override
  void initState() {
    super.initState();
    _informationHeight = _minHeight;
  }

  void setHeight() {
    setState(() {
      var height = _offset.dy;
      if (height < _minHeight) {
        height = _minHeight;
      }

      // dev.log(height.toString());

      _informationHeight = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    _maxHeight = MediaQuery.of(context).size.height;

    return Column(children: [
      GestureDetector(
          onVerticalDragUpdate: (details) {
            _offset -= details.delta;
            setHeight();
          },
          child: Container(color: Colors.amber, height: 25)),
      Container(height: _informationHeight, child: InformationList(list))
    ]);
  }
}
