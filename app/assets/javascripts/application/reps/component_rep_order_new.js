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


function LPRepOrderNew(component) {
  this.base_component = component,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
   "new_order_view" : ["targ__new_order"],
   "show_menu_view" : ["targ__filtered_menu_items"]
  },

  this.endpoints = {
    "post__office_search_orders_path" : "/rep/offices/search?list_type=all_offices_orders",
    "post__office_list_orders_path" : "/rep/offices/search?list_type=offices_orders",
    "get__order__office_search_path" : "/rep/orders/office_search",
    "get__order__appointment_list_path" : "/rep/orders/appointment_list",
    "get__order__new_office_path" : "/rep/orders/new_office_list",
    "get__order__menu_path": "/rep/orders/menu?id=<id>&menu_id=<menu_id>&restaurant_id=<restaurant_id>"
  },

  this.events = {
    "submit form.lp__find_offices_orders" : "searchMyOfficesOrders",
    "click .__select_tab" : "showTab",
    "click .lp__select_menu" : "showMenu",
    "change .lp__select_payment_method": "selectPaymentMethod",
    "click .remove_line_item": "removeLineItem"
  },


  this.removeLineItem = function(e){
    $(e.currentTarget).addClass("disabled");
  },

  this.selectPaymentMethod = function(e){
    form_element = $("#targ-new-payment-method");
    selected_card = $(e.currentTarget).val();
    if(selected_card > 0){
      form_element.hide();
    }else{
      form_element.show();
    }
    stopProp(e);
  },
  this.showMenu = function(e){
    var that = this;
    menu_id = $(e.currentTarget).data("menu-id");
    order_id = $(e.currentTarget).data("order-id");
    restaurant_id = $(e.currentTarget).data("restaurant-id");
    if(order_id && restaurant_id){
      endpoint_path = Requests.buildPath(that.endpoints['get__order__menu_path'], {"id": order_id, "menu_id": menu_id, "restaurant_id": restaurant_id});
      that._updateComponentTemplate(endpoint_path, "show_menu_view");
      that.__find(".nav-link.active").removeClass("active");
      $(e.currentTarget).closest(".nav-link").addClass("active");
    }    
    stopProp(e);
  },
  this._updateComponentTemplate = function(url, data_target) {
    that = this;

    if (!(url && data_target)) {
      debug_error("Missing URL or data_target on getComponentTemplate")
      return;
    }

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

  };

  this.showTab = function(e){
    var that = this;
    $(e.currentTarget).tab('show');

    tab = $(e.currentTarget).attr("data-comp-detail-tab");
    endpoint_path = Requests.buildPath(that.endpoints['get__order__' + tab + '_path']);
  
    that._updateComponentTemplate(endpoint_path, "new_order_view");
  

    stopProp(e);
  },
  this.searchMyOfficesOrders = function(e){
    that = this;

    form = $(e.currentTarget);
    that.filterSearch("post__office_list_orders_path", form);

    stopProp(e);

    return false;
  };

  this.filterSearch = function(endpoint, form) {
    that = this;

    url = that.endpoints[endpoint];
    target = "targ__tab_results";
    if(endpoint == "post__office_search_appts_path"){target = "targ__tab_new_office_results";}
    data = form.serialize();
    Requests._request("post", url, data,
      function(successResponse) {
        if (successResponse.templates && successResponse.templates[target]) {
          $("."+target).html(successResponse.templates[target]);

        }
      },
      function(errorResponse) {
      }
    );

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

    debug("Component handlers bound for LPRepOrderNew(comp__rep_order_new)")
  };

  this.init();
  //add default option that will trigger new payment option form if no payment method is chosen
  
  $("#existing_payment_method_id").prepend("<option value='0' " + (!$(component).data("payment-id") ? 'selected' : '') + ">New Payment Method</option>");
};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRepOrderNew_Initializer = function() {
  var component_name = "comp__rep_order_new"

  $("."+component_name).each(function (idx) {
      obj = new LPRepOrderNew(this)
      $(this).addClass("__comp_active")
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRepOrderNew(object)
      $(object).addClass("__comp_active")
    }
  });
}

