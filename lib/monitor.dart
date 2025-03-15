import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tpsem/waves.dart';

import 'mqtt.dart';

late Timer timer;

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  double initLat = 24.0695114;
  double initLng = 120.5077739;
  double zoom = 7.5;
  double maxZoom = 14.0;
  String _string = '';
  GeoJsonParser geoJson = GeoJsonParser();
  static final defaultInfobox = Container(
    color: Colors.grey,
    child: const SizedBox(
      height: 25,
      width: 300,
      child: Padding(
        padding: EdgeInsets.only(left: 5.0),
        child: Text(
          "無發布的地震預警",
          textAlign: TextAlign.left,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    ),
  );
  List<Container> infobox = [defaultInfobox];
  Container info = defaultInfobox;
  late String _time;
  late Timer tick;
  bool init = true;
  int index = 0;

  @override
  void initState() {
    loadGeoJson();
    _time =
        "${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    super.initState();
  }

  void _updateTime() {
    if (mounted) {
      final DateTime time = DateTime.now();
      final String currentTime =
          "${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
      setState(() {
        _time = currentTime;
      });
    }
  }

  Future<void> loadGeoJson() async {
    String fileText = await rootBundle.loadString("assets/Taiwan.json");
    setState(() {
      _string = fileText;
      geoJson.parseGeoJsonAsString(_string);
    });
  }

  void updateInfobox(Waves waves) {
    if (waves.circles.isEmpty) {
      setState(() {
        infobox = [defaultInfobox];
        index = 0;
      });
    } else {
      if (index + 1 < waves.epicenters.length) {
        setState(() {
          index += 1;
          info = infobox[index];
        });
      } else {
        setState(() {
          index = 0;
          info = infobox[index];
        });
      }
    }
    info = infobox[index];
  }

  @override
  Widget build(BuildContext context) {
    var waves = context.watch<Waves>();
    var mqttState = context.watch<MQTT>();

    MapController mapController = MapController();
    geoJson.defaultPolygonBorderColor = Colors.white;
    geoJson.defaultPolygonFillColor = Colors.grey[800];

    if (init) {
      tick = Timer.periodic(const Duration(seconds: 2),(timer) => updateInfobox(waves));
      init = false;
    }

    if (mqttState.topic == "tpsem/tpsem") {
      setState(() {
        if (infobox.contains(defaultInfobox)) {
          infobox.remove(defaultInfobox);
        }
        infobox.add(
          Container(
            color: Colors.red[400],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text(
                    mqttState.author,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  width: 300,
                  child: Card(
                    shape: const BeveledRectangleBorder(),
                    color: Colors.black87,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Image(
                          image: AssetImage(
                            "assets/${mqttState.intensity}.png",
                          ),
                          width: 50,
                          alignment: Alignment.centerLeft,
                        ),
                        Text(
                          mqttState.locationName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          "M${mqttState.magnitude}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    List<CircleMarker> circles = [];
    circles = waves.circles;
    if (mqttState.type == "eew") {
      mqttState.type = "";
      waves.addWave(mqttState.location, 0, "s");
    }
    if (circles.isEmpty) {
      mqttState.topic = "";
    }
    mqttState.topic = "";
    Icon connectIcon = const Icon(
      Icons.wifi_off,
      color: Colors.white,
    );
    Row reconnectNote = const Row();
    if (mqttState.connected) {
      connectIcon = const Icon(
        Icons.wifi,
        color: Colors.white,
      );
      reconnectNote = const Row();
    } else {
      connectIcon = const Icon(
        Icons.wifi_off,
        color: Colors.white,
      );
      reconnectNote = const Row(children: [
        Icon(
          Icons.wifi_off,
          color: Colors.white,
        ),
        Text(
          "正在重新連線...",
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        )
      ]);
    }
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          FlutterMap(
            // mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(initLat, initLng),
              initialZoom: zoom,
              minZoom: zoom-1,
              maxZoom: maxZoom,
              backgroundColor: Colors.black87,
            ),
            children: [
              /*TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",),*/
              PolygonLayer(polygons: geoJson.polygons),
              PolylineLayer(polylines: geoJson.polylines),
              MarkerLayer(markers: waves.markers), //geoJson.markers
              CircleLayer(circles: circles),
            ],
          ),
          Positioned(
            left: 5,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _time,
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    connectIcon,
                  ],
                ),
                reconnectNote,
              ],
            ),
          ),
          Positioned(
            right: 0,
            child: info,
          ),

          /* when nothing
          Container(
              color: Colors.grey,
              child: const SizedBox(
                height: 25,
                width: 300,
                child: Padding(
                  padding: EdgeInsets.only(left: 5.0),
                  child: Text(
                    "無發布的地震預警",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          */
          /* when something
          Container(
              color: Colors.red[400],
              child: const SizedBox(
                height: 100,
                width: 300,
                child: Card(
                  shape: BeveledRectangleBorder(),
                  color: Colors.black87,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Image(
                          image: AssetImage(
                            "assets/5+.png",
                          ),
                          width: 50,
                          alignment: Alignment.centerLeft,
                        ),
                        Text(
                          "花蓮縣吉安鄉",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          "M7.2",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        )
                      ]),
                ),
              ),
            ),

           */
          /*Positioned(
            left: 0,
            child: Container(
              color: Colors.grey,
              child: const SizedBox(
                height: 100,
                width: 300,
                child: Card(
                  color: Colors.black54,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "嘉義市西區\ncy001",
                          textAlign: TextAlign.left,
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        VerticalDivider(
                          width: 10,
                          thickness: 3,
                          indent: 5,
                          endIndent: 5,
                          color: Colors.grey,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "最大地動加速度(PGA):0",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "最大地動速度(PGA):0",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "震度:0",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                      ]),
                ),
              ),
            ),
          ),*/
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          mapController.move(LatLng(initLat, initLng), zoom);
        },
        tooltip: "回原始定位",
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    tick.cancel();
    super.dispose();
  }
}
