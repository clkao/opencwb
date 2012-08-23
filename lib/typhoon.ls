mongoose = require \mongoose
Schema = mongoose.Schema

TyphoonSchema = new Schema do
    _id: String
    issued:  Date
    source: String
    name: String
    year: Number
    forecasts: []
    current: {}
    past: []

Typhoon = mongoose.model \Typhoon, TyphoonSchema

module.exports = Typhoon
