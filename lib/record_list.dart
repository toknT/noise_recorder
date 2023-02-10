import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

class RecordList extends StatefulWidget {
  const RecordList({super.key});

  @override
  State<RecordList> createState() => _RecordList();
}

class _RecordList extends State<RecordList> {
  final assetsAudioPlayer = AssetsAudioPlayer();
  List<String> recordList = [];
  String currentPlayingPath = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (String path in recordList)
          GestureDetector(
            onTap: () {
              playRecord(path);
            },
            child: Text(
              path
                  .replaceFirst("$downloadPath/", "")
                  .replaceFirst("noise_record__", '')
                  .replaceFirst('.m4a', ''),
              style: TextStyle(
                  color:
                      currentPlayingPath == path ? Colors.blue : Colors.white),
            ),
          )
      ],
    );
  }

  void playRecord(String path) {
    if (currentPlayingPath != path) {
      setState(() {
        currentPlayingPath = path;
      });
      assetsAudioPlayer.open(
        Audio.file(path),
      );
      assetsAudioPlayer.playOrPause();
      return;
    }
    setState(() {
      currentPlayingPath = '';
    });
    assetsAudioPlayer.playOrPause();
  }

  String downloadPath = '';
  @override
  void initState() {
    super.initState();
    listFiles();
  }

  void listFiles() async {
    Directory? tempDir = await DownloadsPath.downloadsDirectory();
    if (tempDir != null) {
      downloadPath = tempDir.path;
      Directory pDir = Directory(tempDir.path);
      var plist = pDir.listSync();
      plist.sort((a, b) => b.path.compareTo(a.path));
      for (var p in plist) {
        if (p.path.contains("noise_record")) {
          recordList.add(p.path);
          if (recordList.length > 7) {
            break;
          }
        }
      }
    }
  }
}
