import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'DateUtil.dart';

class SignController {
  Map<String, List<String>> _records = {}; //所有打卡记录
  Map<String, List<String>> _restRecords = {};  //所有调休记录

  List<String> todayRecords = [];
  bool hadSignAM = false;
  bool hadSignPM = false;
  bool isRest = false; //是否是调休
  BuildContext context;

  Function refreshAction;

  SignController({required this.context, required this.refreshAction}) {
    Timer.periodic(const Duration(seconds: 1), (timer) {
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

      //判断是否是调休
      if (_restRecords.isNotEmpty && _restRecords.containsKey(dateKey)) {
        isRest = true;
        refreshAction();
        return;
      }

      if (_records.isNotEmpty && _records.containsKey(dateKey)) {
        todayRecords = _records[dateKey]!;
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
    _records = await DateUtil.readMapFromFile();
    _restRecords = await DateUtil.readRestMapFromFile();
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(now);
    if (_records.isNotEmpty && _records.containsKey(dateKey)) {
      todayRecords = _records[dateKey]!;
    }
  }

  //点击签到按钮
  void sign() async {
    DateTime now = DateTime.now();
    int hour = now.hour;
    bool needSign = true;
    if (hour >= 9 && hour < 18) {
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
    _records[dateKey] = todayRecords;
    DateUtil.writeMapToFile(_records).then((value) {
      refreshState();
    });
  }

  Future<bool> showTip(BuildContext context) async {
    bool? isSelect = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:const Text("提示"),
          titleTextStyle:const TextStyle(color: Colors.black87, fontSize: 18),
          content:const Text("当前为上班时间，是否要继续打卡?"),
          contentTextStyle:const TextStyle(color: Colors.black54, fontSize: 16),
          actions: <Widget>[
            TextButton(
              child:const Text("取消", style: TextStyle(fontSize: 15)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child:const Text("确定", style: TextStyle(fontSize: 15)),
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
