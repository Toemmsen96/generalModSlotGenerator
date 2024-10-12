angular.module('beamng.apps')
.directive('generalModslotGenerator', [function () {
  return {
    template:
    '<div style="max-height:100%; width:100%;" layout="row" layout-align="center center" layout-wrap class="bngApp">' +
      '<input style="margin: 2px; min-width: 250px; color: #FFFFFF" type="text" ng-model="templatePath" placeholder="Template Path">' +
      '<input style="margin: 2px; min-width: 250px; color: #FFFFFF" type="text" ng-model="templateName" placeholder="Template Name">' +
      '<input style="margin: 2px; min-width: 250px; color: #FFFFFF" type="text" ng-model="outputPath" placeholder="Output Path">' +
      '<md-button flex style="margin: 2px; min-width: 152px" md-no-ink class="md-raised" ng-click="generateSpecificMod()">Generate Specific Mod</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 152px" md-no-ink class="md-raised" ng-click="generateSeparateMods()">Generate Separate Mods</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 152px" md-no-ink class="md-raised" ng-click="getTemplateNames()">Get Template Names</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 152px" md-no-ink class="md-raised" ng-click="generate()">Generate Multislot Modslots</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 178px" md-no-ink class="md-raised md-warn" ng-click="deleteTempFiles()">Delete Generated Files</md-button>' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    link: function (scope, element, attrs) {
        scope.status = "";
        scope.templatePath = ""; // Initialize the templatePath variable
        scope.templateName = ""; // Initialize the templateName variable
        scope.generate = function () {
            bngApi.engineLua('extensions.tommot_modslotGenerator.onExtensionLoaded()');
        };

        scope.generateSpecificMod = function () {
            bngApi.engineLua('extensions.tommot_modslotGenerator.generateSpecificMod("' + scope.templatePath + '", "' + scope.templateName + '", "' + scope.outputPath + '")');
        }

        scope.generateSeparateMods = function () {
            bngApi.engineLua('extensions.tommot_modslotGenerator.generateSeparateMods()');
        }

        scope.deleteTempFiles = function () {
            bngApi.engineLua('extensions.tommot_modslotGenerator.deleteTempFiles()');
        }

        scope.getTemplateNames = function () {
            bngApi.engineLua('extensions.tommot_modslotGenerator.getTemplateNames()');
        }
    }
  }
}]);