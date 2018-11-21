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


function LPOmProviders(component) {
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
    "click .existing-slot": "setStatusForChild",
    "change .form-checkbox:checkbox" : "toggleChildSelection",
    "click #set_availability" : "toggleSetAvailability"
  },

  //handles hiding/showing of provider availability form in OM provider modals
  this.toggleSetAvailability = function(e){
    $("#provider_availability_form").toggle();
  },
  //this handles setting a status to inactive or back to active for existing avails
  this.setStatusForChild = function(e){
    index = $(e.currentTarget).data("index");   //grab index
    nested_attributes = $(component).data("nested-attributes"); //grab name of nested attributes, provider_provider_availabilities_attributes_
    status = $("#" + nested_attributes + index + "_status").val();  //get existing status

    //change status based on existing status
    if(status == "active"){
      $("#" + nested_attributes + index + "_status").val("inactive");
    }else if (status == 'inactive'){
      $("#" + nested_attributes + index + "_status").val("active");
    }
  },

  this.toggleChildSelection = function(e) {
    that = this;
    //get parent, toggle grayed out fields, get the destroy value of the first child_form, which will accurately determine the status if there are 
    //multiple children for this day of week
    $(e.currentTarget).closest(".provider-group-day").toggleClass("provider-time-select-unselected");  
    val = $(e.currentTarget).closest('.provider-group-day').find('.child-form:visible').first().find('input[type=hidden]#_destroy_').val();
    //if destroy has a value, then set destroy to true/false

    if(val){
      if(val == "true"){
        $(e.currentTarget).closest('.provider-group-day').find('.provider-button-group').show();
        $(e.currentTarget).closest('.provider-group-day').find('input[type=hidden]#_destroy_').val(false);
      }else{
        $(e.currentTarget).closest('.provider-group-day').find('.provider-button-group').hide();
        $(e.currentTarget).closest('.provider-group-day').find('input[type=hidden]#_destroy_').val(true);
      }      
    //if destroy doesnt have a value, that means it's an exisitng record, and we should set to inactive/inactive
    }else{
      val = $(e.currentTarget).closest('.provider-group-day').find('.child-form:visible').first().find('input[type=hidden]#_status_').val();
      if(val == "active"){
        $(e.currentTarget).closest('.provider-group-day').find('.provider-button-group').hide();
        $(e.currentTarget).closest('.provider-group-day').find('input[type=hidden]#_status_').val("deleted");
      }else{
        $(e.currentTarget).closest('.provider-group-day').find('.provider-button-group').show();
        $(e.currentTarget).closest('.provider-group-day').find('input[type=hidden]#_status_').val("active");
      }      
    }
    $(e.currentTarget).closest(".form-check-label").toggleClass("checked");
    
    return false;
  };
  this.addChild = function(e){
    var that = this;
    time = new Date().getTime();
    regexp = new RegExp($(e.currentTarget).data('id'), 'g');
    fields = $(e.currentTarget).data('fields');
    $(e.currentTarget).closest(".provider-button-group").before(fields.replace(regexp, time))

    if ($(e.currentTarget).closest('.provider-group-day').find('.child-form:visible').length > 1){
      $(e.currentTarget).closest(".provider-button-group").find(".lp__remove_child").removeClass("disabled");
    }
    //if datepicker fields
    if($(".date-field-" + time).length){
      that.initFlatPickr(".date-field-" + time);
    }    

    stopProp(e);

  },
  this.removeChild = function(e){
    var that = this;
    //if the child requires a 'deleted' status to be set, check whether it's an existing record. if new, delete whole element, else set status 'deleted'
    if($(e.currentTarget).closest('.provider-group-day').find('.child-form:visible').length == 1){
      return;
    }
    if($(e.currentTarget).closest('.provider-group-day').find('.child-form:visible').length == 2){
      $(e.currentTarget).addClass("disabled");
    }

    if($(e.currentTarget).data("value") == "status"){
      parent = $(e.currentTarget).closest('.provider-button-group').prevAll('.child-form:visible')[0];
      $(parent).find('input[type=hidden]#_status_').val('deleted');
      $(parent).hide();
    }else{;
      parent = $(e.currentTarget).closest('.provider-button-group').prevAll('.child-form:visible')[0]
      $(parent).find('input[type=hidden]#_destroy_').val(true);
      $(parent).hide();
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

    debug("Component handlers bound for LPOmProviders (comp__om_providers)");
  },
  this.initSpecialitiesSelectize = function(){
    $.ajax({
      url: '/api/frontend/providers/specialties',
      type: 'GET',
      success: function(data) {
       specialties = data.specialties;
       var items = specialties.map(function(x) { return { item: x }; });
       $('#provider_specialties').selectize({
          plugins: ['remove_button'],
          labelField: "item",
          valueField: "item",
          searchField: 'item',
          options: items,          
          placeholder: "Select specialties for this provider"
        });
      }
    });
    
  }

  this.init();
  this.initSpecialitiesSelectize();

}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPOmProviders_Initializer = function() {
  var component_name = "comp__om_providers";

  $("."+component_name).each(function (idx) {
      obj = new LPOmProviders(this);
      $(this).addClass("__comp_active");
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPOmProviders(object);
      $(object).addClass("__comp_active");
    }
  });
};

