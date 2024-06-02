import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

const ip = "127.0.0.1";
final now = DateTime.now();
final client = MqttServerClient.withPort(ip, "user$now",1883);

class MQTT extends ChangeNotifier {

  var topic = "";
  var author = "";
  var type = "";
  var content = "";
  var contentJSON = {};
  var emergency = false;
  var connected = false;
  var status = "disconnected"; //[disconnected,connected,reconnecting]

  //for EEW (and report)
  var location = const LatLng(0, 0);
  var locationName = "";
  var depth = 0.0;
  var time = 0;
  var magnitude = 0.0;
  var intensity = "";
  //for Report
  var intensities = {};

  Future<void> mqttSetup() async {
    client.logging(on: true);
    client.setProtocolV311();
    client.keepAlivePeriod = 5000;
    client.connectTimeoutPeriod = 5000;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.onAutoReconnect = onAutoReconnect;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    try {
      await client.connect();
    } on Exception {
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      connected = true;
      status = "connected";
    }else {
      client.disconnect();
    }

    //subscribe
    const qos = MqttQos.exactlyOnce;
    const String _topic = "tpsem/+";
    client.subscribe(_topic, qos);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      /// The above may seem a little convoluted for users only interested in the
      /// payload, some users however may be interested in the received publish message,
      /// lets not constrain ourselves yet until the package has been in the wild
      /// for a while.
      /// The payload is a byte buffer, this will be specific to the topic
      topic = c[0].topic;
      content = pt;
      contentJSON = jsonDecode(pt);
      author = contentJSON["author"];
      type = contentJSON["type"];

      if (topic == "tpsem/tpsem" || topic == "tpsem/cwa") {
        emergency = true;
      }else{
        emergency = false;
      }
      // for eew access
      if (type == "eew") {
        location = LatLng(contentJSON["eew"]["lat"], contentJSON["eew"]["lng"]);
        locationName = contentJSON["eew"]["name"];
        depth = contentJSON["eew"]["depth"];
        time = contentJSON["eew"]["time"];
        magnitude = contentJSON["eew"]["magnitude"];
        intensity = contentJSON["eew"]["intensity"];
        intensities = contentJSON["eew"]["intensities"];
      }
      /*
      payload format

      {
        "author":string,
        "type":string[eew],
        "eew":{
          "lat":double,
          "lng":double,
          "name":string,
          "depth":double,
          "time":int(milli),
          "magnitude":double,
          "intensity":string,
          "intensities":{}
        }
      }
      */


      notifyListeners();
    });
  }

  void onAutoReconnect(){
    status = "reconnecting";
    connected = false;
    notifyListeners();
  }

  void onAutoReconnected(){
    status = "connected";
    connected = true;
    notifyListeners();
  }

  void onConnected() {
    status = "connected";
    connected = true;
    notifyListeners();
  }

  void onDisconnected() {
    status = "disconnected";
    connected = false;
    notifyListeners();
  }

}

// ignore: non_constant_identifier_names
