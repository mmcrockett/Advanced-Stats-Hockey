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
        angular.forEach(data, function(obj, i) {
          obj.date = new Date(obj.date);
        });

        $scope.eloData = data;
        $scope.eloChart.data = JsLiteral.from_json($scope.eloData);
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
