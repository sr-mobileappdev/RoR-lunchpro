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


function LPOmAppointments(component) {
  this.base_component = component,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "office_detail" : ["targ__office_detail"]
  },

  this.endpoints = {
    "post__reserve_slot" : "/rep/offices/<id>/reserve_slot",
    "post__rep_search_path" : "/office/search?list_type=all_reps",
  },

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    "calendar:select_week" : "changeWeek"
  },

  this.events = {
    "click .lp__recommend_cuisine" : "showSelectCuisine",
    "click .lp__hide_recommend_cuisine" : "hideSelectCuisine",
    "click .lp__new_rep" : "showNewRepForm",
    "change [name=appointment_type]" : "changeAppointmentType",
    "click .lp__existing_rep" : "showExistingRepForm",
    "submit form.lp__find_reps" : "searchReps",
    "click .cancel_button": "disableButton"
  },

  this.changeAppointmentType = function(e){  
    that = this; 
    that.__find(".form-check-label.checked").removeClass("checked"); 
    $(e.currentTarget).closest(".form-check-label").addClass("checked"); 
    $("." + $(e.currentTarget).val() + "-appointment").show(); 
 
    if($(e.currentTarget).val() == "external") { 
      $(".internal-appointment").hide(); 
      $("#internal_appointment").val(false); 
    } else if ($(e.currentTarget).val() == "internal") { 
      $(".external-appointment").hide(); 
      $("#internal_appointment").val(true);  
      that.showExistingRepForm(e); 
    }  
    stopProp(e); 
    return false;  
  },

  this.disableButton = function(e){    
    $(e.currentTarget).addClass("disabled");
  },

  this.showSelectCuisine = function(e){
    var that = this;
    $(".lp__select_recommendation").show();
    $(".lp__recommendation_buttons").hide();
    cuisines = $('#appointment_recommended_cuisines').attr('data-cuisines');
    that.initializeMultiSelectize(cuisines, "#appointment_recommended_cuisines");
  },
  this.hideSelectCuisine = function(e){
    $(".lp__select_recommendation").hide();
    $(".lp__recommendation_buttons").show();
  },

  this.showNewRepForm = function(e){
    $("#create_rep").val(true);
    var that = this;
    $("#existing-rep").hide();
    $("#new-rep").show();
    $('#sales_rep_company_id').selectize({
      plugins: ['remove_button'],
      options: $("#sales_rep_company_id").attr("data-companies"),
      valueField: 'id',
      labelField: 'name',
      searchField: 'name',
      maxItems: 1,
      mode: 'multi',
      openOnFocus: false,
      create: true,
      score: function scoreFilter(search) {
        var ignore = search && search.length < 3;
        var score = this.getScoreFunction(search);
        //the "search" argument is a Search object (see https://github.com/brianreavis/selectize.js/blob/master/docs/usage.md#search).
        return function onScore(item) {
            if (ignore) {
                //If 0, the option is declared not a match.
                return 0;
            } else {
                var result = score(item);
                return result;
            }
        };
      },
      onDropdownOpen: function ( $dropdown ) {
        $dropdown.css( 'visibility', this.lastQuery.length ? 'visible' : 'hidden' );
      },
      onType: function (str) {
        if (str === "") {
          this.close();
        }
      }
    });
    stopProp(e);
    return false;
  },
  this.showExistingRepForm = function(e){
    $("#create_rep").val(false);
    var that = this;
    $("#existing-rep").show();
    $("#new-rep").hide();
    stopProp(e);
    return false;
  },


  this.initializeMultiSelectize = function(data, id){

    if(data) data = JSON.parse(data);
    $(id).selectize({
      plugins: ['remove_button'],
      options: data,
      valueField: 'id',
      labelField: 'name',
      searchField: 'name'
    });
  },

  this.initializeSingleSelectize = function(data, id){

    if(data) data = JSON.parse(data);
    $(id).selectize({
      plugins: ['remove_button'],
      options: data,
      valueField: 'id',
      labelField: 'name',
      searchField: 'name',
      maxItems: 1
    });
  },

  this.initSlotDayOfWeeksSelectize = function(){
    $.ajax({
      url: '/api/frontend/slots/day_of_weeks',
      type: 'GET',
      success: function(data) {
       data = data.day_of_weeks;       
       $('#appointment_slot_days').selectize({
          plugins: ['remove_button'],
          labelField: "name",
          valueField: "value",
          searchField: 'name',
          options: data,
          placeholder: "Select day(s) of week"
        });
      }
    });
  },

  this._handleRedirect = function(resp) {
    if (resp && resp.redirect) {
      window.location = resp.redirect;
      return;
    } else if (resp && resp.reload) {
      window.location.reload(true);
      return;
    }
  },


  this.handleStars = function(rating){
     $("#quality" + rating).prop("checked", true);
  },

  this.searchReps = function(e) {
    that = this;

    form = $(e.currentTarget);
    that.filterSearch("post__rep_search_path", form);

    stopProp(e);

    return false;
  },

  this.filterSearch = function(endpoint, form) {
    that = this;

    url = that.endpoints[endpoint];
    target = "targ__rep_results";
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
    return false;
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
      $(_handler.base_component).on(event_action, event_target, function(e, options) {
        _handler[method_name](e, options);
      });
    });

    Object.keys(_handler.document_events).forEach(function (key) {
      var method_name = _handler.document_events[key];
      if (key.indexOf(":") !== -1) {
        // Custom event on the document
        $(document).on(key, function(e, el, options) {
          _handler[method_name](e, el, options);
        });
        return;
      }
      this_event = key.split(" ");
      event_action = this_event.splice(0, 1)[0];
      event_target = this_event.join(" ");
      $(document).on(event_action, event_target, function(e) {
        _handler[method_name](e);
      });
    });

    debug("Component handlers bound for LPOmAppointments(comp__om_appointments)");
  },

  this.init();
  if($("#overall").attr("data-comp-checked-value")){
    this.handleStars($("#overall").attr("data-comp-checked-value"));
  }
  if($("#appointment_sales_rep_id").attr("data-reps")){
    this.initializeSingleSelectize($("#appointment_sales_rep_id").attr("data-reps"), "#appointment_sales_rep_id");
  }
  if($(component).data("toggle-edit")){
    this.showSelectCuisine();
  }
  if($("#appointment_slot_days").length){
    this.initSlotDayOfWeeksSelectize();  
  }
}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPOmAppointments_Initializer = function() {
  var component_name = "comp__om_appointments";

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPOmAppointments(this);
      $(this).addClass("__comp_active");
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPOmAppointments(object);
      $(object).addClass("__comp_active");
    }
  });
};
