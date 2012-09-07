exports.config =
  # See docs at http://brunch.readthedocs.org/en/latest/config.html.
  modules:
    definition: false
    wrapper: (path, data) ->
      """
(function() {
  'use strict';
  #{data}
}).call(this);\n\n
      """
  paths:
    public: '_public'
  files:
    javascripts:
      joinTo:
        'js/app.js': /^app/
        'js/vendor.js': /^vendor/
      order:
        before:
          * 'vendor/scripts/console-helper.js'
          * 'vendor/scripts/jquery-1.7.2.js'
          * 'vendor/scripts/angular/angular.js'
          * 'vendor/scripts/angular/angular-resource.js'
          * 'vendor/scripts/angular/angular-cookies.js'
          * 'vendor/scripts/angular/http-auth-interceptor.js'
          * 'vendor/scripts/angular-ui.js'
          * 'vendor/scripts/underscore-1.3.3.js'
          * 'vendor/scripts/date.js'
          * 'vendor/scripts/lawnchair-0.6.1.js'
          * 'vendor/scripts/markerwithlabel.js'

    stylesheets:
      joinTo:
        'css/app.css': /^(app|vendor)/

  # Enable or disable minifying of result js / css files.
  # minify: true
