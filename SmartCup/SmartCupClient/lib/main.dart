import 'dart:async';
import 'dart:io';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AssetUpdater.dart';
import 'BLEController.dart';
import 'DataSynchroniser.dart';
import 'ui/AccountTabView.dart';
import 'ui/CustomSnackBarBuilder.dart';
import 'ui/SensorsTabView.dart';
import 'ui/WaterIntakeTabView.dart';
import 'ui/MotionTabBar/MotionTabBar.dart';

// global scaffold context
GlobalKey _mainScaffoldKey = GlobalKey();

SharedPreferences _prefs;
BLEController _bleController;
DataSynchroniser _dataSynchroniser;

SensorsTabView _sensorTabView;

AssetUpdater _assetUpdater;
WaterIntakeTabView _waterIntakeTabView;

AccountTabView _accountTabView;

const SERVER_PREFIX = 'https://smartcup.toms.directory';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _prefs = await SharedPreferences.getInstance();
  //await _prefs.clear();

  _dataSynchroniser = new DataSynchroniser(
    prefs: _prefs,
    serverPrefix: SERVER_PREFIX,
  );

  _bleController = new BLEController(
    prefs: _prefs,
    dataSynchroniser: _dataSynchroniser,
  );

  _sensorTabView = new SensorsTabView(
    bleController: _bleController,
  );

  _assetUpdater = new AssetUpdater(
    serverPrefix: SERVER_PREFIX,
  );

  _waterIntakeTabView = new WaterIntakeTabView(
    assetUpdater: _assetUpdater,
    dataSynchroniser: _dataSynchroniser,
  );

  _accountTabView = new AccountTabView(
    dataSynchroniser: _dataSynchroniser,
  );

  await _assetUpdater.init();

  runApp(MyApp());

  await _bleController.init();
}

class MyApp extends StatelessWidget {
  MyApp();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child,
        );
      },
      title: 'SmartCup',
      theme: new ThemeData(
        backgroundColor: Color.lerp(Colors.white, Colors.blueGrey[100], 0.65),
        canvasColor: Colors.blueGrey[50],
        dividerColor: Colors.blueGrey[100],
        primaryColor: Colors.blueGrey[900],
        bottomAppBarColor: Colors.grey[200],
        inputDecorationTheme: InputDecorationTheme(
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: Colors.blueGrey[600],
            fontSize: 15.0,
            fontWeight: FontWeight.w800,
          ),
          hintStyle: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        primaryTextTheme: TextTheme(
          headline4: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
          ),
          headline5: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 16.0,
            fontWeight: FontWeight.w800,
          ),
          headline6: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 24.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        textTheme: TextTheme(
          button: TextStyle(
            color: Colors.blueGrey[100],
            fontSize: 16.0,
            fontWeight: FontWeight.w800,
          ),
          subtitle1: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
          caption: TextStyle(
            color: Colors.blueGrey[700],
          ),
          bodyText1: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
          ),
          bodyText2: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        appBarTheme: AppBarTheme(
          brightness: Brightness.light,
        ),
      ),
      darkTheme: new ThemeData(
        backgroundColor: Color.lerp(Colors.blueGrey[900], Colors.black, 0.5),
        canvasColor: Color.lerp(Colors.blueGrey[900], Colors.black, 0.7),
        dividerColor: Color.lerp(Colors.blueGrey[900], Colors.black, 0.3),
        primaryColor: Colors.blueGrey[100],
        bottomAppBarColor: Colors.grey[800],
        inputDecorationTheme: InputDecorationTheme(
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: Colors.blueGrey[400],
            fontSize: 15.0,
            fontWeight: FontWeight.w800,
          ),
          hintStyle: TextStyle(
            color: Colors.blueGrey[200],
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        primaryTextTheme: TextTheme(
          headline4: TextStyle(
            color: Colors.blueGrey[200],
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
          ),
          headline5: TextStyle(
            color: Colors.blueGrey[200],
            fontSize: 16.0,
            fontWeight: FontWeight.w800,
          ),
          headline6: TextStyle(
            color: Colors.blueGrey[200],
            fontSize: 24.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        textTheme: TextTheme(
          button: TextStyle(
            color: Colors.blueGrey[900],
            fontSize: 16.0,
            fontWeight: FontWeight.w800,
          ),
          subtitle1: TextStyle(
            color: Colors.blueGrey[200],
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
          caption: TextStyle(
            color: Colors.blueGrey[300],
          ),
          bodyText1: TextStyle(
            color: Colors.blueGrey[200],
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
          ),
          bodyText2: TextStyle(
            color: Colors.blueGrey[200],
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        appBarTheme: AppBarTheme(
          brightness: Brightness.dark,
        ),
      ),
      home: MainPage(title: 'SmartCup'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> with TickerProviderStateMixin {
  TabController tabController;

  bool isWaterIntakeInitialised = false;

  List<Widget> widgets;

  @override
  void initState() {
    super.initState();

    widgets = [
      _sensorTabView,
      _waterIntakeTabView,
      _accountTabView,
    ];

    tabController = new TabController(vsync: this, length: 3, initialIndex: 1);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    Scaffold mainScaffold = Scaffold(
      extendBody: true,
      body: Padding(
        padding: EdgeInsets.only(
          bottom: 55 + MediaQuery.of(context).padding.bottom,
        ),
        child: TabBarView(
          key: _mainScaffoldKey,
          physics: NeverScrollableScrollPhysics(),
          controller: tabController,
          children: widgets,
        ),
      ),
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: MotionTabBar(
        tabController: tabController,
        tabOneName: "SENSORS",
        tabTwoName: "WATER INTAKE",
        tabThreeName: "ACCOUNT",
        tabOneIcon: CommunityMaterialIcons.access_point,
        tabTwoIcon: CommunityMaterialIcons.cup,
        tabThreeIcon: CommunityMaterialIcons.account,
        onTabItemSelected: (int value) {
          if (tabController.index != value) {
            setState(() {
              if (value == 0) {
                _sensorTabView.init();
                _waterIntakeTabView.deInit();
                _accountTabView.deInit();
              } else if (value == 1) {
                _sensorTabView.deInit();
                _waterIntakeTabView.init();
                _accountTabView.deInit();
              } else {
                _sensorTabView.deInit();
                _waterIntakeTabView.deInit();
                _accountTabView.init();
              }

              tabController.index = value;
            });
          }
        },
      ),
    );

    CustomSnackBarBuilder.setGlobalContext(_mainScaffoldKey.currentContext);

    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: themeData.dividerColor,
        statusBarColor: Colors.transparent,
      ));
    }

    return mainScaffold;
  }
}
