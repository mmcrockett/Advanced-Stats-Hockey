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
  $scope.progress = {message:""}
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
        $scope.jsLiteralData = JsLiteral.from_json(data);

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
