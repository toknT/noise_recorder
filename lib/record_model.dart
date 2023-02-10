import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:record/record.dart';

class RecordModel {
  final record = Record();
  late DateTime startAt;
  void handleError(PlatformException error) {
    debugPrint(error.message);
    debugPrint(error.details);
  }

  Future<void> start(double decibel) async {
    if (await record.isRecording()) {
      return;
    }
    if (await record.hasPermission()) {
      Directory? tempDir = await DownloadsPath.downloadsDirectory();
      if (tempDir != null) {
        startAt = DateTime.now();
        String formattedDate = DateFormat('yyyy-MM-dd-HHmmss').format(startAt);
        String path =
            "${tempDir.path}/noise_record__$formattedDate--${decibel.toStringAsFixed(0)}dB.m4a";
        await record.start(
          path: path,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
      } else {
        // todo: alert download folder not exist?
      }
    }
  }

  Future<void> stop() async {
    try {
      if (await record.isRecording()) {
        await record.stop();
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }
}
