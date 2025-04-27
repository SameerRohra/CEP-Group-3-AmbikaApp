let sql = require('../connections/connect-db')
let config = require('../config')
const winston = require('../winston')
const logStream = winston.stream
const security = require('../common/security')
const constants = require('../constants')

module.exports = {
    getFeeDetails : (req,res) => {
        logStream.write("In function - getFeeDetails")

        const conn = req.params.conn;
        const ambikaid = req.params.ambikaid;
        const key = req.get(constants.apiKeyName)

        try{
            security.verifyApiKey(ambikaid, key, (result) => {
                if(!result){
                    res.status(401).json({"message" :"Key verification failed."})
                    return
                }

                const queryForTransactions = `SELECT DATE_FORMAT(f.Payment_Date, '%Y-%m-%d') as Date,f.* FROM fees f
                                                INNER JOIN students s ON f.Roll_No = s.Roll_No AND f.Course_Name = s.Course_Name
                                                    WHERE s.Ambika_ID = ?`;
                const queryForMonthWise = `SELECT f.Month, sum(f.Amount) as Amount, group_concat(f.Payment_Ref) as Payment_Refs FROM fees f 
                                                INNER JOIN students s ON f.Roll_No = s.Roll_No AND f.Course_Name = s.Course_Name
                                                    WHERE s.Ambika_ID = ? GROUP BY Month`
                const queryForSummary = `SELECT s.Fee_Start_Month,fs.* FROM fee_structure fs INNER JOIN students s ON fs.ID = s.Fee_Structure_ID
                                                WHERE s.Ambika_ID = ?`;
                const queryValues = [ambikaid]
                
                let data = {};
                logStream.write(`Query fired : ${queryForTransactions}. Query values : ${queryValues}`)
                sql[conn].query(queryForTransactions, queryValues, (err_transactions, res_transactions) => {
                    if(err_transactions) {
                        logStream.writeError(
                            {
                                "type" : "SQLError",
                                "message" : err_transactions
                            }
                        )
                        return res.status(500).json({"message" :"SQL error occurred. Please check logs!"})
                    }
                    else {
                            logStream.write(`Query fired : ${queryForMonthWise}. Query values : ${queryValues}`)
                            sql[conn].query(queryForMonthWise, queryValues, (err_monthwise, res_monthwise) => {
                                if(err_monthwise) {
                                    logStream.writeError(
                                        {
                                            "type" : "SQLError",
                                            "message" : err_monthwise
                                        }
                                    )
                                    return res.status(500).json({"message" :"SQL error occurred. Please check logs!"})
                                }
                                else {
                                    logStream.write(`Query fired : ${queryForSummary}. Query values : ${queryValues}`)
                                    sql[conn].query(queryForSummary, queryValues, (err_summary, res_summary) => {
                                        if(err_summary) {
                                            logStream.writeError(
                                                {
                                                    "type" : "SQLError",
                                                    "message" : err_summary
                                                }
                                            )
                                            return res.status(500).json({"message" :"SQL error occurred. Please check logs!"})
                                        }
                                        else {
                                            data.allFeeData = makeData(res_summary,res_transactions,res_monthwise)
                                            logStream.write(
                                                {
                                                    "Entity"           : conn + " : " + ambikaid,
                                                    "API Result Key"   : "allFeeData",
                                                    "API Result Value" : "Result could be long. Summary : " + JSON.stringify(data.allFeeData.summary)
                                                                            + ". Monthwise Length: " + String(data.allFeeData.monthwise.length)
                                                                                + ". Transactions Length: " + String(data.allFeeData.transactions.length)
                                                }
                                            )
                                            return res.status(200).send(data)
                                        }
                                    })
                                }       
                            })
                        }
                })
            })
        }            
        catch(ex) {
            let errorMsg = {
                "type" : "Exception",
                "entity" : conn + " : " + ambikaid,
                "message" : ex.message,
                "stack" : ex.stack
            }
            logStream.writeError(errorMsg)
            return res.status(500).json({"message" :"Exception occurred. Please check logs!"})
        }
        finally {
            logStream.write("EOF - getFeeDetails")
        }
    }
}

makeData = (feestructure,transactions,monthwise) => {
    let summary = {};
    let payable_data = feestructure[0];
    
    let fee_array = [payable_data.Admission_Fee,payable_data.May,payable_data.June,payable_data.July,payable_data.August,payable_data.September,payable_data.October,payable_data.November,payable_data.December,payable_data.January,payable_data.February,payable_data.March,payable_data.April];
    let fee_month = ['Admission_Fee','May','June','July','August','September','October','November','December','January','February','March','April'];
    
    let start_month_index = fee_month.indexOf(payable_data.Fee_Start_Month);
    let total_payable = Number(payable_data.Admission_Fee);

    for(i = start_month_index; i < fee_array.length; i++){
        total_payable += Number(fee_array[i]);
    }

    summary.total_payable = total_payable;

    let total_paid = 0;
    transactions.forEach(transaction => {
        total_paid += Number(transaction.Amount);
    });

    summary.total_paid = total_paid;

    summary.due_amount = total_payable - total_paid;

    let months = [];
    monthwise.forEach(month => {
        month.PayRefList = month.Payment_Refs.split(",")
    })

    for(i = 0; i < fee_month.length; i++){
        let month = {};
        let monthData = monthwise.filter(mw => mw.Month == fee_month[i])
        month.Month = fee_month[i] == "Admission_Fee" ? "Enrollment Fee" : fee_month[i]
        month.Amount = monthData.length > 0 ? monthData[0].Amount : 0
        month.PayRefList = monthData.length > 0 ? monthData[0].PayRefList : []
        month.Payable = Number(fee_array[i])
        month.DueAmount = month.Payable - month.Amount
        month.DueDate = 15
        month.ReminderDate = 10
        month.Snooze = 0
        month.Status = getStatus(month.Amount, month.Payable)
        if(month.Payable > 0) months.push(month) 
    }

    monthwise.forEach(month => {
        month.PayRefList = month.Payment_Refs.split(",")
    })

    return {
        summary : summary,
        monthwise : months,
        transactions : getTransactions(transactions)
    }

}

getTransactions = (transactions) => {
    let finalTransactions = []
    let payRefs = [...new Set(transactions.map(t => t.Payment_Ref))]
    
    payRefs.forEach(ref => {
        let transactionsGroupedByPayRef = transactions.filter(tsns => tsns.Payment_Ref == ref)
        let clubbedTransaction = {
            Payment_Ref : ref,
            Amount : 0,
            Months : [],
            Date : transactionsGroupedByPayRef[0].Date,
            Mode : transactionsGroupedByPayRef[0].Mode,
            Details : transactionsGroupedByPayRef[0].Notes
        }
        transactionsGroupedByPayRef.forEach(tgbpr => {
            clubbedTransaction.Amount += tgbpr.Amount
            clubbedTransaction.Months.push(tgbpr.Month)
        })
        finalTransactions.push(clubbedTransaction)
    })

    return finalTransactions;
}

getMonths = (months) => {
    months.forEach(month => {
        month.PayRefList = month.Payment_Refs.split(",")
    })
    
    return months
}

getStatus = (paid, payable) => {
    if(payable == 0){
        return "NA"
    }
    let due = payable - paid
    if(due > 0){
        if(paid > 0){
            return "Partial"
        }
        return "Pending"
    }
    if(due == 0){
        return "Paid"
    }
}