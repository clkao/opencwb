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

  (,,...[areas]) <- s.$on \xarea-changed
  for a in areas
      forecasts.addForecast a
]

angular.module('app.controllers', []).controller(mod)
