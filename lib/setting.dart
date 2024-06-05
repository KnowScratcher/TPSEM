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

  final TextStyle title = const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  final TextStyle textStyle = const TextStyle(
    fontSize: 20,
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          ListTile(
            title: Text(
              "預警設定",
              style: title,
            ),
          ),
          SwitchListTile(
            title: Text(
              "中央氣象署預警",
              style: textStyle,
            ),
            value: cwa,
            onChanged: (bool value) {
              setState(() {
                cwa = value;
                if (!cwa) {
                  tpsem = false;
                }
                _saveConfig();
              });
            },
          ),
          SwitchListTile(
            title: Text(
              "TPSEM注意",
              style: textStyle,
            ),
            subtitle: Text(
              "(必須接收中央氣象局預警)",
              style: smallText,
            ),
            value: tpsem,
            onChanged: (bool value) {
              setState(() {
                if (value) {
                  cwa = value;
                }
                tpsem = value;
                _saveConfig();
              });
            },
          ),
          ListTile(
            title: Text(
              "計算設定",
              style: title,
            ),
          ),
          SwitchListTile(
            title: Text(
              "計算場址效應",
              style: textStyle,
            ),
            value: siteEffect,
            onChanged: (bool value) {
              setState(() {
                siteEffect = value;
                _saveConfig();
              });
            },
          ),
        ],
      ),
    );
  }
}
