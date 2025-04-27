const express = require('express')

//Router declarations
const getStudentRouter = express.Router()
const getFeesRouter = express.Router()

//Service import
const studentService = require('../services/student-services')

//API routes
getStudentRouter.get('/:conn/:course/:rollno', studentService.getStudents)
getFeesRouter.get('/:conn', studentService.getFees)

//Export
module.exports = {
    getStudentRouter : getStudentRouter,
    getFeesRouter : getFeesRouter
}