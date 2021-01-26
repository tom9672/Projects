const path = require('path');
const crypto = require('crypto');
const fs = require('fs-extra');
const archiver = require('archiver');
const validate = require('jsonschema').validate;

const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');

const SmartCupConfig = require('./../config.js');
const e = require('express');

let _loginCreds = [];

// create a zip file from a directory
function zipDirectory(source, out) {
    const archive = archiver('zip', { zlib: { level: 5 }});
    const stream = fs.createWriteStream(out);

    return new Promise((resolve, reject) => {
        archive
            .directory(source, false)
            .on('error', err => reject(err))
            .pipe(stream);
  
        stream.on('close', () => {
            resolve();
        });
        archive.finalize();
    });
}

// get user hash by username
function getUserHash(username) {
    let hashObj = crypto.createHash('sha256');
    hashObj.update(Buffer.concat([Buffer.from(username), Buffer.from(SmartCupConfig.USER_PATH_SALT)]));
    
    return hashObj.digest('hex');
}

// get water log data of a user
async function getUserWaterLog(username) {
    let obj = {};

    try {
        obj = await fs.readJSON(path.resolve(SmartCupConfig.DB_PATH, './' + getUserHash(username) + '.json'));
    } catch (e) {}

    return obj;
}

// save water log data of a user
async function writeUserWaterLog(username, obj) {
    await fs.writeJSON(path.resolve(SmartCupConfig.DB_PATH, './' + getUserHash(username) + '.json'), obj, {EOL: ''});
}


// verify login session
async function verifySession(req, res, updateLastAccess) {
    let ret = null;

    try {
        let currentTimestamp = (new Date()).getTime();

        if (req.cookies instanceof Object && req.cookies[SmartCupConfig.COOKIE_NAME]) {
            for (let loginCredIdx in _loginCreds) {
                let credToVerify = _loginCreds[loginCredIdx];
                if (currentTimestamp < credToVerify.last_access + SmartCupConfig.COOKIE_TIMEOUT) {
                    if (req.cookies[SmartCupConfig.COOKIE_NAME].toString() === credToVerify.session_id) {
                        let db = await fs.readJSON(SmartCupConfig.USER_JSON_PATH);
        
                        if (db instanceof Array) {
                            for (let dbIdx in db) {
                                let item = db[dbIdx];
                                if (
                                    (item.username === credToVerify.username) &&
                                    (item.pw === credToVerify.pw)
                                ) {
                                    if (updateLastAccess === true) {
                                        let newCredToVerify = Object.assign({}, credToVerify);
                                        newCredToVerify.session_id = (crypto.randomBytes(32)).toString('hex');
                                        newCredToVerify.last_access = currentTimestamp;
                                        res.cookie(SmartCupConfig.COOKIE_NAME, newCredToVerify.session_id, { maxAge: SmartCupConfig.COOKIE_TIMEOUT, httpOnly: true, sameSite: 'strict' });
                                        _loginCreds.push(newCredToVerify);
                                        ret = newCredToVerify;

                                        // delete old session in 60 seconds
                                        credToVerify.last_access = currentTimestamp - SmartCupConfig.COOKIE_TIMEOUT + 60;
                                        throw '';
                                    }
                                    ret = credToVerify;
                                    throw '';
                                }
                            }
                        }
                    }
                } 
            }
        }
    } catch (e) { }

    return ret;
}


// define html directory
const htmlDirectory = path.resolve(__dirname, './../html');

// create a express instance
const app = express();
// disable 'x-powered-by' header
app.disable('x-powered-by');

// define static files
app.use('/css', express.static(htmlDirectory + '/css'));
app.use('/js', express.static(htmlDirectory + '/js'));
app.use('/img', express.static(htmlDirectory + '/img'));

// apply cookie parser and body parser middlewares
app.use(cookieParser(SmartCupConfig.COOKIE_SECRET));
app.use(bodyParser.json({limit: '200kb'}));

// start listening to the defined port
app.listen(SmartCupConfig.SERVER_PORT, function () {
    console.log('SmartCup API started.')
});

// index page
// If the user is signed in, shows the index page, 
// otherwise, shows the login page.
app.get('/', async (req, res) => {
    try {
        let cred = await verifySession(req, res, true);

        if (cred instanceof Object) {
            res.sendFile(htmlDirectory + '/index.html');
        } else {
            res.sendFile(htmlDirectory + '/login.html');
        }

    } catch (e) {
        res.status(500).send();
    }
});

// mobile app update api
app.get('/getLatestWebAssetsVersion', async (req, res) => {
    try {
        let versionString = await fs.readFile(htmlDirectory + '/version', 'utf8');
        res.send({
            status: 'success',
            data: versionString
        });
    } catch (e) {
        res.send({
            status: 'fail',
            reason: 'internal error'
        });
    }
});

// mobile app update api
app.get('/downloadLatestWebAssets', async (req, res) => {
    try {
        let assetsVersionString = await fs.readFile(htmlDirectory + '/version', 'utf8');
        let generatedVersionString = '';

        try {
            generatedVersionString = await fs.readFile('./generated_assets//version', 'utf8');
        } catch (e) {}

        let zipPath = path.resolve(__dirname, './generated_assets/web_assets.zip');

        // check if the compressed asset is up to date
        if (assetsVersionString !== generatedVersionString) {
            await zipDirectory(htmlDirectory, zipPath);
            await fs.writeFile('./generated_assets//version', assetsVersionString);
        }

        if (await fs.pathExists(zipPath)) {
            res.sendFile(zipPath);
        } else {
            throw 'zip doesnt exist.';
        }
    } catch (e) {
        console.log(e);
        res.status(500).send();
    }
});

// register or sign in api
//
// request body structure:
// {username: "user email address", pw: "user password"}
app.post('/registerOrSignin', async (req, res) => {
    let ret = {
        'status': 'fail',
        'reason': 'unknown'
    }

    try {
        let cred = await verifySession(req, res, true);

        if (cred instanceof Object) {
            ret = {
                'status': 'success'
            };

            throw '';
        }

        // check if the request data is in correct format
        if (!(
            req.body && 
            req.body.username &&
            req.body.pw &&
            validate(req.body.username, {type: 'string', format: 'email'}).errors.length == 0 && 
            validate(req.body.pw, {type: 'string', "minLength": 8, "maxLength": 24}).errors.length == 0
        )) {
            ret = {
                'status': 'fail',
                'reason': 'invalid request'
            }

            throw '';
        }

        // limit the server to handle 2000 sessions
        if (_loginCreds.length > 2000) {
            ret = {
                'status': 'fail',
                'reason': 'internal error'
            }

            throw '';
        }

        let username = req.body.username;
        let pw = req.body.pw;

        let userDb = await fs.readJSON(SmartCupConfig.USER_JSON_PATH);

        if (userDb instanceof Array) {
            let currentTimestamp = (new Date()).getTime();

            // check if the user is in the database
            let foundUser = null;
            for (let dbIdx in userDb) {
                let item = userDb[dbIdx];

                if (item.username === username) {
                    foundUser = item;
                    break;
                }
            }

            if (!(foundUser instanceof Object)) {
                foundUser = {
                    username: username,
                    pw: pw
                };

                userDb.push(foundUser);

                await fs.writeJSON(SmartCupConfig.USER_JSON_PATH, userDb, {EOL: ''});
            }

            // check password
            if (foundUser.pw !== pw) {
                ret = {
                    'status': 'fail',
                    'reason': 'password incorrect'
                }
                throw '';
            }

            // generate unique random session id
            let isUnique = true;
                
            let sessionId = (crypto.randomBytes(32)).toString('hex');

            do {
                for (let loginCredIdx in _loginCreds) {
                    let credToVerify = _loginCreds[loginCredIdx];

                    if (currentTimestamp < credToVerify.last_access + SmartCupConfig.COOKIE_TIMEOUT) {
                        if (sessionId === credToVerify.session_id) {
                            sessionId = (crypto.randomBytes(32)).toString('hex');
                            isUnique = false;
                        }
                    }
                }
            } while (isUnique === false);

            res.cookie(SmartCupConfig.COOKIE_NAME, sessionId, { maxAge: SmartCupConfig.COOKIE_TIMEOUT, httpOnly: true, sameSite: 'strict' });

            // save session data in the memory
            _loginCreds.push({
                session_id: sessionId,
                username: username,
                pw: pw,
                last_access: currentTimestamp
            });

            ret = {
                'status': 'success'
            };
        }

    } catch (e) { }

    res.send(ret);
});

// check if the user is signed in
app.post('/checkLogin', async (req, res) => {
    let ret = {
        'status': 'fail',
        'reason': 'unknown'
    }

    try {
        let cred = await verifySession(req, res, true);

        if (!cred instanceof Object) {
            ret = {
                'status': 'fail',
                'reason': 'log out'
            };

            throw '';
        } 

        ret = {
            'status': 'success',
            'data': {
                username: cred.username,
                timestamp: (new Date()).getTime()
            }
        };
    } catch (e) { }

    res.send(ret);
});

// user logout api
app.post('/logout', async (req, res) => {
    let ret = {
        'status': 'fail',
        'reason': 'unknown'
    }

    try {
        res.cookie(SmartCupConfig.COOKIE_NAME, '', { maxAge: 0, httpOnly: true, sameSite: 'strict' });

        let cred = await verifySession(req, res, false);
        if (cred instanceof Object) {
            cred.last_access = 0;
        }
    } catch (e) { }

    res.status(200).send();
});

// upload water log
//
// request body structure:
// {
//    "sensor id 1": [{t: "timestamp in ms", v: "volume in ml"}, ...], 
//    "sensor id 2": [arary of water logs...]
// }
app.post('/uploadWaterLog', async (req, res) => {
    let ret = {
        'status': 'fail',
        'reason': 'unknown'
    }

    try {
        req.body.timestamp = parseInt(req.body.timestamp);

        if (isNaN(req.body.timestamp) || !(req.body.data instanceof Object)) {
            ret = {
                'status': 'fail',
                'reason': 'invalid request'
            }
            throw '';
        }

        let waterLogCount = 0;
        let waterLogs = {};
        let currentTimestamp = (new Date()).getTime();
        let timestampOffset = currentTimestamp - req.body.timestamp;
        let isTimestampAdjustRequired = false;
        
        // if the time different between the client and the server is greater than 5 mins,
        // adjust the water log timestamp
        if (Math.abs(currentTimestamp - req.body.timestamp) > 5 * 60 * 60 * 1000) {
            isTimestampAdjustRequired = true;
        }

        for (let sensorId in req.body.data) {
            try {
                // check sensor name
                if (sensorId.length < 15 || sensorId.length > 18) {
                    throw 'invalid name';
                } else if (!sensorId.startsWith('SmartCup-')) {
                    throw 'invalid sensor prefix';
                } else if (!(req.body.data[sensorId] instanceof Array)) {
                    throw 'invalid sensor data';
                }

                waterLogs[sensorId] = [];

                // check water log structure
                for (let waterLog of req.body.data[sensorId]) {
                    try {
                        waterLog.t = Math.round(parseFloat(waterLog.t));
                        waterLog.v = Math.round(parseFloat(waterLog.v));

                        if (isNaN(waterLog.t) || isNaN(waterLog.v)) {
                            throw 'invalid water log';
                        }

                        // only allow the user to water logs that are less than 180 days old.
                        if (
                            (waterLog.t + timestampOffset >= currentTimestamp - 180 * 24 * 60 * 60 * 1000) &&
                            (waterLog.t + timestampOffset <= currentTimestamp + 1 * 24 * 60 * 60 * 1000)
                        ) {
                            // adjust timestamp
                            if (isTimestampAdjustRequired) {
                                waterLog.t += timestampOffset;
                            }

                            waterLogs[sensorId].push(waterLog);
                            waterLogCount++;
                        }
                    } catch (e) {}
                }


            } catch (e) { }
        }

        if (waterLogCount > 300) {
            ret = {
                'status': 'fail',
                'reason': 'invalid request'
            }
            throw '';
        }

        let cred = await verifySession(req, res, true);

        if (!cred instanceof Object) {
            ret = {
                'status': 'fail',
                'reason': 'log out'
            }
            throw '';
        }

        let savedWaterLogs = await getUserWaterLog(cred.username);

        for (let sensorId in waterLogs) {
            if (!(savedWaterLogs[sensorId] instanceof Array)) {
                savedWaterLogs[sensorId] = [];
            }

            savedWaterLogs[sensorId] = savedWaterLogs[sensorId].concat(waterLogs[sensorId]);
            
            if (savedWaterLogs[sensorId].length == 0) {
                delete savedWaterLogs[sensorId];
            } else {
                // sort the water logs by timestamp
                savedWaterLogs[sensorId].sort((a, b) => {
                    return a.t - b.t;
                });

                // filter water logs that is less then 29 seconds apart from the others.
                let unique = [savedWaterLogs[sensorId][0]];
                for (let waterLog of savedWaterLogs[sensorId]) {
                    if (waterLog.t - (29 * 1000) >= unique[unique.length - 1].t) {
                        unique.push(waterLog);
                    }
                }
                savedWaterLogs[sensorId] = unique;
            }
        }

        await writeUserWaterLog(cred.username, savedWaterLogs);

        ret = {
            'status': 'success'
        }
    } catch (e) {
        console.log(e);
    }

    res.send(ret);
});


// get water log
// If syncHash is defined, the system will calculate 
// the hash of the water log data in the database, and 
// compare it with syncHash. If the hash equals to syncHash,
// the system will return null, otherwise, return all water logs within 180 days.
//
// If afterTimestamp is defined, the system will return all water logs that is 
// recorded after afterTimestamp.
//
// request body structure:
// {
//    "syncHash": "a sha256 hash of the water log data", 
//    "afterTimestamp": "timestamp in ms"
// }
app.post('/getWaterLog', async (req, res) => {
    let ret = {
        'status': 'fail',
        'reason': 'unknown'
    }

    try {
        let afterTimestamp = null;
        let syncHash = null;

        if (req.body) {
            afterTimestamp = parseInt(req.body.afterTimestamp);


            if (req.body.syncHash) {
                if (validate(req.body.syncHash, {type: 'string', "minLength": 64, "maxLength": 64}).errors.length == 0) {
                    syncHash = req.body.syncHash
                }
            }
        }

        if (isNaN(afterTimestamp) && syncHash == null) {
            ret = {
                'status': 'fail',
                'reason': 'invalid request'
            }
            throw '';
        }

        let cred = await verifySession(req, res, true);

        if (cred instanceof Object) {

            let waterLogs = {};
            
            try {
                waterLogs = await getUserWaterLog(cred.username);
            } catch (e) {}

            if (syncHash != null) {
                // keep the water logs that are less than 180 days old.
                let currentTimestamp = (new Date()).getTime();
                for (let sensorId in waterLogs) {
                    waterLogs[sensorId] = waterLogs[sensorId].filter((item) => {
                        return item.t >= currentTimestamp - 180 * 24 * 60 * 10 * 1000;
                    });  
                }
            } else {
                // keep the water logs that are newer than afterTimestamp
                for (let sensorId in waterLogs) {
                    waterLogs[sensorId] = waterLogs[sensorId].filter((item) => {
                        return item.t >= afterTimestamp;
                    });  
                } 
            }

            if (syncHash === null) {
                ret = {
                    'status': 'success',
                    'data': waterLogs
                }
            } else {
                // get user's water log data hash
                let hashObj = crypto.createHash('sha256');
                hashObj.update(Buffer.from(JSON.stringify(waterLogs)));
                let userDbHash = hashObj.digest('hex');

                if (userDbHash === syncHash) {
                    ret = {
                        'status': 'success',
                        'data': null
                    }
                    throw '';
                } else {
                    ret = {
                        'status': 'success',
                        'data': waterLogs
                    }
                }
            }
        } else {
            ret = {
                'status': 'fail',
                'reason': 'log out'
            };
        }
    } catch (e) {
        console.log(e);
    }

    res.send(ret);
});
