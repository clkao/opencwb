# Declare app level module which depends on filters, and services
App = angular.module \app, <[ ngCookies ngResource app.controllers app.directives app.filters app.services ]>

App.config [ '$routeProvider' '$locationProvider'
($routeProvider, $locationProvider, config) ->
  $routeProvider
    .when \/forecasts, templateUrl: \/partials/app/forecasts.html
    .when \/view2, templateUrl: \/partials/app/partial2.html
    # Catch all
    .otherwise redirectTo: \/forecasts

  # Without serve side support html5 must be disabled.
  $locationProvider.html5Mode true
]
