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


function LPWizard(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "restaurant_basic_info" : "targ__restaurant_step1",
    "restaurant_details" : "targ__restaurant_step2",
    "restaurant_menu_items" : "targ__restaurant_step3",
    "restaurant_menus" : "targ__restaurant_step4",
    "restaurant_users" : "targ__restaurant_step5",
    "restaurant_bank_accounts" : "targ__restaurant_step6"
  },

  this.endpoints = {
    "get__registration_path" : "admin/restaurants/registration<step>",
  },

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    "click .wizard-save" : "submitForm"
  },

  // Component only events
  this.events = {
    // "click .form-check-input": "changeListedType"
  },

  this.submitForm = function(e) {
  var that = this;
  NProgress.start();
  // Find the form we need to submit

  var form_element = $(e.currentTarget).parents('form:last');
  if ($(e.currentTarget).attr("data-submit").length > 0) {
    form_element = that.__find("form#"+$(e.currentTarget).attr("data-submit"));
    if (!form_element || form_element.length == 0) {
      debug_error("Unable to locate form with ID '"+$(e.currentTarget).attr("data-submit")+"' (component_form.js -> _processForm)");
    }
  }

  that._processForm(form_element, {},
    function(response_options, success) {
      // Custom handler if desired, for after the form processes (or fails)

      NProgress.done();
    }
  );

  stopProp(e);
},

  this._processForm = function(form_element, options, callback_function) {
  that = this;

  url = $(form_element).attr("action");
  method = $(form_element).attr("method") || "get";

  params = {};
  if (method == "post" || method == "put" || method == "patch") {
    params = form_element.serialize();

  }

  if (!(url && method)) {
    debug_error("Missing URL or METHOD for form post (component_form.js -> _processForm)");
    return;
  }
  Requests._request(method, url, params,
    function(successResponse) {
      var resp = successResponse;
      if(resp.success){
        callback_function(resp, true);
      } else {
        that._showErrors(resp.general_error, resp.errors, {});
      }
    },
    function(errorResponse) {
      var resp = errorResponse.responseJSON; // responseJSON is only returned on errors

      that._showErrors(resp.general_error, resp.errors, {});
      callback_function(resp, false);
    }
  );

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

          }
        });
      },
      function(errorResponse) {
        debug_error(errorResponse);
      }
    );

  },

  this.showStep = function(e) {
    var that = this;
    selectedStep = $(e.currentTarget).attr("data-comp-detail-id");
    endpoint_path = Requests.buildPath(that.endpoints.get__registration_path, {"step" : selectedStep});

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
  this.showStepOnLoad = function(){
    var that = this;
    selectedStep = "#step-1"
    endpoint_path = Requests.buildPath(that.endpoints.get__registration_path, {"step" : selectedStep});
    that._updateComponentTemplate(endpoint_path, "restaurant_basic_info")

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
      $(_handler.base_component).on(event_action, event_target, function(e) {
        _handler[method_name](e);
      });
    });

    debug("Component handlers bound for LPWizard (comp__wizard)");
  },
  this.init();

}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPWizard_Initializer = function() {
  var component_name = "comp__wizard";
  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPWizard(this);
      $(this).addClass("__comp_active");
    }  });



  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPWizard(object);
      $(object).addClass("__comp_active");
    }
  });
};
