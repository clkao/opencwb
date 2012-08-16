mod = {}

mod.OpenCWB = [ \$scope \$location \$resource \$rootScope
(s, $location, $resource, $rootScope) ->

  s.$location = $location
  s.$watch('$location.path()', (path) ->
    s.activeNavId = path || '/'
  )

  s.getClass = (id) ->
    if s.activeNavId.substring(0, id.length) == id
      return 'active'
    else
      return ''
  s.$on \area-changed, (...args) ->
      s.$broadcast(\xarea-changed, ...args)
]

mod.AreaSelect = [ '$scope' '$http' 'forecasts' (s, $http, forecasts) ->
  s.change = -> s.$emit \area-changed, s.currentArea
  $http.get(\/1/area).success ->
    s.areas = it
    forecasts.init(it)
]

mod.AreaForecast = [ '$scope', 'forecasts'
(s, forecasts) ->
  s.forecasts = forecasts
  s.getDate = (t) ->
      d = new Date t
      "#{d.getMonth!+1}/#{d.getDate!}"
  s.getTime = (t) ->
      new Date(t)getHours!

  dayOrNight = (h) -> (if h >= 18 || h <= 3 then 'night' else 'day')

  s.windIcon = (windlevel) -> if windlevel >= 3 then \circle-arrow-up else \arrow-up
  s.getWindStyle = (windlevel) -> do
      opacity: if windlevel <= 1 then 0.3 else if windlevel < 3 then 0.6 else 1
  s.getWeatherStyle = (t,f) ->
      [,icon] = f.WeatherIcon.match /Weather(\d+).bmp/;
      what = dayOrNight(s.getTime t)
      {background-image: "url('http://www.cwb.gov.tw/township/enhtml/pic/#{what}pic/#{what}_#icon.png')"}
  s.getDayOrNight = (t) ->
      h = s.getTime t
      res = \forecast-slot- + dayOrNight(h)
      res += ' forecast-slot-sep' if h === 0
      res
  s.getDateCols = ({forecasts:f}:area) ->
      return [] unless f?
      area.dateCols ||= for {time},i in f when i === 0 || new Date(time)getHours! === 0 then do
          date: s.getDate(time)
          cols: (24 - new Date(time)getHours!) / 3
      area.dateCols

  s.isStarred = forecasts.isStarred
  s.toggleStarred = forecasts.toggleStarred
  s.resetAll = forecasts.resetAll
  s.refresh = forecasts.refresh
  s.remove = forecasts.remove

  (,,...[areas]) <- s.$on \xarea-changed
  for a in areas
      forecasts.addForecast a
]

angular.module('app.controllers', []).controller(mod)
