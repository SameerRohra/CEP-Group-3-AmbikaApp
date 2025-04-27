let sql = require('../connections/connect-db')
const winston = require('../winston')
const logStream = winston.stream
const security = require('../common/security')
const constants = require('../constants')

module.exports = {
    getExamsForCourse : (req, res) => {
        logStream.write("In function - getExamsForCourse")
        
        const conn = req.params.conn
        const course = req.params.course
        const key = req.get(constants.apiKeyName)
        
        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const queryForExams = `SELECT e.ID, e.Course_Name, DATE_FORMAT(e.Date, '%Y-%m-%d') as Date,e.Question_Paper,e.Supervisor,e.Examiner,
                                            e.Total_Marks,e.Subject,e.Exam_Type as Type,e.Result_Date FROM exams e WHERE Course_Name = ?;`
                const queryValues = [course]

                logStream.write(`Query fired : ${queryForExams}. Query values : ${queryValues}`)
                sql[conn].query(queryForExams, queryValues, (err, exams) => {
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
                                "Entity"           : course,
                                "API Result Key"   : "exams",
                                "API Result Value" : "Result could be long. No of records : " + exams.length //avoid writing overhead hence printing the count
                            }
                        )
                        res.status(200).send({"exams" : exams})
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : course,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getExamsForCourse")
        }
    },

    getExamsResultsForStudent : (req, res) => {
        logStream.write("In function - getExamsResultsForStudent")

        const conn = req.params.conn
        const ambikaid = req.params.ambikaid
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(ambikaid, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const queryForStudent = `SELECT e.ID, e.Course_Name, DATE_FORMAT(e.Date, '%Y-%m-%d') as Date,e.Question_Paper,e.Supervisor,e.Examiner,
                                            e.Total_Marks,e.Subject,e.Exam_Type as Type,DATE_FORMAT(e.Result_Date, '%Y-%m-%d') as Result_Date,
                                            r.Roll_No,r.Score,r.Appeared, 1 as Results_Announced
                                            FROM exams e 
                                            INNER JOIN results r ON e.ID = r.Exam_ID 
                                            INNER JOIN students s ON s.Course_Name = e.Course_Name AND s.Roll_No = r.Roll_No
                                            WHERE s.Ambika_ID = ? AND e.Status = 1 and r.Status = 1
                                        UNION 
                                        SELECT e.ID, e.Course_Name, e.Date,e.Question_Paper,e.Supervisor,e.Examiner,e.Total_Marks,
                                            e.Subject,e.Exam_Type as Type,e.Result_Date,0 as Roll_No,0 as Score,0 as Appeared, 0 as Results_Announced
                                            FROM exams e 
                                            INNER JOIN students s ON s.Course_Name = e.Course_Name
                                            WHERE e.ID NOT IN (SELECT DISTINCT Exam_ID from results)
                                            AND s.Ambika_ID = ? AND e.Status = 1;`
                const queryValues = [ambikaid, ambikaid]

                logStream.write(`Query fired : ${queryForStudent}. Query values : ${queryValues}`)
                sql[conn].query(queryForStudent, queryValues, (err, results) => {
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
                        let data = makeExamsResultsData(results)
                        logStream.write(
                            {
                                "Entity"           : conn + " - " + ambikaid,
                                "API Result Key"   : "allData",
                                "API Result Value" : `Overall summary: ${JSON.stringify(data.overallSummary)}. Typewise summary : ${JSON.stringify(data.typeWiseSummary)}. Result could be long. No of result data : ${data.fullList.length}` 
                            }
                        )
                        res.status(200).send({"allData" : data})
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
            logStream.write("EOF - getExamsResultsForStudent")
        }
    }
}

makeExamsResultsData = (fetchedData) => {
    let distinctExamTypes = [...new Set(fetchedData.map(f => f.Type))]
    let overallTotalMarks = 0
    let overallMarksObtained = 0
    let typeWiseDataList = []
    distinctExamTypes.forEach(type => {
        let typeWiseData = {}
        let totalMarks = 0
        let marksObtained = 0
        let filteredData = fetchedData.filter(f => f.Type == type && f.Results_Announced == 1)
        filteredData.forEach(fd => {
            totalMarks += fd.Total_Marks
            marksObtained += fd.Score
        });

        typeWiseData.type = type
        typeWiseData.noOfTests = filteredData.length
        typeWiseData.totalMarks = totalMarks
        typeWiseData.marksObtained = marksObtained
        typeWiseData.percentage = Number(((marksObtained/totalMarks) * 100).toFixed(2))

        typeWiseDataList.push(typeWiseData)
        overallMarksObtained += marksObtained
        overallTotalMarks += totalMarks
    })

    fetchedData.forEach(data => {
        data.percentage = (data.Score/data.Total_Marks) * 100
        if(data.percentage > 85){
            data.Grade = 'A' // Color --> Green
        }
        else if(data.percentage > 50){
            data.Grade = 'B' // Color --> Yellow
        }
        else{
            data.Grade = 'F' // Color --> Red
        }
    })

    return {
        overallSummary : {
            noOfTests : fetchedData.length - fetchedData.filter(f => f.Results_Announced == 0).length,
            totalMarks : overallTotalMarks,
            marksObtained : overallMarksObtained,
            percentage : Number(((overallMarksObtained/overallTotalMarks) * 100).toFixed(2))
        },
        typeWiseSummary : typeWiseDataList,
        fullList : fetchedData
    }
}
