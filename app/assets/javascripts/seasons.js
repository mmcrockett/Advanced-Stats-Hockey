var Season = Backbone.Model.extend({
  name: function(){return this.get("name") || "";}
  ,updated: function(){return this.get("updated_at") || "";}
  ,pointhog: function(){return this.get("pointhog");}
  ,loaded: function(){return this.get("loaded");}
  ,gdata: function(){
    var pointhog = this.pointhog();

    if (false == _.isString(pointhog)) {
      pointhog = '';
    }

    return [this.loaded(), this.id, this.name(), pointhog];
  }
});

var SeasonCollection = Backbone.Collection.extend({
  model: Season
  ,url: "/seasons"
});

var SeasonView = Backbone.View.extend({
  items: new SeasonCollection()
  ,parse_input: function(value) {
    this.items.unshift(new Season({name: value.trim()}));
  }
  ,initialize: function(items, options) {
    var view = this;
    this.items.reset(items);
    this.single_add_button = jQuery('#single-add-button');
    this.single_add_input  = jQuery('#single-import-field');
    this.data_div          = jQuery('#data-div');
    jQuery('#radio-div').hide();

    this.single_add_button.click(function(e){view.parse_input(view.single_add_input.val());view.single_add_input.val('');view.store();});
    this.single_add_input.keypress(function(e){if (13 == e.which) {view.single_add_input.blur();view.single_add_button.click(); return false;}});

    this.render();

    this.listenTo(this.items, 'sync', function() {
      view.render();
    });
    this.listenTo(this.items, 'destroy', function() {
      view.clear_selection();
      view.render();
    });
    this.listenTo(this.items, 'error', function(model, response) {
      jQuery.error('season', response.responseText);
    });
  }
  ,display_items: function() {
    return this.items;
  }
  ,render: _.throttle(function() {
    if (0 == this.data_div.length) {
      return;
    }
    var display_items = this.display_items();
    var data = new google.visualization.DataTable();
    var view = this;

    data.addColumn('boolean', 'Loaded');
    data.addColumn('number', 'Id');
    data.addColumn('string', 'Season');
    data.addColumn('string', 'Pointhog URL');

    if (0 != display_items.length) {
      display_items.forEach(function(item, i, list){
        var rowIndex = data.addRow(item.gdata());
        data.setRowProperty(rowIndex, "item_id", item.id);

        for (var j = 0; j < data.getNumberOfColumns(); j++) {
          if (0 == j) {
            var style  = "cursor:pointer;";
            var dayago = new Date();
            dayago.setDate(dayago.getDate() - 1);

            if (false == data.getValue(rowIndex, j)) {
              style += "background-color:#f2dede;"
            } else if (dayago > new Date(item.updated())) {
              style += "background-color:#fcf8e3;"
            } else {
              style += "background-color:#e7e9f9;"
            }

            data.setProperty(rowIndex, j, "style", style);
          }
        }
      }, this);
    }

    if (true == _.isUndefined(this.wrapper)) {
      this.wrapper = new google.visualization.ChartWrapper({
                      chartType: 'Table',
                      dataTable: data,
                      options: {showRowNumber: false, allowHtml: true, sortColumn: 1, sortAscending: false},
                      containerId: view.data_div.attr('id')
                    });
      google.visualization.events.addListener(this.wrapper, 'ready', function() {
        google.visualization.events.addListener(view.wrapper, 'select', function(){view.store_selection();});
        jQuery('.google-visualization-table-td:first-of-type').css('width', 75);
      });
    } else {
      this.wrapper.setDataTable(data);
    }

    this.wrapper.draw();
    google.visualization.events.addListener(this.wrapper, 'ready', function() {
      jQuery('.google-visualization-table-td:last-of-type').editable(function(value, settings) {
        var season = view.items.findWhere({id:view.selection.item.id});
        season.set("pointhog", value);
        season.save();
        season.fetch();
      });
      jQuery('.google-visualization-table-td:first-of-type').click(function(e) {
        var season = view.items.findWhere({id:view.selection.item.id});
        jQuery.error('season');
        season.save();
      });
    });
  }, 800)
  ,store: function() {
    jQuery.error('new-season');

    this.items.forEach(function(item, i, obj){
      if (true == item.isNew()) {
        item.save();
      }   
    }); 
  }
  ,store_selection: function() {
    var gitems = this.wrapper.getChart().getSelection();

    if (1 == gitems.length) {
      var item = this.items.findWhere({id: this.wrapper.getDataTable().getRowProperty(gitems[0].row, "item_id")});

      this.selection = {
        gitem: gitems[0]
        ,item: item
      };
    }
  }
});

jQuery.errors = [];
jQuery.error = function(id, msg){
  if (true == _.isUndefined(msg)) {
    jQuery.errors = _.reject(jQuery.errors, function(o) {
      return (id == o.id);
    });
  } else {
    jQuery.errors.push({id:id, msg:msg});
  }
  jQuery.errorDisplay();
};
jQuery.errorDisplay = function(){
  var ediv = jQuery('#error-div');
  if (0 != jQuery.errors.length) {
    ediv.html('!ERROR: ' + _.last(jQuery.errors).msg);
    if (false == ediv.hasClass('error')) {
      ediv.addClass('error');
    }
  } else {
    ediv.html('');
    ediv.removeClass('error');
  }
};
jQuery.idEscape = function(str) {
	return str.replace(/([ ;&,\.\+\*\~':"\!\^#$%@\[\]\(\)=>\|])/g, '-');
};

_.number = function(v) {
  if (true == _.isFinite(v)) {
    return v;
  } else {
    return parseInt(v);
  }
};
_.toString = function(v) {
  if (true == _.isFinite(v)) {
    return v.toString();
  } else {
    return v;
  }
};
