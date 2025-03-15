import 'dart:io' as io show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpsem/waves.dart';
import 'package:window_size/window_size.dart';

// report_detail is imported in report.dart
import 'monitor.dart';
import 'mqtt.dart';
import 'report.dart';
import 'setting.dart';

class SoundControl {
  final player = AudioPlayer();

  void playEEW() async {
    await player.play(AssetSource("EEW.mp3"));
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (io.Platform.isWindows) {
    setWindowTitle("TPSEM");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MQTT(),
      child: ChangeNotifierProvider(
        create: (context) => Waves(),
        child: MaterialApp(
          title: 'TPSEM',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MyHomePage(title: 'TPSEM'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  var player = SoundControl();

  @override
  Widget build(BuildContext context) {
    var mqttState = context.watch<MQTT>();
    if (!mqttState.connected) {
      mqttState.mqttSetup();
    }
    if (mqttState.emergency) {
      selectedIndex = 0;
      mqttState.emergency = false;
      player.playEEW();
    }
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const MonitorPage();
      case 1:
        page = const ReportPage();
      case 2:
        page = const Setting();
      default:
        throw UnimplementedError("沒找到");
    }
    return LayoutBuilder(builder: (context, constraints) {
      // print(constraints.maxWidth);
      if (constraints.maxWidth >= 400) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('首頁'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.list),
                    label: Text('地震報告'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text("設定"),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    if (selectedIndex == 0) {
                      timer.cancel();
                    }
                    selectedIndex = value;
                  });
                },
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200), // Adjust duration
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: page, // Build content based on selectedIndex
                ),
              )
            ],
          ),
        );
      } else {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
              SafeArea(
                child: BottomNavigationBar(
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: '首頁',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list),
                      label: '地震報告',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: "設定",
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    setState(() {
                      if (selectedIndex == 0) {
                        timer.cancel();
                      }
                      selectedIndex = value;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }
    });
  }
}
