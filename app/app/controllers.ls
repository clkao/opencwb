mod = {}

mod.OpenCWB = [ \$scope \$location \$resource \$rootScope \forecasts
(s, $location, $resource, $rootScope, forecasts) ->

  s.$location = $location
  s.$watch('$location.path()', (path) ->
    s.activeNavId = path || '/'
  )

  s.getClass = (id) ->
    if s.activeNavId.substring(0, id.length) == id
      return 'active'
    else
      return ''
  $rootScope.$on \area-list, (, it) ->
      s.areas = it

  s.$watch 'currentArea', (newV, oldV)->
      forecasts.addForecast newV if newV
]

mod.AreaSelect = [ '$scope' '$http' 'forecasts', '$rootScope' (s, $http, forecasts, $rootScope) ->
  s.$watch 'currentArea', (newV, oldV)->
      if newV => for a in newV => forecasts.addForecast a
  $rootScope.$on \area-list, (, it) ->
      s.areas = it
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
      res += ' forecast-slot-sep' if h is 0
      res
  s.getForecastsByDate = ({forecasts:f}:area) ->
      return [] unless f?
      area.dateCols ||= _.groupBy(f, ({time}) -> s.getDate(time))

  s.isStarred = forecasts.isStarred
  s.toggleStarred = forecasts.toggleStarred
  s.resetAll = forecasts.resetAll
  s.refresh = forecasts.refresh
  s.remove = forecasts.remove

  if navigator.geolocation
    {{latitude,longitude}:coords} <- navigator.geolocation.getCurrentPosition
    geocoder = new google.maps.Geocoder();
    result, status <- geocoder.geocode {latLng: new google.maps.LatLng latitude,longitude } 
    forecasts.setCurrent result[3]address_components[0]short_name
]

angular.module('app.controllers', []).controller(mod)
