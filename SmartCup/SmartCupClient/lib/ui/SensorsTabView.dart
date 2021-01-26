import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../BLEController.dart';
import 'CustomSnackBarBuilder.dart';
import 'TabViewInterface.dart';

class SensorsTabView extends StatefulWidget implements TabViewInterface {
  final BLEController bleController;

  SensorsTabView({@required this.bleController})
      : assert(bleController != null);

  @override
  State<StatefulWidget> createState() => SensorsTabViewState(
        bleController: bleController,
      );

  @override
  void deInit() {
    bleController.stopScanning();
  }

  @override
  void init() {
    bleController.startScanning();
  }
}

class SensorsTabViewState extends State<SensorsTabView>
    with TickerProviderStateMixin
    implements BLEControllerInterface {
  final BLEController bleController;
  List<BLEResult> scanResults;

  SensorsTabViewState({@required this.bleController})
      : assert(bleController != null);

  @override
  void initState() {
    super.initState();
    bleController.setObserver(this);
    scanResults = bleController.getCachedResults();
  }

  @override
  void dispose() {
    super.dispose();
    bleController.setObserver(null);
  }

  void scanResultsReady(List<BLEResult> newScanResults) {
    if (this.mounted) {
      setState(() {
        this.scanResults = newScanResults;
      });
    }
  }

  Widget makeSectionTitle({
    String title,
    @required SliverStickyHeaderState state,
    @required ThemeData themeData,
  }) {
    Text titleText = title != null
        ? Text(
            title,
            style: themeData.primaryTextTheme.headline5,
          )
        : null;

    return Container(
      height: 40,
      color: state.isPinned == true
          ? themeData.dividerColor.withAlpha(240)
          : themeData.canvasColor,
      padding: EdgeInsets.only(
        top: 8,
        left: 16 + MediaQuery.of(context).padding.left,
        right: 16 + MediaQuery.of(context).padding.right,
        bottom: 8,
      ),
      alignment: Alignment.centerLeft,
      child: titleText,
    );
  }

  Widget makeSectionItem({
    @required int idx,
    String content,
    String subtext,
    IconData iconData,
    Future<void> Function(int) btnCallback,
    @required ThemeData themeData,
  }) {
    double topPadding = 0;
    if (idx == 0) {
      topPadding = 4;
    }

    Text contentText = content != null
        ? Text(
            content,
          )
        : null;

    Text subtextText = subtext != null
        ? Text(
            subtext,
          )
        : null;

    return Card(
      elevation: 0,
      margin: new EdgeInsets.only(
        left: 12 + MediaQuery.of(context).padding.left,
        top: topPadding,
        bottom: 16,
        right: 12 + MediaQuery.of(context).padding.right,
      ),
      color: themeData.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Container(
        child: ListTile(
          contentPadding: EdgeInsets.only(
            left: 16,
            top: 2,
            bottom: 2,
            right: 2,
          ),
          title: contentText,
          subtitle: subtextText,
          trailing: iconData != null
              ? IconButton(
                  icon: Icon(
                    iconData,
                    color: themeData.primaryColor,
                  ),
                  onPressed: btnCallback != null
                      ? () async => await btnCallback(idx)
                      : null,
                  splashRadius: 24,
                  iconSize: 24.0,
                  padding: EdgeInsets.all(15),
                )
              : null,
        ),
      ),
    );
  }

  Widget makeListSection({
    @required String title,
    List<BLEResult> results,
    String emptyText,
    IconData iconData,
    Future<void> Function(BLEResult) btnCallback,
    @required ThemeData themeData,
  }) {
    SliverList sliver;

    if (results.length > 0) {
      sliver = SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, idx) {
            Future<void> Function(int) callback = (idx) async {};

            String subtext = '';
            String subtextValue = '';

            if (results[idx].saved) {
              subtext = '';
              subtextValue = 'Out of range';

              if (results[idx].device != null) {
                if (results[idx].isConnected) {
                  subtextValue = 'Connected';
                } else {
                  subtextValue = 'Disconnected';
                }
              }
            } else {
              subtext = 'Signal Strength: ';
              if (results[idx].rssi > -50) {
                subtextValue = 'Excellent';
              } else if (results[idx].rssi > -65) {
                subtextValue = 'Good';
              } else if (results[idx].rssi > -75) {
                subtextValue = 'Okay';
              } else if (results[idx].rssi > -85) {
                subtextValue = 'Weak';
              } else {
                subtextValue = 'Unstable';
              }
            }

            if (btnCallback != null) {
              callback = (idx) async {
                await btnCallback(results[idx]);
              };
            }

            return makeSectionItem(
              idx: idx,
              content: results[idx].name,
              subtext: '$subtext$subtextValue',
              iconData: iconData != null ? iconData : null,
              btnCallback: callback,
              themeData: themeData,
            );
          },
          childCount: results.length,
        ),
      );
    } else {
      sliver = SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, idx) {
            return Card(
              elevation: 0,
              margin: new EdgeInsets.only(
                left: 12 + MediaQuery.of(context).padding.left,
                top: 2,
                bottom: 16,
                right: 12 + MediaQuery.of(context).padding.right,
              ),
              color: themeData.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                heightFactor: 3,
                child: Text(
                  emptyText,
                  style: TextStyle(
                    color: themeData.textTheme.caption.color,
                  ),
                ),
              ),
            );
          },
          childCount: 1,
        ),
      );
    }

    return SliverStickyHeader.builder(
      builder: (context, state) {
        return makeSectionTitle(
          title: title != null ? title : null,
          state: state,
          themeData: themeData,
        );
      },
      sliver: sliver,
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    List<BLEResult> pairedDeviceResults = [];
    List<BLEResult> othersDeviceResults = [];

    if (this.scanResults != null) {
      this.scanResults.forEach((result) {
        if (result.saved) {
          pairedDeviceResults.add(result);
        } else {
          othersDeviceResults.add(result);
        }
      });
    }

    return CustomScrollView(
      physics: ClampingScrollPhysics(),
      slivers: <Widget>[
        SliverAppBar(
          elevation: 0.0,
          expandedHeight: 64,
          toolbarHeight: 36,
          floating: false,
          pinned: true,
          backgroundColor: themeData.canvasColor.withAlpha(240),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: 16 + MediaQuery.of(context).padding.left,
              right: MediaQuery.of(context).padding.right,
              top: 0,
              bottom: 8,
            ),
            centerTitle: false,
            title: Text(
              'Sensors',
            ),
          ),
        ),
        makeListSection(
          title: 'PAIRED',
          results: pairedDeviceResults,
          emptyText: 'EMPTY',
          iconData: CommunityMaterialIcons.close_circle,
          btnCallback: (result) async {
            CustomSnackBarBuilder.makeSnackBar(
              vsync: this,
              content: 'Removing sensor ' + result.name,
              seconds: 30,
            );

            await bleController.deleteDevice(result.id);

            CustomSnackBarBuilder.makeSnackBar(
              vsync: this,
              content: 'Removed sensor ' + result.name,
              seconds: 3,
            );

            if (this.mounted) {
              setState(() {});
            }
          },
          themeData: themeData,
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: 36),
          sliver: makeListSection(
            title: 'DISCOVERED',
            results: othersDeviceResults,
            emptyText: 'SCANNING...',
            iconData: CommunityMaterialIcons.plus_circle,
            btnCallback: (result) async {
              CustomSnackBarBuilder.makeSnackBar(
                vsync: this,
                content: 'Adding sensor ' + result.name,
                seconds: 30,
              );

              if (await bleController.checkAndSaveDevice(result.device)) {
                CustomSnackBarBuilder.makeSnackBar(
                  vsync: this,
                  content: 'Added sensor ' + result.name,
                  seconds: 3,
                );

                if (this.mounted) {
                  setState(() {});
                }
              } else {
                CustomSnackBarBuilder.makeSnackBar(
                  vsync: this,
                  content: 'Unable to add sensor ' + result.name,
                  seconds: 3,
                );
              }
            },
            themeData: themeData,
          ),
        )
      ],
    );
  }
}
