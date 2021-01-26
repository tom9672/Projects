#include <ArduinoBLE.h>
#include <Arduino_LSM9DS1.h>
#include <VL53L0X.h>
#include <Wire.h>
#include "sns_silib.h"

// from nrf52840 datasheet
#define UUID_ADDR                         ((unsigned char*)0x60)

#define MEASUREMENT_INTERVAL              15    // originally 3mins, changed to 15 seconds for testing
#define NUM_OF_WATER_LEVEL_SAMPLES        2400 // 5 days, 3 mins interval
#define WATER_LEVEL_HISTORY_PADDING_SIZE  (16 - (sizeof(WaterLevelStruct) % 16))



// water level data structure
typedef struct __attribute__((packed)) _WaterLevelStruct {
  unsigned int    rand;
  unsigned int    totalUpTimeInSeconds;
  unsigned int    syncedInSeconds;
  unsigned int    measurementIntervalInSeconds;
  unsigned char   tilted;
  unsigned short  numOfSamples;
  unsigned short  startIdx;
  unsigned char   waterLevels[NUM_OF_WATER_LEVEL_SAMPLES]; // data for 5 days
} WaterLevelStruct;


// application key
const unsigned char ENCRYPT_KEY[16] = {
  190, 212, 68, 82, 231, 230, 89, 139, 179, 56, 54, 200, 138, 223, 63, 255
};
const unsigned char ENCRYPT_IV[16] = {
  196, 8, 104, 48, 94, 165, 6, 152, 113, 204, 7, 136, 71, 115, 117, 95
};

CRYS_RND_State_t      rndState;
CRYS_RND_WorkBuff_t   workBuf;




// application variables
WaterLevelStruct    waterLevelStruct;
unsigned char       encryptedWaterLevelStruct[sizeof(WaterLevelStruct) + WATER_LEVEL_HISTORY_PADDING_SIZE];
unsigned int        waterLevelDropTimestamp = 0;
unsigned int        tiltedTimestamp = 0;
unsigned int        tiltedCheckTimestamp = 0;

// define SmartCup service and its properties
BLEService          SmartCupService("580b6c7f-bd17-4645-8d88-6cfc3a1941c5"); //uuid for smart cup
BLECharacteristic   waterLevelStructProperty1("aab3db8e-e579-4440-ac6c-8921fe2758b9", BLERead | BLENotify, 180);
BLECharacteristic   waterLevelStructProperty2("954367c7-2449-4bdc-8c03-720990781cbf", BLERead | BLENotify, 512);
BLECharacteristic   waterLevelStructProperty3("ba784d2e-c051-40b8-be94-aa86abd41321", BLERead | BLENotify, 512);
BLECharacteristic   waterLevelStructProperty4("1520eec0-b52c-4f32-9d07-82a7edc213bd", BLERead | BLENotify, 512);
BLECharacteristic   waterLevelStructProperty5("5639cf0b-7738-4b27-b4a8-f913328f270e", BLERead | BLENotify, 512);
BLECharacteristic   waterLevelStructProperty6("b96f7797-3186-45d7-aecc-a1d3a10833af", BLERead | BLENotify, sizeof(encryptedWaterLevelStruct) - 2228);
BLECharacteristic   waterLevelReadIndicator("305cffd3-32ba-4a73-960d-79ba4df7bc04", BLEWrite, 4);

// system variables
VL53L0X             tofSensor;
unsigned long       lastMillis = 0;
unsigned long long  upTimeInMillis = 0;
unsigned int        upTimeInSeconds = 0;
unsigned int        lastAdvertiseTimestamp = 0;




void generatePKCS7Padding(uint8_t* buf, uint16_t dataSize, uint8_t paddingSize) {
    for (uint16_t i = 0; i < paddingSize; i++) {
        *(buf + dataSize + i) = paddingSize;
    }
}

void encryptAndSendWaterLevelStruct() {
  // enable cryptocell hardware
  NRF_CRYPTOCELL->ENABLE = 1;
  delay(1);

  // update rand
  CRYS_RND_GenerateVector(&rndState, sizeof(waterLevelStruct.rand), (unsigned char*)&(waterLevelStruct.rand));

  // copy waterLevelHistory to encryption buffer
  memcpy(encryptedWaterLevelStruct, &waterLevelStruct, sizeof(WaterLevelStruct));

  // cryptocell library doesn't support padding, add padding manually
  generatePKCS7Padding(encryptedWaterLevelStruct, sizeof(WaterLevelStruct), WATER_LEVEL_HISTORY_PADDING_SIZE);


  // encrypt with cbc
  {
    size_t encryptedWaterLevelStructSize = sizeof(encryptedWaterLevelStruct);
    SaSiAesUserContext_t aesCtx;
    
    SaSi_AesInit(&aesCtx, SASI_AES_ENCRYPT, SASI_AES_MODE_CBC, SASI_AES_PADDING_NONE);
  
    SaSiAesUserKeyData_t aesKey;
    aesKey.pKey = (unsigned char*)ENCRYPT_KEY;
    aesKey.keySize = 16;
    SaSi_AesSetKey(&aesCtx, SASI_AES_USER_KEY, &aesKey, sizeof(aesKey));
    
    SaSi_AesSetIv(&aesCtx, (unsigned char*)ENCRYPT_IV);
  
    SaSi_AesFinish(
      &aesCtx, 
      sizeof(encryptedWaterLevelStruct), 
      encryptedWaterLevelStruct, sizeof(encryptedWaterLevelStruct),
      encryptedWaterLevelStruct, &encryptedWaterLevelStructSize
    );
  
    SaSi_AesFree(&aesCtx);
  }

  // disable cryptocell hardware
  //SaSi_LibFini(&rndState);
  NRF_CRYPTOCELL->ENABLE = 0;
  
  // update water level history property
  waterLevelStructProperty1.writeValue((unsigned char*)&encryptedWaterLevelStruct, 180);
  waterLevelStructProperty2.writeValue((unsigned char*)&encryptedWaterLevelStruct + 180, 512);
  waterLevelStructProperty3.writeValue((unsigned char*)&encryptedWaterLevelStruct + 692, 512);
  waterLevelStructProperty4.writeValue((unsigned char*)&encryptedWaterLevelStruct + 1204, 512);
  waterLevelStructProperty5.writeValue((unsigned char*)&encryptedWaterLevelStruct + 1716, 512);
  waterLevelStructProperty6.writeValue((unsigned char*)&encryptedWaterLevelStruct + 2228, sizeof(encryptedWaterLevelStruct) - 2228);
}



void turnOnSensors() {
  digitalWrite(PIN_ENABLE_SENSORS_3V3, HIGH);
  digitalWrite(PIN_ENABLE_I2C_PULLUP, HIGH);
}

void turnOffSensors() {
  digitalWrite(PIN_ENABLE_I2C_PULLUP, LOW);
  digitalWrite(PIN_ENABLE_SENSORS_3V3, LOW);
}

unsigned int checkTilted() {
  unsigned int ret = 1;

  unsigned int isIMUReady = 0;

  // roughly 3ms
  for (unsigned int i = 0; i < 80000; i++) {
    if (IMU.begin()) {
      isIMUReady = 1;
      break;
    }
  }

  if (isIMUReady) {

    isIMUReady = 0;

    // roughly 3ms
    for (unsigned int i = 0; i < 80000; i++) {
      if (IMU.gyroscopeAvailable()) {
        isIMUReady = 1;
        break;
      }
    }

    if (isIMUReady) {
      float ax, ay, az;

      if (IMU.readAcceleration(ax, ay, az)) {
        if (az >= 0.885 && az <= 0.915) {
          ret = 0;
        }
      }
    }

    IMU.end();
  }

  if (ret) {
    tiltedTimestamp = upTimeInSeconds;
  }

  return ret;
}

unsigned int getTofReading() {
  unsigned int isTOFReady = 0;

  Wire.begin();

  // roughly 3ms
  for (unsigned int i = 0; i < 80000; i++) {
    if (tofSensor.init()) {
      isTOFReady = 1;
      break;
    }
  }

  if (isTOFReady) {
    unsigned int sumDistance = 0;;
    float sumSignalPerSpad = 0;
    unsigned int numOfSamples = 0;

    for (unsigned int j = 0; j < 36 && numOfSamples < 30; j++) {
      unsigned int reading = tofSensor.readRangeSingleMillimeters();

      if (!tofSensor.timeoutOccurred()) {
        // check if the height is in range
        if (20 < reading && reading < 308) {

          // calculate signalPerSpad
          unsigned int signalRate = tofSensor.readReg16Bit(tofSensor.RESULT_RANGE_STATUS + 6);
          unsigned int effectiveSpadRtnCount = tofSensor.readReg16Bit(tofSensor.RESULT_RANGE_STATUS + 2);
          float signalPerSpad = (float)signalRate / effectiveSpadRtnCount * 256.0f;

          // filter reading if the signal per spad is too high as 
          // it usually shows inaccurate reading
          if (signalPerSpad < 150) {
            Serial.print("signalPerSpad:");
            Serial.println(signalPerSpad);

            sumDistance += reading;
            sumSignalPerSpad += signalPerSpad;

            numOfSamples++;
          } else {
            Serial.print("Failed signalPerSpad:");
            Serial.println(signalPerSpad);
          }
        } else {
          Serial.print("Failed reading:");
          Serial.println(reading);
        }
      }

      NRF_WDT->RR[0] = WDT_RR_RR_Reload;
    }

    if (numOfSamples > 28) {
      float avgDistance = (float)sumDistance / numOfSamples;
      float avgSignalPerSpad = sumSignalPerSpad / numOfSamples;

      Serial.print(avgDistance);
      Serial.print("\t");
      Serial.print(avgSignalPerSpad);

      // calculate calibration offset
      // calibration parameters are hardcoded at the moment
      float calDistance = 0;

      if (avgSignalPerSpad > 105.4f) {
        avgSignalPerSpad = 105.4f;
      }

      calDistance = (avgSignalPerSpad - 105.4f) * (((float)avgDistance - 35.0f) / 200.0f) * 1.0f;

      unsigned int convertedDistance = round((avgDistance + calDistance) / 1.25f);

      // out of range
      if (convertedDistance > 255) {
        Serial.println(0);
        return 0;
      } else {
        Serial.print("\t");
        Serial.println(convertedDistance);
        return convertedDistance;
      }
    }
  }

  Wire.end();
  
  return 0;
}

void measureWaterLevel() {
  // turn on sensors
  turnOnSensors();

  unsigned char currentWaterLevel = 0;

  waterLevelStruct.tilted = checkTilted();

  if (waterLevelStruct.tilted) {
    // reset tilt check timer
    tiltedCheckTimestamp = upTimeInSeconds;
  }
  // If the sensor is tilted in the last 60 seconds,
  // skip one measurement to allow the water to stabilise
  else if (tiltedTimestamp < upTimeInSeconds - 60) {
    // turn on power led to indicate that
    // the mcu is measuring the water level
    digitalWrite(LEDG, LOW);
    
    // get TOF reading
    currentWaterLevel = getTofReading();

    // turn off power led when done
    digitalWrite(LEDG, HIGH);
  }

  // add measurement to waterLevelHistory
  if (waterLevelStruct.numOfSamples == NUM_OF_WATER_LEVEL_SAMPLES) {
    waterLevelStruct.waterLevels[waterLevelStruct.startIdx] = currentWaterLevel;
    waterLevelStruct.startIdx++;
    waterLevelStruct.startIdx %= NUM_OF_WATER_LEVEL_SAMPLES;
  } else {
    waterLevelStruct.waterLevels[waterLevelStruct.numOfSamples] = currentWaterLevel;
    waterLevelStruct.numOfSamples++;
  }
  
  // turn off sensors
  turnOffSensors();

  // update up time
  waterLevelStruct.totalUpTimeInSeconds = upTimeInSeconds;

  // encrypt and send water level history
  encryptAndSendWaterLevelStruct();

  // reminder
  if (waterLevelStruct.numOfSamples >= 19) {
    // get last hour water level
    short last19WaterLevel[19] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    unsigned int numOfSamplesRead = 0;

    for (unsigned int i = waterLevelStruct.numOfSamples - 19; i < waterLevelStruct.numOfSamples; i++) {
      unsigned int waterLevelIdx = (waterLevelStruct.startIdx + i) % NUM_OF_WATER_LEVEL_SAMPLES;
      unsigned char currentWaterLevel = waterLevelStruct.waterLevels[waterLevelIdx];

      if (currentWaterLevel > 0) {
        last19WaterLevel[numOfSamplesRead] = currentWaterLevel;
        numOfSamplesRead++;
      }
    }

    if (numOfSamplesRead >= 5) {

      short cummulativeChange = 0;
      short cummulativeCount = 0;

      // get cummulative water level change
      for (unsigned int idx = 1; idx < numOfSamplesRead; idx++) {

        short previousValue = last19WaterLevel[idx - 1];
        short currentValue = last19WaterLevel[idx];

        cummulativeChange = (currentValue - previousValue) + cummulativeChange;
        cummulativeCount++;

        // if the cummulative water level change is significant enough
        if (cummulativeChange > 7 || cummulativeChange < -8) {

          // positive value means water level decreased
          if (cummulativeChange > 0) {
            waterLevelDropTimestamp = upTimeInSeconds;
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
    }
  }
}


void setup() {
  Serial.begin(115200);
  
  // Configure WDT to prevent hardware fault bug in the ArduinoBLE library
  NRF_WDT->CONFIG         = 0x01;   // Configure WDT to run when CPU is asleep
  NRF_WDT->CRV            = 262143; // Timeout set to 8 seconds, timeout[s] = (CRV-1)/32768
  NRF_WDT->RREN           = 0x01;   // Enable the RR[0] reload register
  NRF_WDT->TASKS_START    = 1;      // Start WDT

  // turn off peripherials
  turnOffSensors();
  digitalWrite(LED_PWR, LOW);
  digitalWrite(LED_BUILTIN, LOW);

  // enable low power mode
  NRF_POWER->TASKS_LOWPWR = 1;

  // turn on greed and red leds to indicate the system is initialising
  digitalWrite(LEDG, LOW);
  digitalWrite(LEDR, LOW);

  // initialise crypto library
  NRF_CRYPTOCELL->ENABLE = 1;
  delay(5);
  SaSi_LibInit(&rndState, &workBuf);
  NRF_CRYPTOCELL->ENABLE = 0;

  // initialise waterLevelHistory
  waterLevelStruct.measurementIntervalInSeconds = MEASUREMENT_INTERVAL;
  waterLevelStruct.totalUpTimeInSeconds = 0;
  waterLevelStruct.syncedInSeconds = 0;
  waterLevelStruct.numOfSamples = 0;
  waterLevelStruct.startIdx = 0;
  encryptAndSendWaterLevelStruct();

  // initialise device name
  String deviceName = "SmartCup-";
  char deviceMacStr[8];

  unsigned int bitProcessed = 0;

  // 6 bytes MAC address to base64
  for (int octIdx = 0; octIdx < 2; octIdx++) {
    unsigned int octValue = *(unsigned int*)((unsigned char*)NRF_FICR->DEVICEADDR + (octIdx * 3));
    octValue &= 0x00FFFFFF;
    
    for (int hexIdx = 3; hexIdx >= 0; hexIdx--) {
      unsigned int hexValue = (octValue >> (hexIdx * 6)) & 0x3F;

      char value = 0;
      
      if (hexValue < 10) {
         deviceName += char(hexValue + 48);
      } else if (hexValue < 36) {
         deviceName += char(hexValue - 10 + 65);
      } else if (hexValue < 62) {
         deviceName += char(hexValue - 36 + 97);
      } else {
         deviceName += char(hexValue - 62 + 35);
      }
    }
  }

  while (!BLE.begin());

  // setup bluetooth name and appearance
  BLE.setLocalName(deviceName.c_str());
  BLE.setDeviceName(deviceName.c_str());

  // setup bluetooth services
  SmartCupService.addCharacteristic(waterLevelStructProperty1);
  SmartCupService.addCharacteristic(waterLevelStructProperty2);
  SmartCupService.addCharacteristic(waterLevelStructProperty3);
  SmartCupService.addCharacteristic(waterLevelStructProperty4);
  SmartCupService.addCharacteristic(waterLevelStructProperty5);
  SmartCupService.addCharacteristic(waterLevelStructProperty6);
  SmartCupService.addCharacteristic(waterLevelReadIndicator);
  BLE.addService(SmartCupService);
  BLE.setAdvertisedService(SmartCupService);

  // set bluetooth parameters
  BLE.setAdvertisingInterval(1500); // slow down the advertisement

  // turn off leds to indicate that
  // bluetooth is initialised
  digitalWrite(LEDG, HIGH);
  digitalWrite(LEDR, HIGH);
  
  // start advertising
  BLE.advertise();
}


void loop() {
  // update system up time
  {
    unsigned long currentMillis = millis();
    
    if (currentMillis > lastMillis) {
      upTimeInMillis += currentMillis - lastMillis;
    } else if (lastMillis > currentMillis) {
      upTimeInMillis += 0xFFFFFFFF - lastMillis;
      upTimeInMillis += currentMillis;
    }
  
    lastMillis = currentMillis;

    upTimeInSeconds = upTimeInMillis / 1000;
  }

  // application events
  {
    // periodically measure water level every MEASUREMENT_INTERVAL seconds
    if (upTimeInSeconds >= waterLevelStruct.totalUpTimeInSeconds + MEASUREMENT_INTERVAL) {
      measureWaterLevel();
    }
    // check if the cup is tilted when idle
    else {
      // deufault tilt checking frequency is 2 seconds
      unsigned int tiltedCheckTimeout = 2;

      // if the cup is tilted, increase the checking frequency to 1 second
      if (waterLevelStruct.tilted) {
        tiltedCheckTimeout = 1;
      }

      // if tilt check timeout, check IMU
      if (upTimeInSeconds > tiltedCheckTimestamp + tiltedCheckTimeout) {
        turnOnSensors();
        waterLevelStruct.tilted = checkTilted();
        turnOffSensors();
        tiltedCheckTimestamp = upTimeInSeconds;
      }
    }

    // turn on led if the bottle is tilted
    if (waterLevelStruct.tilted) {
      digitalWrite(LEDR, LOW);

    }
    // blink the led to remind the user to drink water
    // if the last water level has dropped for an hour
    else if (upTimeInSeconds > waterLevelDropTimestamp + 60 * 60) {
      if (upTimeInSeconds % 2 == 0) {
        digitalWrite(LEDR, LOW);
      } else {
        digitalWrite(LEDR, HIGH);
      }
    }
    // turn off the led otherwise
    else {
      digitalWrite(LEDR, HIGH);
    }
    
  
    // fix for ble stop advertising after disconnect 
    if (upTimeInSeconds > lastAdvertiseTimestamp + 30) {
      if (!BLE.connected()) {
        BLE.advertise();
      }
      lastAdvertiseTimestamp = upTimeInSeconds;
    }
  
    // process ble events
    BLE.poll();

    unsigned int signal = ~waterLevelStruct.rand;

    // update synchronised timestamp to avoid duplicated readings
    // when a signal is received 
    if (BLE.connected()) {
      waterLevelReadIndicator.readValue(&signal, 4);

      if (signal == waterLevelStruct.rand) {
        waterLevelStruct.syncedInSeconds = waterLevelStruct.totalUpTimeInSeconds;
      }

      signal = ~waterLevelStruct.rand;
      waterLevelReadIndicator.writeValue(&signal, 4);
    }

    // Reset WDT
    NRF_WDT->RR[0] = WDT_RR_RR_Reload;
  
    // sleep and wait for event
    if (upTimeInSeconds > 5) {
      __SEV();
      __WFE();
      __WFE();
    }
  }
}
