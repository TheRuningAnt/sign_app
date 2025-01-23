import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'Config.dart';
import 'DateUtil.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  List<String> _showSignData = [];
  Map<String, List<String>> _allRecords = {};  //所有打卡记录
  Map<String, List<String>> _restRecords = {};  //所有调休记录

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DateUtil.readMapFromFile().then((value) {
      _allRecords = value;
      DateUtil.readRestMapFromFile().then((value) {
        _restRecords = value;
        _refreshShowData(DateTime.now());
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("打卡日历"),
        actions: [
          _createActonBtn("补卡",(){
            _showDateChoosePickWidget();
          }),
          _createActonBtn("调休",(){
            _showRestDateChoosePickWidget();
          }),
          _createActonBtn("今天",(){
            _selectedDay = DateTime.now();
            _refreshShowData(DateTime.now());
            setState(() {});
          })
        ],
      ),
      body: Column(
        children: [_createCalendar(), _createSignView()],
      ),
    );
  }

  Widget _createActonBtn(String title,Function action){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap:(){
          action();
        },
        child: Text(title,style: TextStyle(color: Colors.deepPurple),)
      ),
    );
  }

  //创建日历组件
  _createCalendar() {
    return TableCalendar(
      daysOfWeekStyle:
          DaysOfWeekStyle(weekendStyle: TextStyle(color: Colors.cyan,fontWeight: FontWeight.bold),weekdayStyle: TextStyle(fontWeight: FontWeight.bold)),
      calendarBuilders: CalendarBuilders(
          markerBuilder: (BuildContext context, DateTime day, List events) {
        return _createSignTip(day, events);
      }),
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

      holidayPredicate: (DateTime dateTime) {
        return _isHoliday(dateTime);
      },
      onPageChanged: (selectedDay) {
        _selectedDay = selectedDay;
        _refreshShowData(selectedDay);
      },
    );
  }

  //创建签到列表
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

  //创建签到列表item
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
          style: const TextStyle(fontSize: 20),
        )),
      ),
    );
  }

  //刷新展示数据
  _refreshShowData(DateTime day) {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(day);
    if (_allRecords.isNotEmpty && _allRecords.containsKey(dateKey)) {
      _showSignData = _allRecords[dateKey]!;
    } else {
      _showSignData = [];
    }
    setState(() {});
    return _showSignData;
  }

  //展示补卡日期选择
  _showDateChoosePickWidget() async {
    DateTime? selectDate = await DatePicker.showDateTimePicker(
      context,
      locale: LocaleType.zh,
    );
    if (selectDate != null) {
      _addSignData(dateTime: selectDate);
    }
  }

  //补卡增加数据
  _addSignData({required DateTime dateTime}) async {
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
        _allRecords = value;
        _selectedDay = dateTime;
        _refreshShowData(dateTime);
        setState(() {});
      });
    });
  }

  //展示调休日期选择
  _showRestDateChoosePickWidget() async {
    DateTime? selectDate = await DatePicker.showDateTimePicker(
      context,
      locale: LocaleType.zh,
    );
    if (selectDate != null) {
      _addRestData(dateTime: selectDate);
    }
  }

  //调休增加数据
  _addRestData({required DateTime dateTime}) async {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(dateTime);
    DateFormat timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    String timeStr = timeFormat.format(dateTime);
    Map<String, List<String>>? restDateRecords = await DateUtil.readRestMapFromFile();
    List<String> restData;
    if (restDateRecords.containsKey(dateKey)) {
      restData = restDateRecords[dateKey]!;
    } else {
      restData = [];
    }
    restData.add(timeStr);
    restData.sort();
    restDateRecords[dateKey] = restData;
    DateUtil.writeRestMapToFile(restDateRecords).then((value) {
      DateUtil.readRestMapFromFile().then((value) {
        _restRecords = value;
        _selectedDay = dateTime;
        _refreshShowData(dateTime);
        setState(() {});
      });
    });
  }

  //创建签到提示数据
  Widget _createSignTip(DateTime day, List events) {
    List<Widget> tipsWidget = [];
    bool isWorkDay = _isWorkDay(day);
    List<String> signRecords = _getSignRecord(day);

    DateTime nowTime = DateTime.now();
    DateTime startOfDay =
        DateTime(nowTime.year, nowTime.month, nowTime.day, 23, 59, 59, 999);

    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(day);

    //判断是不是调休
    if(_restRecords.containsKey(dateKey)){
      return const Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("休",style: TextStyle(color: Colors.deepPurple,fontSize: 8,fontWeight: FontWeight.bold)),
          SizedBox(height: 5,)
        ],
      );
    }

    //过滤掉今天之后的日期
    if (day.isAfter(startOfDay)) {
      //判断是不是调班
      bool isOtherWorkDay = false;
      if (Other_Work_Day_Config.contains(dateKey)) {
        isOtherWorkDay = true;
      }
      if(isOtherWorkDay){
        return const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("班",style: TextStyle(color: Colors.red,fontSize: 8,fontWeight: FontWeight.bold)),
            SizedBox(height: 5,)
          ],
        );
      }
      return const SizedBox();
    }

    if (isWorkDay) {
      if (signRecords.isEmpty) {
        tipsWidget.add(_createSignTipItem(Sign_Type.Lose_Sign));
        tipsWidget.add(_createSignTipItem(Sign_Type.Lose_Sign));
      } else if (signRecords.length == 1) {
        if (signRecords.contains("am")) {
          tipsWidget.add(_createSignTipItem(Sign_Type.Had_Sign));
        } else {
          if (day.day == nowTime.day && nowTime.hour < 12) {
            tipsWidget.add(_createSignTipItem(Sign_Type.Wait_Sign));
          } else {
            tipsWidget.add(_createSignTipItem(Sign_Type.Lose_Sign));
          }
        }

        if (signRecords.contains("pm")) {
          tipsWidget.add(_createSignTipItem(Sign_Type.Had_Sign));
        } else {
          if (day.day == nowTime.day) {
            tipsWidget.add(_createSignTipItem(Sign_Type.Wait_Sign));
          } else {
            tipsWidget.add(_createSignTipItem(Sign_Type.Lose_Sign));
          }
        }
      } else if (signRecords.length == 2) {
        tipsWidget.add(_createSignTipItem(Sign_Type.Had_Sign));
        tipsWidget.add(_createSignTipItem(Sign_Type.Had_Sign));
      }
    } else {
      if (signRecords.length == 1) {
        tipsWidget.add(_createSignTipItem(Sign_Type.Had_Sign));
      } else if (signRecords.length == 2) {
        tipsWidget.add(_createSignTipItem(Sign_Type.Had_Sign));
        tipsWidget.add(_createSignTipItem(Sign_Type.Had_Sign));
      }
    }

    //判断是不是调班
    bool isOtherWorkDay = false;
    if (Other_Work_Day_Config.contains(dateKey)) {
        isOtherWorkDay = true;
    }
    if(isOtherWorkDay){
      return SizedBox(
        width: 20,
        height: 20,
        child: Column(
          children: [
            const Text("班",style: TextStyle(color: Colors.red,fontSize: 8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: tipsWidget,
            ),
          ],
        ),
      );
    }else{
      return SizedBox(
        width: 20,
        height: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: tipsWidget,
        ),
      );
    }


  }

  //判断当天是否需要上班
  bool _isWorkDay(DateTime day) {
    bool needWork = false;
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(day);
    if (Holiday_Config.contains(dateKey)) {
      needWork = false;
    } else if (Other_Work_Day_Config.contains(dateKey)) {
      needWork = true;
    } else if (day.weekday == 6 || day.weekday == 7) {
      needWork = false;
    } else {
      needWork = true;
    }
    return needWork;
  }

  //获取当天的签到记录
  List<String> _getSignRecord(DateTime day) {
    List<String> records = [];
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(day);

    if (_allRecords.containsKey(dateKey)) {
      List<String> dayRecords = _allRecords[dateKey]!;
      for (var dateTimeStr in dayRecords) {
        DateTime dateTime = DateTime.parse(dateTimeStr);
        int hour = dateTime.hour;
        if (hour < 12 && !records.contains("am")) records.add("am");
        if (hour > 12 && !records.contains("pm")) records.add("pm");
      }
    }
    return records;
  }

  //创建签到提示小圆点
  Widget _createSignTipItem(Sign_Type signType) {
    Color itemColor;
    switch (signType) {
      case Sign_Type.Wait_Sign:
        itemColor = Wait_Sign_Color;
      case Sign_Type.Had_Sign:
        itemColor = Had_Sign_Color;
      case Sign_Type.Lose_Sign:
        itemColor = Lose_Sign_Color;
      default:
        itemColor = Colors.cyan;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
          color: itemColor, borderRadius: BorderRadius.circular(4)),
    );
  }

  //判断是否是假期
  bool _isHoliday(DateTime dateTime) {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String dateKey = dateFormat.format(dateTime);
    return Holiday_Config.contains(dateKey);
  }
}
