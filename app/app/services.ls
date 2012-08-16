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
    forecasts = {
        current: []
        _current: {}
        starred: {}
        all: {}
        addForecast: (area) -> 
            unless forecasts.all[area.zip]
                forecasts.all[area.zip] = {} <<< area;
                $http.get("/1/forecast/#{area.zip}").success ->
                    forecasts.all[area.zip] = forecasts.all[area.zip] <<< forecasts: it
            unless forecasts._current[area.zip]
                forecasts.current.push(forecasts._current[area.zip] = forecasts.all[area.zip])

        isStarred: (zip) ->
            if forecasts.starred[zip] then 'icon-star' else 'icon-star-empty'
        toggleStarred: (zip) ->
            forecasts.starred[zip] = !forecasts.starred[zip]
            store.save {key: \starred, starred: forecasts.starred}
        resetAll: ->
            console.log forecasts.starred
            forecasts.current = [forecasts.all[zip] for zip of forecasts.starred]
            forecasts._current = {[zip,f] for zip,f of forecasts.current}
        init: (areas) ->
            config <- store.get 'starred'
            forecasts.starred = config.starred || {}
            for a in areas when forecasts.starred[a.zip] => forecasts.addForecast a

    }
    forecasts
]

angular.module('app.services', []).factory(mod)
