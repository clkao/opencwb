mongoose = require \mongoose
{Typhoon} = require \../lib/schema
Q = require \q
fs = require \fs

env = (try JSON.parse fs.readFileSync \environment.json, \utf8) or process.env
mongoose.connect env.MONGOLAB_URI

request = require \request
vm = require \vm

all_r = (r) -> { ne: r, se: r, nw: r, sw: r }
make_entry = -> do
    lat: parseFloat @lat
    lon: parseFloat @lon
    time: @tau
    swind: @wind * 1.943
    windr: [ { wr: 27 } <<< all_r(@r7 / 1.852) ] +++ if @r10 > 0 => [ { wr: 48 } <<< all_r(@r10 / 1.852) ] else []

make_past = ->
    @time[1]--
    do
        lat: parseFloat @lat
        lon: parseFloat @lon
        swind: @wind * 1.943
        time: new Date(Date.UTC ...@time)

defers = []

parse_typhoon = (t) ->
    defer = Q.defer!
    defers.push defer.promise

    time = t.init
    --time[1]
    meta = { issued: new Date(Date.UTC ...time), name: t.typhname_eng }

    year = meta.issued.getFullYear!
    current = make_entry.apply t.curr
    past = [make_past.apply p for p in t.best_track]
    forecasts = [make_entry.apply f for f in t.fcst]
    console.log meta
    _id = "CWB-#{meta.name}-#year-#{meta.issued.getTime!}"
    t = new Typhoon { forecasts, current, past: past, issued: meta.issued, source: \CWB, name: meta.name, year, _id }
    err <- t.save!
    console.log err, \saved
    defer.resolve!

parse_uri = (uri) ->
    d = Q.defer!
    do
        error, {statusCode}?, data <- request uri
        sandbox = {}
        vm.runInNewContext(data, sandbox)
        for t in sandbox.typhs => parse_typhoon t
        d.resolve!
    return d

d = <[ http://www.cwb.gov.tw/V7/prevent/typhoon/Data/PTA_NEW/js/datas/ty_infos.js
       http://www.cwb.gov.tw/V7e/prevent/warning/Data/TEDPTA/js/datas/ty_infos.js?082317 ]>
.map -> (parse_uri it).promise

<- Q.allResolved d
.then
console.log \wait
<- Q.allResolved defers
.then
console.log \alldone
process.exit 0
