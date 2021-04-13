import 'package:flutter/material.dart';

class SlidingRows extends StatefulWidget {
  BoxConstraints constraints;
  Widget topChild;
  Widget bottomChild;
  Color handleColor;
  double handleHeight;

  SlidingRows(
      {required this.constraints,
      required this.topChild,
      required this.bottomChild,
      this.handleColor: Colors.amber,
      this.handleHeight: 25});

  @override
  _SlidingRowsState createState() => _SlidingRowsState();
}

class _SlidingRowsState extends State<SlidingRows> {
  final double _minHeight = 0;
  final double _velocityThreshold = 10;

  late double _maxHeight;
  late double _informationHeight;
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _maxHeight = widget.constraints.maxHeight - widget.handleHeight;
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
    return Column(
      children: [
        widget.topChild,
        Column(children: [
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
                        color: widget.handleColor,
                        height: widget.handleHeight,
                        child: Icon(
                            _informationHeight < _maxHeight
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.white)))
              ])),
          Container(height: _informationHeight, child: widget.bottomChild)
        ])
      ],
    );
  }
}
