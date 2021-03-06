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


function LPOmRestaurants(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "filtered_restaurants_list" : ["targ__restaurant_list"],    
    "show_menu_view" : ["targ__filtered_menu_items"]
  };

  this.endpoints = {
    "post__filter_restaurants" : "/office/appointments/<id>/filter_restaurants",
    "get__select_food" : "/office/appointments/<id>/select_food?restaurant_id=<restaurant_id>",
    "post__sort_by_restaurants": "/office/appointments/<id>/sort_restaurants",
    "get__order__menu_path": "/office/orders/menu?id=<id>&menu_id=<menu_id>&restaurant_id=<restaurant_id>"
  };

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    // "calendar:select_week" : "changeWeek",
  };

  this.events = {
    "click [data-toggleable-price]" : "toggleFilters",
    "click [data-toggleable-cuisine]" : "toggleFilters",
    "click .lp__select_food" : "showSelectFood",
    "change .lp__sort_by": "sortRestaurants",    
    "click .lp__select_menu" : "showMenu",
    "change #order_tip_field": "updateOrderTotal",    
    "click .btn": "disableButton"
  };


  this.disableButton = function(e){
    $(e.currentTarget).addClass("disabled");
  },
  
  
  this.updateOrderTotal = function(e){
    subtotal = $("#order_subtotal_field").data("value");
    delivery = $("#order_delivery_fee_field").data("value");
    tax = $("#order_tax_field").data("value");
    if(isNaN(parseFloat($("#order_tip_field").val()))){
      tip = 0;
      $("#order_tip_field").val("0.00");
    }else{
      tip = parseFloat($("#order_tip_field").val()) * 100;
    }
    total = ((subtotal + delivery + parseFloat(tax) + tip) / 100).toLocaleString("en-US", {style:"currency", currency:"USD"});
    $("#order_total_charge").html(total);

  },

  this.sortRestaurants = function(e){
   var that = this;

    endpoint_path = Requests.buildPath(that.endpoints['post__sort_by_restaurants'], 
      {"id" : $(this.base_component).data("appointment-id"), "sort_by":$(e.currentTarget).val(), "restaurant_ids": $(e.currentTarget).data('restaurant-ids')});
    data = {"sort_by" : $(e.currentTarget).val(), "restaurant_ids": $(e.currentTarget).data('restaurant-ids')};
    that._updateComponentTemplate(endpoint_path, "filtered_restaurants_list", data)
    
    stopProp(e);
  },
  this.showMenu = function(e){
    var that = this;
    menu_id = $(e.currentTarget).data("menu-id");
    order_id = $(e.currentTarget).data("order-id");
    restaurant_id = $(e.currentTarget).data("restaurant-id");
    if(order_id && restaurant_id){
      endpoint_path = Requests.buildPath(that.endpoints['get__order__menu_path'], {"id": order_id, "menu_id": menu_id, "restaurant_id": restaurant_id});
      that._updateComponentTemplate(endpoint_path, "show_menu_view", {}, "GET");
      that.__find(".nav-link.active").removeClass("active");
      $(e.currentTarget).closest(".nav-link").addClass("active");
    }    
    stopProp(e);
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

  this.showSelectFood = function(e){
    var that = this;
    appt_id = $(e.currentTarget).data("appointment-id");
    restaurant_id = $(e.currentTarget).data("restaurant-id");

    endpoint_path = Requests.buildPath(that.endpoints['get__select_food'], {"id" : appt_id, "restaurant_id": restaurant_id})
    window.location.href = endpoint_path;
    stopProp(e);
  },

  this.toggleFilters = function(e) {
    that = this;

    if ($(e.currentTarget).attr("data-toggleable-cuisine")) {
      $(e.currentTarget).toggleClass("active")

      //grab active filters and get the ids to pass into controller
      var activeFilters = $(".lp__filters_cuisine.active");
      var filterIds = []
      if(activeFilters.length > 0){
        activeFilters.each(function(i, filter){
          filterIds.push($(filter).attr("data-off-value"));
        });
      }
    }

    if ($(e.currentTarget).attr("data-toggleable-price")) {
      if ($(e.currentTarget).hasClass('active')) {
        $(".lp__filters_price").removeClass("active");
      } else {
        $(".lp__filters_price").removeClass("active");
        $(e.currentTarget).toggleClass("active");
      }
    }

    //grab active filters and get the ids to pass into controller
    var activeFilters = $(".lp__filters_price.active");
    var filterIds = []
    if(activeFilters.length > 0){
      activeFilters.each(function(i, filter){
        filterIds.push($(filter).attr("data-value"));
      });
    }

    //grab active cuisine filters and get the ids to pass into controller
    var activeFilters = $(".lp__filters_cuisine.active");
    var cuisineFilterIds = []
    if(activeFilters.length > 0){
      activeFilters.each(function(i, filter){
        cuisineFilterIds.push($(filter).attr("data-value"));
      });
    }



    endpoint_path = Requests.buildPath(that.endpoints['post__filter_restaurants'], {"id" : $(this.base_component).attr("data-appointment-id")})

    data = { "price_range": filterIds, "cuisines": cuisineFilterIds }
    target = $(".targ-restaurants")

    //$(e.currentTarget)
    Requests._request("post", endpoint_path, data,
      function(successResponse) {
        if (successResponse.template) {
          $(target).html(successResponse.template)
        }
      },
      function(errorResponse) {
      }
    );

    stopProp(e);
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

    debug("Component handlers bound for LPRestaurants(comp__om_restaurants)")
  };

  this.init();
};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPOmRestaurants_Initializer = function() {
  var component_name = "comp__om_restaurants"

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPOmRestaurants(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPOmRestaurants(object)
      $(object).addClass("__comp_active")
    }
  });
}
