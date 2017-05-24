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
    data: JsLiteral.EMPTY_DATA(),
    type: 'LineChart',
    options: {
      annotations: {
        textStyle: {
          fontSize: 10
        }
      },
      explorer: {
        keepInBounds: true,
        axis: 'horizontal',
        actions: ['dragToZoom', 'rightClickToReset']
      },
      hAxis: {
        ticks: []
      }
    }
  };
  $scope.clear_progress = function() {
    $scope.progress.message = "";
  };
  $scope.initialize = function() {
    $scope.progress.message = "Loading data...";
    Elo
    .get()
    .$promise
    .then(
      function(response){
        $scope.progress.message = "Rendering chart...";
        var js_literal_options = {'elo':{}};
        var data   = response.data;
        var labels = response.labels;

        js_literal_options.elo[JsLiteral.TYPE] = 'number';

        $scope.jsLiteralData = JsLiteral.from_json(data, js_literal_options);

        $scope.eloChart.data = $scope.jsLiteralData;

        angular.forEach(labels, function(v, i) {
          $scope.eloChart.options.hAxis.ticks.push({v:new Date(v.date), f:v.label});
        });
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
