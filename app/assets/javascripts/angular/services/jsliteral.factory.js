app.factory('JsLiteral', ['$log', 'humanizeFilter', function(Logger, HumanizeFilter) {
  var STYLE='style';
  var CALLBACK='callback';
  var jsliteral_function = function(input, options) {
      var output = {};
      output.cols = [];
      output.rows = [];

      angular.forEach(input, function(wdata, i) {
        var row = {c:[]};
        var style = {};

        angular.forEach(wdata, function(v, k) {
          if (0 == i) {
            var type = "Unknown";
            if (true == angular.isNumber(v)) {
              type = "number";
            } else if (true == angular.isDate(v)) {
              type = "date";
            } else if (true == angular.isString(v)) {
              type = "string";
            } else if (("boolean" === typeof v) || (null == v)) {
              type = "boolean";
            } else if (true == angular.isObject(v)) {
              type = "string";
            } else {
              Logger.error("!ERROR: type unknown '" + typeof v + "'.");
            }

            output.cols.push({
              "id"   : k,
              "label": HumanizeFilter(k),
              "type" : type,
            });
          }

          if (true == _.has(options, k)) {
            key_options = options[k];

            if (true == _.has(key_options, STYLE)) {
              style_modifier = key_options[STYLE];
              if (true == angular.isFunction(style_modifier)) {
                style["style"] = style_modifier(v, wdata);
              } else {
                style["style"] = style_modifier;
              }
            }

            if (true == _.has(key_options, CALLBACK)) {
              callback = key_options[CALLBACK];
              if (true == angular.isFunction(callback)) {
                v = callback(v, wdata);
              } else {
                Logger.error("Not a function for callback on '" + k + "' and '" + v + "' callback is '" + callback + "'.");
              }
            }
          }

          row.c.push({v:v, p:style});
        });
        output.rows.push(row);
      });

      return output;
  }

  return {
    STYLE: STYLE,
    CALLBACK: CALLBACK,
    from_json: jsliteral_function
  };
}]);
