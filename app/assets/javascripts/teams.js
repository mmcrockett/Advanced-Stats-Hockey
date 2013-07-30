var Team = Backbone.Model.extend({
  name: function(){return this.get("name") || "";}
  ,games: function(){return this.get("games");}
  ,points: function(){return this.get("points");}
  ,gf: function(){return this.get("goals_scored");}
  ,ga: function(){return this.get("goals_allowed");}
  ,gdata: function(){
    var gaa = this.ga()/this.games();
    var gfa = this.gf()/this.games();
    var diff = this.gf() - this.ga();
    var x = Math.pow((this.ga() + this.gf()) / this.games(), 0.285);
    var xW = Math.pow(this.gf(),x)/(Math.pow(this.ga(),x) + Math.pow(this.gf(),x));
    var xPts = Math.round(this.games() * xW * 3);
    var xDiff = this.points() - xPts;
    return [this.name(), this.games(), this.points(), diff, this.gf(), this.gf()/this.games(), this.ga(), gaa, x, xW, xPts, xDiff]
  }
});

var TeamCollection = Backbone.Collection.extend({
  model: Team
  ,url: "/teams"
  ,gheaders: function() {
    return [
      {name:  'Team', type: 'string'}
      ,{name: 'Games', type: 'number'}
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
  }
});

var TeamView = Backbone.View.extend({
  items: new TeamCollection()
  ,initialize: function(items, options) {
    var view = this;
    this.errors = this.items.clone();
    this.items.reset(items);
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
  ,default_click: _.after(2, function() {
    jQuery('#season-radio').click();
  })
  ,create_accordion: function(accordion) {
    accordion.accordion.accordion({heightStyle: 'content'});
    this.default_click();
  }
  ,render: function(accordion) {
    var view = this;
    var display_items = this.items;

    if (0 != display_items.length) {
      _.forEach(display_items.groupBy(accordion.grouping), function(teams, group_name, list) {
        var data = new google.visualization.DataTable();
        var clean_name = jQuery.idEscape(group_name);
        var wrapper = null;
        var redformatter = new google.visualization.NumberFormat({negativeColor: 'red'});
        var fixedformatter = new google.visualization.NumberFormat({fractionDigits: 0});

        accordion.accordion.append('<div id="' + clean_name + '"></div>');
        jQuery('#' + clean_name).before('<h3>' + group_name + '</h3>');
        accordion.wrappers.unshift(new google.visualization.ChartWrapper({
                      chartType: 'Table',
                      options: {showRowNumber: false, allowHtml: true, sort: 0},
                      containerId: clean_name
                    }))

        _.forEach(display_items.gheaders(), function(header, i, list) {
          data.addColumn(header.type, header.name);
        });

        teams.forEach(function(team, i, list){
          data.addRow(team.gdata());
        });

        redformatter.format(data, 3);
        fixedformatter.format(data, 3);
        redformatter.format(data, 5);
        redformatter.format(data, 7);
        redformatter.format(data, 8);
        redformatter.format(data, 9);
        redformatter.format(data, 11);
        fixedformatter.format(data, 11);
        accordion.wrappers[0].setDataTable(data);
        accordion.wrappers[0].draw();
      });

      var afterFunction = _.after(accordion.wrappers.length, function() {view.create_accordion(accordion);});

      _.forEach(accordion.wrappers, function(wrapper, i, list) {
        google.visualization.events.addListener(wrapper, 'ready', afterFunction);
      })
    }
  }
});
