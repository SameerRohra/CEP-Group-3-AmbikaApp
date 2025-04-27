let sql = require('../connections/connect-db')
const winston = require('../winston')
const logStream = winston.stream
const security = require('../common/security')
const constants = require('../constants')

module.exports = {
    getFQCsForStudent : (req, res) => {
        logStream.write("In function - getFQCsForStudent")

        const ambikaid = req.params.ambikaid
        const key  = req.get('apiKey')

        try{
            security.verifyApiKey(ambikaid, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const queryForFQC = 
                "SELECT ID, Ambika_ID, FQCTitle, FQCType, DATE_FORMAT(FQCDate, '%Y-%m-%d') as FQCDate, FQCDescription, FQCResolution, FQCStatus, " +
                "case when FQCStatus = 0 then 'Open' " +
                "when FQCStatus = 1 then 'Pending' " +
                "else 'Closed' " +
                "end as FQCStatusText FROM fqc WHERE Ambika_ID = ?;"
                const queryValues = [ambikaid]

                logStream.write(`Query fired : ${queryForFQC}. Query values : ${queryValues}`)
                sql.connect_main.query(queryForFQC, queryValues, (err, fqc) => {
                    if(err) {
                        logStream.writeError(
                            {
                                "type" : "SQLError",
                                "message" : err
                            }
                        )
                        return res.status(500).json({"message" :"SQL error occurred. Please check logs!"})
                    }
                    else{
                        logStream.write(
                            {
                                "Entity"           : ambikaid ? ambikaid : 0,
                                "API Result Key"   : "fqc",
                                "API Result Value" : "Result could be long. No of records : " + fqc.length //avoid writing overhead hence printing the count
                            }
                        )
                        res.status(200).send({"fqc" : fqc})
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : ambika_id ? ambika_id : 0,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getFQCsForStudent")
        }
    },

    getALLFQCs : (req, res) => {
        logStream.write("In function - getALLFQCs")

        const key = req.get(constants.apiKeyName)
        
        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                let queryForFQC = 
                "SELECT ID, Ambika_ID, FQCTitle, FQCType, DATE_FORMAT(FQCDate, '%Y-%m-%d') as FQCDate, FQCDescription, FQCResolution, FQCStatus, " +
                "case when FQCStatus = 0 then 'Open' " +
                "when FQCStatus = 1 then 'Pending' " +
                "else 'Closed' " +
                "end as FQCStatusText FROM fqc"
                
                logStream.write(`Query fired : ${queryForFQC}.`)
                sql.connect_main.query(queryForFQC, (err, fqc) => {
                    if(err) {
                        logStream.writeError(
                            {
                                "type" : "SQLError",
                                "message" : err
                            }
                        )
                        return res.status(500).json({"message" :"SQL error occurred. Please check logs!"})
                    }
                    else{
                        logStream.write(
                            {
                                "Entity"           : "Manage Ambika",
                                "API Result Key"   : "fqc",
                                "API Result Value" : "Result could be long. No of records : " + fqc.length //avoid writing overhead hence printing the count
                            }
                        )
                        res.status(200).send({"fqc" : fqc})
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : 'Manage Ambika',
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getALLFQCs")
        }
    },

    addFQC : (req, res) => {
        logStream.write("In function - addFQC")

        let ans = {
            'addition' : false,
            'message' : 'There was an error submitting you F/Q/C. Kindly contact administrator.'
        }
        const body = req.body
        let type = ""
        let typeForTable = "Feedback"

        const ambikaid = body.ambikaid
        const key = req.get(constants.apiKeyName)
        
        try{
            security.verifyApiKey(ambikaid, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                if(body.type == "Q" || body.type == "Query") {
                    typeForTable = "Query"
                    type = "query"
                }
                else if(body.type == "C" || body.type == "Complaint") {
                    typeForTable = "Complaint"
                    type = "complaint"
                }
                else {
                    typeForTable = "Feedback"
                    type = "feedback"
                }

                let successMessage = "Thank you for submitting your " + type +". We will get back to you withing 48 hours. " + 
                "For emergency queries, kindly contact office."

                const insertFQC = 
                "INSERT INTO fqc (`Ambika_ID`, `FQCType`, `FQCTitle`, `FQCDate`, `FQCStatus`, `FQCDescription`) " +
                "VALUES ( ?, ?, ?, ?, 0, ?);"
                const queryValues = [body.ambikaid, typeForTable, body.title, body.date, body.description]

                logStream.write(`Query fired : ${insertFQC}. Query values : ${queryValues}`)
                sql.connect_main.query(insertFQC, queryValues, (err, fqc) => {
                    if(err) {
                        logStream.writeError(
                            {
                                "type" : "SQLError",
                                "message" : err
                            }
                        )
                        return res.status(500).json({"message" :"SQL error occurred. Please check logs!"})
                    }
                    else{
                        if(fqc.affectedRows > 0) {
                            ans.addition = true,
                            ans.message = successMessage
                        }
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
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : body.ambikaid ? body.ambikaid : 0,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - addFQC")
        }
    }
}