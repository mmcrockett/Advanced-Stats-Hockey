var Team = Backbone.Model.extend({
  name: function(){return this.get("name") || "";}
  ,games: function(){return this.get("games");}
  ,points: function(){return this.get("points");}
  ,gf: function(){return this.get("goals_scored");}
  ,ga: function(){return this.get("goals_allowed");}
  ,season_id: function(){return this.get("season_id");}
  ,gdata: function(isTeamGroup, seasons){
    var gaa = this.ga()/this.games();
    var gfa = this.gf()/this.games();
    var diff = this.gf() - this.ga();
    var x = Math.pow((this.ga() + this.gf()) / this.games(), 0.285);
    var xW = Math.pow(this.gf(),x)/(Math.pow(this.ga(),x) + Math.pow(this.gf(),x));
    var xPts = Math.round(this.games() * xW * 3);
    var xDiff = this.points() - xPts;
    var data = [this.games(), this.points(), diff, this.gf(), this.gf()/this.games(), this.ga(), gaa, x, xW, xPts, xDiff];

    if (true == isTeamGroup) {
      data.unshift(seasons.findWhere({id:parseInt(this.season_id())}).name());
    } else {
      data.unshift(this.name());
    }

    return data;
  }
});

var TeamCollection = Backbone.Collection.extend({
  model: Team
  ,url: "/teams"
  ,gheaders: function(isTeamGroup) {
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

    if (true == isTeamGroup) {
      headers.unshift({name: 'Season', type: 'string'});
    } else {
      headers.unshift({name: 'Team', type: 'string'});
    }

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
      jqElem.click(function(e) {
        view.accordions[type].accordion.show();
        view.accordions[type].accordion.find('.google-visualization-table-table').css('width', Math.floor(view.accordions[type].accordion.width() * 0.95) + 'px');
        if ('team' == type) {
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
    var fixedformatter = new google.visualization.NumberFormat({fractionDigits: 0});

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
    redformatter.format(data, 3);
    fixedformatter.format(data, 3);
    redformatter.format(data, 5);
    redformatter.format(data, 7);
    redformatter.format(data, 8);
    redformatter.format(data, 9);
    redformatter.format(data, 11);
    fixedformatter.format(data, 11);
    fixedformatter.format(data, 1);
    fixedformatter.format(data, 2);
    fixedformatter.format(data, 4);
    fixedformatter.format(data, 6);
    fixedformatter.format(data, 10);
    sorted_rows.push(data.getNumberOfRows() - 1);
    data_view.setRows(sorted_rows);
    wrapper.getChart().draw(data_view, {allowHtml: true, sort: 'event', sortColumn: e.column, sortAscending: e.ascending});
  }
  ,render: function(accordion) {
    var view = this;
    var display_items = this.items;

    if (0 != display_items.length) {
      _.forEach(display_items.groupBy(accordion.grouping), function(teams, group_name, list) {
        var isTeamGroup = true;

        if (true == _.isFinite(group_name)) {
          group_name = view.seasons.findWhere({id:parseInt(group_name)}).name();
          isTeamGroup = false;
        }

        var data = new google.visualization.DataTable();
        var clean_name = jQuery.idEscape(group_name);
        var wrapper = null;

        accordion.accordion.append('<div id="' + clean_name + '"></div>');
        jQuery('#' + clean_name).before('<h3>' + group_name + '</h3>');
        accordion.wrappers.unshift(new google.visualization.ChartWrapper({
                      chartType: 'Table',
                      options: {showRowNumber: false, allowHtml: true, sort: 'event'},
                      containerId: clean_name
                    }))

        _.forEach(display_items.gheaders(isTeamGroup), function(header, i, list) {
          data.addColumn(header.type, header.name);
        });

        teams.forEach(function(team, i, list){
          data.addRow(team.gdata(isTeamGroup, view.seasons));
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
          view.sort(wrapper, {column: 0, ascending: true});
        });

        google.visualization.events.addListener(wrapper, 'ready', afterCreateAccordion);
        google.visualization.events.addListener(wrapper, 'ready', oneListener);
        google.visualization.events.addListener(wrapper, 'ready', oneInitialSort);
        wrapper.draw();
      })
    }
  }
});
