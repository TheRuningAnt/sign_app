import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'DateUtil.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  List<String> _showSignData = [];
  Map<String, List<String>> records = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DateUtil.readMapFromFile().then((value) {
      records = value;
      _refreshShowData(DateTime.now());
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 60),
              child: Text("打卡日历"),
            )),
        actions: [
          TextButton(
              onPressed: () {
                _showDateChoosePickWidget();
              },
              child: Text("补卡")),
          TextButton(
              onPressed: () {
                _selectedDay = DateTime.now();
                _refreshShowData(DateTime.now());
                setState(() {});
              },
              child: Text("今天"))
        ],
      ),
      body: Column(
        children: [_createCalendar(), _createSignView()],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _createCalendar() {
    return TableCalendar(
      calendarStyle: const CalendarStyle(
          markerDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          )),
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2050, 12, 31),
      locale: "zh_CN",
      focusedDay: _selectedDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        _selectedDay = selectedDay;
        _refreshShowData(selectedDay);
      },
      eventLoader: (day) {
        return _refreshDayTags(day);
      },
      onPageChanged: (selectedDay) {
        _selectedDay = selectedDay;
        _refreshShowData(selectedDay);
      },
    );
  }

  _createSignView() {
    return Expanded(
      child: _showSignData.isEmpty
          ? const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Text(
          "暂无数据",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
          itemCount: _showSignData.length,
          itemBuilder: (context, index) {
            return _createSignItem(_showSignData[index]);
          }),
    );
  }

  _createSignItem(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    int hour = dateTime.hour;
    String timeTag = "上午";
    if (hour > 12) timeTag = "下午";

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: hour > 12 ? Colors.cyan : Colors.pinkAccent, width: 2),
        ),
        child: Center(
            child: Text(
              "$timeTag $dateTimeStr",
              style: TextStyle(fontSize: 20),
            )),
      ),
    );
  }

  _refreshShowData(DateTime day) {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(day);
    if (records.isNotEmpty && records.containsKey(dateKey)) {
      _showSignData = records[dateKey]!;
    } else {
      _showSignData = [];
    }
    setState(() {});
    return _showSignData;
  }

  _refreshDayTags(DateTime day) {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(day);
    List showTags = [];
    bool amSign = false;
    bool pmSign = false;

    if (records.isNotEmpty && records.containsKey(dateKey)) {
      records[dateKey]!.forEach((dateTimeStr) {
        DateTime dateTime = DateTime.parse(dateTimeStr);
        int hour = dateTime.hour;
        if (hour < 12) amSign = true;
        if (hour > 12) pmSign = true;
      });
    }
    if (amSign) showTags.add("");
    if (pmSign) showTags.add("");
    return showTags;
  }

  _showDateChoosePickWidget() async {
    DateTime? selectDate = await DatePicker.showDateTimePicker(
        context,
        locale: LocaleType.zh,
    );
    if (selectDate != null) {
      _addSignData(dateTime: selectDate);
    }
  }

  _addSignData({
    required DateTime dateTime
  }) async {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(dateTime);
    DateFormat timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    String timeStr = timeFormat.format(dateTime);
    Map<String, List<String>>? dateRecords = await DateUtil.readMapFromFile();
    List<String> signData;
    if (dateRecords.containsKey(dateKey)) {
      signData = dateRecords[dateKey]!;
    } else {
      signData = [];
    }
    signData.add(timeStr);
    signData.sort();
    dateRecords[dateKey] = signData;
    DateUtil.writeMapToFile(dateRecords).then((value) {
      DateUtil.readMapFromFile().then((value) {
        records = value;
        _selectedDay = dateTime;
        _refreshShowData(dateTime);
        setState(() {});
      });
    });
  }
}
