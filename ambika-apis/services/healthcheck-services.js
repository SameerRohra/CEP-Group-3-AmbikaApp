const winston = require('../winston')
const logStream = winston.stream

module.exports = {
    checkAllHealth : (req, res) => {
        // check API health
        let response = {
            status : 'ok',
            message : 'pong'
        }
        // logStream.write(response)
        return res.status(200).json(response)
    }
}