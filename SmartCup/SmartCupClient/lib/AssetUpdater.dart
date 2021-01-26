import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'HTTPHelper.dart';

class AssetUpdaterDrawer {
  void updateStarted() {}
  void updateCompleted() {}
}

class AssetUpdater {
  final serverPrefix;

  final HttpClient httpClient = HttpClient();
  String supportPath;

  String oldVersion;
  bool _updated = false;

  bool _oldVersionAvailable = false;
  bool _initFailed = false;
  bool _webStarted = false;

  AssetUpdaterDrawer drawer;

  AssetUpdater({@required this.serverPrefix}) {
    assert(serverPrefix != null);
    httpClient.connectionTimeout = Duration(seconds: 30);
  }

  bool get updated {
    return _updated;
  }

  bool get oldVersionAvailable {
    return _oldVersionAvailable;
  }

  bool get initFailed {
    return _initFailed;
  }

  String get assetsPath {
    return supportPath + '/assets';
  }

  void setDrawer(AssetUpdaterDrawer newDrawer) {
    drawer = newDrawer;
  }

  Future<void> init() async {
    try {
      if (supportPath == null) {
        supportPath = (await getApplicationSupportDirectory()).path;
        await Directory(assetsPath).create(recursive: true);
      }

      if (supportPath == null) {
        throw 'storage error';
      }

      File localVersionFile = File(assetsPath + '/version');
      if (await localVersionFile.exists()) {
        oldVersion = await localVersionFile.readAsString();
        _oldVersionAvailable = true;
      }

      update();
    } catch (e) {
      _initFailed = true;
    }
  }

  Future<void> update() async {
    _updated = false;

    if (drawer != null) {
      drawer.updateStarted();
    }

    bool isCheckRequired = true;
    bool isUpdateRequired = true;
    String newVersion;

    for (int i = 0; i < 3 && !_updated; i++) {
      try {
        if (isCheckRequired) {
          HttpClientRequest req = await httpClient.getUrl(
            Uri.parse(serverPrefix + '/getLatestWebAssetsVersion'),
          );

          HttpClientResponse res = await req.close();
          if (res.statusCode != 200) {
            throw 'connection error';
          }

          Map<String, dynamic> assetsVersionJson = await readJson(res);

          if (assetsVersionJson['status'] != 'success') {
            throw 'connection error';
          }

          newVersion = assetsVersionJson['data'];
          isCheckRequired = false;

          if (newVersion == oldVersion) {
            _updated = true;
            isUpdateRequired = false;
          }
        }

        if (!isCheckRequired && isUpdateRequired) {
          HttpClientRequest req = await httpClient.getUrl(
            Uri.parse(serverPrefix + '/downloadLatestWebAssets'),
          );

          HttpClientResponse res = await req.close();

          if (res.statusCode != 200) {
            throw 'connection error';
          }

          Archive archive = ZipDecoder().decodeBytes(await readResponse(res));

          for (ArchiveFile file in archive) {
            String filename = assetsPath + '/' + file.name;

            if (file.isFile) {
              File outFile = File(filename);
              outFile = await outFile.create(recursive: true);
              await outFile.writeAsBytes(file.content);
            }
          }

          _updated = true;
          _oldVersionAvailable = true;
          oldVersion = newVersion;

          if (drawer != null) {
            drawer.updateCompleted();
          }
        }
      } catch (e) {
        print(e);
      }
    }

    if (!_oldVersionAvailable) {
      Future.delayed(Duration(seconds: 10), update);
    } else if (!_webStarted) {}
  }
}
