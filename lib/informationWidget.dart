import 'package:flutter/material.dart';
import 'package:flutter_application_1/informationList.dart';
import 'package:flutter_application_1/regatta.dart';
import "dart:developer" as dev;

class Informations extends StatefulWidget {
  final BoxConstraints constraints;
  Informations(this.constraints);

  @override
  _InformationsState createState() => _InformationsState();
}

class _InformationsState extends State<Informations> {
  List<RegattaInformation> list = [
    new RegattaInformation("test", "test2", "value"),
    new RegattaInformation("test", "test2", "value"),
    new RegattaInformation("test", "test2", "value"),
  ];

  final double _minHeight = 0;
  final double _handleHeigth = 25;
  final double _velocityThreshold = 10;

  double _maxHeight;
  double _informationHeight;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _informationHeight = _minHeight;
    _maxHeight = widget.constraints.maxHeight - _handleHeigth;
  }

  void setHeight() {
    setState(() {
      var height = _offset.dy;
      if (height < _minHeight) {
        height = _minHeight;
      }
      if (height > _maxHeight) {
        height = _maxHeight;
      }

      // dev.log(height.toString());

      _informationHeight = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    // _maxHeight = MediaQuery.of(context).size.height;

    return Column(children: [
      GestureDetector(
          onVerticalDragUpdate: (details) {
            _offset -= details.delta;
            setHeight();
          },
          onTap: () {
            if (_informationHeight < _maxHeight) {
              if (_informationHeight >= _maxHeight / 2) {
                _offset = Offset(0, _maxHeight);
              } else {
                _offset = Offset(0, _maxHeight / 2);
              }
            } else {
              _offset = Offset.zero;
            }
            setHeight();
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity < -_velocityThreshold) {
              if (_informationHeight > _maxHeight / 2) {
                _offset = Offset(0, _maxHeight);
              } else {
                _offset = Offset(0, _maxHeight / 2);
              }
            } else if (details.primaryVelocity > _velocityThreshold) {
              _offset = Offset.zero;
            }
            setHeight();
          },
          child: Row(children: [
            Expanded(
                child: Container(
                    color: Colors.amber,
                    height: _handleHeigth,
                    child: Icon(
                        _informationHeight < _maxHeight
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white)))
          ])),
      Container(height: _informationHeight, child: InformationList(list))
    ]);
  }
}
