const express = require('express')

//Router declarations
const healthCheckRouter = express.Router()
const signupRouter = express.Router()
const signinRouter = express.Router()
const lectureRouter = express.Router()
const feeRouter = express.Router()
const adsandnoticeRouter = express.Router()
const enquiryRouter = express.Router()
const employmentEnquiryRouter = express.Router()
const lectureByDateRouter = express.Router()
const otpRouter = express.Router()
const appConfigRouter = express.Router()
const attendanceRouter = express.Router()
const examsandresultsRouter = express.Router()
const fqcRouter = express.Router()
const notificationRouter = express.Router()

//Service import
const healthCheckService = require('../services/healthcheck-services')
const signupService = require('../services/signup-services')
const signinService = require('../services/signin-services')
const lectureService = require('../services/lecture-services')
const feeService = require('../services/fee-services')
const adsandnoticeService = require('../services/adsandnotice-services')
const enquiryService = require('../services/enquiry-services')
const appConfigService = require('../services/appconfiguration-services')
const attendanceService = require('../services/attendance-services')
const examsandresultsService = require('../services/examsandresults-services')
const fqcService = require('../services/fqc-services')
const notificationService = require('../services/notification-services')
const commonUploaderService = require('../common/uploader')


//API routes
signupRouter.get('/validateUserExistence/:conn/:ambikaid/:emailid', signupService.validateUserExistence)
signupRouter.post('/addPassword', signupService.addPassword)

signinRouter.post('/validateCredentialsToGetAY', signinService.validateCredentialsToGetAY)
signinRouter.get('/getStudentData/:conn/:ambikaid', signinService.getStudentData)
signinRouter.post('/uploadProfilePicture', commonUploaderService.single('profilePic'), signinService.uploadProfilePicture)
signinRouter.get('/getProfilePicture/:ambikaid', signinService.getProfilePicture)
signinRouter.get('/peepcache/:ambikaid', signinService.peepCache)

lectureRouter.get('/all/:conn/:course' , lectureService.getLectures)
lectureRouter.get('/groupByDate/:conn/:course/:noOfRecords' , lectureService.getAllLectures)
lectureRouter.get('/forDate/:conn/:date', lectureService.getLecturesForDate)

feeRouter.get('/get/:conn/:ambikaid', feeService.getFeeDetails)

adsandnoticeRouter.get('/allNotices/:conn/:ambikaid/:course/:db_year_conn', adsandnoticeService.getAllPublishedNotices)
adsandnoticeRouter.get('/allAds/:conn', adsandnoticeService.getAds)
adsandnoticeRouter.get('/getCommonNotices', adsandnoticeService.getCommonNotices)
adsandnoticeRouter.get('/uploadAds', commonUploaderService.single('ads'), adsandnoticeService.uploadAds)
adsandnoticeRouter.post('/uploadFileForNotice', commonUploaderService.single('fileForNotice'), adsandnoticeService.uploadFileForNotice)
adsandnoticeRouter.get('/allNotices/', adsandnoticeService.getAllNotices)
adsandnoticeRouter.get('/mobileAppAds',adsandnoticeService.getMobileAppAds)

enquiryRouter.post('/addEnquiry',enquiryService.addEnquiry)
enquiryRouter.post('/addEmploymentEnquiry',enquiryService.addEmploymentEnquiry)

otpRouter.get('/get/:conn/:ambikaid/:emailid',signupService.getOTP)
otpRouter.post('/add',signupService.addOTP)

appConfigRouter.get('/getBaseURL', appConfigService.getBaseURL)

attendanceRouter.get('/student/:conn/:ambikaid', attendanceService.getAttendanceForStudent)
attendanceRouter.post('/addAbsenceReason',attendanceService.addAbsenceReason)

examsandresultsRouter.get('/course/:conn/:course', examsandresultsService.getExamsForCourse)
examsandresultsRouter.get('/summary/:conn/:ambikaid', examsandresultsService.getExamsResultsForStudent)

fqcRouter.get('/student/:ambikaid', fqcService.getFQCsForStudent)
fqcRouter.get('/all/', fqcService.getALLFQCs)
fqcRouter.post('/add/', fqcService.addFQC)

notificationRouter.post('/addToken/', notificationService.addToken)
notificationRouter.post('/send/', notificationService.send)

healthCheckRouter.get('/ping', healthCheckService.checkAllHealth)

//Export
module.exports = {
    signupRouter : signupRouter,
    signinRouter : signinRouter,
    lectureRouter : lectureRouter,
    feeRouter : feeRouter,
    adsandnoticeRouter : adsandnoticeRouter,
    enquiryRouter : enquiryRouter,
    employmentEnquiryRouter : employmentEnquiryRouter,
    lectureByDateRouter : lectureByDateRouter,
    otpRouter : otpRouter,
    appConfigRouter : appConfigRouter,
    attendanceRouter : attendanceRouter,
    examsandresultsRouter : examsandresultsRouter,
    fqcRouter : fqcRouter,
    notificationRouter: notificationRouter,
    healthCheckRouter: healthCheckRouter
}