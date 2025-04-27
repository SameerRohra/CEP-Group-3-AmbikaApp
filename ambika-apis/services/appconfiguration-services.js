const express = require('express');
var sql = require('../connections/connect-db');

module.exports = {
    getBaseURL: (req, res) => {
        let connection = req.params.conn;
        let query = "SELECT ConfigValue as BaseURL FROM app_settings WHERE CommonContext = 'APIURL' AND Active_Flag = 1 ORDER BY ID DESC LIMIT 1;";
        sql.connect_main.query(query, function (err, results) {
            if(err) {
                throw err;
            }
            else {
                return res.status(200).json(results);
            }
        }); 
    }
}