app.controller('ElosController', [
'$scope',
'$log',
'Elo',
'JsLiteral',
function(
  $scope,
  Logger,
  Elo,
  JsLiteral
) {
  $scope.error = "";
  $scope.progress = {message:""};
  $scope.eloData = [];
  $scope.eloChart = {
    "type": "LineChart"
  };
  $scope.clear_progress = function() {
    $scope.progress.message = "";
  };
  $scope.initialize = function() {
    $scope.progress.message = "Loading data...";
    Elo
    .query()
    .$promise
    .then(
      function(data){
        $scope.progress.message = "Rendering chart...";
        var js_literal_options = {'elo':{}};
        js_literal_options.elo[JsLiteral.TYPE] = 'number';

        $scope.jsLiteralData = JsLiteral.from_json(data, js_literal_options);

        $scope.eloChart.data = $scope.jsLiteralData;
        Logger.debug("Retrieved elos, count '" + data.length + "'.");
      }
    ).catch(
      function(e){
        $scope.error = "Couldn't load data.";
        Logger.error("Failure '" + e + "'.");
      }
    ).finally();
  };
}]);
