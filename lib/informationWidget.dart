import 'package:flutter/material.dart';
import 'package:flutter_application_1/informationList.dart';
import 'package:flutter_application_1/helperClasses.dart';
import "dart:developer" as dev;
import "regattaDatabase.dart";

import 'package:location/location.dart';

import 'timerControll.dart';

class Informations extends StatelessWidget {
  final LocationData? locationData;

  final Function onRaceStartCallback;
  final Function onTickCallback;
  final Function onRaceStopCallback;

  Informations(this.locationData, this.onRaceStartCallback, this.onTickCallback,
      this.onRaceStopCallback);

  @override
  Widget build(BuildContext context) {
    List<RegattaInformation> list = [];

    if (locationData != null) {
      list = <RegattaInformation>[
        new RegattaInformation("Speed", "max: ",
            "${(locationData!.speed * 100).roundToDouble() / 100} ± ${(locationData!.speedAccuracy * 100).roundToDouble() / 100} m/s"),
      ];
    } else {
      list = <RegattaInformation>[
        new RegattaInformation("Speed", "max: ", "0.0 ± 0.0 m/s"),
      ];
    }

    return Column(
      children: <Widget>[
        TimerControllPanel(
            onRaceStartCallback, onTickCallback, onRaceStopCallback),
        Expanded(child: InformationList(list))
      ],
    );
  }
}
