import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../AssetUpdater.dart';
import '../DataSynchroniser.dart';
import 'TabViewInterface.dart';

bool checkDarkModeOn(ThemeData theme) {
  if (theme.brightness == Brightness.dark) {
    return true;
  }
  return false;
}

String getColorJson(String key, Color color) {
  return key +
      ': "rgba(' +
      color.red.toString() +
      ',' +
      color.green.toString() +
      ',' +
      color.blue.toString() +
      ',' +
      color.opacity.toStringAsFixed(2).toString() +
      ')"';
}

String getFontJson(String key, TextStyle textStyle) {
  return key +
      ': {' +
      getColorJson('color', textStyle.color) +
      ',fontSize:' +
      textStyle.fontSize.toString() +
      ',fontWeight:"' +
      textStyle.fontWeight.toString() +
      '"}';
}

class WaterIntakeTabView extends StatefulWidget implements TabViewInterface {
  final AssetUpdater assetUpdater;
  final DataSynchroniser dataSynchroniser;

  WaterIntakeTabView({
    @required this.assetUpdater,
    @required this.dataSynchroniser,
  })  : assert(assetUpdater != null),
        assert(dataSynchroniser != null);

  @override
  State<StatefulWidget> createState() {
    return WaterIntakeTabViewState(
      assetUpdater: assetUpdater,
      dataSynchroniser: dataSynchroniser,
    );
  }

  @override
  void deInit() {}

  @override
  void init() {}
}

class WaterIntakeTabViewState extends State<WaterIntakeTabView>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin<WaterIntakeTabView>
    implements AssetUpdaterDrawer, DataSynchroniserSyncInterface {
  final AssetUpdater assetUpdater;
  final DataSynchroniser dataSynchroniser;

  InAppWebViewController _webViewController;
  bool isLoading = true;
  bool shouldRedraw = true;

  WaterIntakeTabViewState({
    @required this.assetUpdater,
    @required this.dataSynchroniser,
  }) {
    assert(assetUpdater != null);
    assert(dataSynchroniser != null);
    assetUpdater.setDrawer(this);
    dataSynchroniser.setSyncInterface(this);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      shouldRedraw = true;
      updateKeepAlive();
    }
  }

  Widget buildUpdating(ThemeData themeData) {
    String stateStr = 'INTERNAL ERROR';

    if (!assetUpdater.initFailed) {
      stateStr = 'UPDATING...';
    }

    return Container(
      color: themeData.backgroundColor.withAlpha(240),
      child: Container(
        color: themeData.canvasColor,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              elevation: 0.0,
              expandedHeight: 64.0,
              toolbarHeight: 36,
              floating: false,
              pinned: true,
              backgroundColor: themeData.backgroundColor.withAlpha(240),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(
                  left: 16 + MediaQuery.of(context).padding.left,
                  right: MediaQuery.of(context).padding.right,
                  bottom: 8,
                ),
                centerTitle: false,
                title: Text(
                  "Water Intake",
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Card(
                elevation: 0,
                margin: new EdgeInsets.only(
                  left: 12 + MediaQuery.of(context).padding.left,
                  top: 24,
                  bottom: 16,
                  right: 12 + MediaQuery.of(context).padding.right,
                ),
                color: Theme.of(context).backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  heightFactor: 3,
                  child: Text(
                    stateStr,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.caption.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getSetThemeJs(ThemeData themeData, EdgeInsets safeArea) {
    return 'setLocal(' +
        // theme data
        '{' +
        getColorJson('canvasColor', themeData.canvasColor) +
        ',' +
        getColorJson('backgroundColor', themeData.backgroundColor) +
        ',' +
        getColorJson('primaryColor', themeData.primaryColor) +
        ',' +
        getColorJson('dividerColor', themeData.dividerColor) +
        ',' +
        getFontJson('headline4', themeData.primaryTextTheme.headline4) +
        ',' +
        getFontJson('headline5', themeData.primaryTextTheme.headline5) +
        ',' +
        getFontJson('headline6', themeData.primaryTextTheme.headline6) +
        ',' +
        getFontJson('button', themeData.textTheme.button) +
        ',' +
        getFontJson('subtitle1', themeData.textTheme.subtitle1) +
        ',' +
        getFontJson('caption', themeData.textTheme.caption) +
        ',' +
        getFontJson('bodyText1', themeData.textTheme.bodyText1) +
        ',' +
        getFontJson('bodyText2', themeData.textTheme.bodyText2) +
        ',' +
        getFontJson('labelStyle', themeData.inputDecorationTheme.labelStyle) +
        '}, ' +
        // safe area
        '{left:' +
        MediaQuery.of(context).padding.left.toString() +
        ', right:' +
        MediaQuery.of(context).padding.right.toString() +
        ', top:' +
        MediaQuery.of(context).padding.top.toString() +
        ', bottom:32' +
        '}' +
        ');';
  }

  Widget buildUpdated(ThemeData themeData) {
    if (shouldRedraw == false) {
      if (_webViewController != null) {
        if (!isLoading) {
          _webViewController.evaluateJavascript(
            source: getSetThemeJs(themeData, MediaQuery.of(context).padding),
          );
          _webViewController.evaluateJavascript(
            source:
                'waterLevelDataUpdated(' + dataSynchroniser.getAllData() + ')',
          );
        }
      }
    }

    return Container(
      color: themeData.canvasColor,
      child: InAppWebView(
        initialUrl: 'file://' + assetUpdater.assetsPath + '/index.html',
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStart: (controller, url) {
          isLoading = true;
        },
        onLoadStop: (controller, url) {
          isLoading = false;
          if (_webViewController != null) {
            _webViewController.evaluateJavascript(
              source: getSetThemeJs(themeData, MediaQuery.of(context).padding),
            );

            _webViewController.evaluateJavascript(
              source: 'waterLevelDataUpdated(' +
                  dataSynchroniser.getAllData() +
                  ')',
            );
          }
        },
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            disableContextMenu: true,
            supportZoom: false,
            transparentBackground: true,
          ),
          android: AndroidInAppWebViewOptions(
            overScrollMode: AndroidOverScrollMode.OVER_SCROLL_NEVER,
          ),
          ios: IOSInAppWebViewOptions(
            allowsLinkPreview: false,
            allowsBackForwardNavigationGestures: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ThemeData themeData = Theme.of(context);

    Widget currentWidget;

    if (assetUpdater.initFailed || !assetUpdater.oldVersionAvailable) {
      currentWidget = buildUpdating(themeData);
    } else {
      currentWidget = buildUpdated(themeData);
    }

    shouldRedraw = false;
    updateKeepAlive();

    return currentWidget;
  }

  @override
  void dataAvailable() {
    if (shouldRedraw == false) {
      if (_webViewController != null && isLoading == false) {
        _webViewController.evaluateJavascript(
          source:
              'waterLevelDataUpdated(' + dataSynchroniser.getAllData() + ')',
        );
      }
    }
  }

  @override
  void updateCompleted() {
    if (shouldRedraw == false) {
      if (this.mounted) {
        setState(() {
          if (_webViewController != null) {
            _webViewController.reload();
          }
        });
      }
    }
  }

  @override
  void updateStarted() {}

  @override
  bool get wantKeepAlive => !shouldRedraw;
}
