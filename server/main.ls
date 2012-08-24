_ = require \underscore
{Forecast,LastUpdated,Typhoon} = require \../lib/schema

@include = ->
    cwb = require \cwbtw
    @use \bodyParser, @app.router, @express.static __dirname + \/../_public


    RealBin = require \path .dirname do
        require \fs .realpathSync __filename
    RealBin -= /\/server/

    LastUpdated.findOne { key: \72hr-forecast }, (err, last) ~>
        @last = last.time

    sendFile = (file) -> ->
        @response.contentType \text/html
        @response.sendfile "#RealBin/_public/#file"

    JsonType = { \Content-Type : 'application/json; charset=utf-8' }

    cache = {}
    cached_json = (opts, cb) -> (p) ->
        name = opts.key
        if opts.keyparam
            name += ':' + p[opts.keyparam]
        if {results,expiry}? = cache[name] => if expiry > new Date!getTime!
            return @response.send JSON.stringify(results), JsonType, 200
        results <~ cb p
        cache[name] = { results, expiry: new Date!getTime! + 10*60*1000 }
        @response.send JSON.stringify(results), JsonType, 200

    forecast_for = (area, cb) ~>
        Forecast.find { area, issued: @last }
            .sort \time
            .exec (err, results) ->
                cb err, [ {area,issued,time,forecast} for {area,issued,time,forecast} in results]

    get_area = (cb) ~>
        cb null, _.values cwb.cwbspec

    @set databag: \param
    @get '/1/forecast/:area': cached_json key: \forecast keyparam: \area, (p, cb) ->
        err, results <~ forecast_for p.area
        cb results

    @get '/1/area': (p) ->
        err, results <~ get_area
        @response.send JSON.stringify(results), JsonType, 200

    @get '/1/typhoon/:source': cached_json keyparam: \source, key: \_list, (p, cb) ->
        err, res <- Typhoon.find do
            source: p.source.toUpperCase!
            year: new Date!getFullYear!
            issued: $gt: new Date(new Date! - 1000*86400)
        .sort issued: -1
        .exec

        results = {}
        for {name}:entry in res
            results[name] ||= entry
        cb _.values results

    @get '/1/typhoon/jtwc/:name': cached_json key: \jtwc keyparam: \name, (p, cb) ->
        err, results <~ Typhoon.findOne { source: \JTWC, name: p.name, year: new Date!getFullYear! }
            .sort issued: -1
            .limit 1
            .exec
        cb results

    @get '/1/typhoon/cwb/:name': cached_json key: \cwb keyparam: \name, (p, cb) ->
        err, results <~ Typhoon.findOne { source: \CWB, name: p.name, year: new Date!getFullYear! }
            .sort issued: -1
            .limit 1
            .exec
        cb results

    @get '/:what': sendFile \index.html
