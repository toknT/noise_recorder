import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:noise_recorder/record_list.dart';
import 'package:noise_recorder/record_model.dart';
import 'package:permission_handler/permission_handler.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});
  @override
  State<StartPage> createState() => _StartPage();
}

class _StartPage extends State<StartPage> {
  bool storagePermissionGranted = false;
  double firedDecibel = 70;
  DateTime lastActiveAt = DateTime.now();
  int autoSaveSeconds = 3;

  Future _getPermission() async {
    if (await Permission.storage.request().isGranted) {
      setState(() {
        storagePermissionGranted = true;
      });
    } else if (await Permission.storage.request().isPermanentlyDenied) {
      await openAppSettings();
    } else if (await Permission.storage.request().isDenied) {
      setState(() {
        storagePermissionGranted = false;
      });
    }
  }

  bool _isRecording = false;
  // noise meter
  StreamSubscription<NoiseReading>? _noiseSubscription;
  late NoiseMeter _noiseMeter;
  late RecordModel _recordModel;
  double currentDecibel = 0;

  @override
  void initState() {
    super.initState();
    _getPermission();
    _noiseMeter = NoiseMeter(onError);
    _recordModel = RecordModel();
  }

  void onError(Object error) {
    debugPrint(error.toString());
    _isRecording = false;
  }

  @override
  void dispose() {
    _noiseSubscription?.cancel();
    super.dispose();
  }

  void stop() async {
    try {
      _recordModel.stop();
      setState(() {
        _isRecording = false;
      });
    } catch (err) {
      debugPrint('stop error: $err');
    }
  }

  void start() async {
    try {
      _noiseSubscription ??= _noiseMeter.noiseStream.listen(onMeterHasData);
      setState(() {
        _isRecording = true;
      });
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  void onMeterHasData(NoiseReading noiseReading) {
    double tmpDb = noiseReading.maxDecibel > 0 ? noiseReading.maxDecibel : 0;
    setState(() {
      currentDecibel = tmpDb;
    });
    DateTime now = DateTime.now();
    // start record if meet the decibel
    if (_isRecording && currentDecibel >= firedDecibel) {
      _recordModel.start(firedDecibel);
      lastActiveAt = now;
      return;
    }
    // auto stop if no sound
    if (_isRecording &&
        currentDecibel < firedDecibel &&
        now.difference(lastActiveAt) > Duration(seconds: autoSaveSeconds)) {
      _recordModel.stop();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.noise_control_off),
            Text("noise recorder"),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
          ),
        ],
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${currentDecibel.toStringAsFixed(1)} dB",
            style: Theme.of(context).textTheme.headline4,
          ),
          _isRecording && currentDecibel > firedDecibel
              ? const Text(
                  "caught",
                  style: TextStyle(color: Colors.red),
                )
              : const Text("waiting"),
        ],
      )),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text("over ${firedDecibel.toStringAsFixed(1)} dB "),
              FloatingActionButton(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                onPressed: _isRecording ? stop : start,
                child: _isRecording
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.mic),
              ),
            ],
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            const ListTile(
              title: Text('record sound meet'),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${firedDecibel.toStringAsFixed(2)} dB',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'night noise is recommend less than 40 dB',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Slider(
                  activeColor: _isRecording ? Colors.blueGrey : Colors.blue,
                  value: firedDecibel,
                  min: 10,
                  max: 100,
                  divisions: 90,
                  onChanged: (value) {
                    if (_isRecording) {
                      return;
                    }
                    setState(() {
                      firedDecibel = value;
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            const ListTile(
              title: Text('save to file after'),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${autoSaveSeconds.toString()} seconds',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  activeColor: _isRecording ? Colors.blueGrey : Colors.blue,
                  value: autoSaveSeconds.toDouble(),
                  min: 3,
                  max: 60,
                  divisions: 57,
                  onChanged: (value) {
                    if (_isRecording) {
                      return;
                    }
                    setState(() {
                      autoSaveSeconds = value.toInt();
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            const ListTile(
              title: Text('recent records'),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'all files can found in download folder',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Column(
              children: const [RecordList()],
            )
          ],
        ),
      ),
    );
  }
}
