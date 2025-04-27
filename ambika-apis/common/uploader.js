const multer = require('multer')

let path = './files/uploads/'

let storage = multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, path)
    },
    filename: function (req, file, cb) {
      cb(null, file.originalname)
    }
})

let upload = multer({ 
  storage: storage,
  fileFilter: function (req, file, callback) {
    if(file.mimetype !== 'image/png' 
          && file.mimetype !== 'image/jpg'
                && file.mimetype !== 'image/jpeg'
                    && file.mimetype !== 'application/pdf') {
        return callback('Invalid file type.')
    }
    callback(null, true)
},
})

module.exports = upload