import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';

class TimerControllPanel extends StatefulWidget {
  final Function onRaceStartCallback;
  final Function onTickCallback;
  final Function onRaceStopCallback;

  TimerControllPanel(
      this.onRaceStartCallback, this.onTickCallback, this.onRaceStopCallback);

  @override
  _TimerControllPanelState createState() => _TimerControllPanelState();
}

enum CounterState { fresh, countdown, paused, stopwatch }

class _TimerControllPanelState extends State<TimerControllPanel> {
  int selectedCountdownInSeconds = 3 * 60;
  late int _countdownInSeconds;
  CounterState _counterState = CounterState.fresh;
  Timer? _timer;
  List<int> _selectedTimeIndex = [3];

  @override
  void initState() {
    super.initState();
    _countdownInSeconds = -selectedCountdownInSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                    onPressed: _counterState != CounterState.fresh
                        ? null
                        : () => _showPickerNumber(context),
                    child: _timerValue()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _startPauseButton(),
                    ElevatedButton(
                        child: Text("Stop"),
                        onPressed: _counterState == CounterState.fresh
                            ? null
                            : () {
                                _stopTimer();
                                setState(
                                    () => _counterState = CounterState.fresh);
                              },
                        style: ElevatedButton.styleFrom(primary: Colors.red)),
                  ]
                      .map((widget) => Expanded(
                              child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: widget,
                          )))
                      .toList(),
                )
              ]
                  .map((widget) => Expanded(
                        child: widget,
                      ))
                  .toList(),
            )));
  }

  Widget _timerValue() {
    String minutes;
    String seconds;

    if (_countdownInSeconds.isNegative) {
      minutes = "-${(_countdownInSeconds.abs() / 60).floor()}";
      seconds = "${(60 - _countdownInSeconds % 60) % 60}";
    } else {
      minutes = "${(_countdownInSeconds.abs() / 60).floor()}";
      seconds = "${_countdownInSeconds % 60}";
    }

    return Text("$minutes:$seconds");
  }

  Widget _startPauseButton() {
    Widget button;

    switch (_counterState) {
      case CounterState.fresh:
      case CounterState.paused:
        button = ElevatedButton(
            child: Text("Start"),
            onPressed: () {
              setState(() => _counterState = CounterState.countdown);
              _startTimer();
            },
            style: ElevatedButton.styleFrom(primary: Colors.green));
        break;

      case CounterState.stopwatch:
      case CounterState.countdown:
        button = ElevatedButton(
            child: Text("Pause"),
            onPressed: _counterState == CounterState.countdown
                ? () {
                    setState(() => _counterState = CounterState.paused);
                    _pauseTimer();
                  }
                : null,
            style: ElevatedButton.styleFrom(primary: Colors.deepOrange));
        break;
    }

    return button;
  }

  void _startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        widget.onTickCallback(_countdownInSeconds);
        if (_countdownInSeconds == 0) {
          widget.onRaceStartCallback();
          setState(() => _counterState = CounterState.stopwatch);
        }

        if (_counterState == CounterState.stopwatch ||
            _counterState == CounterState.countdown) {
          setState(() {
            _countdownInSeconds++;
          });
        }
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    widget.onRaceStopCallback();
    _countdownInSeconds = -selectedCountdownInSeconds;
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  _showPickerNumber(BuildContext context) {
    var pickerData = [
      [0, 1, 2, 3, 5, 10, 15, 30, 45, 60]
    ];

    Picker(
        adapter: PickerDataAdapter<String>(
          pickerdata: pickerData,
          isArray: true,
        ),
        hideHeader: true,
        selecteds: _selectedTimeIndex,
        title: Text("Please select the minutes till start"),
        selectedTextStyle: TextStyle(color: Colors.blue),
        onCancel: () => {},
        onConfirm: (Picker picker, List value) {
          print(value.toString());
          print(picker.getSelectedValues());
          _selectedTimeIndex = value as List<int>;

          setState(() {
            selectedCountdownInSeconds =
                (int.parse(picker.getSelectedValues()[0]) * 60);
            _countdownInSeconds = -selectedCountdownInSeconds;
          });
        }).showDialog(context);
  }
}
