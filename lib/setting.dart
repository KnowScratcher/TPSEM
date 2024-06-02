import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("設定"),
      ),
      backgroundColor: Colors.purple[100]!,
      body: const SettingMatrix(),
    );
  }
}

class SettingMatrix extends StatefulWidget {
  const SettingMatrix({super.key});

  @override
  State<SettingMatrix> createState() => _SettingMatrixState();
}

class _SettingMatrixState extends State<SettingMatrix> {
  _loadConfig() async {
    //load all
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cwa = (prefs.getBool("cwa") ?? true);
      tpsem = (prefs.getBool("tpsem") ?? false);
      siteEffect = (prefs.getBool("siteEffect") ?? true);
    });
  }

  _saveConfig() async {
    //save all
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("cwa", cwa);
    prefs.setBool("tpsem", tpsem);
    prefs.setBool("siteEffect", siteEffect);
  }

  final TextStyle textStyle = const TextStyle(
    fontSize: 15,
  );
  final TextStyle smallText = const TextStyle(
    fontSize: 12,
  );

  var cwa = true;
  var tpsem = false;
  var siteEffect = true;

  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            "預警設定",
            style: TextStyle(
              fontSize: 30,
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2,
              children: [
                SizedBox(
                  height: 100,
                  child: Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "接收CWA預警",
                          style: textStyle,
                        ),
                        Switch(
                          thumbIcon: thumbIcon,
                          value: cwa,
                          onChanged: (bool value) {
                            setState(() {
                              cwa = value;
                              if (!cwa) {
                                tpsem = false;
                                _saveConfig();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "接收TPSEM注意",
                              style: textStyle,
                            ),
                            Text(
                              "(必須先啟用CWA)",
                              style: smallText,
                            ),
                          ],
                        ),
                        Switch(
                          thumbIcon: thumbIcon,
                          value: tpsem,
                          onChanged: (bool value) {
                            setState(() {
                              if (cwa) {
                                tpsem = value;
                                _saveConfig();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
