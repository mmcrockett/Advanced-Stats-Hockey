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
  $scope.eloData = [];
  $scope.eloChart = {
    "type": "LineChart"
  };
  $scope.initialize = function() {
    Elo
    .query()
    .$promise
    .then(
      function(data){
        $scope.jsLiteralData = JsLiteral.from_json(data);

        $scope.eloChart.data = $scope.jsLiteralData;
        Logger.debug("Retrieved elos, count '" + $scope.eloData.length + "'.");
      }
    ).catch(
      function(e){
        $scope.error = "Couldn't load data.";
        Logger.error("Failure '" + e + "'.");
      }
    ).finally();
  };
}]);
