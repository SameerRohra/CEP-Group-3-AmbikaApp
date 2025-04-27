const express = require('express')
const cors = require('cors');

const app = express()

app.use(cors({
    origin: '*'
}));

app.use(express.urlencoded({ extended: true }))
app.use(express.json())

const student = require('./routes/students')
app.use('/getStudents', student.getStudentRouter)
app.use('/getFees', student.getFeesRouter)

const router = require('./routes/router')
app.use('/signup',router.signupRouter)
app.use('/signin',router.signinRouter)
app.use('/lectures', router.lectureRouter)
app.use('/fees',router.feeRouter)
app.use('/adsandnotices',router.adsandnoticeRouter)
app.use('/enquiries',router.enquiryRouter)
app.use('/otp',router.otpRouter)
app.use('/config',router.appConfigRouter)
app.use('/attendance',router.attendanceRouter)
app.use('/exams',router.examsandresultsRouter)
app.use('/fqc',router.fqcRouter)
app.use('/notification/',router.notificationRouter)
app.use('/health', router.healthCheckRouter)

module.exports = app