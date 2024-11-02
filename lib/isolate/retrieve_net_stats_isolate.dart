import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:lvluo/src/rust/api/net_monitor.dart';

loadNetMonitorIsolate(Map<String, dynamic> params) async {
  print("Net Monitor Isolate started");

  SendPort p = params['sendPort'];
  RootIsolateToken rootIsolateToken = params['rootIsolateToken'];
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  var signalReceivePort = ReceivePort();
  p.send(signalReceivePort.sendPort);
  await for (var signal in signalReceivePort) {
    print('Got signal: ${signal}');
    if (signal is String) {
      var stats = getNetDevStats();
      p.send(stats);
    } else if (signal == null) {}
  }
}
