library motiontabbar;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'MotionTabItem.dart';
import 'package:vector_math/vector_math.dart' as vector;

typedef MotionTabBuilder = Widget Function();

class MotionTabBar extends StatefulWidget {
  final TabController tabController;
  final String tabOneName, tabTwoName, tabThreeName;
  final IconData tabOneIcon, tabTwoIcon, tabThreeIcon;
  final Function onTabItemSelected;

  MotionTabBar({
    @required this.tabController,
    @required this.tabOneName,
    @required this.tabTwoName,
    @required this.tabThreeName,
    @required this.tabOneIcon,
    @required this.tabTwoIcon,
    @required this.tabThreeIcon,
    @required this.onTabItemSelected,
  })  : assert(tabController != null),
        assert(tabOneName != null),
        assert(tabTwoName != null),
        assert(tabThreeName != null),
        assert(tabOneIcon != null),
        assert(tabTwoIcon != null),
        assert(tabThreeIcon != null);

  @override
  _MotionTabBarState createState() => _MotionTabBarState();
}

class _MotionTabBarState extends State<MotionTabBar>
    with TickerProviderStateMixin {
  AnimationController _animationController;
  Tween<double> _positionTween;
  Animation<double> _positionAnimation;

  AnimationController _fadeOutController;
  Animation<double> _fadeFabOutAnimation;
  Animation<double> _fadeFabInAnimation;

  double fabIconAlpha = 1;
  IconData nextIcon;
  IconData activeIcon;
  int lastSelected = 1;
  int currentSelected = 1;

  @override
  void initState() {
    super.initState();

    nextIcon = widget.tabTwoIcon;
    activeIcon = widget.tabTwoIcon;

    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: ANIM_DURATION));
    _fadeOutController = AnimationController(
        vsync: this, duration: Duration(milliseconds: (ANIM_DURATION ~/ 5)));

    _positionTween = Tween<double>(begin: 0, end: 0);
    _positionAnimation = _positionTween.animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut))
      ..addListener(() {
        setState(() {});
      });

    _fadeFabOutAnimation = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut))
      ..addListener(() {
        setState(() {
          fabIconAlpha = _fadeFabOutAnimation.value;
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            activeIcon = nextIcon;
          });
        }
      });

    _fadeFabInAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.8, 1, curve: Curves.easeOut)))
      ..addListener(() {
        setState(() {
          fabIconAlpha = _fadeFabInAnimation.value;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Color tabIconColor = themeData.primaryColor;
    final Color backgroundColor = themeData.dividerColor;

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Container(
          height: 55 + MediaQuery.of(context).padding.bottom,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          margin: EdgeInsets.only(top: 45),
          decoration: BoxDecoration(color: backgroundColor, boxShadow: [
            BoxShadow(
                color: Colors.black12, offset: Offset(0, -1), blurRadius: 5)
          ]),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              MotionTabItem(
                selected: currentSelected == 0,
                iconData: widget.tabOneIcon,
                title: widget.tabOneName,
                callbackFunction: () {
                  if (!widget.tabController.indexIsChanging) {
                    if (!_animationController.isAnimating) {
                      nextIcon = widget.tabOneIcon;
                      lastSelected = currentSelected;
                      currentSelected = 0;
                      if (lastSelected != currentSelected) {
                        widget.onTabItemSelected(currentSelected);
                        setState(() {});
                        _initAnimationAndStart(_positionAnimation.value, -1);
                      }
                    }
                  }
                },
              ),
              MotionTabItem(
                selected: currentSelected == 1,
                iconData: widget.tabTwoIcon,
                title: widget.tabTwoName,
                callbackFunction: () {
                  if (!widget.tabController.indexIsChanging) {
                    if (!_animationController.isAnimating) {
                      nextIcon = widget.tabTwoIcon;
                      lastSelected = currentSelected;
                      currentSelected = 1;
                      if (lastSelected != currentSelected) {
                        widget.onTabItemSelected(currentSelected);
                        setState(() {});
                        _initAnimationAndStart(_positionAnimation.value, 0);
                      }
                    }
                  }
                },
              ),
              MotionTabItem(
                selected: currentSelected == 2,
                iconData: widget.tabThreeIcon,
                title: widget.tabThreeName,
                callbackFunction: () {
                  if (!widget.tabController.indexIsChanging) {
                    if (!_animationController.isAnimating) {
                      nextIcon = widget.tabThreeIcon;
                      lastSelected = currentSelected;
                      currentSelected = 2;
                      if (lastSelected != currentSelected) {
                        widget.onTabItemSelected(currentSelected);
                        setState(() {});
                        _initAnimationAndStart(_positionAnimation.value, 1);
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(color: Colors.transparent),
            child: Align(
              heightFactor: 1,
              alignment: Alignment(_positionAnimation.value, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / 3,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 90,
                      width: 90,
                      child: ClipRect(
                          clipper: HalfClipper(),
                          child: Container(
                            child: Center(
                              child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                      color: backgroundColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8)
                                      ])),
                            ),
                          )),
                    ),
                    SizedBox(
                        height: 70,
                        width: 90,
                        child: CustomPaint(
                          painter: HalfPainter(color: backgroundColor),
                        )),
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tabIconColor,
                            border: Border.all(
                                color: backgroundColor,
                                width: 5,
                                style: BorderStyle.none)),
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Opacity(
                            opacity: fabIconAlpha,
                            child: Icon(
                              activeIcon,
                              size: 36,
                              color: backgroundColor,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _initAnimationAndStart(double from, double to) {
    _positionTween.begin = from;
    _positionTween.end = to;

    _animationController.reset();
    _fadeOutController.reset();
    _animationController.forward();
    _fadeOutController.forward();
  }
}

class HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height / 2);
    return rect;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}

class HalfPainter extends CustomPainter {
  Color color;

  HalfPainter({
    @required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect beforeRect = Rect.fromLTWH(0, (size.height / 2) - 10, 10, 10);
    final Rect largeRect = Rect.fromLTWH(10, 0, size.width - 20, 70);
    final Rect afterRect =
        Rect.fromLTWH(size.width - 10, (size.height / 2) - 10, 10, 10);

    final path = Path();
    path.arcTo(beforeRect, vector.radians(0), vector.radians(90), false);
    path.lineTo(20, size.height / 2);
    path.arcTo(largeRect, vector.radians(0), -vector.radians(180), false);
    path.moveTo(size.width - 10, size.height / 2);
    path.lineTo(size.width - 10, (size.height / 2) - 10);
    path.arcTo(afterRect, vector.radians(180), vector.radians(-90), false);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
