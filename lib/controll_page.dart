import 'dart:async';
import 'dart:math';

import 'package:control_pad/views/joystick_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:speedometer/speedometer.dart';

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
  final double x;
  final double y;
  final double z;

  const Velocity(this.x, this.y, this.z);

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

  var firstTime = true;

  PublishSubject<double> eventObservable = new PublishSubject();

  @override
  void initState() {
    super.initState();
    const period1 = const Duration(milliseconds: 1000);
    new Timer.periodic(period1, (Timer t) {
      eventObservable.add(pow(pow(this.linear.x, 2.0), 0.5) * 40.0);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);
    // Keep a reference to the app state.
    currentAppState = appState;
    const period2 = const Duration(milliseconds: 1000);
    new Timer.periodic(period2, (Timer t) {
      if (this.manager.getState().getAppConnectionState ==
          MQTTAppConnectionState.connected) {
        this.manager.publish("{\"Angular\":[0," +
            this.angular.getY().toString() +
            ",0],\"Linear\":[" +
            this.linear.getX().toString() +
            ",0,0]");
      } else {
        Navigator.pop(context);
      }
    });
    final Params params = ModalRoute.of(context).settings.arguments;
    final ThemeData somTheme = new ThemeData(
        primaryColor: Colors.blue,
        accentColor: Colors.black,
        backgroundColor: Colors.grey);

    manager = params.manager;
    //  currentAppState=params.appState;

    return Scaffold(
      appBar: AppBar(title: Text("Controll")),
      body: OrientationBuilder(builder: (context, orientation) {
        return GridView.count(
            shrinkWrap: true,
            padding: orientation == Orientation.portrait
                ? EdgeInsets.fromLTRB(50, 30, 50, 0)
                : EdgeInsets.fromLTRB(50, 0, 50, 0),

            // Create a grid with 2 columns in portrait mode, or 3 columns in
            // landscape mode.
            crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
            // Generate 100 widgets that display their index in the List.
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                //  margin: const EdgeInsets.all(30) ,
                // width: 400,
                // height: 300,
                child: SpeedOMeter(
                  end: 40,
                  start: 0,
                  eventObservable: this.eventObservable,
                  themeData: somTheme,
                  highlightStart: 10.0 / 40,
                  highlightEnd: 30.0 / 40,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(30),
                //  margin: const EdgeInsets.all(30) ,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                // width: 400,
                // height: 300,
                child: JoystickView(
                  //   size: 200,

                  onDirectionChanged: (double degrees, double distance) {
                    setState(() {
                      linear =
                          Velocity(distance * cos(degrees / 180 * pi), 0, 0);
                      angular =
                          Velocity(0, distance * sin(degrees / 180 * pi), 0);
                    });
                  },
                ),
              ),
            ]);

        return JoystickView(
          onDirectionChanged: (double degrees, double distance) {
            manager.publish("{\"Angular\":[0," +
                this.angular.getY().toString() +
                ",0],\"Linear\":[" +
                this.linear.getX().toString() +
                ",0,0]");
            setState(() {
              linear = Velocity(distance * cos(degrees / 180 * pi), 0, 0);
              angular = Velocity(0, distance * sin(degrees / 180 * pi), 0);
            });
          },
        );
      }),
      bottomSheet: (Text("Velocity Linear:" +
          this.linear.getX().toString() +
          " Angular: " +
          this.angular.getY().toString())),
    );
  }
}
