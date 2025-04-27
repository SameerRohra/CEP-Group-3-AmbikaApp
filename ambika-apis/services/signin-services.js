let sql = require('../connections/connect-db')
let config = require('../config')
const fs = require("fs")
const path = require("path")
const winston = require('../winston')
const logStream = winston.stream
const baseFilePath = "./files/"
const profilePicPath = "profileImages/"
const allUploadPath = "uploads/"
const security = require('../common/security')
const constants = require('../constants')

module.exports = {
    validateCredentialsToGetAY : (req, res) => {
        logStream.write("In function - validateCredentialsToGetAY")

        let finalResult = {
            'valid_user' : 0,
            'AY_list' : [],
            'message' : 'Please enter the correct Ambika Id and Password.'
        }
        let body = req.body
        let conn = body.conn
        


        try{
            let query = "CALL `GET_ACADEMIC_YEAR`('" + body.ambikaid + "',MD5('" + body.password + "'),'" + body.environment + "')";

            if(isNaN(body.ambikaid) || body.ambikaid == ''){
                finalResult.message = "Ambika ID is wrong. Please use your Ambika ID."
                logStream.write({"message" : finalResult.message, "queryformed" : query})
                return res.status(200).json(finalResult);
            }

            if(body.password == ''){
                finalResult.message = "Password cannot be blank. Please enter correct password."
                logStream.write({"message" : finalResult.message, "queryformed" : query})
                return res.status(200).json(finalResult);
            }
            
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
                    finalResult.valid_user = results[0][0].valid_user
                    finalResult.AY_list = results[1]
                    if(finalResult.valid_user == 0 || finalResult.valid_user == false || finalResult.valid_user == '0') {
                        finalResult.message = 'Invalid credentials. Kindly reset password if you do not remember.'
                    }
                    else {
                        finalResult.apiKey = security.generateApiKey()
                        finalResult.message = 'Sign in successful. Welcome!'
                        // store generated api key in cache and db
                        security.addApiKey(body.ambikaid,finalResult.apiKey, (result) => {
                            if(!result){
                                logStream.write("Generated API key could not be stored correctly.")
                                finalResult.apiKey = ""
                                finalResult.message = "Something went wrong during sign in. Please contact administrator!"
                                finalResult.valid_user = 0
                            }
                        })
                    }

                    logStream.write(
                        {
                            "Entity"           : body.ambikaid ? body.ambikaid : 0,
                            "API Result Key"   : "none",
                            "API Result Value" : finalResult
                        }
                    )
                    return res.status(200).json(finalResult)
                }
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
            logStream.write("EOF - validateCredentialsToGetAY")
        }
    },

    getStudentData : (req,res) => {
        logStream.write("In function - getStudentData")

        const conn = req.params.conn
        const ambikaid = req.params.ambikaid
        const key = req.get(constants.apiKeyName)
        try{
            security.verifyApiKey(ambikaid, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }
                
                let query = "SELECT a.Roll_No, b.Ambika_ID, b.Name, DATE_FORMAT(a.DOJ, '%Y-%m-%d') as DOJ, a.Course_Name, c.Standard, c.Board, c.Batch, a.PaymentScheme, " + 
                    "DATE_FORMAT(b.DOB, '%Y-%m-%d') as DOB, b.Gender, b.Address, b.Primary_Email as Email, b.Primary_CN as Contact, a.Fee_Start_Month, d.School_Name, '' as Profile_Picture FROM `students` as a JOIN " + 
                    config.dbconn[3].db + ".`people` as b ON a.Ambika_ID = b.Ambika_ID " + 
                    "INNER JOIN `courses` as c on a.Course_Name = c.Course_Name " +
                    "INNER JOIN " + config.dbconn[3].db + ".`schools` as d on a.School_ID = d.ID " +
                    "WHERE a.Ambika_ID = " + ambikaid + ";";
                    
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
                        let fileDetails = getProfilePicPath(ambikaid)
                        if(fileDetails.fileName != 'No file')
                            results[0]['Profile_Picture'] = config.filePath + "profileImages/" + fileDetails.fileName

                        logStream.write(
                            {
                                "Entity"           : ambikaid ? ambikaid : 0,
                                "API Result Key"   : "studentData",
                                "API Result Value" : results[0]
                            }
                        )
                        return res.status(200).json({"studentData" : results[0]});
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" :  ambikaid ? ambikaid : 0,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getStudentData")
        }
    },

    uploadProfilePicture : async (req, res, next) => {
        logStream.write("In function - uploadProfilePicture")

        const body = req.body
        const ambikaid = body.ambikaid
        const key = req.get(constants.apiKeyName)
        try{
            security.verifyApiKey(ambikaid,key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }
                const file = req.file;
                
                if (!file) {
                    logStream.writeError(
                        {
                            "type" : "Param Error",
                            "errorMessage" : 'No image uploaded while calling upload profile picture API.',
                            "message" : 'Please upload an image.'
                        }
                    )
                    return res.status(400).send({ message: 'Please upload an image.' });
                }
                
                const fileName = file.originalname
                const currentPath = path.join(baseFilePath, allUploadPath, fileName);
                const destinationPath = path.join(baseFilePath, profilePicPath, "profilePic-" + body.ambikaid + ".jpg");
        
                let getExistingFile = getProfilePicPath(body.ambikaid, true) // to delete an existing image
        
                fs.rename(currentPath, destinationPath, function (err) {
                    if (err) {
                        logStream.writeError(
                            {
                                "type" : "File System Error",
                                "errorMessage" : 'File renaming and moving failed.',
                                "message" : err
                            }
                        )
                        return res.status(400).send({ message: 'File renaming and moving failed.' + err });
                    } else {
                        let msg = "Profile picture uploaded successfully.";

                        logStream.write(
                            {
                                "Entity"           : body.ambikaid ? body.ambikaid : 0,
                                "API Result Key"   : "message",
                                "API Result Value" : msg
                            }
                        )

                        return res.status(200).send({ message: msg });
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
            logStream.write("EOF - uploadProfilePicture")
        }
    },

    getProfilePicture : (req, res) => {
        logStream.write("In function - getProfilePicture")

        const ambikaid = req.params.ambikaid
        const key = req.get(constants.apiKeyName)
        try{
            security.verifyApiKey(ambikaid,key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                let fileDetails = getProfilePicPath(ambikaid)
            
                if(fileDetails.fileLocation == "No file"){
                    let msg = "Requested file was not found!"
                    logStream.write({"Message" :  msg})
                    return res.status(400).send({ message: msg});
                }
                else{
                    res.download(fileDetails.fileLocation,fileDetails.fileName)
                    logStream.write(
                        {
                            "Entity"           : ambikaid ? ambikaid : 0,
                            "API Result Key"   : "none",
                            "API Result Value" : "File found and downloaded successfully"
                        }
                    )
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
            logStream.write("EOF - getProfilePicture")
        }
    },

    peepCache : (req, res) => {
        let ambikaid
        try{
            ambikaid = req.params.ambikaid
            let cacheResults = security.peepCache(ambikaid)
            logStream.write(`Cache Results retrieved. Total length ${cacheResults.length}`)
            return res.status(200).send(security.peepCache(ambikaid));
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
            logStream.write("EOF - peepCache")
        }
    }
}

getProfilePicPath = (ambikaid, deleteFlag = false) => {
    let fileNameInJPG = "profilePic-" + ambikaid + ".jpg"
    let fileLocationInJPG = baseFilePath + profilePicPath + fileNameInJPG
    
    if(fs.existsSync(fileLocationInJPG)){
        if(deleteFlag) {
            fs.unlink(fileLocationInJPG,function(err){
                if(err) return console.log(err);
                console.log('JPG file deleted successfully!')
            })
        }
        return {
            fileLocation : fileLocationInJPG,
            fileName : fileNameInJPG
        }
    }
    else{
        return  {
            fileLocation : "No file",
            fileName : "No file"
        }
    }
}