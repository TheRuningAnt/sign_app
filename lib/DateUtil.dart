import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DateUtil{
  //写入打卡数据
  static Future<void> writeMapToFile(Map<String, List<String>> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/record/record.json';
    final recordDirectory = Directory('${directory.path}/record');
    if (!await recordDirectory.exists()) {
      await recordDirectory.create();
    }

    File file = File(filePath);
    if(file.existsSync()){
      file.deleteSync();
    }

    final jsonData = json.encode(data);
    final newFile = File(filePath);
    await newFile.writeAsString(jsonData);
  }

  //读取打卡数据
  static Future<Map<String, List<String>>> readMapFromFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/record/record.json';
    final file = File(filePath);
    if (await file.exists()) {
      final jsonData = await file.readAsString();
      final Map<String, dynamic> decoded = json.decode(jsonData);
      return decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
    }
    return {};
  }

  //写入调休数据
  static Future<void> writeRestMapToFile(Map<String, List<String>> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/record/rest_record.json';
    final recordDirectory = Directory('${directory.path}/record');
    if (!await recordDirectory.exists()) {
      await recordDirectory.create();
    }
    File file = File(filePath);
    if(file.existsSync()){
      file.deleteSync();
    }

    final jsonData = json.encode(data);
    final newFile = File(filePath);
    await newFile.writeAsString(jsonData);
  }

  //读取调休数据
  static Future<Map<String, List<String>>> readRestMapFromFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/record/rest_record.json';
    final file = File(filePath);
    if (await file.exists()) {
      final jsonData = await file.readAsString();
      final Map<String, dynamic> decoded = json.decode(jsonData);
      return decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
    }
    return {};
  }
}