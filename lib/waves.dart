import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Waves extends ChangeNotifier {
  List<CircleMarker> circles = [];
  List<LatLng> epicenters = [];
  List<Marker> markers = [];

  late Timer timer;

  bool firstLoad = true;
  final int updateMillis = 100;
  final int sWaveVelocity = 3000;
  final int pWaveVelocity = 6000;

  void init() {
    timer = Timer.periodic(Duration(milliseconds: updateMillis), update);
  }

  /// location:LatLng (23.5,120)
  ///
  /// radius:int (m)
  void addWave(LatLng location, double radius, String type) {
    epicenters.add(location);
    circles.add(CircleMarker(
        point: location,
        radius: radius,
        useRadiusInMeter: true,
        color: const Color.fromARGB(50, 255, 170, 0),
        borderColor: Colors.red,
        borderStrokeWidth: 3));
    circles.add(CircleMarker(
        point: location,
        radius: radius,
        useRadiusInMeter: true,
        color: const Color.fromARGB(50, 255, 170, 0),
        borderColor: Colors.orange,
        borderStrokeWidth: 3));
    if (firstLoad) {
      init();
      firstLoad = false;
    }
  }

  void update(Timer timer) {
    if (circles.isNotEmpty) {
      List<CircleMarker> newCircles = [];
      for (var k in circles) {
        if (k.radius > 300000) {
          //
        } else {
          if (k.borderColor == Colors.red) {
            newCircles.add(CircleMarker(
                point: k.point,
                radius: k.radius + (sWaveVelocity / (1000 / updateMillis)),
                // Update radius
                useRadiusInMeter: true,
                color: const Color.fromARGB(50, 255, 170, 0),
                borderColor: Colors.red,
                borderStrokeWidth: 3));
          } else if (k.borderColor == Colors.orange) {
            //
            newCircles.add(CircleMarker(
                point: k.point,
                radius: k.radius + (pWaveVelocity / (1000 / updateMillis)),
                // Update radius
                useRadiusInMeter: true,
                color: const Color.fromARGB(50, 255, 170, 0),
                borderColor: Colors.orange,
                borderStrokeWidth: 3));
          }
        }
      }
      circles = newCircles;
      markers = [];
      for (var k in epicenters) {
        markers.add(
          Marker(
            point: k,
            width: 50,
            height: 50,
            child: Image.asset("assets/mark.png"),
          ),
        );
      }
      notifyListeners();
    }else {
      epicenters.clear();
      markers.clear();
      notifyListeners();
    }

  }
}
