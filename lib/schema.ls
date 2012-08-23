mongoose = require \mongoose
Schema = mongoose.Schema

s = {}
s.ForecastSchema = new Schema do
    issued:  Date
    time: Date
    area: String
    forecast: do
        PoP:    Number

s.LastUpdatedSchema = new Schema do
    key: String
    time: Date

s.TyphoonSchema = new Schema do
    _id: String
    issued:  Date
    source: String
    name: String
    year: Number
    forecasts: []
    current: {}
    past: []

module.exports = { [name, mongoose.model name, s[name + 'Schema']] for name in
    <[ Forecast LastUpdated Typhoon ]>
}
