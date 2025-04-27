const appRoot = require('app-root-path')
const winston = require('winston')
const selfEmailer = require('./common/selfEmailer')
const config = require('./config')
require('winston-daily-rotate-file')

// define the custom settings for each transport (file, console)
let options = {
  file: {
    level: 'info',
    filename: `${appRoot}/logs/app-%DATE%.log`,
    handleExceptions: true,
    json: true,
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '20m',
    maxFiles: '14d',
    colorize: false,
    format: winston.format.combine(
      winston.format.timestamp({
        format: "YYYY-MM-DD HH:mm:ss",
      }),
      winston.format.json()
    ),
  },
  console: {
    level: 'debug',
    handleExceptions: true,
    json: false,
    colorize: true,
    format: winston.format.combine(
      winston.format.timestamp({
        format: "YYYY-MM-DD HH:mm:ss",
      }),
      winston.format.json()
    ),
  },
};

let transport = new winston.transports.DailyRotateFile(options.file)

transport.on('rotate', function(oldFilename, newFilename) {
  // do something fun
});

// instantiate a new Winston Logger with the settings defined above
var logger = new winston.createLogger({
  transports: [
    transport,
    new winston.transports.Console(options.console)
  ],
  exitOnError: false, // do not exit on handled exceptions
});

// create a stream object with a 'write' function that will be used by `morgan`
logger.stream = {
  write: function(message, encoding) {
    // use the 'info' log level so the output will be picked up by both transports (file and console)
    logger.info(message);
  },
  writeError: (message) => {
    logger.error(message)
    if(config.env == 'PROD') selfEmailer.sendEmail(JSON.stringify(message))
  },
  writeWarn: (message) => {
    logger.warn(message)
  }
};

module.exports = logger;