module.exports = new (function () {
    const path = require('path');

    this.SERVER_PORT = 7800;

    this.COOKIE_NAME = 'SmartCup';
    this.COOKIE_TIMEOUT = 28 * 24 * 60 * 60 * 1000; // 28 days
    this.COOKIE_SECRET = '(*&ewjf"83u40[23n~ 2#Q_)O_?>,0832H#)jaiqhjCief';

    this.DB_PATH = path.resolve(__dirname, './db');
    this.USER_JSON_PATH = path.resolve(this.DB_PATH, './user.json');
    this.USER_PATH_SALT = 'oijrlrngup9q347rija0efh7_YH(*YU#J@)JHR)39rqj[rm4';
})();