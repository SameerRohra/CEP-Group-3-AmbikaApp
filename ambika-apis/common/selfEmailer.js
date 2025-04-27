let nodemailer = require('nodemailer')
const winston = require('../winston')
const logStream = winston.stream

let transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'ambikaclasses123@gmail.com',
    pass: 'lqwckvtbqksipcrv'
  }
})

module.exports = {
    sendEmail : (message, from = 'ambikaclasses123@gmail.com', to = "shubhampanda126@gmail.com", subject = "Message from Ambika API.") => {
        let mailOptions = {
            from: from,
            to: to,
            subject: subject,
            text: message
        }
    
        transporter.sendMail(mailOptions, function(error, info){
            if (error) {
              logStream.write(error)
            } else {
              logStream.write('Email sent: ' + info.response)
            }
        })
    }
}


