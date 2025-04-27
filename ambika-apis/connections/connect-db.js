let mysql = require('mysql')
const config = require('../config')
const winston = require('../winston')
const logStream = winston.stream


let connect_2324 = mysql.createPool({
  connectionLimit: 100,
  host: config.db_host,
  user: config.user,
  password: config.password,
  database: config.dbconn[2].db
})

connect_2324.on('connection', function (_conn) {
  if (_conn) {
    let db = _conn._pool.config.connectionConfig.database
    if(_conn.state == 'connected'){
      logStream.write('Pool (connect_2324) : Connected the database ' + db + ' via threadId ' + _conn.threadId)
      _conn.query('SET SESSION auto_increment_increment=1')
    }
    else{
      logStream.writeError('Pool (connect_2324) failed to connect to database ' + db)
    }
}
})

let connect_2223 = mysql.createPool({
  connectionLimit: 100,
  host: config.db_host,
  user: config.user,
  password: config.password,
  database: config.dbconn[1].db
})

connect_2223.on('connection', function (_conn) {
  if (_conn) {
    let db = _conn._pool.config.connectionConfig.database
    if(_conn.state == 'connected'){
      logStream.write('Pool (connect_2223) : Connected the database ' + db + ' via threadId ' + _conn.threadId)
      _conn.query('SET SESSION auto_increment_increment=1')
    }
    else{
      logStream.writeError('Pool (connect_2223) failed to connect to database ' + db)
    }
}
})

let connect_2122 = mysql.createPool({
  connectionLimit: 100,
  host: config.db_host,
  user: config.user,
  password: config.password,
  database: config.dbconn[0].db
})

connect_2122.on('connection', function (_conn) {
  if (_conn) {
      let db = _conn._pool.config.connectionConfig.database
      if(_conn.state == 'connected'){
        logStream.write('Pool (connect_2122) : Connected the database ' + db + ' via threadId ' + _conn.threadId)
        _conn.query('SET SESSION auto_increment_increment=1')
      }
      else{
        logStream.writeError('Pool (connect_2122) failed to connect to database ' + db)
      }
  }
})

let connect_main = mysql.createPool({
  connectionLimit: 100,
  host: config.db_host,
  user: config.user,
  password: config.password,
  database: config.dbconn[3].db
})

connect_main.on('connection', function (_conn) {
  if (_conn) {
    let db = _conn._pool.config.connectionConfig.database
    if(_conn.state == 'connected'){
      logStream.write('Pool (connect_main) : Connected the database ' + db + ' via threadId ' + _conn.threadId)
      _conn.query('SET SESSION auto_increment_increment=1')
    }
    else{
      logStream.writeError('Pool (connect_main) failed to connect to database ' + db)
    }
}
})

module.exports = {
  connect_2122 : connect_2122,
  connect_2223 : connect_2223,
  connect_2324 : connect_2324,
  connect_main : connect_main
}