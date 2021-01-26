import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../DataSynchroniser.dart';
import 'CustomSnackBarBuilder.dart';
import 'TabViewInterface.dart';

String formatTime(int timestamp) {
  return DateFormat('HH:mm - dd MMM yyyy')
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
}

class AccountTabView extends StatefulWidget implements TabViewInterface {
  final DataSynchroniser dataSynchroniser;

  AccountTabView({@required this.dataSynchroniser})
      : assert(dataSynchroniser != null);

  @override
  State<StatefulWidget> createState() => AccountTabViewState(
        dataSynchroniser: dataSynchroniser,
      );

  @override
  void deInit() {}

  @override
  void init() {}
}

class AccountTabViewState extends State<AccountTabView>
    with TickerProviderStateMixin
    implements DataSynchroniserLoginInterface {
  final DataSynchroniser dataSynchroniser;

  AccountTabViewState({@required this.dataSynchroniser})
      : assert(dataSynchroniser != null);

  final _loginFormKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final pwController = TextEditingController();

  String passwordCounter = '0/24';
  double emailPaddingBottom = 0;
  double passwordPaddingBottom = 0;

  @override
  void initState() {
    super.initState();
    dataSynchroniser.setLoginInterface(this);
  }

  @override
  void dispose() {
    usernameController.dispose();
    pwController.dispose();
    dataSynchroniser.setLoginInterface(null);
    super.dispose();
  }

  @override
  void loginCallback() {
    if (dataSynchroniser.lastLoginStatus ==
        DataSynchroniserLoginEnum.LoginSuccess) {
      if (this.mounted) {
        setState(() {});
      }
    } else {
      String msg = 'Error occured. Please try again later.';

      if (dataSynchroniser.lastLoginStatus ==
          DataSynchroniserLoginEnum.LoginFail) {
        msg = 'The password is incorrect.';
      }

      CustomSnackBarBuilder.makeSnackBar(
        vsync: this,
        content: msg,
        seconds: 5,
      );
    }
  }

  @override
  void loginStatusChanged() {
    if (this.mounted) {
      setState(() {});
    }
  }

  void processLogin() {
    if (_loginFormKey.currentState.validate()) {
      dataSynchroniser.login(
        username: usernameController.text,
        pw: pwController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MediaQueryData mediaQueryData = MediaQuery.of(context);

    if (dataSynchroniser.lastLoginStatus ==
            DataSynchroniserLoginEnum.NoInternetLogin ||
        dataSynchroniser.lastLoginStatus ==
            DataSynchroniserLoginEnum.LoginSuccess) {
      String lastSyncStr = 'Never';
      if (dataSynchroniser.lastSync > 10) {
        lastSyncStr = formatTime(dataSynchroniser.lastSync);
      }

      Container timeAccuracyText;
      if (dataSynchroniser.lastLoginStatus ==
          DataSynchroniserLoginEnum.LoginSuccess) {
        if (dataSynchroniser.isTimeAccurate) {
          timeAccuracyText = Container(
            color: themeData.backgroundColor,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16 + mediaQueryData.padding.left,
                right: 16 + mediaQueryData.padding.right,
                bottom: 16,
              ),
              child: SizedBox(
                width: double.infinity, // match_parent
                child: Text(
                  "Your clock is accurate.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        } else {
          timeAccuracyText = Container(
            color: themeData.backgroundColor,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16 + mediaQueryData.padding.left,
                right: 16 + mediaQueryData.padding.right,
                bottom: 16,
              ),
              child: SizedBox(
                width: double.infinity, // match_parent
                child: Text(
                  "Your system clock is inaccurate. (Current time on the server: " +
                      formatTime(dataSynchroniser.serverTime) +
                      ")",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }
      } else {
        timeAccuracyText = Container();
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
                left: 16 + mediaQueryData.padding.left,
                right: mediaQueryData.padding.right,
                top: 0,
                bottom: 8,
              ),
              centerTitle: false,
              title: Text(
                'Account',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _loginFormKey,
              child: Column(
                children: <Widget>[
                  Container(
                    color: themeData.backgroundColor,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16 + mediaQueryData.padding.left,
                        right: 16 + mediaQueryData.padding.right,
                        top: 16,
                      ),
                      child: SizedBox(
                        width: double.infinity, // match_parent
                        child: Text(
                          "Hello,",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: themeData.backgroundColor,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16 + mediaQueryData.padding.left,
                        right: 16 + mediaQueryData.padding.right,
                        bottom: 16,
                      ),
                      child: SizedBox(
                        width: double.infinity, // match_parent
                        child: Text(
                          dataSynchroniser.savedUsername,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: themeData.backgroundColor,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16 + mediaQueryData.padding.left,
                        right: 16 + mediaQueryData.padding.right,
                        bottom: 16,
                      ),
                      child: SizedBox(
                        width: double.infinity, // match_parent
                        child: Text(
                          "Your data will be synchronised to the cloud automatically but you can also synchronise manually by clicking \"Synchronise now\".",
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  timeAccuracyText,
                  Container(
                    color: themeData.backgroundColor,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16 + mediaQueryData.padding.left,
                        right: 16 + mediaQueryData.padding.right,
                        bottom: 20,
                      ),
                      child: SizedBox(
                        width: double.infinity, // match_parent
                        child: Text(
                          "Last synchronisation: " + lastSyncStr,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 12 + mediaQueryData.padding.left,
                      right: 12 + mediaQueryData.padding.right,
                      top: 24,
                      bottom: 12,
                    ),
                    child: SizedBox(
                      width: double.infinity, // match_parent
                      child: FlatButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        color: themeData.primaryColor,
                        padding: EdgeInsets.all(22),
                        onPressed: () {
                          dataSynchroniser.synchronise();
                        },
                        child: Text(
                          "Synchronise now",
                          style: themeData.textTheme.button,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 12 + mediaQueryData.padding.left,
                      right: 12 + mediaQueryData.padding.right,
                      top: 12,
                      bottom: 52,
                    ),
                    child: SizedBox(
                      width: double.infinity, // match_parent
                      child: FlatButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        color: themeData.primaryColor,
                        padding: EdgeInsets.all(22),
                        onPressed: () {
                          dataSynchroniser.logout();
                        },
                        child: Text(
                          "Sign out",
                          style: themeData.textTheme.button,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: CustomScrollView(
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
                  left: 16 + mediaQueryData.padding.left,
                  right: 16 + mediaQueryData.padding.right,
                  top: 0,
                  bottom: 8,
                ),
                centerTitle: false,
                title: Text(
                  'Account',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Form(
                key: _loginFormKey,
                child: Column(
                  children: <Widget>[
                    Container(
                      color: themeData.backgroundColor,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16 + mediaQueryData.padding.left,
                          right: mediaQueryData.padding.right,
                          top: 16,
                          bottom: 16,
                        ),
                        child: SizedBox(
                          width: double.infinity, // match_parent
                          child: Text(
                            "You haven't signed in yet!",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: themeData.backgroundColor,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16 + mediaQueryData.padding.left,
                          right: 16 + mediaQueryData.padding.right,
                          bottom: 16,
                        ),
                        child: SizedBox(
                          width: double.infinity, // match_parent
                          child: Text(
                            "You need to sign in to your SmartCup account to sychronise the data to the cloud.",
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: themeData.backgroundColor,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16 + mediaQueryData.padding.left,
                          right: 16 + mediaQueryData.padding.right,
                          bottom: 20,
                        ),
                        child: SizedBox(
                          width: double.infinity, // match_parent
                          child: Text(
                            "If you don't have a SmartCup account, the system will create one for you.",
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12 + mediaQueryData.padding.left,
                        right: 12 + mediaQueryData.padding.right,
                        top: 24,
                        bottom: 12,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeData.backgroundColor,
                          borderRadius: new BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 16, right: 16, bottom: emailPaddingBottom),
                          child: TextFormField(
                            controller: usernameController,
                            autocorrect: false,
                            validator: (value) {
                              if (!EmailValidator.validate(value)) {
                                emailPaddingBottom = 8;
                                return 'The email address is invalid.';
                              } else {
                                emailPaddingBottom = 0;
                              }
                              return null;
                            },
                            cursorColor: themeData.primaryColor,
                            keyboardAppearance:
                                themeData.appBarTheme.brightness,
                            decoration: InputDecoration(
                              labelText: 'Email address',
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).nextFocus();
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12 + mediaQueryData.padding.left,
                        right: 12 + mediaQueryData.padding.right,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeData.backgroundColor,
                          borderRadius: new BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: passwordPaddingBottom),
                          child: TextFormField(
                            controller: pwController,
                            autocorrect: false,
                            maxLength: 24,
                            buildCounter: (context,
                                {currentLength, isFocused, maxLength}) {
                              passwordCounter = currentLength.toString() +
                                  "/" +
                                  maxLength.toString();

                              Future.delayed(Duration.zero, () {
                                if (this.mounted) {
                                  setState(() {});
                                }
                              });
                              return null;
                            },
                            validator: (value) {
                              if (value.length < 8) {
                                passwordPaddingBottom = 8;
                                return 'The password must have at least 8 characters.';
                              } else {
                                passwordPaddingBottom = 0;
                              }
                              return null;
                            },
                            cursorColor: themeData.primaryColor,
                            keyboardAppearance:
                                themeData.appBarTheme.brightness,
                            decoration: InputDecoration(
                              suffixText: '$passwordCounter',
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.go,
                            onFieldSubmitted: (_) {
                              processLogin();
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12 + mediaQueryData.padding.left,
                        right: 12 + mediaQueryData.padding.right,
                        top: 12,
                        bottom: 52,
                      ),
                      child: SizedBox(
                        width: double.infinity, // match_parent
                        child: FlatButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          color: themeData.primaryColor,
                          padding: EdgeInsets.all(22),
                          onPressed: () {
                            processLogin();
                          },
                          child: Text(
                            "Continue",
                            style: themeData.textTheme.button,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
