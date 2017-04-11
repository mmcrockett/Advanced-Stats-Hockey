app.filter('humanize', function() {
  return function(input) {
    var words  = input.toLowerCase().replace(/_/g, " ").split(" ");
    var output = null;

    angular.forEach(words, function(word, i) {
      var capitalized_word = word.charAt(0).toUpperCase() + word.slice(1);

      if (0 == i) {
        output = capitalized_word;
      } else {
        output += " " + capitalized_word;
      }
    });

    return output;
  };
})
