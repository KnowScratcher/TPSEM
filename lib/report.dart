import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'report_detail.dart';
import 'response.dart';

Report reports = Report(earthquakes: jsonDecode("{}"));

Future<Report> fetchReports() async {
  final response = await http.get(Uri.parse(
      "https://opendata.cwa.gov.tw/api/v1/rest/datastore/E-A0015-001?Authorization=CWA-FF78208A-EA07-4AB8-B696-2EA738026DD1&limit=50&format=JSON"));
  // TODO: debuging
  // final response = Response();
  // await Future.delayed(const Duration(seconds: 2));
  // TODO: end debug
  if (response.statusCode == 200) {
    return Report.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception("failed to get reports");
  }
}

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

class Report {
  final List<dynamic> earthquakes;

  const Report({required this.earthquakes});

  factory Report.fromJson(Map<String, dynamic> json) {
    reports = Report(earthquakes: json["records"]["Earthquake"]);
    return reports;
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<Report> reports;

  @override
  void initState() {
    super.initState();
    reports = fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    /*final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );*/
    return FutureBuilder<Report>(
        future: reports,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("地震報告"),
              ),
              backgroundColor: Colors.purple[100]!,
              body: ListView.builder(
                  itemCount: snapshot.data!.earthquakes.length,
                  itemBuilder: (context, index) {
                    var i = snapshot.data!.earthquakes[index];
                    String maxIntensity = getMaxIntensity(i);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    ReportDetailPage(report: i),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return ScaleTransition(
                                scale:
                                    Tween<double>(begin: 0.2, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.fastOutSlowIn,
                                  ),
                                ),
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(
                                    CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.fastOutSlowIn),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                AssetImage("assets/$maxIntensity.png"),
                          ),
                          title: Text(
                              "${i["EarthquakeNo"]} ${i["EarthquakeInfo"]["Epicenter"]["Location"].split("(位於")[1].split(")")[0]}"),
                          subtitle: Text(i["EarthquakeInfo"]["OriginTime"]),
                          trailing: Text(
                            "M${i["EarthquakeInfo"]["EarthquakeMagnitude"]["MagnitudeValue"]}",
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    );
                  }),
            );
          } else if (snapshot.hasError) {
            return const Text("發生錯誤");
          }

          return Scaffold(
              appBar: AppBar(
                title: const Text("地震報告"),
              ),
              backgroundColor: Colors.purple[100]!,
              body: SizedBox(
                height: 5.0,
                child: LinearProgressIndicator(
                ),
              ));
        });
  }
}
