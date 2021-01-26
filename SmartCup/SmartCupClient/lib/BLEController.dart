import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:background_fetch/background_fetch.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'DataSynchroniser.dart';

class BLEControllerInterface {
  void scanResultsReady(List<BLEResult> scanResults) {}
}

class BLEResult {
  Peripheral device;
  // ignore: avoid_init_to_null
  Service service = null;
  String name;
  String id;
  bool isConnected = false;
  bool saved;
  bool isTilted = false;
  int rssi;
  int lostCount;

  BLEResult({
    this.device,
    this.name,
    this.id,
    this.saved,
    this.rssi,
    this.lostCount,
  })  : assert(name != null),
        assert(id != null),
        assert(saved != null),
        assert(rssi != null),
        assert(lostCount != null);
}

class SensorReading {
  final int d;
  final int timestamp;
  const SensorReading({this.d, this.timestamp});
}

class BLEController {
  static const String SMARTCUP_SERVICE_UUID =
      '580b6c7f-bd17-4645-8d88-6cfc3a1941c5';
  static const String SMARTCUP_PROPERTY1_UUID =
      'aab3db8e-e579-4440-ac6c-8921fe2758b9';
  static const String SMARTCUP_PROPERTY2_UUID =
      '954367c7-2449-4bdc-8c03-720990781cbf';
  static const String SMARTCUP_PROPERTY3_UUID =
      'ba784d2e-c051-40b8-be94-aa86abd41321';
  static const String SMARTCUP_PROPERTY4_UUID =
      '1520eec0-b52c-4f32-9d07-82a7edc213bd';
  static const String SMARTCUP_PROPERTY5_UUID =
      '5639cf0b-7738-4b27-b4a8-f913328f270e';
  static const String SMARTCUP_PROPERTY6_UUID =
      'b96f7797-3186-45d7-aecc-a1d3a10833af';
  static const String SMARTCUP_READ_INDICATOR_UUID =
      '305cffd3-32ba-4a73-960d-79ba4df7bc04';

  static const int SCAN_CYCLE_INTERVAL = 5;
  static const int SCAN_CYCLE_ACTIVE = 4;
  static const int SCAN_CYCLE_BACKGROUND = 24;

  final AES SmartCupEncrypt = AES(
    Key(
      Uint8List.fromList(
        [
          190,
          212,
          68,
          82,
          231,
          230,
          89,
          139,
          179,
          56,
          54,
          200,
          138,
          223,
          63,
          255,
        ],
      ),
    ),
    mode: AESMode.cbc,
  );
  final IV iv = IV(
    Uint8List.fromList(
      [
        196,
        8,
        104,
        48,
        94,
        165,
        6,
        152,
        113,
        204,
        7,
        136,
        71,
        115,
        117,
        95,
      ],
    ),
  );

  final SharedPreferences prefs;
  final DataSynchroniser dataSynchroniser;
  BleManager bleManager;

  int currentScanCycles = 0;
  int maxScanCycles = SCAN_CYCLE_BACKGROUND;
  Timer scanTimeoutTimer;

  BLEControllerInterface observer;
  LinkedHashMap<String, BLEResult> cachedScanResults;

  BLEController({
    @required this.prefs,
    @required this.dataSynchroniser,
  }) {
    assert(prefs != null);
    assert(dataSynchroniser != null);
    bleManager = BleManager();
    cachedScanResults = LinkedHashMap<String, BLEResult>();
  }

  Future<void> init() async {
    try {
      // load saved devices
      if (prefs.containsKey('savedDevices')) {
        Map<String, dynamic> savedDevices =
            json.decode(prefs.getString('savedDevices'));

        savedDevices.forEach((currentDeviceId, currentDeviceName) {
          Map<String, dynamic> typedCurrentDeviceName = currentDeviceName;

          cachedScanResults[currentDeviceId] = BLEResult(
            name: typedCurrentDeviceName['name'].toString(),
            id: currentDeviceId,
            device: null,
            rssi: -1000,
            lostCount: 4,
            saved: true,
          );
        });
      }

      await bleManager.createClient();
      await bleManager.setLogLevel(LogLevel.none);

      await scanPeripheralLoop();
    } catch (e) {
      print(e);
    }
  }

  BLEResult addPeripheral({
    @required Peripheral peripheral,
    @required bool isConnected,
    @required int rssi,
  }) {
    String id = peripheral.identifier;
    if (peripheral.name.startsWith('SmartCup-')) {
      if (cachedScanResults.containsKey(id)) {
        cachedScanResults[id].name = peripheral.name;
        cachedScanResults[id].id = id;
        cachedScanResults[id].lostCount = 0;
        cachedScanResults[id].rssi = rssi;
        cachedScanResults[id].device = peripheral;
        cachedScanResults[id].isConnected = isConnected;
      } else {
        cachedScanResults[id] = BLEResult(
          name: peripheral.name,
          id: id,
          lostCount: 0,
          device: peripheral,
          rssi: rssi,
          saved: false,
        );
      }

      return cachedScanResults[id];
    }

    return null;
  }

  Future<void> pullWaterLevelData(
      Peripheral device, CharacteristicWithValue c1) async {
    try {
      if (c1 == null) {
        c1 = await device.readCharacteristic(
          SMARTCUP_SERVICE_UUID,
          SMARTCUP_PROPERTY1_UUID,
        );
      }

      CharacteristicWithValue c2 = await device.readCharacteristic(
        SMARTCUP_SERVICE_UUID,
        SMARTCUP_PROPERTY2_UUID,
      );

      CharacteristicWithValue c3 = await device.readCharacteristic(
        SMARTCUP_SERVICE_UUID,
        SMARTCUP_PROPERTY3_UUID,
      );

      CharacteristicWithValue c4 = await device.readCharacteristic(
        SMARTCUP_SERVICE_UUID,
        SMARTCUP_PROPERTY4_UUID,
      );

      CharacteristicWithValue c5 = await device.readCharacteristic(
        SMARTCUP_SERVICE_UUID,
        SMARTCUP_PROPERTY5_UUID,
      );
      CharacteristicWithValue c6 = await device.readCharacteristic(
        SMARTCUP_SERVICE_UUID,
        SMARTCUP_PROPERTY6_UUID,
      );

      Uint8List bytes = SmartCupEncrypt.decrypt(
        Encrypted(
          Uint8List.fromList(
              c1.value + c2.value + c3.value + c4.value + c5.value + c6.value),
        ),
        iv: iv,
      );

      // Parse data from the sensor
      //
      //typedef struct __attribute__((packed)) _WaterLevelStruct {
      //  unsigned int    rand;
      //  unsigned int    totalUpTimeInSeconds;
      //  unsigned int    syncedInSeconds;
      //  unsigned int    measurementIntervalInSeconds;
      //  unsigned char   tilted;
      //  unsigned short  numOfSamples;
      //  unsigned short  startIdx;
      //  unsigned char   waterLevels[NUM_OF_WATER_LEVEL_SAMPLES]; // data for 5 days
      //} WaterLevelStruct;

      ByteData byteData = bytes.buffer.asByteData();
      int totalUpTimeInSeconds = byteData.getUint32(4, Endian.little);
      int syncedInSeconds = byteData.getUint32(8, Endian.little);
      int measurementIntervalInSeconds = byteData.getUint32(12, Endian.little);
      int tilted = byteData.getUint8(16);
      int numOfSamples = byteData.getUint16(17, Endian.little);
      int startIdx = byteData.getUint16(19, Endian.little);

      cachedScanResults[device.identifier].isTilted =
          tilted == 1 ? true : false;

      int measurementInterval = measurementIntervalInSeconds * 1000;

      if (numOfSamples > 1) {
        int currentTimestamp = DateTime.now().millisecondsSinceEpoch;

        BLEResult result = cachedScanResults[device.identifier];

        int lastSyncTimestamp = currentTimestamp -
            (totalUpTimeInSeconds * 1000) +
            (syncedInSeconds * 1000);

        int waitForSyncTimestamp =
            currentTimestamp - (totalUpTimeInSeconds * 1000);

        if (totalUpTimeInSeconds / measurementInterval >= numOfSamples) {
          waitForSyncTimestamp =
              currentTimestamp - (measurementInterval * numOfSamples);
        }

        if (waitForSyncTimestamp < lastSyncTimestamp) {
          waitForSyncTimestamp = lastSyncTimestamp;
        }

        // calculate number of readings
        int measurementToRead =
            ((currentTimestamp - waitForSyncTimestamp) / measurementInterval)
                .floor();

        // Checks if the previous water level is available to read
        //
        // The previous water level is only available
        // if there are at least two samples in the buffer and
        // it is not overwritten
        if (numOfSamples > 1 && measurementToRead < numOfSamples) {
          measurementToRead += 1;
        }

        List<SensorReading> validReadings = List<SensorReading>();

        if (measurementToRead > 1 && numOfSamples >= measurementToRead) {
          for (int i = numOfSamples - measurementToRead;
              i < numOfSamples;
              i++) {
            int currentIdx = (i + startIdx) % numOfSamples;
            int currentValue = byteData.getUint8(21 + currentIdx);

            if (currentValue > 0) {
              SensorReading reading = SensorReading(
                d: currentValue,
                timestamp: currentTimestamp -
                    ((numOfSamples - i) * measurementInterval),
              );
              validReadings.add(reading);
            }
          }
        }

        if (validReadings.length > 1) {
          int cummulativeChange = 0;
          int cummulativeCount = 0;

          List<WaterLog> newLogObjList = List<WaterLog>();

          for (int i = 1; i < validReadings.length; i++) {
            SensorReading previousItem = validReadings[i - 1];
            SensorReading currentItem = validReadings[i];

            cummulativeChange =
                (currentItem.d - previousItem.d) + cummulativeChange;
            cummulativeCount++;

            // if the cummulative water level change is significant enough
            if (cummulativeChange > 7 || cummulativeChange < -8) {
              // positive value means water level decreased
              if (cummulativeChange > 0) {
                double heightDifferent = cummulativeChange.toDouble() * 1.25;

                // assume the diameter of the bottle is 2.8cm
                WaterLog newLogObj = WaterLog(
                  t: currentItem.timestamp,
                  v: ((pi * 28 * 28 * heightDifferent) / 1000).round(),
                );

                newLogObjList.add(newLogObj);
              }

              cummulativeChange = 0;
              cummulativeChange = 0;
            } else if (cummulativeCount > 3) {
              // reset cummulative variables if
              // there is no significant changes  in the last 3 reading
              cummulativeChange = 0;
              cummulativeCount = 0;
            }
          }

          if (newLogObjList.length > 0) {
            await dataSynchroniser.addNewLog(
              id: result.name,
              newLogObjList: newLogObjList,
            );

            print('writing');

            await Future.delayed(Duration(seconds: 1));

            for (int i = 0; i < 5; i++) {
              await Future.delayed(Duration(milliseconds: 200 * i), () async {
                await device.writeCharacteristic(
                  SMARTCUP_SERVICE_UUID,
                  SMARTCUP_READ_INDICATOR_UUID,
                  Uint8List.fromList([
                    byteData.getUint8(0),
                    byteData.getUint8(1),
                    byteData.getUint8(2),
                    byteData.getUint8(3),
                  ]),
                  true,
                );
              });
            }

            print('done');
          }
        }
        print(bytes);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> setupWaterLevelMonitor(Peripheral device) async {
    try {
      if (await device.isConnected()) {
        await device.discoverAllServicesAndCharacteristics();

        device
            .monitorCharacteristic(
                SMARTCUP_SERVICE_UUID, SMARTCUP_PROPERTY1_UUID)
            .listen((c1) {
          pullWaterLevelData(device, c1);
        });
      }
    } catch (e) {}
  }

  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.location.isGranted == false) {
        if (await Permission.location.request() == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
  }

  Future<void> scanPeripheralLoop() async {
    if (currentScanCycles == 0) {
      if (scanTimeoutTimer != null) {
        scanTimeoutTimer.cancel();
        scanTimeoutTimer = null;
      }
      await bleManager.stopPeripheralScan();
      if (await checkPermissions()) {
        print('start scan');
        bleManager.startPeripheralScan(
          uuids: [
            SMARTCUP_SERVICE_UUID,
          ],
        ).listen((result) async {
          print(result.peripheral.name);

          BLEResult bleResult = addPeripheral(
            peripheral: result.peripheral,
            isConnected: false,
            rssi: result.rssi,
          );

          Future.delayed(Duration(seconds: 1), () async {
            try {
              if (bleResult != null && bleResult.saved) {
                if (!(await bleResult.device.isConnected())) {
                  await bleResult.device
                      .connect(timeout: Duration(seconds: 20));
                  bleResult.isConnected = await bleResult.device.isConnected();
                  notifyObserver();
                }

                setupWaterLevelMonitor(bleResult.device);
              }
            } catch (e) {
              print(e);
            }
          });

          cachedScanResults.forEach((key, value) {
            value.lostCount++;
          });

          cachedScanResults.removeWhere((key, value) =>
              ((value.lostCount > 1) && (value.saved == false)));

          notifyObserver();
        });
      }

      scanTimeoutTimer = Timer(
        Duration(seconds: SCAN_CYCLE_INTERVAL * SCAN_CYCLE_ACTIVE - 1),
        () {
          scanTimeoutTimer = null;
          print('stop scan');
          bleManager.stopPeripheralScan();
        },
      );

      currentScanCycles = maxScanCycles;
    } else {
      currentScanCycles--;
    }

    Future.delayed(
      Duration(seconds: SCAN_CYCLE_INTERVAL),
      scanPeripheralLoop,
    );
  }

  List<BLEResult> getCachedResults() {
    return List<BLEResult>.from(cachedScanResults.values);
  }

  Future<void> savePrefs() async {
    try {
      Map<String, dynamic> savedDevices;

      if (prefs.containsKey('savedDevices')) {
        savedDevices = json.decode(prefs.getString('savedDevices'));
      } else {
        savedDevices = Map<String, Map<String, String>>();
      }

      cachedScanResults.forEach((currentDeviceId, result) {
        if (result.saved) {
          if (!savedDevices.containsKey(currentDeviceId)) {
            savedDevices[currentDeviceId] = Map<String, dynamic>();
          }

          Map<String, dynamic> currentDeviceObj = savedDevices[currentDeviceId];
          currentDeviceObj['name'] = result.name;
        } else if (savedDevices.containsKey(currentDeviceId)) {
          savedDevices.remove(currentDeviceId);
        }
      });

      await prefs.setString('savedDevices', json.encode(savedDevices));
    } catch (e) {
      print(e);
    }
  }

  Future<bool> checkAndSaveDevice(Peripheral device) async {
    try {
      await device.connect(timeout: Duration(seconds: 20));

      if (await device.isConnected()) {
        cachedScanResults[device.identifier].saved = true;
        cachedScanResults[device.identifier].isConnected = true;
        await savePrefs();
        await setupWaterLevelMonitor(device);
        return true;
      }
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<void> deleteDevice(String id) async {
    try {
      if (cachedScanResults.containsKey(id)) {
        cachedScanResults[id].saved = false;
        await savePrefs();

        if (cachedScanResults[id].device != null) {
          await cachedScanResults[id].device.disconnectOrCancelConnection();
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void startScanning() {
    currentScanCycles = 0;
    maxScanCycles = SCAN_CYCLE_ACTIVE;
  }

  void stopScanning() {
    currentScanCycles = SCAN_CYCLE_BACKGROUND;
    maxScanCycles = SCAN_CYCLE_BACKGROUND;
  }

  void setObserver(BLEControllerInterface newObserver) {
    this.observer = newObserver;
  }

  void notifyObserver() {
    if (observer != null) {
      observer.scanResultsReady(getCachedResults());
    }
  }
}
