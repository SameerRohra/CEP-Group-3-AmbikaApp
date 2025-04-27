let sql = require('../connections/connect-db')
const winston = require('../winston')
const logStream = winston.stream

module.exports = {
    addEnquiry : (req, res) => {
        logStream.write("In function - addEnquiry")

        let ans = {
            'insertion' : false,
            'message' : "Submission unsuccessful. Kindly try again or contact us directly.",
            'sqlerrorcode' : 0
        }
        let body = req.body

        try{
            const query = "INSERT INTO `enquiries`"
            + "(`Student_Name`,`Parent_Name`,`Standard`,`Board`,`Email_ID`,`Contact_No`,`Date`,`Message`,`Source`,`Referee`,`LastUpdatedBy`) "
            + "VALUES "
            + "(?,?,?,?,?,?,?,?,?,?,?);";
            const queryValues = [
                body.student_name, body.parent_name, body.standard, body.board, body.email_id, 
                body.contact_no, new Date().toISOString().slice(0, 10), body.message, body.source, body.referee, 'App'
            ]

            logStream.write(`Query fired : ${query}. Query values : ${queryValues}`)
            sql.connect_main.query(query, queryValues, (err, results) => {
                if(err) {
                    ans.sqlerrorcode = err.errno
                    if(err.errno == 1062){
                        ans.message = "Submission unsuccessful. We have already registered your enquiry. If you do not hear from us within 2 days, kindly contact us on 8108541190!"
                    }
                    logStream.writeError(
                        {
                            "type" : "SQLError",
                            "message" : err
                        }
                    )
                    return res.status(200).json(ans)
                }
                else {
                    if(results.affectedRows > 0) {
                        ans.insertion = true
                        ans.message = "Submission successful. We will get back to you within 2 working days."
                    }
                    logStream.write(
                        {
                            "Entity"           : body.student_name,
                            "API Result Key"   : "none",
                            "API Result Value" : ans
                        }
                    )
                    return res.status(200).json(ans)
                }
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : body.student_name,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - addEnquiry")
        }
    },

    addEmploymentEnquiry : (req, res) => {
        logStream.write("In function - addEmploymentEnquiry")

        let ans = {
            'insertion' : false,
            'message' : "Submission unsuccessful. Kindly try again or contact us directly.",
            'sqlerrorcode' : 0
        }
        let body = req.body

        try{
            let query = `INSERT INTO employment_enquiries
                (
                    Name,Subject,Position_Preference,Grade_Group,Email_ID,Contact_No,Date,
                    Work_Experience,Highest_Qualification,Source,Referee,LastUpdatedBy
                )
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?);`
            
            const queryValues = [
                body.name,body.subject,
                body.position,body.grade_group,
                body.email_id,body.contact_no,
                new Date().toISOString().slice(0, 10),
                body.work_experience,body.highest_qualification,
                body.source,body.referee,'Website'
            ]
            
            logStream.write(`Query fired : ${query}. Query values : ${queryValues}`)
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
                    if(results.affectedRows > 0) {
                        ans.insertion = true
                        ans.message = "Submission successful. We will get back to you within 2 working days."
                    }
                    logStream.write(
                        {
                            "Entity"           : body.name,
                            "API Result Key"   : "none",
                            "API Result Value" : ans
                        }
                    )
                    return res.status(200).json(ans)
                }
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : body.name,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - addEmploymentEnquiry")
        }

    }
}