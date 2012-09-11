mongoose = require \mongoose
Schema = mongoose.Schema

s =
    ForecastSchema: Schema do
        issued: Date
        time: Date
        area: String
        forecast: do
            PoP:    Number

    LastUpdatedSchema: new Schema do
        key: String
        time: Date

    TyphoonSchema: Schema do
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
