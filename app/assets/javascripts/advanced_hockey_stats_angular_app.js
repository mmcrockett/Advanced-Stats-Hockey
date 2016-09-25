var app = angular.module('AdvancedHockeyStats', ['ngResource', 'ui.bootstrap']);
app.config(["$httpProvider", function(provider) {
  provider.defaults.headers.common['X-CSRF-Token'] = jQuery('meta[name=csrf-token]').attr('content');
}]);
app.config(["$logProvider", function(provider) {
  if (true !== jQuery.development) {
    provider.debugEnabled(false);
  }
}]);
