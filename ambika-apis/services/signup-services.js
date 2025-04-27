let sql = require('../connections/connect-db')
const winston = require('../winston')
const logStream = winston.stream

module.exports = {
    validateUserExistence : (req, res) => {
        logStream.write("In function - validateUserExistence");
      
        let ans = {
          validation: false,
          message: "Ambika Id and Email Id combination does not exist. Kindly contact branch.",
          mobileNumberForOTP: 1234567890,
        };
      
        const { conn, ambikaid, emailid } = req.body;
      
        if (isNaN(ambikaid)) {
          ans.message = "Ambika ID is wrong. Please collect your Ambika ID from reception.";
          logStream.write(JSON.stringify({ message: ans.message }));
          return res.status(400).json(ans);
        }
      
        try {
          const query = "SELECT Primary_CN FROM people WHERE Ambika_ID = ? AND Primary_Email = ?";
          logStream.write(`Query fired --> ${query}`);
          
          sql[conn].query(query, [ambikaid, emailid], (err, results) => {
            if (err) {
              logStream.writeError({ type: "SQLError", message: err.message });
              return res.status(500).json({ message: "SQL error occurred. Please check logs!" });
            }
      
            if (results.length > 0) {
              ans.validation = true;
              ans.message = `User check successful. Kindly proceed. Check for OTP on your number XXXXXX${results[0].Primary_CN.slice(-4)}`;
              ans.mobileNumberForOTP = results[0].Primary_CN;
            }
      
            logStream.write(JSON.stringify({ Entity: ambikaid, "API Result": ans }));
            return res.status(200).json(ans);
          });
        } catch (ex) {
          logStream.writeError({ type: "Exception", message: ex.message, stack: ex.stack });
          return res.status(500).json({ message: "Exception occurred. Please check logs!" });
        } finally {
          logStream.write("EOF - validateUserExistence");
        }
      },
      

    addPassword : (req, res) => {
        logStream.write("In function - addPassword")

        let ans = {
            'addition' : false,
            'message' : 'Password was not added successfully. Please try again.'
        };
        let body = req.body
        let conn = body.conn

        try{
            let query = "UPDATE people SET App_Password = MD5('" + body.password + "') WHERE Ambika_ID = " + body.ambikaid + ";";
            
            if(isNaN(body.ambikaid) || body.ambikaid == ''){
                ans.message = "Ambika ID is wrong. Please use your Ambika ID."
                logStream.write({"message" : ans.message, "queryformed" : query})
                return res.status(200).json(ans);
            }

            if(body.password == ''){
                ans.message = "Password cannot be blank. Please enter correct password."
                logStream.write({"message" : ans.message, "queryformed" : query})
                return res.status(200).json(ans);
            }

            logStream.write("Query fired --> " + query)
            if(body.password){
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
                        if(results.affectedRows > 0) {
                            ans.addition = true
                            ans.message = 'Password added successfully. Please proceed to sign in with the same password.'
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
            }
            else{
                let errorMsg = {
                    "type" : "Param Error",
                    "entity" : body.ambikaid ? body.ambikaid : 0,
                    "message" : "Incorrect arguments in add password method.",
                    "requestBody" : body
                }
                logStream.writeError(errorMsg)
                return res.status(200).json(ans)
            }
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
            logStream.write("EOF - addPassword")
        }
    },

    addOTP : (req, res) => {
        let ans = {
            'addition' : false
        };
        let body = req.body;
        let conn = body.conn;
        let query = "INSERT INTO `otps`(`AmbikaID`,`EmailID`,`OTP`,`Verification_Flag`,`ExpiryFlag`,`Application`,`Context`)" +
        "VALUES (" + body.ambikaid + ", '" + body.emailid + "', '" + body.otp + "',0,0,'Ambika Mobile','App sign up.');";
        if(true){ // add arguement validation here later if required
            sql[conn].query(query, function(err, results) {
                if(err) throw err;
                else {
                    if(results.affectedRows > 0) ans.addition = true
                    return res.status(200).json(ans)
                }
            })
        }
        else{
            ans.error_msg = "Incorrect arguments!"
            return res.status(200).json(ans)
        }
    },

    getOTP : (req,res) => {
        let conn = req.params.conn;
        let ambikaid = req.params.ambikaid;
        let emailid = req.params.emailid;
        let query = "SELECT * FROM otps WHERE AmbikaID = " + ambikaid + " AND EmailID = '" + emailid + "' ORDER BY InsertedOn DESC LIMIT 1;";
        
        sql[conn].query(query, function(err, results) {
            if(err) throw err;
            else {
                return res.status(200).json(results);
            }
        })
    }
}