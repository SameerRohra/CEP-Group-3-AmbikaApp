let sql = require('../connections/connect-db')
let config = require('../config')
let fcm = require('fcm-node')
const FCM = require('fcm-node/lib/fcm')
const winston = require('../winston')
const logStream = winston.stream
const security = require('../common/security')
const constants = require('../constants')

module.exports = {
    send : (req, res) => {
        logStream.write("In function - send - notification services")
        const body = req.body
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const serverKey = config.fcm_server_key
                const fcm = new FCM(serverKey)
                const message = {
                    registration_ids : body.registrationTokens,
                    collapse_key : body.module,
                    notification : {
                        title: body.title,
                        body: body.body
                    },
                    data: {
                        module : body.module
                    }
                }
        
                logStream.write(`Notification body : ${message}`)
                if(body.registrationTokens.length == 0){
                    logStream.write('No registration tokens sent.')
                    return res.status(300).json({'Message' : 'No registration tokens sent.'})
                }
                
                fcm.send(message, (err, response) => {
                    if(err){
                        let errorMsg = {
                            "type" : "FCM Notification Error",
                            "entity" : 'FCM',
                            "message" : err,
                            "notificationBody" : message
                        }
                        logStream.writeError(errorMsg)
                        return res.status(300).json(errorMsg)
                    }
                    logStream.write(
                        {
                            "Entity"           : "Notification",
                            "API Result Key"   : "none",
                            "API Result Value" : response
                        }
                    )
                    return res.status(200).json(JSON.parse(response))
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : 'none',
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - send - notification services")
        }
    },

    addToken : (req, res) => {
        logStream.write("In function - addToken")

        let ans = {
            'addition' : false
        }
        const body = req.body;
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(body.ambikaid, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const query = `INSERT INTO notification_tokens (Ambika_ID,Token) VALUES (?,?);`
                const queryValues = [body.ambikaid, body.token]

                if(body.ambikaid && body.token){
                    sql.connect_main.query(query, queryValues, (err, results) => {
                        if(err) {
                            logStream.writeError(
                                {
                                    "type" : "SQLError",
                                    "message" : err
                                }
                            )
                            return res.status(500).json({"message" :"SQL error occurred. Please check logs!"})
                        }
                        else {
                            if(results.affectedRows > 0) ans.addition = true
                            logStream.write(
                                {
                                    "Entity"           : body.ambikaid ? body.ambikaid : 0,
                                    "API Result Key"   : "none",
                                    "API Result Value" : ans
                                }
                            )
                            return res.status(200).json(ans)
                        }
                    })
                }
                else{
                    ans.error_msg = "Incorrect arguments!"

                    let errorMsg = {
                        "type" : "Param Error",
                        "errorMessage" : 'Incorrect arguments while adding notification token',
                        "message" : ans,
                        "requestBody" : body 
                    }
                    logStream.writeError(errorMsg)
                    return res.status(500).json(ans)
                }
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : 'none',
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - uploadAds")
        }
    }
}