mongoose = require \mongoose
Typhoon = require \../lib/typhoon
Q = require \q

env = (try JSON.parse fs.readFileSync \environment.json, \utf8) or process.env
mongoose.connect env.MONGOLAB_URI

parse = (body) ->
    lines = body.split("\n")map (it) -> it - /\s*$/
    meta = {}
    past = []
    for line in lines when date = line.match /^(\d\d\d\d)(\d\d)(\d\d)(\d\d) /
        --date[2]
        time = new Date(Date.UTC(...date[1 to 4]))
        if meta.name
            [, coor, swind] = line.split " "
            [,lat,lon] = line.match /(\d+)N(\d+)E/ .map (it) -> it/10
            past.push {time, swind, lat, lon}
        else
            [,,meta.name,meta.warningId] = line.split(/\s+/)
            meta.issued = time
    paths = []
    for line in lines
        if line.match(/^T/)
            paths.push line
        break if line == 'AMP'
    paths = paths.map ->
        [time, lat, lon, swind, ...wind] = it.split(" ")
        lat = parseInt(lat) / 10
        lon = parseInt(lon) / 10
        swind = parseFloat swind
        windr = []
        while wind.length
            wr = wind.shift!
            [ne, ,, se ,,, sw ,,, nw ,,] = wind.splice(0, 12)map -> parseFloat it
            windr.push {wr,ne,se,sw,nw}
        { time, lat, lon, swind, windr }

    current = paths.shift!

    results = { current, paths, past, meta }

request = require \request

error, {statusCode}?, data <- request \http://jtwccdn.appspot.com/JTWC/
$ = require \cheerio .load(data)

defers = []
do
    <- $('a:contains(JMV 3.0 Data)').each
    defer = Q.defer!
    defers.push defer.promise
    uri = $(@)attr('href')
    error, {statusCode}?, body <- request uri
#body = fs.readFileSync \/tmp/wp1512.tcw.txt, \utf8
    { meta, current, paths, past } = parse body

    console.log meta
    year = meta.issued.getFullYear!
    _id = "JTWC-#{meta.name}-#year-#{meta.warningId}"
    t = new Typhoon { forecasts: paths, current, past: past, issued: meta.issued, source: \JTWC, name: meta.name, year, _id }
    err <- t.save!
    console.log err, \saved
    defer.resolve!

<- Q.allResolved defers
.then
console.log \alldone
process.exit 0
