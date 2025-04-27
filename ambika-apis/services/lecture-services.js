let sql = require('../connections/connect-db')
let config = require('../config')
const winston = require('../winston')
const logStream = winston.stream
const security = require('../common/security')
const constants = require('../constants')

module.exports = {
    getLectures : (req,res) => {
        logStream.write("In function - getLectures")

        const conn = req.params.conn;
        const course = req.params.course;
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }
            
                let query = "SELECT lec.Id, DATE_FORMAT(lec.Lecture_Date, '%Y-%m-%d') as Lecture_Date, schools.School_Name, lec.Subject, lec.Time_IN, lec.Time_OUT, lec.Notes, lec.Room_No, people.Name as Teacher, lec.Lecture_Type, lec.Status FROM lectures as lec " + 
                "INNER JOIN courses as c ON c.Course_Name = lec.Course_Name " + 
                "INNER JOIN staff as s ON lec.Staff_ID = s.Staff_ID " + 
                "INNER JOIN " + config.dbconn[3].db + ".schools as schools ON schools.ID = lec.School_ID " +
                "INNER JOIN " + config.dbconn[3].db + ".people as people ON people.Ambika_ID = s.Ambika_ID " + 
                "WHERE c.Course_Name = '" + course + "' ORDER BY Lecture_Date DESC, Time_OUT DESC;";
                
                logStream.write("Query fired --> " + query)
                sql[conn].query(query, function(err, results) {
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
                        logStream.write(
                            {
                                "Entity"           : conn + " : " + course,
                                "API Result Key"   : "allLectures",
                                "API Result Value" : "Result could be long. No of records : " + results.length //avoid writing overhead hence printing the count
                            }
                        )
                        return res.status(200).json({"allLectures" : results});
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : conn + " : " + course,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getLectures")
        }


        
    },

    getLecturesForDate : (req,res) => {
        logStream.write("In function - getLecturesForDate")

        const conn = req.params.conn
        const date = req.params.date
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                let query = "SELECT lec.*, people.Name FROM lectures lec CROSS JOIN  " + config.dbconn[3].db + ".people as people ON people.Ambika_ID = s.Ambika_ID " + 
                "WHERE lec.Lecture_Date = " + date + ";";
                
                logStream.write("Query fired --> " + query)
                sql[conn].query(query, function(err, results) {
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
                        logStream.write(
                            {
                                "Entity"           : conn + " : " + date,
                                "API Result Key"   : "none",
                                "API Result Value" : results
                            }
                        )
                        return res.status(200).json(results);
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : conn + " : " + date,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getLecturesForDate")
        }
    },

    getAllLectures : (req,res) => {
        logStream.write("In function - getAllLectures")

        const conn = req.params.conn;
        const course = req.params.course;
        const key = req.get(constants.apiKeyName)
        const noOfRecords = req.params.noOfRecords;
        let limit = noOfRecords
        if(noOfRecords == 0) limit = 50000 // max
        
        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                let query = "SELECT lec.Id, DATE_FORMAT(lec.Lecture_Date, '%Y-%m-%d') as Lecture_Date, schools.School_Name, lec.Subject, lec.Time_IN, lec.Time_OUT, lec.Notes, lec.Room_No, people.Name as Teacher, lec.Lecture_Type, lec.Status FROM lectures as lec " + 
                "INNER JOIN courses as c ON c.Course_Name = lec.Course_Name " + 
                "INNER JOIN staff as s ON lec.Staff_ID = s.Staff_ID " + 
                "INNER JOIN " + config.dbconn[3].db + ".schools as schools ON schools.ID = lec.School_ID " +
                "INNER JOIN " + config.dbconn[3].db + ".people as people ON people.Ambika_ID = s.Ambika_ID " + 
                "WHERE c.Course_Name = '" + course + "' ORDER BY Lecture_Date DESC, Time_OUT DESC " +
                "LIMIT " + limit + ";";
                
                logStream.write("Query fired --> " + query)
                sql[conn].query(query, function(err, results) {
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
                        let allLectures = groupLecturesByDate(results)
                        
                        logStream.write(
                            {
                                "Entity"           : conn + " : " + course,
                                "API Result Key"   : "allLectures",
                                "API Result Value" : "Result could be long. No of total records fetched : " + results.length + ". No of records after grouped by date : " + allLectures.length
                            }
                        )
                        return res.status(200).json(
                            {
                                "allLectures" : allLectures
                            }
                        )
                    }
                })
            })  
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : conn + " : " + course,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getAllLectures")
        }        
    }
}

groupLecturesByDate = (results) => {
    let finalResult = []
    let allDates = []
    results.map(r => {
        if(!allDates.includes(r.Lecture_Date))
        allDates.push(r.Lecture_Date)
    })
    // console.log(allDates)
    allDates.map(date => {
        let groupedData = []
        let subjects = []
        results.map(r => {
            if(r.Lecture_Date == date){
                subjects.push(r.Subject)
                groupedData.push(r)
            }
        })
        finalResult.push({
                "date" : date,
                "summary" : {
                    "subjects" : subjects.join(',')
                },
                "lectures" : groupedData
            }
        )
    })

    return finalResult
}