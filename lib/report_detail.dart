import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

double getIntensity(String intensity) {
  switch (intensity) {
    case "1級":
      return 1.0;
    case "2級":
      return 2.0;
    case "3級":
      return 3.0;
    case "4級":
      return 4.0;
    case "5弱":
      return 5.0;
    case "5強":
      return 5.5;
    case "6弱":
      return 6.0;
    case "6強":
      return 6.5;
    case "7級":
      return 7.0;
    default:
      return 0.0;
  }
}

String getIntensityText(String intensity) {
  var dintensity = getIntensity(intensity);
  switch (dintensity) {
    case 1.0:
      return "1";
    case 2.0:
      return "2";
    case 3.0:
      return "3";
    case 4.0:
      return "4";
    case 5.0:
      return "5-";
    case 5.5:
      return "5+";
    case 6.0:
      return "6-";
    case 6.5:
      return "6+";
    case 7.0:
      return "7";
    default:
      throw Exception("convert to name failed");
  }
}

String getMaxIntensity(dynamic report) {
  double max = 0.0;
  for (var i in report["Intensity"]["ShakingArea"]) {
    if (getIntensity(i["AreaIntensity"]) > max) {
      max = getIntensity(i["AreaIntensity"]);
    }
  }
  switch (max) {
    case 1.0:
      return "1";
    case 2.0:
      return "2";
    case 3.0:
      return "3";
    case 4.0:
      return "4";
    case 5.0:
      return "5-";
    case 5.5:
      return "5+";
    case 6.0:
      return "6-";
    case 6.5:
      return "6+";
    case 7.0:
      return "7";
    default:
      throw Exception("convert to name failed");
  }
}


class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({super.key, required this.report});

  final dynamic report;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  double lat = 24.0695114;
  double lng = 120.8077739;
  double zoom = 7.5;
  String _string = '';
  GeoJsonParser geoJson = GeoJsonParser();
  var reposition = const Icon(Icons.gps_fixed);

  @override
  void initState() {
    loadGeoJson();
    super.initState();
  }

  Future<void> loadGeoJson() async {
    String fileText = await rootBundle.loadString("assets/Taiwan.json");
    setState(() {
      _string = fileText;
      geoJson.parseGeoJsonAsString(_string);
    });
  }

  Container buildTextWidget(String word) {
    var color = Colors.white;
    switch (word) {
      case "1":
        color = const Color.fromRGBO(0, 255, 0, 1.0);
      case "2":
        color = const Color.fromRGBO(136, 255, 0, 1.0);
      case "3":
        color = const Color.fromRGBO(170, 255, 0, 1.0);
      case "4":
        color = const Color.fromRGBO(255, 255, 0, 1.0);
      case "5-":
        color = const Color.fromRGBO(255, 170, 0, 1.0);
      case "5+":
        color = const Color.fromRGBO(255, 136, 0, 1.0);
      case "6-":
        color = const Color.fromRGBO(255, 0, 0, 1.0);
      case "6+":
        color = const Color.fromRGBO(170, 0, 0, 1.0);
      case "7":
        color = const Color.fromRGBO(136, 0, 255, 1.0);
    }
    return Container(
        alignment: Alignment.center,
        child: Text(
          word,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            height: 0.1,
            fontSize: 20,
          ),
        ));
  }

  Marker placeIntensity(LatLng coordinates, String word) {
    return Marker(
      point: coordinates,
      width: 12,
      height: 12,
      child: buildTextWidget(word),
    );
  }

  void unfocus() {
    setState(() {
      reposition = const Icon(Icons.gps_not_fixed);
    });
  }

  @override
  Widget build(BuildContext context) {

    MapController mapController = MapController();
    mapController.mapEventStream.listen((event) {
      if (event is MapEventMove) {
        unfocus();
      }
    });
    geoJson.defaultPolygonBorderColor = Colors.white;
    geoJson.defaultPolygonFillColor = Colors.grey[800];

    String maxIntensity = getMaxIntensity(widget.report);
    String time = widget.report["EarthquakeInfo"]["OriginTime"]; //.split(" ")[1]


    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.purple[200],
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage("assets/$maxIntensity.png"),
              ),
              const Padding(padding: EdgeInsets.all(5)),
              Text(
                  "$time ${(widget.report["EarthquakeInfo"]["Epicenter"]["Location"].split("(位於")[1].split(")")[0])}"),
            ],
          )),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: LatLng(lat, lng),
          initialZoom: zoom,
          minZoom: zoom,
          backgroundColor: Colors.black87,
        ),
        children: [
          /*TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),*/
          PolygonLayer(polygons: geoJson.polygons),
          PolylineLayer(polylines: geoJson.polylines),
          MarkerLayer(markers: [
            for (var i in widget.report["Intensity"]["ShakingArea"])
              for (var j in i["EqStation"])
                placeIntensity(
                    LatLng(j["StationLatitude"], j["StationLongitude"]),
                    getIntensityText(j["SeismicIntensity"])),
            Marker(
              point: LatLng(
                  widget.report["EarthquakeInfo"]["Epicenter"]
                  ["EpicenterLatitude"],
                  widget.report["EarthquakeInfo"]["Epicenter"]
                  ["EpicenterLongitude"]),
              width: 50,
              height: 50,
              child: Image.asset("assets/mark.png"),
            ),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          mapController.move(LatLng(lat, lng), zoom);
          setState(() {
            reposition = const Icon(Icons.gps_fixed);
          });
        },
        tooltip: "回原始定位",
        child: reposition,
      ),
    );
  }
}


/*@override
  Widget build(BuildContext context) {
    String maxIntensity = getMaxIntensity(widget.report);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.purple[200],
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage("assets/$maxIntensity.png"),
              ),
              const Padding(padding: EdgeInsets.all(5)),
              Text(widget.report["EarthquakeNo"].toString()),
            ],
          )),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              widget.report["ReportImageURI"].toString(),
              height: 500,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                return child;
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                } else {
                  return const Center(child: LinearProgressIndicator());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}*/