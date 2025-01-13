import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'CalendarPage.dart';
import 'SignController.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '打卡',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '打卡'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SignController signController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    signController = SignController(
        context: context,
        refreshAction: () {
          setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(
            child: Padding(
          padding: EdgeInsets.only(left: 80),
          child: Text(widget.title),
        )),
        actions: [
          TextButton(
              onPressed: () {
                _pushCalendarPage();
              },
              child: Text("打卡日历"))
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 30),
          _createDateTitle(),
          const SizedBox(height: 30),
          _createSignItem("上午: ", signController.hadSignAM),
          const SizedBox(height: 10),
          _createSignItem("下午: ", signController.hadSignPM),
          const SizedBox(height: 130),
          _createSignBtn()
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _createDateTitle() {
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('yyyy年MM月dd日 HH:mm:ss');
    String formattedDate = dateFormat.format(now);
    return Center(
        child: Text(formattedDate,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)));
  }

  _createSignItem(String title, bool hadSign) {
    return Row(
      children: [
        SizedBox(width: 50),
        Text(
          title,
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text(
          hadSign ? "已打卡" : "未打卡",
          style: TextStyle(
              color: hadSign ? Colors.greenAccent : Colors.redAccent,
              fontSize: 40,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  _createSignBtn() {
    bool signComplete = signController.hadSignAM && signController.hadSignPM;

    return TextButton(
      onPressed: () {
        signController.sign();
      },
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
            color: signComplete ? Colors.cyan : Colors.green,
            borderRadius: BorderRadius.circular(120)),
        child: Center(
          child: Text(
            signComplete ? "打卡完成" : "打卡",
            style: TextStyle(
                color: signComplete ? Colors.white : Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  _pushCalendarPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => CalendarPage()));
  }
}
