const express = require('express');
var sql = require('../connections/connect-db');

module.exports = {
    getStudents: (req, res) => {
        logStream.write("In function - getStudents")
        let conn = req.params.conn
        let course = req.params.course
        let rollno = req.params.rollno
        try{
            let query = "select * from students WHERE Course_Name = '" + req.params.course + 
            "' AND Roll_No = " + req.params.rollno

            logStream.write("Query fired --> " + query)
            sql[conn].query(query, function (err, results) {
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
                            "Entity"           : conn + " : " + course + "-" + rollno,
                            "API Result Key"   : "none",
                            "API Result Value" : results
                        }
                    )
                    return res.status(200).json(results);
                }
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : conn + " : " + course + "-" + rollno,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getStudents")
        } 
    },

    getFees: (req, res) => {
        let connection = req.params.conn;
        sql[connection].query("select * from fees", function (err, results) {
            if(err) {
                throw err;
            }
            else {   
                return res.status(200).json(results);
            }
        }); 
    }
}