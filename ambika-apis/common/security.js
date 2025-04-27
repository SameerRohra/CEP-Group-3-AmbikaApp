const uuid = require('uuid')
const winston = require('../winston')
const logStream = winston.stream
const fs = require('fs')
const LRU = require('lru-cache')
const cache = new LRU({
    max : 1000
})
const sql = require('../connections/connect-db')
const config = require('../config')
const moment = require('moment')

module.exports = {
    generateApiKey : () => {
        logStream.write("Api key generated successfully!")
        return uuid.v4()
    },

    addApiKey : (ambikaid, key, callback) => {
        logStream.write("In function - addApiKey")
        /*
            Store ambikaid, generatedkey and current_timestamp to be stored in database first.
            If successful, to be stored in cache. Since, there should be only unique ambikaid-key pairs in both database and cache,
            for database, we have set ambika id to be unique key and the on duplicate key query will always update the key if ambika id is already present in the table;
            for cache, we are explicitly moving through the cache and deleting the one matching
        */
        try{
            let query = "INSERT INTO api_keys (Ambika_ID, APIKey, Timestamp) VALUES (?,?,?) ON DUPLICATE KEY UPDATE APIKey = ?, Timestamp = ?;";

            const timestamp = moment.unix(Date.now()/1000).format('YYYY-MM-DD HH:mm:ss');
            const values = getValues(ambikaid, timestamp)
            sql.connect_main.query(query, [ambikaid, key, timestamp, key, timestamp], function(err, results) {
                if(err) {
                    logStream.writeError({"type" : "SQLError","message" : err})
                    callback(false)
                    return
                }
                else {
                    deleteAllKeysForAmbikaID(ambikaid)
                    cache.set(key, values)
                    logStream.write("API key added successfully for ambikaid + " + ambikaid)
                    callback(true)
                    return
                }
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : ambikaid ? ambikaid : 0,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - addApiKey")
        }
        
    },

    verifyApiKey : (ambikaid, key, callback) => {
        logStream.write("In function - verifyApiKey")
        try{
            if (cache.has(key)) {
                let values = cache.get(key)
                if ((values.ambikaid == ambikaid || ambikaid === 0) && checkTimeStampValidity(values)) {
                    logStream.write(`API key verification complete for Ambika ID ${ambikaid} by cache hit.`)
                    callback(true)
                    return
                }
                logStream.write(`API key verification not found in cache for Ambika ID ${ambikaid}.`);
            }
            
            // check database
            let query = 'SELECT Timestamp FROM api_keys WHERE Ambika_ID = ? AND State = 1 ORDER BY ID DESC';
            if(ambikaid === 0) query = 'SELECT Timestamp FROM api_keys WHERE Ambika_ID <> ? AND State = 1 ORDER BY ID DESC';
            sql.connect_main.query(query, [ambikaid, key], (err, results) => {
                if (err) {
                    logStream.writeError({ type: 'SQLError', message: err })
                    callback(false)
                    return
                } else {
                    if(results[0] == null || results[0] == undefined){
                        logStream.write(`API key verification failed for Ambika ID ${ambikaid}. Record not found in database.`)
                        callback(false)
                        return
                    }

                    if (!checkTimeStampValidity(getValues(ambikaid,results[0]["Timestamp"]))) {
                        logStream.write(`API key verification failed for Ambika ID ${ambikaid}. Record found in database but is expired.`)
                        callback(false)
                        return
                    }

                    logStream.write(`API key verification complete for Ambika ID ${ambikaid} by database check.`)
            
                    cache.set(key, getValues(ambikaid, results[0]["Timestamp"]))
                    logStream.write(`API key added successfully for ambikaid ${ambikaid}`)
            
                    callback(true)
                    return
                }
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : ambikaid ? ambikaid : 0,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - verifyApiKey")
        }
        
    },

    peepCache : (ambikaid) => {
        logStream.write("In function - peepCache")
        let cacheResults = {}
        try{
            const keys = cache.keys()
            if(ambikaid == 0){
                cache.forEach((value,key) => {
                    cacheResults[key] = value
                })
            }
            return cacheResults
        }
        catch(ex){
            let errorMsg = {
                "type" : "Exception",
                "entity" : ambikaid ? ambikaid : 0,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally{
            logStream.write("EOF - peepCache")
        }
    }
}

deleteAllKeysForAmbikaID = (ambikaid) => {
    let deletedKeys = []
    cache.forEach((value, key) => {
        if (value.ambikaid == ambikaid) {
          cache.delete(key)
        }
        deletedKeys.push(key)
    })
    logStream.write("These API keys were deleted for the Ambika ID " + ambikaid + " - " + deletedKeys.join(','))
}

checkTimeStampValidity = (values) => {
    const currentTimestamp = moment(new Date(), 'YYYY-MM-DD HH:mm:ss').unix();
    const storedTimestamp = moment(values.timestamp, 'YYYY-MM-DD HH:mm:ss').unix()
    const diffInMinutes = (currentTimestamp - storedTimestamp) / 60
   
    // If the difference is greater than the apiKeysTTLinMins value, invalidate the key
    if (diffInMinutes > config.apiKeysTTLinMins) {
        logStream.write(`API key expired because it was ${diffInMinutes} old. It will be removed from cache and database.`)
        deleteAllKeysForAmbikaID(values.ambikaid)
        return false;
    }
    return true
}

getValues = (ambikaid, timestamp) => {
    return {
        'ambikaid' : ambikaid,
        'timestamp' : timestamp
    }
}