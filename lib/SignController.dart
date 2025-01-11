import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'DateUtil.dart';

class SignController {
  Map<String, List<String>> records = {};
  List<String> todayRecords = [];
  bool hadSignAM = false;
  bool hadSignPM = false;
  BuildContext context;

  Function refreshAction;

  SignController({required this.context, required this.refreshAction}) {
    Timer.periodic(Duration(seconds: 1), (timer) {
      refreshAction();
    });
    refreshState();
  }

  //刷新页面数据
  void refreshState() {
    getLocalData().then((value) {
      DateTime now = DateTime.now();
      DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      String dateKey = dateFormat.format(now);
      if (records.isNotEmpty && records.containsKey(dateKey)) {
        todayRecords = records[dateKey]!;
      }

      if (todayRecords.isNotEmpty) {
        todayRecords.forEach((dateTimeStr) {
          DateTime dateTime = DateTime.parse(dateTimeStr);
          int hour = dateTime.hour;
          if (hour > 6 && hour < 12) hadSignAM = true;
          if (hour > 12 && hour < 24) hadSignPM = true;
        });
      }

      refreshAction();
    });
  }

  //读取本地数据
  Future<void> getLocalData() async {
    records = await DateUtil.readMapFromFile();
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(now);
    if (records.isNotEmpty && records.containsKey(dateKey)) {
      todayRecords = records[dateKey]!;
    }
  }

  //点击签到按钮
  void sign() async {
    DateTime now = DateTime.now();
    int hour = now.hour;
    bool needSign = true;
    if (hour >= 9 && hour <= 16) {
      needSign = await showTip(context);
    }

    if (!needSign) {
      print("停止打卡");
    } else {
      print("继续打卡");
    }

    if (!needSign) return;

    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(now);
    DateFormat timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    String timeStr = timeFormat.format(now);
    todayRecords.add(timeStr);
    records[dateKey] = todayRecords;
    DateUtil.writeMapToFile(records).then((value) {
      refreshState();
    });
  }

  Future<bool> showTip(BuildContext context) async {
    bool? isSelect = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("提示"),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18),
          content: Text("当前为上班时间，是否要继续打卡?"),
          contentTextStyle: TextStyle(color: Colors.black54, fontSize: 16),
          actions: <Widget>[
            TextButton(
              child: Text("取消", style: TextStyle(fontSize: 15)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("确定", style: TextStyle(fontSize: 15)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    return isSelect ?? false;
  }
}
