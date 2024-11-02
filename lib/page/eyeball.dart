import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:lvluo/isolate/retrieve_net_stats_isolate.dart';
import 'package:lvluo/src/rust/api/net_monitor.dart';
import 'package:lvluo/utils/data_fmt.dart';
import 'package:lvluo/widget/rt_item.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import "package:async/async.dart" show StreamQueue;


class NetDevStatSpeed {
  BigInt ts;
  String devId;
  BigInt rxBytes;
  BigInt txBytes;

  NetDevStatSpeed({required this.ts, required this.devId, required this.rxBytes, required this.txBytes});
}


class EyeballPage extends StatefulWidget {
  const EyeballPage({super.key});

  @override
  State<EyeballPage> createState() => _EyeballPageState();
}

class _EyeballPageState extends State<EyeballPage>
    with TrayListener, WindowListener {
  bool isIgnoreMouseEvents = false;
  Timer? refreshNetStatsTimer;
  Timer? initIsolatesTimer;
  StreamQueue<dynamic>? netStatsEvents;
  final RootIsolateToken articleRootIsolateToken = RootIsolateToken.instance!;
  final netStatsReceivePort = ReceivePort();
  SendPort? signalReceivePort;
  bool netMonitorIsolateReady = false;
  List<NetDevStat> netDevStats = [];
  List<NetDevStat> preNetDevStats = [];
  Map<String, NetDevStatSpeed> netDevStatSpeedMap = {};
  List<Map<String, NetDevStat>> netDevStatsMapHistory = [];

  @override
  void initState() {
    init();

    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  initIsolates() async {
    Map<String, dynamic> isolateParams = {
      "sendPort": netStatsReceivePort.sendPort,
      "rootIsolateToken": articleRootIsolateToken,
    };
    await Isolate.spawn(loadNetMonitorIsolate, isolateParams);
    var _events = StreamQueue<dynamic>(netStatsReceivePort);
    var _signalReceivePort = await _events.next;

    setState(() {
      netStatsEvents = _events;
      signalReceivePort = _signalReceivePort;
      netMonitorIsolateReady = true;
    });
  }

  Future<void> init() async {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
        ),
        MenuItem(
          key: 'set_ignore_mouse_events',
          label: 'setIgnoreMouseEvents(false)',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    await windowManager.setAlignment(Alignment.centerRight, animate: true);

    Timer _refreshNetStatsTimer = Timer.periodic(Duration(milliseconds: 1000), (timer){
      var _curNetDevStats = getNetDevStats();
      var _curNetDevStatsMap = netDevStatsListToMap(_curNetDevStats);
      List<Map<String, NetDevStat>> _netDevStatsMapHistory = netDevStatsMapHistory;
      if (netDevStatsMapHistory.length >= 10){
        _netDevStatsMapHistory = netDevStatsMapHistory.sublist(netDevStatsMapHistory.length-9, netDevStatsMapHistory.length);
      }
      _netDevStatsMapHistory.add(_curNetDevStatsMap);
      // if (_netDevStatsMapHistory.length % 4 == 0){
        setState(() {
          netDevStatsMapHistory = _netDevStatsMapHistory;
        });
        print("netDevStatsMapHistory: ${netDevStatsMapHistory.length}");
      // }

    });

    setState(() {
      refreshNetStatsTimer = _refreshNetStatsTimer;
    });
  }

  Map<String, NetDevStat> netDevStatsListToMap(List<NetDevStat> netDevStats){
    Map<String, NetDevStat> _map = {};
    for (NetDevStat _stat in netDevStats){
      var _key = _stat.devId;
      var _val = _stat;
      _map[_key] = _val;
    }
    return _map;
  }

  Map<String, NetDevStatSpeed> computeNetSpeed(List<Map<String, NetDevStat>> statMaps){
    Map<String, NetDevStat> _startStatMap = {};
    Map<String, NetDevStat> _endStatMap = {};
    if (statMaps.isNotEmpty){
      if (statMaps.length < 2){
        _startStatMap = {};
        _endStatMap = statMaps[statMaps.length-1];
      }else{
        _startStatMap = statMaps[0];
        _endStatMap = statMaps[statMaps.length-1];
      }
    }

    Map<String, NetDevStatSpeed> _speedMap = {};
    for (var devId in _endStatMap.keys){
      var _endStat = _endStatMap[devId];
      var _startStat = _startStatMap[devId];
      var _rxSpeed = BigInt.zero;
      var _txSpeed = BigInt.zero;
      if (_endStat != null && _startStat != null){
        var _rxDiff = _endStat.rxBytes - _startStat.rxBytes;
        var _txDiff = _endStat.txBytes - _startStat.txBytes;
        var _msNum = _endStat.ts - _startStat.ts;
        _rxSpeed = BigInt.from(_rxDiff * BigInt.from(1000) / _msNum);
        _txSpeed = BigInt.from(_txDiff * BigInt.from(1000) / _msNum);
      }
      _speedMap[devId] = NetDevStatSpeed(ts: _endStat!.ts, devId: devId, rxBytes: _rxSpeed, txBytes: _txSpeed);
    }

    return _speedMap;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (isIgnoreMouseEvents) {
          windowManager.setOpacity(1.0);
        }
      },
      onExit: (_) {
        if (isIgnoreMouseEvents) {
          windowManager.setOpacity(0.5);
        }
      },
      child: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    List<NetDevStatSpeed> _devSpeeds = [];
    if (netDevStatsMapHistory.length >= 5){
      var latestStatsMaps = netDevStatsMapHistory.sublist(netDevStatsMapHistory.length-3, netDevStatsMapHistory.length);
      var _speedMap = computeNetSpeed(latestStatsMaps);
      _devSpeeds = _speedMap.values.where((e)=>e.rxBytes > BigInt.from(0) || e.txBytes > BigInt.from(0)).toList();
    }


    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            windowManager.startDragging();
          },
          onPanEnd: (details) {
            // windowManager.setA
          },
          child: SizedBox(
            width: 300,
            // height: 100,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.blue),
                  child: ListView.builder(
                    itemBuilder: (BuildContext context, int idx){
                    var _devSpeed = _devSpeeds[idx];
                    var _rxSpeed = netSpeedFmt(_devSpeed.rxBytes);
                    var _txSpeed = netSpeedFmt(_devSpeed.txBytes);
                    return Column(
                      children: [ RtItem(
                        itemIcon: Icon(
                          Icons.arrow_upward,
                          size: 12,
                        ),
                        labelText: "Upload Speed",
                        infoText: "${formatDouble(_rxSpeed.value, 2)} ${_txSpeed.unitName}/S",
                      ),
                        RtItem(
                          itemIcon: Icon(
                            Icons.arrow_downward,
                            size: 12,
                          ),
                          labelText: "Download Speed",
                          infoText: "${formatDouble(_txSpeed.value, 2)} ${_rxSpeed.unitName}/S",
                        ),
                        SizedBox(height: 5,),
                      ],
                    );
                  }, itemCount: _devSpeeds.length,),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
