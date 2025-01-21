angular.module('beamng.apps')
.directive('generalModslotGeneratorToggleMenu', [function () {
  return {
    template:
    '<div style="max-height:100%; width:100%;" layout="row" layout-align="center center" layout-wrap class="bngApp">' +
      '<md-button flex style="margin: 2px; min-width: 140px" md-no-ink class="md-raised" ng-click="toggleMenu()">Toggle GMSG-UI</md-button>' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    link: function (scope, element, attrs) {
        scope.toggleMenu = function () {
            bngApi.engineLua('extensions.tommot_gmsgUI.toggleUI()');
        };
    }
  }
}]);