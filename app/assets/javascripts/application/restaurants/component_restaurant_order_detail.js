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
// 1.4 - New Component observer is `lp-component.added` which sis LunchPro specific
// 1.4 - Changed initialization from jquery reday to using an initializer function that somebody must call (LPRepOfficeDetail_Initializer)
// 1.4 - Integrated endpoints into JS component (instead of those living in the markup)


function LPRestaurantOrderDetail(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "order_detail" : ["targ__restaurant_order_detail"]
  },


  this.endpoints = {
    "get__order_detail_path" : "/restaurant/orders/<id>"
  },

  this.events = {
    "click [data-comp-detail-id]" : "showOrder",
    "click [data-submit]" : "submitStatus",
    "click #print" : "printPage",
    "click #download" : "downloadPage"
  },

  this.printPage = function(e){
    window.print();
    stopProp(e);
  },

  this.selectOnTime = function(e){
    $(component).find(".form-check-label.checked").removeClass("checked");
    $(e.currentTarget).closest(".form-check-label").addClass("checked");
  },
  this._updateComponentTemplate = function(url, data_target) {
    that = this;
    if (!(url && data_target)) {
      debug_error("Missing URL or data_target on getComponentTemplate");
      return;
    }
    Requests.getRequestWithState(url,
      function(successResponse) {

        forEach(that.data_targets[data_target], function(target, index) {

          if (successResponse.templates && successResponse.templates[target]) {
            $("."+target).html(successResponse.templates[target]);
            LPRestaurantForm_Initializer();
            $('.list-active').removeClass('list-active');
            $("[data-comp-detail-id ='" + selectedOrder + "']").addClass('list-active');

          }
        });
      },
      function(errorResponse) {
        debug_error(errorResponse);
      }
    );

  },

  this._handleRedirect = function(resp){
    if (resp && resp.redirect) {
      window.location = resp.redirect;
      return;
    } else if (resp && resp.reload) {
      window.location.reload(true);
      return;
    }
  },

  this.showOrder = function(e) {

    var that = this;

    show_in = $(e.currentTarget).attr("data-comp-show-in");
    selectedOrder = $(e.currentTarget).attr("data-comp-detail-id");
    endpoint_path = Requests.buildPath(that.endpoints.get__order_detail_path, {"id" : selectedOrder});

    if ($(e.currentTarget).attr("data-url") != undefined) {
      endpoint_path = $(e.currentTarget).attr("data-url");
    }

    if (show_in != undefined && show_in == "modal") {
      $(document).trigger("lp.show_modal", [{url: endpoint_path}]);
    } else if (show_in != undefined && show_in == "new") {
      window.location = endpoint_path;
    } else {
      that._updateComponentTemplate(endpoint_path, "order_detail");
    }

    stopProp(e);
  };

  this.showOrderOnLoad = function(e){
    var that = this;

    endpoint_path = Requests.buildPath(that.endpoints.get__order_detail_path, {"id" : selectedOrder});
    that._updateComponentTemplate(endpoint_path, "order_detail")
    $("[data-comp-detail-id ='" + selectedOrder + "']").addClass('list-active');
  };

  this.submitStatus = function(e){
    var that = this;
    NProgress.start();

    var form_element = $(e.currentTarget).parents('form:first');

    that._processStatus(form_element, {},
      function(response_options, success) {
        // Custom handler if desired, for after the form processes (or fails)
        // Should set to refresh with currently selected order
        if(response_options.refresh_nav){
          $(".user-info").load(location.href + " .user-info");
        }
        NProgress.done();
      }
    );

    stopProp(e);
  };

  this._processStatus = function(form_element, options, callback_function) {
    that = this;

    url = $(form_element).attr("action");
    method = $(form_element).attr("method") || "get";

    params = {}
    if (method == "post" || method == "put" || method == "patch") {
      params = form_element.serialize();
    }

    if (!(url && method)) {
      debug_error("Missing URL or METHOD for form post (component_restaurant_order_detail.js -> _processStatus)");
      return;
    }

    Requests._request(method, url, params,
      function(successResponse) {
        var resp = successResponse
        if(resp.success){
          endpoint_path = Requests.buildPath(that.endpoints.get__order_detail_path, {"id" : resp.id});
          that._handleRedirect(resp);
          callback_function(resp, true);
        }else{

        }
      },
      function(errorResponse) {
        var resp = errorResponse.responseJSON;
        callback_function(resp, false);
      }
    );
  };

  if ($("#delivery_driver_form").length == 0){
    var selectedOrder = $(component).attr("data-comp-order-load-id");
    this.showOrderOnLoad();
  };


  // CORE COMPONENT BASE METHODS. Every component should have these. Without these methods it will not operate.

  // Find all matching objects by selector within the scope of this component
  this.__find_all = function(selector) {
    return $(this.base_component).find(selector);
  },

  // Find first matching object by selector within the scope of this component
  this.__find = function(selector) {
    return $(this.base_component).find(selector).first();
  },

  this.init = function() {
    if (this.base_component == undefined) { console.error("Missing component during init of new object"); return; }
    this.bind_handlers();
  },

  this.bind_handlers = function() {
    var _handler = this;
    Object.keys(_handler.events).forEach(function (key) {
      this_event = key.split(" ");
      var method_name = _handler.events[key];
      event_action = this_event.splice(0, 1)[0];
      event_target = this_event.join(" ");
      $(_handler.base_component).on(event_action, event_target, function(e, options) {
        _handler[method_name](e, options);
      });
    });

    debug("Component handlers bound for LPRestaurantOrderDetail (comp__restaurant_order_detail)");
  },

  this.init();

}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRestaurantOrderDetail_Initializer = function() {
  var component_name = "comp__restaurant_order_detail";

  $("."+component_name).each(function (idx) {
      obj = new LPRestaurantOrderDetail(this);
      $(this).addClass("__comp_active");
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRestaurantOrderDetail(object);
      $(object).addClass("__comp_active");
    }
  });
};
