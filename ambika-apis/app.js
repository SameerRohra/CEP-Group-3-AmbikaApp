const app = require('./index')
let winston = require('./winston')
let morgan = require('morgan')

app.listen(3000, (err) => {
    if (err) throw err
    console.log('Server running in http://127.0.0.1:3000')
})

app.use(morgan('combined', { stream: winston.stream }))