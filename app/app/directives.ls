# Directive

# Create an object to hold the module.
mod = {}

# module for using css-toggle buttons instead of checkboxes
# toggles the class named in button-toggle element if value is checked
angular.module(\buttonToggle []).directive \buttonToggle -> do
        restrict: 'A',
        require: 'ngModel',
        link: ($scope, element, attr, ctrl) ->
            classToToggle = attr.buttonToggle;
            element.bind 'click', ->
                checked = ctrl.$viewValue;
                $scope.$apply (scope) -> ctrl.$setViewValue(!checked)

            $scope.$watch attr.ngModel, (newValue, oldValue) ->
                if newValue => element.addClass classToToggle else element.removeClass classToToggle 

# register the module with Angular
angular.module('app.directives', [
  # require the 'app.service' module
  'app.services'
]).directive(mod)
