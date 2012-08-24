# Declare app level module which depends on filters, and services
App = angular.module \app, <[ ngCookies ngResource buttonToggle app.controllers app.directives app.filters app.services ui.directives]>

App.config [ '$routeProvider' '$locationProvider'
($routeProvider, $locationProvider, config) ->
  $routeProvider
    .when \/forecasts, templateUrl: \/partials/app/forecasts.html
    .when \/typhoon, templateUrl: \/partials/app/typhoon.html
    # Catch all
    .otherwise redirectTo: \/typhoon

  # Without serve side support html5 must be disabled.
  $locationProvider.html5Mode true
]
