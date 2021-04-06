import 'package:flutter/material.dart';
import 'package:flutter_application_1/informationList.dart';
import 'package:flutter_application_1/helperClasses.dart';
import "dart:developer" as dev;
import "regattaDatabase.dart";

import 'package:location/location.dart';

import 'timerControll.dart';

class Informations extends StatefulWidget {
  final BoxConstraints constraints;
  final LocationData? locationData;

  final Function onRaceStartCallback;
  final Function onTickCallback;
  final Function onRaceStopCallback;

  Informations(this.constraints, this.locationData, this.onRaceStartCallback,
      this.onTickCallback, this.onRaceStopCallback);

  @override
  _InformationsState createState() => _InformationsState();
}

class _InformationsState extends State<Informations> {
  List<RegattaInformation> list = [];

  final double _minHeight = 0;
  final double _handleHeigth = 25;
  final double _velocityThreshold = 10;

  late double _maxHeight;
  late double _informationHeight;
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _maxHeight = widget.constraints.maxHeight - _handleHeigth;
    // _informationHeight = _maxHeight / 2;
    // _offset = Offset(0, _maxHeight / 2);
    _informationHeight = _minHeight;
    _offset = Offset.zero;
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
      _informationHeight = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locationData != null) {
      list = <RegattaInformation>[
        new RegattaInformation("Speed", "max: ",
            "${(widget.locationData!.speed * 100).roundToDouble() / 100} ± ${(widget.locationData!.speedAccuracy * 100).roundToDouble() / 100} m/s"),
      ];
    } else {
      list = <RegattaInformation>[
        new RegattaInformation("Speed", "max: ", "0.0 ± 0.0 m/s"),
      ];
    }

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
          onDoubleTap: () {},
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < -_velocityThreshold) {
              if (_informationHeight > _maxHeight / 2) {
                _offset = Offset(0, _maxHeight);
              } else {
                _offset = Offset(0, _maxHeight / 2);
              }
            } else if (details.primaryVelocity! > _velocityThreshold) {
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
      Container(
          height: _informationHeight,
          child: Column(
            children: <Widget>[
              TimerControllPanel(widget.onRaceStartCallback,
                  widget.onTickCallback, widget.onRaceStopCallback),
              Expanded(child: InformationList(list))
            ],
          ))
    ]);
  }
}
