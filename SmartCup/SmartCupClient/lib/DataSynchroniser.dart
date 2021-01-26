import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HTTPHelper.dart';

class WaterLog {
  final int v;
  final int t;
  const WaterLog({this.v, this.t});

  factory WaterLog.fromJson(dynamic json) {
    return WaterLog(
      v: json['v'],
      t: json['t'],
    );
  }

  Map<String, dynamic> toJson() => {
        'v': v,
        't': t,
      };
}

class DataSynchroniserLoginInterface {
  void loginCallback() {}
  void loginStatusChanged() {}
}

class DataSynchroniserSyncInterface {
  void dataAvailable() {}
}

class DataSynchroniser {
  static const WATERLOG_SYNC_LIMIT = 200;
  static const WATERLOG_SYNC_RETRY = 3;

  final serverPrefix;
  final SharedPreferences prefs;
  final HttpClient httpClient = HttpClient();

  DataSynchroniserLoginInterface loginInterface;
  DataSynchroniserSyncInterface syncInterface;

  DataSynchroniserLoginEnum lastLoginStatus =
      DataSynchroniserLoginEnum.NoInternetLogout;

  String savedUsername = '';
  int lastSync = 0;
  int lastDataReceived = 0;
  bool isTimeAccurate = false;
  int serverTime = 0;

  DataSynchroniser({@required this.prefs, @required this.serverPrefix}) {
    assert(prefs != null);
    assert(serverPrefix != null);

    httpClient.connectionTimeout = Duration(seconds: 30);

    try {
      if (prefs.containsKey('lastSync')) {
        lastSync = prefs.getInt('lastSync');
      }
    } catch (e) {}

    lastDataReceived = lastSync + 1;

    synchroniseLoop();
  }

  void setLoginInterface(DataSynchroniserLoginInterface newLoginInterface) {
    loginInterface = newLoginInterface;
  }

  void setSyncInterface(DataSynchroniserSyncInterface newSyncInterface) {
    syncInterface = newSyncInterface;
  }

  Future<List<Cookie>> getSavedCookies() async {
    if (prefs.containsKey('savedCookies')) {
      List<Cookie> cookies = List<Cookie>();

      List<String> savedCookies = prefs.getStringList('savedCookies');

      for (String savedCookie in savedCookies) {
        cookies.add(Cookie.fromSetCookieValue(savedCookie));
      }

      return cookies;
    }

    return null;
  }

  Future<bool> setSavedCookies(List<Cookie> cookies) async {
    if (cookies != null && cookies.length > 0) {
      List<String> cookieStrs = List<String>();

      for (Cookie cookie in cookies) {
        cookieStrs.add(cookie.toString());
      }
      return await prefs.setStringList('savedCookies', cookieStrs);
    }

    return true;
  }

  Future<void> deleteSession() async {
    lastSync = 0;

    await prefs.setStringList('savedCookies', null);
    await prefs.setString('savedUsername', null);
    await prefs.setString('cachedWaterLogs', null);
    await prefs.setInt('lastSync', 0);
  }

  Future<void> addNewLog({
    @required String id,
    @required List<WaterLog> newLogObjList,
  }) async {
    // SAVE TO FILE
    List<dynamic> combinedLogList = List<dynamic>();

    try {
      if (prefs.containsKey('log_' + id)) {
        String oldLogStr = prefs.getString('log_' + id);

        List<dynamic> oldLogList = json.decode(oldLogStr);
        combinedLogList.addAll(oldLogList);
      }
    } catch (e) {
      print(e);
    }

    try {
      newLogObjList.forEach((element) {
        combinedLogList.add(element.toJson());
      });
    } catch (e) {}

    try {
      await prefs.setString('log_' + id, json.encode(combinedLogList));

      lastDataReceived = DateTime.now().millisecondsSinceEpoch;

      await synchronise();
    } catch (e) {
      print(e);
    }

    if (syncInterface != null) {
      syncInterface.dataAvailable();
    }
  }

  Future<DataSynchroniserLoginEnum> checkLogin(bool isOnlineCheck) async {
    DataSynchroniserLoginEnum ret = DataSynchroniserLoginEnum.NoInternetLogout;

    try {
      List<Cookie> cookies = await getSavedCookies();

      if (cookies != null) {
        ret = DataSynchroniserLoginEnum.NoInternetLogin;

        if (isOnlineCheck) {
          HttpClientResponse res = await postString(
            httpClient,
            serverPrefix + '/checkLogin',
            cookies,
            null,
            null,
          );

          await setSavedCookies(res.cookies);

          if (res.statusCode == 200) {
            Map<String, dynamic> resObj = await readJson(res);

            if (resObj['status'] == 'success') {
              ret = DataSynchroniserLoginEnum.LoginSuccess;

              serverTime = resObj['data']['timestamp'];

              if ((DateTime.now().millisecondsSinceEpoch - serverTime).abs() <
                  5 * 60 * 1000) {
                isTimeAccurate = true;
              } else {
                isTimeAccurate = false;
              }
            } else {
              ret = DataSynchroniserLoginEnum.NoInternetLogout;
              await deleteSession();
            }
          }
        }
      }
    } catch (e) {
      print(e);
    }

    if (loginInterface != null) {
      if (lastLoginStatus == DataSynchroniserLoginEnum.LoginSuccess ||
          lastLoginStatus == DataSynchroniserLoginEnum.NoInternetLogin) {
        if (ret == DataSynchroniserLoginEnum.NoInternetLogout) {
          lastLoginStatus = ret;
          loginInterface.loginStatusChanged();
        }
      }
    }

    lastLoginStatus = ret;

    return ret;
  }

  Future<DataSynchroniserLoginEnum> login({String username, String pw}) async {
    DataSynchroniserLoginEnum ret = DataSynchroniserLoginEnum.NoInternetLogout;

    try {
      List<Cookie> cookies = await getSavedCookies();

      Map<String, dynamic> loginObj = {
        'username': username,
        'pw': pw,
      };

      HttpClientResponse res = await postJson(
        httpClient,
        serverPrefix + '/registerOrSignin',
        cookies,
        null,
        loginObj,
      );

      await setSavedCookies(res.cookies);

      if (res.statusCode == 200) {
        Map<String, dynamic> resObj = await readJson(res);

        if (resObj['status'] == 'success') {
          if (await prefs.setString('savedUsername', username)) {
            savedUsername = username;

            lastSync = 0;
            await synchronise();
            ret = DataSynchroniserLoginEnum.LoginSuccess;
          }
        } else if (resObj['status'] == 'fail' &&
            resObj['reason'] == 'password incorrect') {
          ret = DataSynchroniserLoginEnum.LoginFail;
        } else {
          ret = DataSynchroniserLoginEnum.LoginError;
        }
      }
    } catch (e) {
      print(e);
    }

    lastLoginStatus = ret;

    if (loginInterface != null) {
      loginInterface.loginCallback();
    }

    return ret;
  }

  Future<DataSynchroniserLoginEnum> logout() async {
    try {
      List<Cookie> cookies = await getSavedCookies();

      if (cookies != null) {
        await postString(
          httpClient,
          serverPrefix + '/logout',
          cookies,
          null,
          null,
        );
      }
    } catch (e) {
      print(e);
    } finally {
      await deleteSession();
    }

    lastLoginStatus = DataSynchroniserLoginEnum.NoInternetLogout;

    if (loginInterface != null) {
      loginInterface.loginStatusChanged();
    }

    return DataSynchroniserLoginEnum.NoInternetLogout;
  }

  // remove data that is older than 60 days in the json list
  List<Map<String, dynamic>> filterCachedWaterLogJsonList(
    List<Map<String, dynamic>> oldWaterLogList,
  ) {
    List<Map<String, dynamic>> newWaterLogList = List<Map<String, dynamic>>();

    if (oldWaterLogList != null) {
      newWaterLogList.addAll(oldWaterLogList);

      newWaterLogList.sort((a, b) {
        return a['t'] - b['t'];
      });

      newWaterLogList.removeWhere((element) {
        return element['t'] <
            DateTime.now().millisecondsSinceEpoch - 180 * 24 * 60 * 60 * 1000;
      });

      if (newWaterLogList.length > 0) {
        List<Map<String, dynamic>> uniqueWaterLogList =
            List<Map<String, dynamic>>();

        uniqueWaterLogList.add(newWaterLogList[0]);

        newWaterLogList.forEach((element) {
          if (element['t'] - 29 * 1000 >=
              uniqueWaterLogList[uniqueWaterLogList.length - 1]['t']) {
            uniqueWaterLogList.add(element);
          }
        });

        newWaterLogList = uniqueWaterLogList;
      }
    }

    return newWaterLogList;
  }

  // combine two water log json, remove duplicates and data that is older than 180 days
  //
  // JSON structure:
  // {
  //   "sensor_id_1": [
  //     {"t": 0, "v": 100},
  //     {"t": 1, "v": 100}
  //   ]
  // }
  Map<String, dynamic> combineCachedWaterLogJsonMap(
    Map<String, dynamic> oldWaterLogMap,
    Map<String, dynamic> newWaterLogMap,
  ) {
    Map<String, dynamic> combinedWaterLogMap = Map<String, dynamic>();

    if (oldWaterLogMap == null) {
      oldWaterLogMap = Map<String, dynamic>();
    }
    if (newWaterLogMap == null) {
      newWaterLogMap = Map<String, dynamic>();
    }

    oldWaterLogMap.forEach((key, value) {
      if (!combinedWaterLogMap.containsKey(key)) {
        combinedWaterLogMap[key] = List<Map<String, dynamic>>();
      }

      value.forEach((element) {
        if (!combinedWaterLogMap[key].contains(element)) {
          combinedWaterLogMap[key].add(element);
        }
      });
    });

    newWaterLogMap.forEach((key, value) {
      if (!combinedWaterLogMap.containsKey(key)) {
        combinedWaterLogMap[key] = List<Map<String, dynamic>>();
      }

      value.forEach((element) {
        if (!combinedWaterLogMap[key].contains(element)) {
          combinedWaterLogMap[key].add(element);
        }
      });
    });

    combinedWaterLogMap.forEach((key, value) {
      combinedWaterLogMap[key] = filterCachedWaterLogJsonList(value);
    });

    return combinedWaterLogMap;
  }

  String getCachedWaterLogsHash() {
    String cahcedWaterLogsStr = '{}';

    if (prefs.containsKey('cachedWaterLogs')) {
      Map<String, dynamic> oldWaterLogMap = json.decode(
        prefs.getString('cachedWaterLogs'),
      );

      Map<String, dynamic> newWaterLogMap = combineCachedWaterLogJsonMap(
        oldWaterLogMap,
        {},
      );

      cahcedWaterLogsStr = json.encode(newWaterLogMap);
      prefs.setString('cachedWaterLogs', cahcedWaterLogsStr);
    }

    return sha256.convert(utf8.encode(cahcedWaterLogsStr)).toString();
  }

  String getAllData() {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    int timestampLimit = currentTimestamp - 180 * 24 * 60 * 60 * 1000;

    Map<String, dynamic> waitForSyncLogs = Map<String, dynamic>();
    Map<String, dynamic> cachedWaterLogs = Map<String, dynamic>();

    // Gets sensors' log
    Set<String> keys = prefs.getKeys();
    keys.removeWhere((element) {
      return !element.startsWith('log_');
    });

    // For each sensor
    for (String key in keys) {
      try {
        String id = key.substring(4);
        waitForSyncLogs[id] = List<Map<String, dynamic>>();

        List<dynamic> currentDeviceWaterLogs =
            json.decode(prefs.getString(key));

        for (dynamic waterLog in currentDeviceWaterLogs) {
          if (waterLog['t'] > timestampLimit) {
            waitForSyncLogs[id].add({
              't': waterLog['t'],
              'v': waterLog['v'],
            });
          }
        }
      } catch (e) {}
    }

    if (prefs.containsKey('cachedWaterLogs')) {
      try {
        cachedWaterLogs = json.decode(prefs.getString('cachedWaterLogs'));
      } catch (e) {}
    }

    return json.encode(
      combineCachedWaterLogJsonMap(
        cachedWaterLogs,
        waitForSyncLogs,
      ),
    );
  }

  Future<void> synchronise() async {
    try {
      if (savedUsername == '') {
        savedUsername = prefs.getString('savedUsername');
      }

      if (await checkLogin(true) == DataSynchroniserLoginEnum.LoginSuccess) {
        int failCount = 0;
        if (lastSync < lastDataReceived) {
          int waterLogCount = 0;

          int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
          int timestampLimit = currentTimestamp - 180 * 24 * 60 * 60 * 1000;

          // Iterates all sensors and upload the water logs.
          // For each upload, upload WATERLOG_SYNC_LIMIT number of water logs
          //
          // The synchronisation will stop
          // if the number of failures exceeds WATERLOG_SYNC_RETRY
          //
          Map<String, dynamic> waitForSyncLogs;
          Map<String, dynamic> remainingLogs;
          do {
            try {
              waterLogCount = 0;
              waitForSyncLogs = Map<String, dynamic>();
              remainingLogs = Map<String, dynamic>();

              // Gets sensors' log
              Set<String> keys = prefs.getKeys();
              keys.removeWhere((element) {
                return !element.startsWith('log_');
              });

              // For each sensor
              for (String key in keys) {
                try {
                  if (waterLogCount > WATERLOG_SYNC_LIMIT) {
                    // Quits the loop if there are
                    // WATERLOG_SYNC_LIMIT number of logs in waitForSyncLogs
                    break;
                  } else {
                    // Create new lists for the current sensor.
                    // Each sensor will have two lists,
                    // one is for storing uploading logs (waitForSyncLogs),
                    // another is for storing upload pending logs (remainingLogs).
                    String id = key.substring(4);
                    waitForSyncLogs[id] = List<Map<String, dynamic>>();
                    remainingLogs[id] = List<Map<String, dynamic>>();

                    List<dynamic> currentDeviceWaterLogs =
                        json.decode(prefs.getString(key));

                    for (dynamic waterLog in currentDeviceWaterLogs) {
                      if (waterLog['t'] > timestampLimit) {
                        if (waterLogCount > WATERLOG_SYNC_LIMIT) {
                          remainingLogs[id].add({
                            't': waterLog['t'],
                            'v': waterLog['v'],
                          });
                        } else {
                          waitForSyncLogs[id].add({
                            't': waterLog['t'],
                            'v': waterLog['v'],
                          });
                          waterLogCount++;
                        }
                      }
                    }
                  }
                } catch (e) {}
              }

              // remove sensor ids with no logs in waitForSyncLogs
              waitForSyncLogs.removeWhere((key, value) {
                return value.length == 0;
              });

              if (waterLogCount > 0) {
                // create upload request
                List<Cookie> cookies = await getSavedCookies();

                HttpClientResponse res = await postJson(
                  httpClient,
                  serverPrefix + '/uploadWaterLog',
                  cookies,
                  null,
                  {
                    'timestamp': currentTimestamp,
                    'data': waitForSyncLogs,
                  },
                );

                await setSavedCookies(res.cookies);

                // check if upload success
                if (res.statusCode == 200) {
                  Map<String, dynamic> resObj = await readJson(res);

                  if (resObj['status'] == 'success') {
                    // Moves uploaded water logs to the cache

                    Map<String, dynamic> cachedWaterLogs =
                        Map<String, dynamic>();

                    if (prefs.containsKey('cachedWaterLogs')) {
                      try {
                        cachedWaterLogs =
                            json.decode(prefs.getString('cachedWaterLogs'));
                      } catch (e) {}
                    }

                    String newCachedWaterLogsStr = json.encode(
                      combineCachedWaterLogJsonMap(
                        cachedWaterLogs,
                        waitForSyncLogs,
                      ),
                    );

                    await prefs.setString(
                      'cachedWaterLogs',
                      newCachedWaterLogsStr,
                    );

                    // Removes uploaded water logs from the app
                    for (String key in remainingLogs.keys) {
                      if (remainingLogs[key].length > 0) {
                        await prefs.setString(
                            'log_' + key, json.encode(remainingLogs[key]));
                      } else {
                        await prefs.setString('log_' + key, null);
                      }
                    }
                  } else {
                    throw 'request fail';
                  }
                } else {
                  throw 'request error';
                }
              }
            } catch (e) {
              failCount++;
              print(e);
            }
          } while (waterLogCount > 0 && failCount < WATERLOG_SYNC_RETRY);
        }

        // pull water logs from server
        {
          // create pull request
          List<Cookie> cookies = await getSavedCookies();

          HttpClientResponse res = await postJson(
            httpClient,
            serverPrefix + '/getWaterLog',
            cookies,
            null,
            {
              'syncHash': getCachedWaterLogsHash(),
            },
          );

          await setSavedCookies(res.cookies);

          // check if upload success
          if (res.statusCode == 200) {
            Map<String, dynamic> resObj = await readJson(res);

            if (resObj['status'] == 'success') {
              if (resObj['data'] != null) {
                await prefs.setString(
                  'cachedWaterLogs',
                  json.encode(
                    combineCachedWaterLogJsonMap(
                      resObj['data'],
                      {},
                    ),
                  ),
                );

                if (syncInterface != null) {
                  syncInterface.dataAvailable();
                }
              }
            }
          }
        }

        // Updates lastSync if the synchronisation is successful
        if (failCount < 3) {
          print('synced');
          lastSync = DateTime.now().millisecondsSinceEpoch;
          await prefs.setInt('lastSync', lastSync);
          if (loginInterface != null) {
            loginInterface.loginStatusChanged();
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> synchroniseLoop() async {
    await synchronise();
    Future.delayed(Duration(minutes: 5), synchroniseLoop);
  }
}

enum DataSynchroniserLoginEnum {
  LoginSuccess,
  LoginFail,
  LoginError,
  NoInternetLogin,
  NoInternetLogout,
}
