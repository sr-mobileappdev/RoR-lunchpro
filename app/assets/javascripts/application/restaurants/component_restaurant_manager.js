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
// 1.4 - Changed initialization from jquery reday to using an initializer function that somebody must call (LPRepOfficeDetail_Initializer)
// 1.4 - Integrated endpoints into JS component (instead of those living in the markup)


function LPRestaurantManager(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
  },

  this.endpoints = {
  },

  this.events = {
    "click .lp__remove_child": "removeChild",
    "click .lp__add_child": "addChild",
    "click .form-check-input": "changeListedType",
    "click .add-poc-link" : "showPocForm"

  },

  this.showPocForm = function(e){
    $(".poc-form").show();
    $(".no-poc-label").hide();
  },

  this.changeListedType = function(e){
    $(".restaurant-form-check-label").removeClass("checked");
    $(e.currentTarget).closest(".restaurant-form-check-label").toggleClass("checked");
  },

  this.addChild = function(e){
    var that = this;
    time = new Date().getTime();
    regexp = new RegExp($(e.currentTarget).data('id'), 'g');
    fields = $(e.currentTarget).data('fields');
    $(e.currentTarget).after(fields.replace(regexp, time))

    //if datepicker fields
    if($(".date-field-" + time).length){
      that.initFlatPickr(".date-field-" + time);
    }

    stopProp(e);

  },
  this.removeChild = function(e){
    var that = this;
    //if the child requires a 'deleted' status to be set, check whether it's an existing record. if new, delete whole element, else set status 'deleted'
    if($(e.currentTarget).data("value") == "status"){
      if($(e.currentTarget).data("id")){
        $(e.currentTarget).prevAll('input[type=hidden]').val("deleted");
        $(e.currentTarget).closest('.child-form').hide();
      }else{
        $(e.currentTarget).closest('.child-form').remove();
      }
    }else{
      $(e.currentTarget).prevAll('input[type=hidden]').val(true);
      $(e.currentTarget).closest('.child-form').hide();
    }
    stopProp(e);
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
  this.initFlatPickr = function(className){
    flatpickr(className,
    {altInput: true,
      altFormat: "F j, Y",
      dateFormat: "Y-m-d"
    });
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

    debug("Component handlers bound for LPRestaurantManager (comp__restaurant_manager)");
  },
  this.init();

  if($(".date-field").length){
    this.initFlatPickr('.date-field');
  }
  if(!$(component).data("existing-exclusions")){
   // this.addExclusionDate();
  }
}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRestaurantManager_Initializer = function() {
  var component_name = "comp__restaurant_manager";

  $("."+component_name).each(function (idx) {
      obj = new LPRestaurantManager(this);
      $(this).addClass("__comp_active");
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRestaurantManager(object);
      $(object).addClass("__comp_active");
    }
  });
};
