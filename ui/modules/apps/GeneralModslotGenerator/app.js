angular.module('beamng.apps')
.directive('generalModslotGenerator', ['$timeout', function ($timeout) {
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
      '<md-button flex style="margin: 2px; min-width: 152px" md-no-ink class="md-raised" ng-click="loadSettings()">Load Settings</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 152px" md-no-ink class="md-raised" ng-click="saveSettings()">Save Settings</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 178px" md-no-ink class="md-raised md-warn" ng-click="deleteTempFiles()">Delete Generated Files</md-button>' +
      '<md-checkbox ng-model="separateMods" aria-label="Separate Mods">Separate Mods</md-checkbox>' +
      '<md-checkbox ng-model="detailedDebug" aria-label="Detailed Debug">Detailed Debug</md-checkbox>' +
      '<md-checkbox ng-model="useCoroutines" aria-label="Use Coroutines">Use Coroutines</md-checkbox>' +
      '<md-checkbox ng-model="autoApply" aria-label="Automatically apply Settings">Automatically apply Settings</md-checkbox>' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    link: function (scope, element, attrs) {
        scope.status = "";
        scope.templatePath = ""; // Initialize the templatePath variable
        scope.templateName = ""; // Initialize the templateName variable
        scope.outputPath = ""; // Initialize the outputPath variable
        scope.separateMods = false;
        scope.detailedDebug = false;
        scope.useCoroutines = false;
        scope.autoApply = false;
        var disableWatchers = false;

        // Array to track initial values
        var initialValues = {
            separateMods: null,
            detailedDebug: null,
            useCoroutines: null,
            autoApply: null
        };

        bngApi.engineLua('extensions.tommot_modslotGenerator.sendSettingsToUI()');

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
        scope.loadSettings = function () {
            bngApi.engineLua('extensions.tommot_modslotGenerator.loadSettings()');
        }
        scope.saveSettings = function () {
            var data = {
                SeparateMods: scope.separateMods,
                DetailedDebug: scope.detailedDebug,
                UseCoroutines: scope.useCoroutines,
                AutoApplySettings: scope.autoApply
            };
            var jsonData = JSON.stringify(data);
            // Escape the JSON string for Lua
            var escapedJsonData = jsonData.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
            disableWatchers = true;
            bngApi.engineLua('extensions.tommot_modslotGenerator.setModSettings("' + escapedJsonData + '")');
            $timeout(function() {
                disableWatchers = false;
            }, 100); // Adjust the timeout duration as needed
        }

        function checkAndSaveSettings() {
            if (scope.autoApply && !disableWatchers) {
                if (initialValues.separateMods !== scope.separateMods ||
                    initialValues.detailedDebug !== scope.detailedDebug ||
                    initialValues.useCoroutines !== scope.useCoroutines ||
                    initialValues.autoApply !== scope.autoApply) {
                    scope.saveSettings();
                }
            }
        }

        scope.$watch('separateMods', function(newValue, oldValue) {
            if (initialValues.separateMods === null) {
                initialValues.separateMods = newValue;
            } else {
                checkAndSaveSettings();
            }
        });
        scope.$watch('detailedDebug', function(newValue, oldValue) {
            if (initialValues.detailedDebug === null) {
                initialValues.detailedDebug = newValue;
            } else {
                checkAndSaveSettings();
            }
        });
        scope.$watch('useCoroutines', function(newValue, oldValue) {
            if (initialValues.useCoroutines === null) {
                initialValues.useCoroutines = newValue;
            } else {
                checkAndSaveSettings();
            }
        });
        scope.$watch('autoApply', function(newValue, oldValue) {
            if (initialValues.autoApply === null) {
                initialValues.autoApply = newValue;
            } else {
                checkAndSaveSettings();
            }
        });

        scope.$on('setModSettings', function (event, data) {
            $timeout(function() {
                disableWatchers = true;
                scope.separateMods = data.SeparateMods;
                scope.detailedDebug = data.DetailedDebug;
                scope.useCoroutines = data.UseCoroutines;
                scope.autoApply = data.AutoApplySettings;
                initialValues.separateMods = data.SeparateMods;
                initialValues.detailedDebug = data.DetailedDebug;
                initialValues.useCoroutines = data.UseCoroutines;
                initialValues.autoApply = data.AutoApplySettings;
                disableWatchers = false;
            });
        });
    }
  }
}]);