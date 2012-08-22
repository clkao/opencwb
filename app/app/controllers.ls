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

mod.TyphoonCtrl = 
    * '$scope'
    * '$http'
    * (s, $http) ->
        render_windr = ({wr}:windr, lat, lon) ->
            path = []
            for qd,i in <[ne se sw nw]> => let r = windr[qd] * 1852 / 111000, steps = [90*i to 90*(i+1) by 6]
                path.=concat [new google.maps.LatLng(
                    lat + r * Math.cos(rx),
                    lon + r * Math.sin(rx)) for rx in steps.map -> it / 180 * Math.PI]
            new google.maps.Polygon do
                map: s.myMap
                paths: path
                strokeColor: \#FF0000
                strokeOpacity: 0.15
                strokeWeight: 2
                fillColor: \#FF0000
                fillOpacity: 0.1

        hurricane = new google.maps.MarkerImage \/img/hurricane.png, null,
                        new google.maps.Point(0,0),
                        new google.maps.Point(12, 12),
                        new google.maps.Size(24, 24)
        hurricane-filled = new google.maps.MarkerImage \/img/hurricane-filled.png, null,
                        new google.maps.Point(0,0),
                        new google.maps.Point(12, 12),
                        new google.maps.Size(24, 24)

        var render_typhoon2
        render_typhoon = (name, paths, issued, past) ->
            path = paths.map ->
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
            render_typhoon2 name, path, issued, past

        render_typhoon2 = (name, paths, issued, past=[]) ->
            pastpath = [for node,i in past
                [time, coor, swind] = node.split " "
                [,lat,lon] = coor.match /(\d+)N(\d+)E/ .map (it) -> it/10
                strong = swind >= 65
                flip = if i % 2 then 1 else -1
                pos = new google.maps.LatLng lat, lon
                new MarkerWithLabel do
                    position: pos
                    map: s.myMap
                    labelContent: ''
                    labelAnchor: new google.maps.Point(20, 30 * flip)
                    labelClass: "labels"
                    labelStyle: opacity: 0.75
                    opacity: 0.7
                    icon: if strong then hurricane-filled else hurricane

                pos
            ]
            s.myPaths.push new google.maps.Polyline do
                path: pastpath
                strokeColor: \#FF0000
                strokeOpacity: 0.7
                strokeWeight: 2
                map: s.myMap

            s.myPaths.push new google.maps.Polyline do
                path: [new google.maps.LatLng(lat,lon) for {lat,lon} in paths]
                strokeColor: \#FF0000
                strokeOpacity: 0.7
                strokeWeight: 2
                map: s.myMap

            for {time,swind,lat,lon,windr},i in paths
                pos = new google.maps.LatLng(lat,lon)
                strong = swind >= 65
                flip = if i % 2 then 1 else -1
                if i == paths.length-1 => new MarkerWithLabel do
                    position: pos
                    map: s.myMap
                    labelContent: name
                    labelAnchor: new google.maps.Point(44, 60)
                    labelClass: "typhoon-name"
                    icon: hurricane
                new MarkerWithLabel do
                    position: pos
                    map: s.myMap
                    labelContent: time
                    labelAnchor: new google.maps.Point(20, 30 * flip)
                    labelClass: "labels"
                    labelStyle: opacity: 0.75
                    opacity: 0.7
                    icon: if strong then hurricane-filled else hurricane
                windr?forEach -> render_windr it, lat, lon

        s.myMarkers = []
        s.myCircles = []
        s.myPaths = []

        s.$watch \myMap, ->
            $http.get("/1/typhoon/jtwc/wp1612").success ({name,paths,issued, past})->
                render_typhoon name, paths, issued, past
                s.JTWCtime = issued
            $http.get("/1/typhoon/jtwc/wp1512").success ({name,paths,issued, past})->
                render_typhoon name, paths, issued, past
                s.JTWCtime = issued
            $http.get("/1/typhoon/cwb").success ->
                for t in it => let t
                    render_typhoon2 t.name, [time: \T0, lon: t.lon, lat: t.lat]+++ t.forecasts
                s.CWBtime = t.date

        s.setZoomMessage = (zoom) ->
            s.zoom = zoom
            size = if zoom > 9 then 36 else if zoom > 5 then 24 else if zoom > 3 then 12 else 0
            hurricane.scaledSize = new google.maps.Size(size, size)
            hurricane.anchor = new google.maps.Point(size/2, size/2)
            hurricane-filled.scaledSize = new google.maps.Size(size, size)
            hurricane-filled.anchor = new google.maps.Point(size/2, size/2)

        s.addMarker = ($event) ->
            s.myMarkers.push new google.maps.Marker do
                map: s.myMap
                position: $event.latLng
        s.mapOptions = do
          center: new google.maps.LatLng(24.03, 121.24)
          zoom: 6
          mapTypeId: google.maps.MapTypeId.ROADMAP

angular.module('app.controllers', []).controller(mod)
