let sql = require('../connections/connect-db')
let config = require('../config')
const fs = require("fs")
const path = require("path")
const baseFilePath = "./files/"
const adsPath = "ads/"
const mobileAppAdsPath = "mobile_app/"
const noticesPath = "notices/"
const allUploadPath = "uploads/"
const winston = require('../winston')
const logStream = winston.stream
const security = require('../common/security')
const constants = require('../constants')

module.exports = {
    getAllPublishedNotices : (req,res) => {
        logStream.write("In function - getAllPublishedNotices")

        const conn = req.params.conn
        const course = req.params.course
        const ambikaid = req.params.ambikaid
        const db_year_conn = req.params.db_year_conn
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(ambikaid, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const query = `SELECT * FROM (select n.ID, n.Ambika_ID, n.Title, n.Description, n.Course_Name, n.Database, DATE_FORMAT(n.Date, '%Y-%m-%d') as Date, DATE_FORMAT(n.Date, '%H:%i:%S') as Time, n.Status, n.File_Name, ay.Connection_Name 
                FROM notices as n LEFT JOIN academic_years as ay ON n.Database = ay.DB_Name AND ay.State = 1 ORDER BY Date DESC) as main WHERE main.Status = 1`;
                
                logStream.write(`Query fired : ${query}.`)
                sql[conn].query(query, (err, results) => {
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
                        notices = filterNotices(results,ambikaid,course,db_year_conn);
                        notices.forEach(notice => {
                            let fileDetails = getNoticeFilePath(notice.ID)

                            if(fileDetails.fileLocation == "No file"){
                                notice.File_Name = ""
                            }
                            else{
                                notice.File_Name = config.filePath + "notices/" + fileDetails.fileName
                            }                    
                        })

                        logStream.write(
                            {
                                "Entity"           : ambikaid ? ambikaid : 0,
                                "API Result Key"   : "allNotices",
                                "API Result Value" : "Result could be long. No of records : " + notices.length //avoid writing overhead hence printing the count
                            }
                        )

                        return res.status(200).json({"allNotices" :notices})
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "ambikaid" : ambikaid ? ambikaid : 0,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getAllPublishedNotices")
        }
        
    },

    getAds : (req,res) => {
        logStream.write("In function - getAds")

        try{
            const conn = req.params.conn;
            const query = `select * from advertisements WHERE Status = 1;`;
            let allAds = []

            logStream.write(`Query fired : ${query}.`)
            sql[conn].query(query, function(err, results) {
                if(err) {
                    logStream.writeError(err)
                    throw err;
                }
                else {
                    results.forEach(res => {
                        allAds.push(config.filePath + "ads/ad-" + res.Image_Name)
                    })

                    logStream.write(
                        {
                            "Entity"           : "MobileAppUser",
                            "API Result Key"   : "allAds",
                            "API Result Value" : allAds
                        }
                    )

                    return res.status(200).json({'allAds' : allAds});
                }
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "ambikaid" : ambikaid ? ambikaid : 0,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getAds")
        }
    },

    // for website notice board
    getCommonNotices : (req,res) => {
        logStream.write("In function - getCommonNotices")

        try{
            const query = `select * from notices where Status = 1 and Course_Name = 'ALL' and Ambika_ID = 0`;
        
            logStream.write(`Query fired : ${query}.`)
            sql.connect_main.query(query, function(err, results) {
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
                    results.forEach(notice => {
                        let fileDetails = getNoticeFilePath(notice.ID)

                        if(fileDetails.fileLocation == "No file"){
                            notice.file = ""
                            console.log("No file found for notice id " + notice.ID)
                        }
                        else{
                            notice.file = config.filePath + "notices/" + fileDetails.fileName
                        }                    
                    })
                    
                    logStream.write(
                        {
                            "Entity"           : "Website",
                            "API Result Key"   : "commonNotices",
                            "API Result Value" : "Result could be long. No of records : " + results.length //avoid writing overhead hence printing the count
                        }
                    )

                    return res.status(200).json({"commonNotices" : results})
                }
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getCommonNotices")
        }
    },

    uploadAds : (req, res) => {
        logStream.write("In function - uploadAds")
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const file = req.file
                const fileName = file.originalname
                if (!file) {
                    logStream.writeError({
                        type : 'Erroneous Params',
                        message : 'API was called without attaching a file.'
                    })
                    return res.status(400).send({ message: 'Please upload a file.' });
                }
                // const fileName = file.originalname
                const body = req.body
                
                const currentPath = path.join(baseFilePath, allUploadPath, fileName)
                const destinationPath = path.join(baseFilePath, adsPath, "ad-" + fileName)

                fs.rename(currentPath, destinationPath, function (err) {
                    if (err) {
                        let msg = 'File renaming and moving failed.' + err
                        logStream.writeError({
                            type : 'File System Error',
                            message : msg
                        })
                        return res.status(500).send({ message: msg });
                    } else {
                        let msg = "Successfully renamed and moved the file!";
                        logStream.write(
                            {
                                "Entity"           : "Website",
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
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - uploadAds")
        }
        
    },

    uploadFileForNotice : (req, res) => {
        logStream.write("In function - uploadFileForNotice")
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const file = req.file
                if (!file) {
                    logStream.writeError({
                        type : 'Erroneous Params',
                        message : 'API was called without attaching a file.'
                    })
                    return res.status(400).send({ message: 'Please upload a file.' });
                }
                const fileName = file.originalname
                const body = req.body
                
                
                const currentPath = path.join(baseFilePath, allUploadPath, fileName)
                const destinationPath = path.join(baseFilePath, noticesPath, "notice-" + body.noticeid + path.extname(fileName))

                fs.rename(currentPath, destinationPath, function (err) {
                    if (err) {
                        let msg = 'File renaming and moving failed.' + err
                        logStream.writeError({
                            type : 'File System Error',
                            message : msg
                        })
                        return res.status(400).send({ message: msg });
                    } else {
                        let msg = "Successfully renamed and moved the file!";
                        logStream.writeError({
                            type : 'File System Error',
                            message : msg
                        })
                        return res.status(200).send({ message: msg });
                    }
                })
            })
        }
        catch(ex) {
            logStream.writeError(
                {
                    "type" : "Exception",
                    "message" : ex.message,
                    "stack" : ex.stack
                }
            )

            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - uploadFileForNotice")
        }
        
    },

    getAllNotices : (req,res) => {
        logStream.write("In function - getAllNotices")
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(0, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const query = `select n.ID, n.Title, n.Description, n.Ambika_ID, n.Module, n.Course_Name, n.Database, DATE_FORMAT(n.Date, '%Y-%m-%d') as Date, DATE_FORMAT(n.Date, '%H:%i:%S') as Time, n.Status, ay.Connection_Name, ay.Academic_Year FROM notices as n LEFT JOIN academic_years as ay ON n.Database = ay.DB_Name AND ay.State = 1 ORDER BY Date DESC;`
                
                logStream.write(`Query fired : ${query}.`)
                sql.connect_main.query(query, (err, results) => {
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
                        results.forEach(notice => {
                            let fileDetails = getNoticeFilePath(notice.ID)

                            if(fileDetails.fileLocation == "No file"){
                                notice.File_Name = ""
                            }
                            else{
                                notice.File_Name = config.filePath + "notices/" + fileDetails.fileName
                            }                    
                        })
                        
                        logStream.write(
                            {
                                "Entity"           : "ManageAmbika",
                                "API Result Key"   : "allNotices",
                                "API Result Value" : "Result could be long. No of records : " + results.length //avoid writing overhead hence printing the count
                            }
                        )
                        
                        return res.status(200).json({"allNotices" :results});
                    }
                })
            })
        }
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : "",
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - uploadAds")
        }
    },

    getMobileAppAds : (req, res) => {
        let flag = true
        let imageNumber = 1
        let mobileAppAds = []
        while(flag){
            let ad = getMobileAppAdsPath(imageNumber)
            if(ad.fileName == 'No file' || imageNumber == 20){
                flag = false
                break
            }
            mobileAppAds.push(config.filePath + adsPath + mobileAppAdsPath + ad.fileName)
            imageNumber++
        }

        return res.status(200).json({"mobileAppAds" : mobileAppAds})
    }
}

filterNotices = (allnotices,ambikaid,course,db_year_conn) => {
    let final_list = [];
    allnotices.forEach(notice => {

        if(checkCourses(notice.Course_Name,course,notice.Connection_Name,db_year_conn)){
            if(notice.Ambika_ID == ambikaid || notice.Ambika_ID == 0){
                final_list.push(notice);
            }
        }
    })

    return final_list;
}

checkCourses = (courses,mycourse,notice_conn,my_conn) => {
    let allcourses = courses.split(',');
    return (allcourses.includes(mycourse) && notice_conn == my_conn) || allcourses == 'ALL';
}

getNoticeFilePath = (noticeid) => {
    let fileNameInJPG = "notice-" + noticeid + ".jpg"
    let fileNameInPNG = "notice-" + noticeid + ".png"
    let fileNameInJPEG = "notice-" + noticeid + ".jpeg"
    let fileNameInPDF = "notice-" + noticeid + ".pdf"
    let fileLocationInJPG = baseFilePath + noticesPath + fileNameInJPG
    let fileLocationInPNG = baseFilePath + noticesPath + fileNameInPNG
    let fileLocationInJPEG = baseFilePath + noticesPath + fileNameInJPEG
    let fileLocationInPDF = baseFilePath + noticesPath + fileNameInPDF

    if(fs.existsSync(fileLocationInJPG)){
        return {
            fileLocation : fileLocationInJPG,
            fileName : fileNameInJPG
        }
    }
    else if(fs.existsSync(fileLocationInPNG)){
        return {
            fileLocation : fileLocationInPNG,
            fileName : fileNameInPNG
        }
    }
    else if(fs.existsSync(fileLocationInJPEG)){
        return {
            fileLocation : fileLocationInJPEG,
            fileName : fileNameInJPEG
        }
    }
    else if(fs.existsSync(fileLocationInPDF)){
        return {
            fileLocation : fileLocationInPDF,
            fileName : fileNameInPDF
        }
    }
    else{
        return  {
            fileLocation : "No file",
            fileName : "No file"
        }
    }
}

getMobileAppAdsPath = (imageNumber) => {
    let fileNameInJPG = "ad-mobile_app-" + imageNumber + ".jpg"
    let fileNameInPNG = "ad-mobile_app-" + imageNumber + ".png"
    let fileNameInJPEG = "ad-mobile_app-" + imageNumber + ".jpeg"
    let fileNameInPDF = "ad-mobile_app-" + imageNumber + ".pdf"
    let fileLocationInJPG = baseFilePath + adsPath + mobileAppAdsPath + fileNameInJPG
    let fileLocationInPNG = baseFilePath + adsPath + mobileAppAdsPath + fileNameInPNG
    let fileLocationInJPEG = baseFilePath + adsPath + mobileAppAdsPath + fileNameInJPEG
    let fileLocationInPDF = baseFilePath + adsPath + mobileAppAdsPath + fileNameInPDF

    if(fs.existsSync(fileLocationInJPG)){
        return {
            fileLocation : fileLocationInJPG,
            fileName : fileNameInJPG
        }
    }
    else if(fs.existsSync(fileLocationInPNG)){
        return {
            fileLocation : fileLocationInPNG,
            fileName : fileNameInPNG
        }
    }
    else if(fs.existsSync(fileLocationInJPEG)){
        return {
            fileLocation : fileLocationInJPEG,
            fileName : fileNameInJPEG
        }
    }
    else if(fs.existsSync(fileLocationInPDF)){
        return {
            fileLocation : fileLocationInPDF,
            fileName : fileNameInPDF
        }
    }
    else{
        return  {
            fileLocation : "No file",
            fileName : "No file"
        }
    }
}