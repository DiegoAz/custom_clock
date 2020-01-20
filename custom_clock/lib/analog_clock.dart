// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'container_hand.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'drawn_hand.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;
  Timer timer;
  Color lightColor;
  Color darkColor;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
    _updateColor();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  List darkColors = [
    Color(0xffff00ff),
    Color(0xffff0000),
  ];

  List lightColors = [
    Color(0xff000000),
    Color(0xffff0000),
    Color(0xff0000ff),
    Color(0xffff00ff),
  ];

  void _updateColor() {
    setState(() {
      lightColor = lightColors[Random().nextInt(lightColors.length)];
      darkColor = darkColors[Random().nextInt(darkColors.length)];
      timer = Timer(
        Duration(seconds: 5),
        _updateColor,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].

    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFF000000),
            // Minute hand.
            highlightColor: Color(0xFF000000),
            // Second hand.
            accentColor: Color(0xFFff0000),
            backgroundColor: Color(0xffffffff),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFffffff),
            highlightColor: Color(0xFFffffff),
            accentColor: Color(0xffFF0000),
            backgroundColor: Color(0xFF000000),
          );

    bool _isVisible = Theme.of(context).brightness == Brightness.light;
    final fontFamily = 'JetBrains Mono';
    final time = DateFormat.Hms().format(DateTime.now());

    final temperature = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor, fontFamily: fontFamily),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(_temperature), Text(_temperatureRange)],
      ),
    );

    final condition = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor, fontFamily: fontFamily),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_condition.toUpperCase()),
        ],
      ),
    );

    final location = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor, fontFamily: fontFamily),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_location),
        ],
      ),
    );

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
        color: customTheme.backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: _isVisible,
              child: SvgPicture.asset(
                "assets/light.svg",
                alignment: Alignment.center,
                color: lightColor,
              ),
              replacement: SvgPicture.asset(
                "assets/dark.svg",
                alignment: Alignment.center,
                color: customTheme.primaryColor,
              ),
            ),
            // Example of a hand drawn with [Container].
            ContainerHand(
              color: Colors.transparent,
              size: 0.5,
              angleRadians: _now.hour * radiansPerHour,
              child: Transform.translate(
                offset: Offset(0.0, -66.0),
                child: Container(
                  width: 4,
                  height: 130,
                  decoration: BoxDecoration(
                    color: customTheme.highlightColor,
                  ),
                ),
              ),
            ),
            DrawnHand(
              color: customTheme.primaryColor,
              radius: 5.0,
              size: 0.73,
              angleRadians: _now.minute * radiansPerTick,
            ),
            DrawnHand(
              color: _isVisible
                  ? lightColor == Color(0xff000000) ? Colors.red : lightColor
                  : darkColor,
              radius: 5.0,
              size: 0.73,
              angleRadians: _now.second * radiansPerTick,
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: temperature,
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: condition,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: location,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
