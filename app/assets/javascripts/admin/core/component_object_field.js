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


function LPObjectField(component) {
  this.base_component = component,
  this._loadingDelay = 500,
  this._searchDelay = 1000
  this._searchDelayHandler = null,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    //"nothing" : ["targ__nothing"]
  };

  this.endpoints = {
    //"get__office_detail_path" : "/rep/offices/<id>",
  };

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    // "click [data-submit]" : "submitForm"
  };

  // Component only events
  this.events = {
    "focus .__object_field" : "showObjectResults",
    "click .__select_list li" : "selectResult",
    "keydown .__object_field" : "handleKeypress",
    "keypress .__object_field" : "handleReturnKeypress",
  };

  this.showObjectResults = function(e) {
    var that = this

    $(this.base_component).addClass("__open");
    $('body').on("click", function(e) {
      that.closeResults();
    });
    $(this.base_component).on("click", function(e) {
      stopProp(e);
    });

    stopProp(e);
  };

  this.selectResult = function(e) {
    this.__find(".__object_field").val($(e.currentTarget).attr("data-value"))
    this.__find(".targ-field-value").val($(e.currentTarget).attr("data-id"))
    this.closeResults();
    stopProp(e);
  };

  this.closeResults = function() {
    that = this

    current_value = that.__find(".__object_field").val()
    if (current_value.length < 2) {
      that.__find(".__object_field").val("")
      that.__find(".targ-field-value").val("")
    }

    this.__find(".__loading").removeClass("on")
    if ($(that.base_component).hasClass("__open")) {
      $(that.base_component).removeClass("__open");
      $('body').off("click");
    } else {
      $('body').off("click");
    }
  };

  this.handleReturnKeypress = function(e) {
    that = this;

    if (e.keyCode != undefined && e.keyCode == 13) {
      stopProp(e);
    }

  };

  this.handleKeypress = function(e) {
    that = this
    that.searching("on");

    // Set our search term
    term = that.__find(".__object_field").val()

    // If popup is closed, open it
    if (!$(this.base_component).hasClass("__open")) {
      that.showObjectResults(e);
    }

    if (e.keyCode != undefined && e.keyCode == 8) {
      if ($(e.currentTarget).val().length < 2) {
        that.clearSearch();
      }
    }

    if (that._searchDelayHandler != undefined) {
      // If search term is long enough, go ahead and search
      if (term.length < 5) {
        window.clearTimeout(that._searchDelayHandler);
      }
    }

    that._searchDelayHandler = window.setTimeout(function() {
      url = $(e.currentTarget).attr("data-url");
      if (url && url != undefined) {
        that.search(url, term);
      }
    }, that._searchDelay);

  };

  this.clearSearch = function() {
    that = this;
    that.__find(".__select_list ul").html("");

    current_value = that.__find(".__object_field").val()
    if (current_value.length < 2) {
      that.__find(".targ-field-value").val("")
    }
    that.searching("off");
    this.closeResults();
  };

  this.search = function(url, term) {
    that = this;

    if (term == undefined || term.length < 2) {
      that.__find(".__select_list ul").html("")
      return;
    }

    params = {search_term: term}

    Requests._postRequest(url, params,
      function(successResponse) {
        that.__find(".__select_list ul").html(successResponse.html)
        that.searching("off");
      },
      function(errorResponse) {
      }
    );

  };

  this.searching = function(status) {
    if (status == "on") {
      this.__find(".__loading").addClass("on")
    } else {
      this.__find(".__loading").removeClass("on")
    }
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

    debug("Component handlers bound for LPObjectField (comp__object_field)")
  };

  this.init();

};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPObjectField_Initializer = function() {
  var component_name = "comp__object_field"

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPObjectField(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPObjectField(object)
      $(object).addClass("__comp_active")
    }
  });
}

