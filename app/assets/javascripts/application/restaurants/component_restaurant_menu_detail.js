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


function LPRestaurantMenuDetail(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "show_menu_view" : ["targ__menu_detail"]
  };

  this.endpoints = {
    "get__restaurant__menu_path": "/restaurant/menus/<id>",
    "get__restaurant__menus_path" : "/restaurant/menus"
  };

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    // "calendar:select_week" : "changeWeek",
  };

  this.events = {
    "click .lp__select_menu" : "showMenu"
  };


  this.showMenu = function(e){
    var that = this;
    if ($(e.currentTarget)){
      menu_id = $(e.currentTarget).data("menu-id");
    }

    if(menu_id){
      endpoint_path = Requests.buildPath(that.endpoints['get__restaurant__menu_path'], {"id": menu_id});
      that._updateComponentTemplate(endpoint_path, "show_menu_view", {}, "GET");
      that.__find(".nav-link.active").removeClass("active");
      $(e.currentTarget).closest(".nav-link").addClass("active");
    } else {
      endpoint_path = Requests.buildPath(that.endpoints['get__restaurant__menu_path'], {"id": 0});
      that._updateComponentTemplate(endpoint_path, "show_menu_view", {}, "GET");
      that.__find(".nav-link.active").removeClass("active");
      $(component).find("#all-menus").addClass("active");
    }

  },


  this._updateComponentTemplate = function(url, data_target, data, method) {
    that = this;

    if (!(url && data_target && data)) {
      debug_error("Missing URL or data_target on getComponentTemplate");
      return;
    }
    if(method == "GET"){
      Requests.getRequestWithState(url,
        function(successResponse) {
          forEach(that.data_targets[data_target], function(target, index) {
            if (successResponse.templates && successResponse.templates[target]) {
              $("."+target).html(successResponse.templates[target]);
            }
          });
        },
        function(errorResponse) {
          debug_error("We got an error response");
          debug_error(errorResponse);
        }
      );
    }else{
      Requests._request("post", url, data,
        function(successResponse) {
          forEach(that.data_targets[data_target], function(target, index) {
            if (successResponse.templates && successResponse.templates[target]) {
              $("."+target).html(successResponse.templates[target]);
            }
          });
        },
        function(errorResponse) {
        }
      );
    }
  },


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
  };

  this.bind_handlers = function() {
    var _handler = this
    Object.keys(_handler.events).forEach(function (key) {
      this_event = key.split(" ");
      var method_name = _handler.events[key];
      event_action = this_event.splice(0, 1)[0]
      event_target = this_event.join(" ")
      $(_handler.base_component).on(event_action, event_target, function(e, options) {
        _handler[method_name](e, options)
      });
    });

    Object.keys(_handler.document_events).forEach(function (key) {
      var method_name = _handler.document_events[key];
      if (key.indexOf(":") !== -1) {
        // Custom event on the document
        $(document).on(key, function(e, el, options) {
          _handler[method_name](e, el, options)
        });
        return;
      }
      this_event = key.split(" ");
      event_action = this_event.splice(0, 1)[0]
      event_target = this_event.join(" ")
      $(document).on(event_action, event_target, function(e) {
        _handler[method_name](e)
      });
    });

    debug("Component handlers bound for LPRestaurants(comp__restaurant_menu_detail)")
  };

  this.init();
  this.showMenu(this.__find("#all-menus").first());
};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRestaurantMenuDetail_Initializer = function() {
  var component_name = "comp__restaurant_menu_detail"

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPRestaurantMenuDetail(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRestaurantMenuDetail(object)
      $(object).addClass("__comp_active")
    }
  });
}
