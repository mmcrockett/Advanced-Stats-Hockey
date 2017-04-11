app.factory('Elo', ['$resource', function($resource) {
  return $resource('/graph.json', {}, {});
}]);
