let sql = require('../connections/connect-db')
const winston = require('../winston')
const logStream = winston.stream
const security = require('../common/security')
const constants = require('../constants')

module.exports = {
    getAttendanceForStudent: (req, res) => {
        logStream.write("In function - getAttendanceForStudent")

        const conn = req.params.conn
        const ambikaid = req.params.ambikaid
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(ambikaid, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                let finalResult = {
                    absence_summary : {
                        total_days : 0,
                        present_days : 0,
                        absent_days : 0,
                        holidays : 0,
                        percentage : 0
                    },
                    absent_days : [],
                    holidays : []
                }
        
                const query = `(SELECT DATE_FORMAT(ab.Absence_Date, '%Y-%m-%d') as Date, 'Start_Date' as Status, '' as Type, Reason as Comments 
                                    FROM student_absence ab
                                    INNER JOIN students s ON ab.Course_Name = s.Course_Name AND ab.Roll_No = s.Roll_No
                                    WHERE s.Ambika_ID = ? ORDER BY Absence_Date LIMIT 1) 
                                UNION 
                                (SELECT DATE_FORMAT(ab.Absence_Date, '%Y-%m-%d') as Date, 'End_Date' as Status, '' as Type, Reason as Comments 
                                    FROM student_absence ab
                                    INNER JOIN students s ON ab.Course_Name = s.Course_Name AND ab.Roll_No = s.Roll_No
                                    WHERE s.Ambika_ID = ? ORDER BY Absence_Date DESC LIMIT 1) 
                                UNION 
                                (SELECT DATE_FORMAT(ab.Absence_Date, '%Y-%m-%d') as Date, 'Absent' as Status, '' as Type, Reason as Comments 
                                    FROM student_absence ab
                                    INNER JOIN students s ON ab.Course_Name = s.Course_Name AND ab.Roll_No = s.Roll_No
                                    WHERE s.Ambika_ID = ? ORDER BY ab.Absence_Date)
                                UNION 
                                (SELECT DATE_FORMAT(hol.Date, '%Y-%m-%d') Date, 'Holiday' as Status, Day_Type as Type,Comments 
                                    FROM student_holiday_calendar hol
                                    INNER JOIN students s ON hol.Course_Name = s.Course_Name OR hol.Course_Name = 'ALL'
                                    WHERE s.Ambika_ID = ? ORDER BY Date);`
                const queryValues = [ambikaid,ambikaid,ambikaid,ambikaid]

                logStream.write(`Query fired : ${query}. Query values : ${queryValues}`)
                sql[conn].query(query, queryValues, (err, results) => {
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
                        finalResult.absent_days = results.filter(days => days.Status == 'Absent')
                        finalResult.holidays = results.filter(days => days.Status == 'Holiday')
                        finalResult.absence_summary = getSummaryData(
                                                        results.find(r => r.Status == 'Start_Date').Date,
                                                            results.find(r => r.Status == 'End_Date').Date,
                                                                finalResult.absent_days.length,
                                                                    finalResult.holidays.length)
                        
                        logStream.write(
                            {
                                "Entity"           : conn + " : " + ambikaid,
                                "API Result Key"   : "multiple",
                                "API Result Value" : "Result could be long. No of records : " + results.length //avoid writing overhead hence printing the count
                            }
                        )

                        return res.status(200).json(finalResult)
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : conn + " : " + ambikaid,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getAttendanceForStudent")
        }

    },

    addAbsenceReason: (req, res) => {
        logStream.write("In function - addAbsenceReason")

        let ans = {
            'addition' : false,
            'message' : 'Something went wrong!'
        }
        let body = req.body

        try{
            let query = "UPDATE student_absence SET Reason = " + sql[body.conn].escape(body.reason) + ", Comments = 'Updated from mobile app.'" +
                        " WHERE Course_Name = " + sql[body.conn].escape(body.course) + " AND Roll_No = " + body.roll_no +
                        " AND  Absence_Date = " + sql[body.conn].escape(body.date)
            
            logStream.write("Query fired --> " + query)
            if(body.date && body.reason && body.roll_no && body.course){
                sql[body.conn].query(query, function(err, results) {
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
                        if(results.affectedRows > 0) {
                            ans.addition = true
                            ans.message = 'Reason added to the absent date.'
                        }
                        else {
                            ans.addition = false
                            ans.message = ans.message + ' Please check if the selected date is marked as absent. If no contact office for the same.'
                        }
                        logStream.write(
                            {
                                "Entity"           : body.conn + " : " + body.course + "-" + body.roll_no,
                                "API Result Key"   : "none",
                                "API Result Value" : ans
                            }
                        )
                        return res.status(200).json(ans)
                    }
                })
            }
            else{
                ans.message = ans.message + " Incorrect arguments!"
                logStream.writeError({
                    "type" : "Erroneous Params",
                    "entity" : body.conn + " : " + body.course + "-" + body.roll_no,
                    "message" : ans.message,
                })
                return res.status(400).json(ans)
            }
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : body.conn + " : " + body.course + "-" + body.roll_no,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - addAbsenceReason")
        }
    }
}

getSummaryData = (start_date, end_date, total_days_absent, total_days_holidays) => {
    let total_days = getDateDiff(new Date(start_date), new Date(end_date))
    
    let result = {}
    result.overall_presence = Math.round(getPresentPercentage(total_days, total_days_holidays, total_days_absent))
    return result
}

getDateDiff = (date_1, date_2) => {
    let timeDiff = date_2.getTime() - date_1.getTime()
    let dayDiff = timeDiff / (1000 * 3600 * 24)

    return dayDiff
}

getPresentPercentage = (total_days, total_holidays, total_absents) => {
    let total_working_days = total_days - total_holidays
    return ((total_working_days - total_absents) / total_working_days) * 100
}