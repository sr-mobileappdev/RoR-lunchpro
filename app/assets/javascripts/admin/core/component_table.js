// Component
// ---
// It does stuff

// COMPONENT PROGRAMMING GUIDE
// -----
// Three core elements make up a fully-deployed component.
// 1. The HTML element(s) on the pages themselves, that have a .comp__XXXX style class assigned to them
// 2. A small binding / initialization function (shown near the bottom of this file) which loops through all elements from the above class and instantiats the objects associated with them
// 3. The actual javascript component class itself (the bulk of the code below)

// USAGE
// -----
// Put this somewhere: <span class="comp__sample_me"><em>clickable thing</em></span>
// Click it, and it should replicate

// VERSION : Trying to keep track of when I improve the base
// -----
// 1.4 - Made component activation utilize a `component_name` variable to reduce things that must be re-written when creating a new comp
// 1.4 - New Component observer is `lp-component.added` which is LunchPro specific
// 1.4 - Changed initialization from jquery reday to using an initializer function that somebody must call (LPRepOfficeList_Initializer)
// 1.4 - Integrated endpoints into JS component (instead of those living in the markup)
// 1.5 - Added document_events for document scoped events (not just component-only events)


function LPTable(component) {
  this.base_component = component,
  this._loadingDelay = 500,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    //"nothing" : ["targ__nothing"]
  };

  this.endpoints = {
    //"get__office_detail_path" : "/rep/offices/<id>",
  };

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    "click .targ-paginate-link" : "changePage"
    // "click [data-submit]" : "submitForm"
  };

  // Component only events
  this.events = {
    "click #source" : "setSourceRep",
    "click #destination" : "setDestinationRep"
  };

  this.setSourceRep = function(e){
    var that = this;
    
    if($(e.currentTarget).prop('checked')){
      record_id = $(e.currentTarget).closest("tr").data('record-id');      
      $(".source").val(null);
      $(".source").attr("name", null);
      $(e.currentTarget).closest(".lp__inline_radio").next(".source").val(record_id).attr('name', 'source_id');
      $(".source-checkbox").hide();
      $(e.currentTarget).closest(".source-checkbox").show();
      $(".destination-checkbox").show();
      $(e.currentTarget).closest(".source-checkbox").next(".destination-checkbox").hide();

      destination_checked = $('.destination_checkbox:checked');
      if(destination_checked.length){
        $(".destination-checkbox").hide();
        destination_checked.closest(".destination-checkbox").show();
      }
    }else{
      $(".source").val(null);
      $(".source").attr("name", null);
      $(".source-checkbox").show();      
      destination_checked = $('.destination_checkbox:checked');
      $(".destination-checkbox").hide();

      if(destination_checked.length){
        destination_checked.closest(".destination-checkbox").show();
        destination_checked.closest(".destination-checkbox").prev(".source-checkbox").hide();
      }else{

      }
    }
  },

  this.setDestinationRep = function(e){
    var that = this;
    
    if($(e.currentTarget).prop('checked')){
      record_id = $(e.currentTarget).closest("tr").data('record-id');
      $(".destination").val(null);
      $(".destination").attr("name", null);
      $(e.currentTarget).closest(".lp__inline_radio").next(".destination").val(record_id).attr('name', 'destination_id');
      $(".destination-checkbox").hide();
      $(e.currentTarget).closest(".destination-checkbox").show();

    }else{
      $(".destination").val(null);
      $(".destination").attr("name", null);
      $(".destination-checkbox").show();
      source_checked = $('.source_checkbox:checked');
      if(source_checked.length){
        source_checked.closest(".source-checkbox").next(".destination-checkbox").hide();
        source_checked.show();
      }else{
        $(".source-checkbox").show();  
        $(".destination-checkbox").hide();
      } 
    }
  },

  this.changePage = function(e) {
    var that = this

    url = $(e.currentTarget).attr("href")

    NProgress.start();

    column_count = that.__find("*[data-table-url]").attr("data-column-count") || 4;

    that.__find("[data-table-url] tbody").html("<tr class='is-loading-stickies'><td class='loading_content' colspan='"+column_count+"'><div class='sp-loading left'></div> <span class='lp__loading'></span></td>></tr>")

    that._loadTable(url,
      function(response_options, success) {
        // Custom handler if desired, for after the form processes (or fails)
        NProgress.done();
      }
    );

    stopProp(e);

  };

  this.reloadTable = function() {
    var that = this

    describe_workflow([
      "Find the data-table-url",
      "Show loading spinner",
      "Reload the table based on current url in data-table-url",
      "Remove loading spinner and show results",
    ])

    url = that.__find("*[data-table-url]").attr("data-table-url")
    change_url = (that.__find("*[data-table-url]").attr("data-same-url") == undefined) ? true : false

    NProgress.start();

    that._loadTable(url,
      function(response_options, success) {
        // Custom handler if desired, for after the form processes (or fails)
        NProgress.done();
      }
    , change_url);
  };

  this._loadTable = function(url, callback_function, should_change_url) {
    var that = this

    Requests.getRequestWithState(url,
      function(successResponse) {

        column_count = 4
        if (successResponse.column_count) {
          column_count = successResponse.column_count
        }

        setTimeout(function() {
          that.__find("*[data-table-url]").attr("data-column-count", column_count)
          that.__find("*[data-table-url]").html(successResponse.table_html)
          that.__find(".targ-table-pagination").html(successResponse.pagination_html)
          callback_function(successResponse, true)
        }, that._loadingDelay);

      },
      function(errorResponse) {
        setTimeout(function() {
          that.__find("*[data-table-url]").html("<p>ERROR</p>")
          callback_function(successResponse.responseJSON, true)
        }, that._loadingDelay);
      }
    , should_change_url);

  };






  // CORE COMPONENT BASE METHODS. Every component should have these. Without these methods it will not operate.

  // Find all matching objects by selector within the scope of this component
  this.__find_all = function(selector) {
    return $(this.base_component).find(selector)
  };

  // Find first matching object by selector within the scope of this component
  this.__find = function(selector) {
    return $(this.base_component).find(selector).first()
  };

  this.init = function() {
    if (this.base_component == undefined) { console.error("Missing component during init of new object"); return; }
    this.bind_handlers();

    if ($(this.base_component).find("table").hasClass("autoload")) {
      this.reloadTable();
    }
  };

  this.bind_handlers = function() {
    var _handler = this
    Object.keys(_handler.events).forEach(function (key) {
      this_event = key.split(" ");
      var method_name = _handler.events[key];
      event_action = this_event.splice(0, 1)[0]
      event_target = this_event.join(" ")
      $(_handler.base_component).on(event_action, event_target, function(e) {
        _handler[method_name](e)
      });
    });

    Object.keys(_handler.document_events).forEach(function (key) {
      this_event = key.split(" ");
      var method_name = _handler.document_events[key];
      event_action = this_event.splice(0, 1)[0]
      event_target = this_event.join(" ")
      $(document).on(event_action, event_target, function(e) {
        _handler[method_name](e)
      });
    });

    debug("Component handlers bound for LPTable (comp__table)")
  };

  this.init();

};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPTable_Initializer = function() {
  var component_name = "comp__table"

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPTable(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPTable(object)
      $(object).addClass("__comp_active")
    }
  });
}

