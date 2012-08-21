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
    * (s) ->
        render_typhoon = (name, $str) ->
            path = $str.split(" \n").map ->
                [time, lat, lon, sw, ...wind] = it.split(" ")
                lat = parseInt(lat) / 10
                lon = parseInt(lon) / 10
                windr = []
                while wind.length
                    [wr, ne, ,, se ,,, sw ,,, nw ,,] = wind.splice 0, 13;
                    windr.push {wr,ne,se,sw,nw}
                { time, lat, lon, sw, windr }

            s.myPaths.push new google.maps.Polyline do
                path: [new google.maps.LatLng(lat,lon) for {lat,lon} in path]
                strokeColor: \#FF0000
                strokeOpacity: 0.7
                strokeWeight: 2
                map: s.myMap

            for {time,lat,lon,windr},i in path
                console.log time, windr
                pos = new google.maps.LatLng(lat,lon)
                if i == path.length-1 => new MarkerWithLabel do
                    position: pos
                    map: s.myMap
                    labelContent: name
                    labelAnchor: new google.maps.Point(44, 60)
                    labelClass: "typhoon-name"
                    icon: 'foo.png'
                new MarkerWithLabel do
                    position: pos
                    map: s.myMap
                    labelContent: time
                    labelAnchor: new google.maps.Point(22, 0)
                    labelClass: "labels"
                    labelStyle: opacity: 0.75
                    icon: 'foo.png'
                for {wr,ne,se,sw,nw} in windr
                    s.myCircles.push new google.maps.Circle do
                        strokeColor: \#FF0000
                        strokeOpacity: 0.15
                        strokeWeight: 2
                        fillColor: \#FF0000
                        fillOpacity: 0.1,
                        map: s.myMap,
                        center: pos
                        radius: Math.max(ne,se,sw,nw) * 1852


        s.myMarkers = []
        s.myCircles = []
        s.myPaths = []
        s.time = "082109Z"

        typhoons = 
            * name: \TEMBIN
              jmv: """T000 210N 1254E 110 R064 030 NE QD 030 SE QD 030 SW QD 030 NW QD R050 065 NE QD 065 SE QD 060 SW QD 060 NW QD R034 100 NE QD 100 SE QD 095 SW QD 095 NW QD 
T012 220N 1250E 115 R064 035 NE QD 035 SE QD 035 SW QD 035 NW QD R050 070 NE QD 065 SE QD 065 SW QD 065 NW QD R034 110 NE QD 110 SE QD 105 SW QD 105 NW QD 
T024 227N 1243E 120 R064 040 NE QD 035 SE QD 035 SW QD 040 NW QD R050 070 NE QD 070 SE QD 065 SW QD 070 NW QD R034 120 NE QD 115 SE QD 115 SW QD 115 NW QD 
T036 232N 1233E 120 R064 040 NE QD 040 SE QD 040 SW QD 040 NW QD R050 070 NE QD 070 SE QD 070 SW QD 070 NW QD R034 125 NE QD 120 SE QD 120 SW QD 125 NW QD 
T048 236N 1220E 110 R064 040 NE QD 040 SE QD 040 SW QD 040 NW QD R050 070 NE QD 070 SE QD 070 SW QD 070 NW QD R034 130 NE QD 125 SE QD 125 SW QD 130 NW QD 
T072 239N 1191E 075 R064 025 NE QD 025 SE QD 025 SW QD 025 NW QD R050 050 NE QD 050 SE QD 050 SW QD 050 NW QD R034 110 NE QD 100 SE QD 100 SW QD 110 NW QD 
T096 238N 1165E 065 
T120 238N 1144E 050"""
            * name: \BOLAVEN
              jmv: """T000 184N 1404E 055 R050 025 NE QD 025 SE QD 025 SW QD 025 NW QD R034 050 NE QD 050 SE QD 050 SW QD 050 NW QD 
T012 190N 1391E 065 R050 030 NE QD 025 SE QD 025 SW QD 030 NW QD R034 065 NE QD 060 SE QD 060 SW QD 065 NW QD 
T024 195N 1376E 070 R064 020 NE QD 020 SE QD 020 SW QD 020 NW QD R050 040 NE QD 035 SE QD 035 SW QD 040 NW QD R034 085 NE QD 080 SE QD 080 SW QD 085 NW QD 
T036 201N 1359E 075 R064 025 NE QD 025 SE QD 025 SW QD 025 NW QD R050 045 NE QD 045 SE QD 045 SW QD 045 NW QD R034 100 NE QD 095 SE QD 095 SW QD 100 NW QD 
T048 207N 1340E 080 R064 030 NE QD 030 SE QD 030 SW QD 030 NW QD R050 050 NE QD 050 SE QD 050 SW QD 050 NW QD R034 110 NE QD 105 SE QD 105 SW QD 110 NW QD 
T072 219N 1307E 090 R064 035 NE QD 035 SE QD 035 SW QD 035 NW QD R050 060 NE QD 060 SE QD 060 SW QD 060 NW QD R034 125 NE QD 120 SE QD 120 SW QD 125 NW QD 
T096 230N 1281E 095 
T120 245N 1256E 100"""

        s.$watch \myMap, ->
            for {name,jmv} in typhoons => render_typhoon name, jmv

        s.setZoomMessage = (zoom) -> console.log('You just zoomed to '+zoom+'!')
        s.addMarker = ($event) ->
            console.log $event
            s.myMarkers.push new google.maps.Marker do
                map: s.myMap
                position: $event.latLng
            console.log s.myMarkers
        s.mapOptions = do
          center: new google.maps.LatLng(24.03, 121.24)
          zoom: 6
          mapTypeId: google.maps.MapTypeId.ROADMAP
        console.log s.mapOptions

angular.module('app.controllers', []).controller(mod)
