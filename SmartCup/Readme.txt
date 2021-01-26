The system is divided into three parts: 
- Sensor firmware (in SmartCupFirmware directory)
- Server app (in SmartCupWeb directory)
- Mobile app (in SmartCupClient directory)


=============Sensor firmware=============
The sensor firmware is written using Arduino IDE.
To compile the firmware, you will need to 
install the following dependencies:
- "Arduino nRF528x Boards (Mbed OS)" from Boards Manager
- "ArduinoBLE" from Library Manager
- "Arduino_LSM9DS1" from Library Manager
- "VL53L0X" from Library Manager


=============Server app=============
The server app is a Nodejs application, so you will need to
install nodejs to run the server app.

"config.js" contains the configuration of the app, 
such as port number and the database path.

"html" directory contains the user interface of the application.

"db" directory contains sample database files.

"api" directory contains the code of the server app. 

To run the server app, you need to set the working directory 
to the "api" directory first.

If this is the first time you run the app, you will need to run 
"npm install" command to install all dependencies.

Then run "node api.js" to run the app.


=============Mobile app=============
The mobile app is developed using Flutter framework with Visual Studio Code.

To setup the environment, please refer to this guide:
https://flutter.dev/docs/get-started/install

After you have installed Flutter and the Flutter plugin for Visual Studio Code,
you can simply drag the directory to Visual Studio Code and run the app.
