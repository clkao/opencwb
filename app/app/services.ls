# Services

# Create an object to hold the module.
mod = {}

mod.version = -> "0.1"

mod.store = ->
    new Lawnchair {
        adapter: \dom
        name: \starred
    }, -> it

mod.forecasts = ['$http', 'store', ($http, store) ->
    var splicer
    forecasts = {
        current: []
        _current: {}
        starred: {}
        all: {}
        addForecast: (area) -> 
            if !forecasts.all[area.zip] || forecasts.all[area.zip]dirty
                forecasts.all[area.zip] ||= {} <<< area;
                forecasts.all[area.zip]loading = true
                $http.get("/1/forecast/#{area.zip}").success ->
                    forecasts.all[area.zip] = forecasts.all[area.zip] <<< forecasts: it
                    forecasts.all[area.zip]loading = null
                    delete forecasts.all[area.zip]['dateCols'] if forecasts.all[area.zip]dirty
                    delete forecasts.all[area.zip]['dirty']

            unless forecasts._current[area.zip]
                forecasts.current.push(forecasts._current[area.zip] = forecasts.all[area.zip])

        setCurrent: (zip) ->
            [a] = [a for a in forecasts.areas when zip is a.zip]
            return unless a
            console.log a
            forecasts.addForecast a
            forecasts.all[zip]geoCurrent = true
        refresh: (area) ->
            forecasts.all[area.zip]dirty = true
            forecasts.addForecast area
        remove: (area) ->
            console.log \removing, area.zip
            delete forecasts._current[area.zip]
            forecasts.current .= filter -> it.zip != area.zip
        isStarred: (zip) ->
            if forecasts.starred[zip] then 'icon-star' else 'icon-star-empty'
        toggleStarred: (zip) ->
            forecasts.starred[zip] = !forecasts.starred[zip]
            store.save {key: \starred, starred: forecasts.starred}
        resetAll: ->
            forecasts.current = [forecasts.all[zip] for zip of forecasts.starred]
            forecasts._current = {[zip,f] for zip,f of forecasts.current}
        init: (areas) ->
            config <- store.get 'starred'
            forecasts.starred = config?starred || {}
            for a in areas when forecasts.starred[a.zip] => forecasts.addForecast a
            forecasts.areas = areas
    }

    splicer = ->
        now = new Date!
        for zip,{forecasts:f}:area of forecasts.all => let f, area
            if new Date(f[0].time).getTime! < now.getTime! - 2400 * 3000
                f.shift!
                area.dateCols = null

    runner = (delay) ->
        setTimeout ->
            splicer!
            runner!
        , 1000 * (delay ? 1800)

    runner (15 - new Date!getMinutes!) %% 60 * 60

    forecasts
]

angular.module('app.services', []).factory(mod)
