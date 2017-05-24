app.factory('JsLiteral', ['$log', 'humanizeFilter', function(Logger, HumanizeFilter) {
  var STYLE='style';
  var CALLBACK='callback';
  var TYPE='type';
  var RESERVED_COLUMNS=_.constant(['annotation', 'tooltip']);
  var EMPTY_DATA = _.constant({
    cols:[
      {label:null,type:'string'},
      {label:null,type:'number'}
    ],
    rows:[
      {c:[
        {v:null},
        {v:null}]}
    ]
  });
  var get_column_type = function(k, v, key_options) {
    if (true == _.has(key_options, TYPE)) {
      return key_options[TYPE];
    } else {
      return infer_column(k, v);
    }
  };
  var infer_column = function(k, sample_v) {
    var type = "Unknown";
    if (true == angular.isNumber(sample_v)) {
      type = "number";
    } else if (true == angular.isDate(sample_v)) {
      type = "date";
    } else if (true == angular.isString(sample_v)) {
      if (-1 != k.toLowerCase().indexOf("date")) {
        type = "date";
      } else {
        type = "string";
      }
    } else if (("boolean" === typeof sample_v) || (null == sample_v)) {
      type = "boolean";
    } else if (true == angular.isObject(sample_v)) {
      type = "string";
    } else {
      Logger.error("!ERROR: type unknown '" + typeof sample_v + "'.");
    }

    return type;
  };
  var build_column = function(id, label, type, p) {
    var column = {
      id: id,
      label: label,
      type: type
    };

    if (true == angular.isObject(p)) {
      column['p'] = p;
    }

    return column;
  };
  var jsliteral_function = function(input, options) {
      var output = {};
      options = options || {};
      output.cols = [];
      output.rows = [];

      angular.forEach(input, function(wdata, i) {
        var row = {c:[]};
        var style = {};

        angular.forEach(wdata, function(v, k) {
          var key_options = options[k] || {};
          var v_options   = {};
          var col_type    = get_column_type(k, v, key_options);
          var v_options   = {};

          if (true == angular.isObject(v)) {
            var sub_data = _.omit(v, RESERVED_COLUMNS());
            v_options  = _.pick(v, RESERVED_COLUMNS());

            if (1 != _.values(sub_data).length) {
              Logger.error("Tried to deconstruct an object with length != 1, taking first value '" + k + "' '" + angular.toJson(v) + "'.");
            }

            v     = _.first(_.values(sub_data));
            sub_k = _.first(_.keys(sub_data));
            col_type = get_column_type(k, v, _.extend(key_options, options[sub_k]));
          }

          if (0 == i) {
            output.cols.push(build_column(k, HumanizeFilter(k), col_type));

            angular.forEach(v_options, function(v2, k2) {
              output.cols.push(build_column('', '', 'string', {role: k2}));
            })
          }

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

          if ((true == angular.isString(v)) && ('date' == col_type)) {
            v = new Date(v);
          }

          if (false == _.isEmpty(style)) {
            row.c.push({v:v, p:style});
          } else {
            row.c.push({v:v});
          }

          if (true === jQuery.jsliteral_debug) {
            Logger.debug("'" + v + "' '" + col_type + "' jsliteral_debug");
          }

          angular.forEach(v_options, function(v2, k2) {
            row.c.push({v:v2});
          })
        });
        output.rows.push(row);
      });

      return output;
  };

  return {
    STYLE: STYLE,
    CALLBACK: CALLBACK,
    TYPE: TYPE,
    EMPTY_DATA: EMPTY_DATA,
    from_json: jsliteral_function,
    infer_column: infer_column,
    build_column: build_column
  };
}]);
