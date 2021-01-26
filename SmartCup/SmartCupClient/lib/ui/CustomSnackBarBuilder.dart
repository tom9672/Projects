import 'package:flutter/material.dart';

class CustomSnackBarBuilder {
  static BuildContext _globalContext;

  static void setGlobalContext(BuildContext context) {
    _globalContext = context;
  }

  static makeSnackBar({vsync, content, seconds}) {
    ThemeData themeData = Theme.of(_globalContext);
    MediaQueryData mediaQueryData = MediaQuery.of(_globalContext);

    Scaffold.of(_globalContext).removeCurrentSnackBar();
    Scaffold.of(_globalContext).showSnackBar(
      SnackBar(
        elevation: 0,
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Scaffold.of(_globalContext).hideCurrentSnackBar();
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom:
                  mediaQueryData.size.height - mediaQueryData.padding.top - 228,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: themeData.dividerColor,
                borderRadius: new BorderRadius.circular(64.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(0.0, 0.0), //(x,y)
                    blurRadius: 12.0,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: themeData.primaryTextTheme.headline5,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        duration: Duration(
          seconds: seconds,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
