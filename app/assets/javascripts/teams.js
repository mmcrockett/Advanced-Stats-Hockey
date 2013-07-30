var Team = Backbone.Model.extend({
  name: function(){return this.get("name") || "";}
  ,games: function(){return this.get("games");}
  ,place: function(){return this.get("place");}
  ,points: function(){return this.get("points");}
  ,gf: function(){return this.get("goals_scored");}
  ,ga: function(){return this.get("goals_allowed");}
  ,season_id: function(){return this.get("season_id");}
  ,isChampion: function(){
  }
  ,gdata: function(isTeam, seasons){
    var gaa = this.ga()/this.games();
    var gfa = this.gf()/this.games();
    var diff = this.gf() - this.ga();
    var x = Math.pow((this.ga() + this.gf()) / this.games(), 0.285);
    var xW = Math.pow(this.gf(),x)/(Math.pow(this.ga(),x) + Math.pow(this.gf(),x));
    var xPts = Math.round(this.games() * xW * 3);
    var xDiff = this.points() - xPts;
    var data = [this.games(), this.points(), diff, this.gf(), this.gf()/this.games(), this.ga(), gaa, x, xW, xPts, xDiff];

    if (true == isTeam) {
      data.unshift(seasons.findWhere({id:parseInt(this.season_id())}).name());
      data.unshift(this.season_id().toString());
    } else {
      data.unshift(this.name());
    }

    if (true == _.isFinite(this.place())) {
      data.unshift(this.place().toString());
    } else {
      data.unshift('---');
    }

    return data;
  }
});

var TeamCollection = Backbone.Collection.extend({
  model: Team
  ,url: "/teams"
  ,gheaders: function(isTeam) {
    var headers = [
      {name: 'Games', type: 'number'}
      ,{name: 'Points', type: 'number'}
      ,{name: '+/-', type: 'number'}
      ,{name: 'GF', type: 'number'}
      ,{name: 'GFA', type: 'number'}
      ,{name: 'GA', type: 'number'}
      ,{name: 'GAA', type: 'number'}
      ,{name: 'X', type: 'number'}
      ,{name: 'xW', type: 'number'}
      ,{name: 'xPts', type: 'number'}
      ,{name: 'xDiff', type: 'number'}
    ];

    if (true == isTeam) {
      headers.unshift({name: 'Season', type: 'string'});
      headers.unshift({name: 'Id', type: 'string'});
    } else {
      headers.unshift({name: 'Team', type: 'string'});
    }

    headers.unshift({name: 'Place', type: 'string'});

    return headers;
  }
});

var TeamView = Backbone.View.extend({
  items: new TeamCollection()
  ,seasons: new SeasonCollection()
  ,initialize: function(items, seasons) {
    var view = this;
    this.errors = this.items.clone();
    this.items.reset(items);
    this.seasons.reset(seasons);
    this.accordions = {};
    jQuery('#single-add-button').hide();
    jQuery('#single-import-field').hide();
    this.data_div = jQuery('#data-div');

    _.forEach(jQuery('input[id$=-radio]'), function(elem, i, list) {
      jqElem = jQuery(elem);
      var type = jqElem.attr('groupname');
      view.data_div.append('<div id="' + type + '-accordion"></div>');
      view.accordions[type] = {};
      view.accordions[type].accordion = jQuery('#' + type + '-accordion');
      view.accordions[type].grouping  = jqElem.attr('grouping');
      view.accordions[type].wrappers  = [];
      view.accordions[type].isTeam    = ('team' == type);
      jqElem.click(function(e) {
        view.accordions[type].accordion.show();
        view.accordions[type].accordion.find('.google-visualization-table-table').css('width', Math.floor(view.accordions[type].accordion.width() * 0.95) + 'px');
        if (true == view.accordions[type].isTeam) {
          view.accordions['season'].accordion.hide();
        } else {
          view.accordions['team'].accordion.hide();
        }
      });
      view.render(view.accordions[type]);
    });
  }
  ,default_click: _.after(2, _.once(function() {
    jQuery('#season-radio').click();
  }))
  ,create_accordion: function(accordion) {
    accordion.accordion.accordion({heightStyle: 'content'});
    this.default_click();
  }
  ,add_summary: function(data) {
    var summary = [];

    _(data.getNumberOfRows()).times(function(row) {
      _(data.getNumberOfColumns()).times(function(col) {
        if ('number' == data.getColumnType(col)) {
          if (true == _.isFinite(summary[col])) {
            summary[col] += data.getValue(row, col);
          } else {
            summary[col] = data.getValue(row, col);
          }
        } else if (0 == col) {
          summary[col] = 'Summary';
        } else {
          summary[col] = '---';
        }
      });
    });

    _.forEach(summary, function(val, i, list) {
      if (true == _.isFinite(val)) {
        summary[i] = val/data.getNumberOfRows();
      }
    });

    data.addRow(summary);

    _(data.getNumberOfColumns()).times(function(col) {
      data.setProperty(data.getNumberOfRows() - 1, col, "style", "font-weight:bold;");
    });
  }
  ,sort: function(wrapper, e) {
    var data = wrapper.getDataTable();
    var data_view = new google.visualization.DataView(data);
    var sorted_rows = null;
    var summary_row = data.getFilteredRows([{column: 0, value: 'Summary'}]);
    var redformatter = new google.visualization.NumberFormat({negativeColor: 'red'});
    var fixedformatter = new google.visualization.NumberFormat({fractionDigits: 0});
    var percentformatter = new google.visualization.NumberFormat({pattern:'##%'});
    var no_decimal_list = ["Place", "Games", "Points", "GA", "GF", "+/-", "xPts", "xDiff"];
    var percent_list = ["xW"];

    if (false == _.isEmpty(summary_row)) {
      _.forEach(summary_row, function(row, i, list) {
        data.removeRow(row);
      });
    }

    sorted_rows = data.getSortedRows(e.column);

    if (false == e.ascending) {
      sorted_rows.reverse();
    }

    this.add_summary(data);

    _(data.getNumberOfColumns()).times(function(col) {
      if ('number' == data.getColumnType(col)) {
        redformatter.format(data, col);
        if (-1 != _.indexOf(no_decimal_list, data.getColumnLabel(col))) {
          fixedformatter.format(data, col);
        }
        if (-1 != _.indexOf(percent_list, data.getColumnLabel(col))) {
          percentformatter.format(data, col);
        }
      }
    });
    sorted_rows.push(data.getNumberOfRows() - 1);
    data_view.setRows(sorted_rows);
    wrapper.getChart().draw(data_view, {allowHtml: true, sort: 'event', sortColumn: e.column, sortAscending: e.ascending});
    jQuery('.google-visualization-table-td:first-of-type').editable(_.bind(function(value, settings) {
      var wrapper = this.wrapper;
      var teams   = this.teams;
      var gitems  = wrapper.getChart().getSelection();

      if (1 == gitems.length) {
        var team = teams.findWhere({id: wrapper.getDataTable().getRowProperty(gitems[0].row, "item_id")});

        if (true == _.isObject(team)) {
          team.set("place", value);
          team.save();
          team.fetch();
        }
      }

      return value;
    },{teams: this.items, wrapper: wrapper}));
  }
  ,render: function(accordion) {
    var view = this;
    var display_items = this.items;

    if (0 != display_items.length) {
      _.forEach(display_items.groupBy(accordion.grouping), function(teams, group_name, list) {
        if (false == accordion.isTeam) {
          group_name = view.seasons.findWhere({id:parseInt(group_name)}).name();
        }

        var data = new google.visualization.DataTable();
        var clean_name = jQuery.idEscape(group_name);
        var wrapper = null;

        if (true == accordion.isTeam) {
          accordion.accordion.append('<div id="' + clean_name + '"></div>');
        } else {
          accordion.accordion.prepend('<div id="' + clean_name + '"></div>');
        }
        jQuery('#' + clean_name).before('<h3>' + group_name + '</h3>');
        accordion.wrappers.unshift(new google.visualization.ChartWrapper({
                      chartType: 'Table',
                      options: {showRowNumber: false, allowHtml: true, sort: 'event'},
                      containerId: clean_name
                    }))

        _.forEach(display_items.gheaders(accordion.isTeam), function(header, i, list) {
          data.addColumn(header.type, header.name);
        });

        teams.forEach(function(team, i, list){
          data.addRow(team.gdata(accordion.isTeam, view.seasons));
          data.setRowProperty(data.getNumberOfRows() - 1, "item_id", team.id);
        });

        accordion.wrappers[0].setDataTable(data);
      });

      var afterCreateAccordion = _.after(accordion.wrappers.length, _.once(function() {view.create_accordion(accordion);}));

      _.forEach(accordion.wrappers, function(wrapper, i, list) {
        var oneListener = _.once(function() {
          google.visualization.events.addListener(wrapper.getChart(), 'sort', function(e) {
            view.sort(wrapper, e);
          });
        });

        var oneInitialSort = _.once(function() {
          var column = 1;
          if (false == accordion.isTeam) {
            column = 3;
          }
          view.sort(wrapper, {column: column, ascending: false});
        });

        google.visualization.events.addListener(wrapper, 'ready', afterCreateAccordion);
        google.visualization.events.addListener(wrapper, 'ready', oneListener);
        google.visualization.events.addListener(wrapper, 'ready', oneInitialSort);
        wrapper.draw();
      })
    }
  }
});
