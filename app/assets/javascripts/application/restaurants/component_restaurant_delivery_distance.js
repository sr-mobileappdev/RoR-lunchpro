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


function LPRestaurantDeliveryDistance(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    //"nothing" : ["targ__nothing"]
  },

  this.endpoints = {
    //"get__office_detail_path" : "/rep/offices/<id>",
  },

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
 //   "click [data-submit]" : "submitForm"
  },

  // Component only events
  this.events = {
    "click .lp__error_box .lp__close" : "closeErrorBox",
    "click .use-complex-choice" : "toggleChildSelection",
    "click .use-complex-choice" : "setStatusForChild"
  },

  this.toggleChildSelection = function(e) {
    that = this;

    $(e.currentTarget).closest(".delivery-distance").find(".cardinal-directions").toggleClass(".complex-distance-unselected")

    return false;
  },

  this.setStatusForChild = function(e){

    nested_attributes = $(component).data("nested-attributes");
    complex = $(e.currentTarget)["0"].checked.val();

    if(complex == true){
      $("#" + nested_attributes + "_use_complex").val(false);
    }else if (complex == false){
      $("#" + nested_attributes + "_use_complex").val(true);
    }
  },

  this.closeErrorBox = function(e) {
    $(e.currentTarget).closest(".lp__error_box").removeClass("show");
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

    Object.keys(_handler.document_events).forEach(function (key) {
      this_event = key.split(" ");
      var method_name = _handler.document_events[key];
      event_action = this_event.splice(0, 1)[0];
      event_target = this_event.join(" ");
      $(document).on(event_action, event_target, function(e) {
        _handler[method_name](e);
      });
    });

    debug("Component handlers bound for LPRestaurantDeliveryDistance (comp__delivery_distance)");
  },

  this.init();
}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRestaurantDeliveryDistance_Initializer = function() {
  var component_name = "comp__restaurant_delivery_distance";
  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPRestaurantDeliveryDistance(this);
      $(this).addClass("__comp_active");
    }  });



  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRestaurantDeliveryDistance(object);
      $(object).addClass("__comp_active");
    }
  });
};
