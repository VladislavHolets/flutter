import 'dart:async';
import 'dart:math';

import 'package:control_pad/views/joystick_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speedometer/flutter_speedometer.dart';
import 'package:provider/provider.dart';

import 'connect_page.dart';
import 'mqtt/MQTTManager.dart';
import 'mqtt/state/MQTTAppState.dart';

class Control extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ControlState();
  }
}

class Velocity {
  double x;
  double y;
  double z;

  Velocity(this.x, this.y, this.z);

  getX() => x;

  getY() => y;

  getZ() => z;
}

class _ControlState extends State<Control> {
  //HeaderMain headerMain;
  MQTTAppState currentAppState;
  MQTTManager manager;
  Velocity linear = Velocity(0, 0, 0);
  Velocity angular = Velocity(0, 0, 0);
  Speedometer speedometer = Speedometer(
      backgroundColor: Colors.white,
      meterColor: Colors.blueAccent,
      kimColor: Colors.black87,
      currentValue: 0,
      displayText: "KM/H",
      maxValue: 40,
      minValue: 0);
  Timer messageTimer;

  var firstTime = true;

  @override
  void initState() {
    super.initState();
    const period1 = const Duration(seconds: 1);
    messageTimer = Timer.periodic(period1, (Timer t) {
      if (this.manager.getState().getAppConnectionState ==
          MQTTAppConnectionState.connected) {
        this.manager.publish("{\"Angular\":[0," +
            this.angular.getY().toString() +
            ",0],\"Linear\":[" +
            this.linear.getX().toString() +
            ",0,0]}");
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    messageTimer.cancel();
    //this.speedOMeter.
  }

  @override
  Widget build(BuildContext context) {
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);
    // Keep a reference to the app state.
    currentAppState = appState;
    const period2 = const Duration(seconds: 1);
    new Timer.periodic(period2, (Timer t) {});
    final Params params = ModalRoute.of(context).settings.arguments;

    manager = params.manager;
    return Scaffold(
      //appBar: AppBar(title: Text("Controll")),
      body: OrientationBuilder(builder: (context, orientation) {
        return GridView.count(
            //shrinkWrap: true,
            padding: orientation == Orientation.portrait
                ? EdgeInsets.fromLTRB(50, 30, 50, 0)
                : EdgeInsets.fromLTRB(50, 60, 50, 0),

            // Create a grid with 1 columns in portrait mode, or 2 columns in
            // landscape mode.
            crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
            children: <Widget>[
              this.speedometer,
              JoystickView(
                size: 200,
                onDirectionChanged: (double degrees, double distance) {
                  //setState(() {
                  setState(() {
                    linear = Velocity(distance * cos(degrees / 180 * pi), 0, 0);
                    angular =
                        Velocity(0, distance * sin(degrees / 180 * pi), 0);
                    this.speedometer = Speedometer(
                        backgroundColor: Colors.white,
                        meterColor: Colors.blueAccent,
                        kimColor: Colors.black87,
                        currentValue:
                            (pow(pow(this.linear.x, 2.0), 0.5) * 40.0).toInt(),
                        displayText: "KM/H",
                        maxValue: 40,
                        minValue: 0);
                  });
                },
              ),
            ]);
      }),
      bottomSheet: (Text("Velocity Linear:" +
          this.linear.getX().toString() +
          " Angular: " +
          this.angular.getY().toString())),
    );
  }
}
