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
        render_windr = ({wr}:windr, lat, lon, color = \#ff0000) ->
            path = []
            for qd,i in <[ne se sw nw]> => let r = windr[qd] * 1852 / 111000, steps = [90*i to 90*(i+1) by 6]
                path.=concat [new google.maps.LatLng(
                    lat + r * Math.cos(rx),
                    lon + r * Math.sin(rx)) for rx in steps.map -> it / 180 * Math.PI]
            new google.maps.Polygon do
                map: s.myMap
                paths: path
                strokeColor: color
                strokeOpacity: 0.15
                strokeWeight: 2
                fillColor: color
                fillOpacity: 0.1

        hicons = {[i, new google.maps.MarkerImage "/img/#i.png", null,
            new google.maps.Point(0,0),
            new google.maps.Point(12, 12),
            new google.maps.Size(24, 24)] for i in <[hurricane hurricane-filled]>}


        labels = {}

        time_MDH = (t) -> (t.getMonth!+1)+'-'+(t.getDate!)+'T'+(t.getHours!)+'Z'
        mk_label = (pos, name, source, issued) ->
            labels[name] ||= new MarkerWithLabel do
                position: pos
                map: s.myMap
                labelContent: name
                labelAnchor: new google.maps.Point(144,30)
                labelClass: "typhoon-name"
                icon: hicons.hurricane
            labels[name].labelContent = labels[name].labelContent + "<div class='issued #{source}'>#{source}: #{time_MDH(issued)}</div>"

        render_typhoon = (name, paths, issued, past=[],pathColor=\#ff0000, source="") ->
            pastpath = [for node,i in past
                {time, lat,lon, swind} = node
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
                    icon: if strong then hicons[\hurricane-filled] else hicons.hurricane

                pos
            ]
            s.myPaths.push new google.maps.Polyline do
                path: pastpath
                strokeColor: \#FF0000
                strokeOpacity: 0.7
                strokeWeight: 2
                map: s.myMap

            s.myPaths.push fpaths = new google.maps.Polyline do
                path: [new google.maps.LatLng(lat,lon) for {lat,lon} in paths]
                strokeColor: pathColor
                strokeOpacity: 0.7
                strokeWeight: 2
                map: s.myMap

            for {time,swind,lat,lon,windr},i in paths
                pos = new google.maps.LatLng(lat,lon)
                strong = swind >= 65
                flip = if i % 2 then 1 else -1
#                plat = Math.min ...paths.map (.lat)
#                plon = Math.min ...paths.map (.lon)
                if i == paths.length-1 => mk_label pos, name, source, issued
                date = new Date(issued + (Number("#time" - /^T0+/) * 60min * 60sec * 1000ms))
                dateString = "#{1+date.getMonth!}/#{date.getDate!} #{date.getHours!}h"

                new MarkerWithLabel do
                    position: pos
                    map: s.myMap
                    labelContent: dateString
                    labelAnchor: new google.maps.Point(20, 30 * flip)
                    labelClass: "typhoon-time #source"
                    labelStyle: opacity: 0.75
                    opacity: 0.7
                    icon: if strong then hicons[\hurricane-filled] else hicons.hurricane
                windr?forEach -> render_windr it, lat, lon, pathColor

        parseDate = (str) ->
            | matched = "#str".match //^(\d\d)(\d\d)UTC\s+(\d+)\s+(\w+)\s+(\d+)//
                [_, hh, mm, day, month, year] = matched
                month = "#{$.inArray(month, <[ _
                    January February March April May June July
                    August September October November December
                ]>)}"replace(/^(.)$/, "0$1")
                new Date "#{year}-#{month}-#{day}T#hh:#mm:00Z"
            | otherwise => new Date str

        s.myMarkers = []
        s.myCircles = []
        s.myPaths = []

        s.$watch \myMap, ->
            $http.get("/1/typhoon/jtwc").success ->
                for t in it => let t
                    issued = new Date t.issued
                    render_typhoon t.name, [t.current] +++ t.forecasts, issued, t.past,,\JTWC
            $http.get("/1/typhoon/cwb").success ->
                for t in it => let t
                    issued = new Date t.issued
                    render_typhoon t.name, [t.current] +++ t.forecasts, issued, null,\#0000ff ,\CWB

        s.setZoomMessage = (zoom) ->
            s.zoom = zoom
            size = if zoom > 9 then 36 else if zoom > 5 then 24 else if zoom > 3 then 12 else 0
            for name,i of hicons
                i.scaledSize = new google.maps.Size(size, size)
                i.anchor = new google.maps.Point(size/2, size/2)

        s.addMarker = ($event) ->
            s.myMarkers.push new google.maps.Marker do
                map: s.myMap
                position: $event.latLng
        s.mapOptions = do
          center: new google.maps.LatLng(24.03, 121.24)
          zoom: 6
          mapTypeId: google.maps.MapTypeId.ROADMAP

angular.module('app.controllers', []).controller(mod)
