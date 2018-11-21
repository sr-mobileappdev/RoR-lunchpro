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


function LPForm(component) {
  this.base_component = component,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    //"nothing" : ["targ__nothing"]
  };

  this.endpoints = {
    //"get__office_detail_path" : "/rep/offices/<id>",
  };

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    "click [data-submit]" : "submitForm",
    "click [data-submit-menu]" : "submitForm",
    "click [data-submit-user]" : "submitForm",
    "click [data-submit-bank-account]" : "submitForm",
    "change [name=trig__radius]" : "changeRestaurantRadiusOptions",
    "click .lp__add_child" : "addChild",
    "click .lp__add_diet_restriction" : "addDietRest",
    "keypress input[type=number]" : "preventKeypress",
    "click .trigger-sales-rep-form" : "triggerAddSalesRepForm",
    "change .date-field" : "handleReportDateChange",
    "click .lp__cancel" : "goBack"
  };

  // Component only events
  this.events = {
    "click .lp__error_box .lp__close" : "closeErrorBox",
    "change [name=mark__headquarters]" : "changeRestaurantType"
    // "click [data-submit]" : "submitForm"
  };

  //append start and end date to payout report url
  this.handleReportDateChange = function(e){
    if ( document.getElementById("Payout").style.display == "none")
    { 

    }
    else 
    {
      btn = $("#export_weekly_payout_btn");
      href = btn.attr("href").split("?")[0];
      btn.attr("href", href + "?scope=payout&start_date=" + $("#start_date").val() + "&end_date=" + $("#end_date").val());
    }

    if ( document.getElementById("LPreps").style.display == "none")
    {

    }
    else 
    {
      btn = $("#export_lprep_active_btn");
      href = btn.attr("href").split("?")[0];
      btn.attr("href", href + "?scope=lpReps&start_date=" + $("#start_dateLP").val() + "&end_date=" + $("#end_dateLP").val());
    }

    if ( document.getElementById("NonLPreps").style.display == "none")
    {

    }
    else 
    {
      btn = $("#export_non_lprep_active_btn");
      href = btn.attr("href").split("?")[0];
      btn.attr("href", href + "?scope=nonLpReps&start_date=" + $("#start_dateNonLP").val() + "&end_date=" + $("#end_dateNonLP").val());
    }

    if ( document.getElementById("BookedAppointmentsFood").style.display == "none")
    {

    }
    else 
    {
      btn = $("#export_booked_appmnt_food_btn");
      href = btn.attr("href").split("?")[0];
      btn.attr("href", href + "?scope=appmntsFood&start_date=" + $("#start_dateBookedFood").val() + "&end_date=" + $("#end_dateBookedFood").val());
    }
  };

  this.triggerAddSalesRepForm = function(e){
    $("#find-sales-rep-form").toggle();
    $("#add-sales-rep-form").toggle();
    if($("#create_rep").val() == 'false'){
      $("#create_rep").val(true);
    }else{
      $("#create_rep").val(false);
    }
  };

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

  this.preventKeypress = function(e){
    e.preventDefault();
  },

  this.addDietRest = function(e){
    var that = this;
    $(".new-diet-restriction").show()
  },

  this.changeRestaurantType = function(e){
    checked = $(e.currentTarget).is(":checked");
    if(checked){
      $(".headquarters__select").hide();
      $("#restaurant_headquarters_id").val(null);
    }else{
      $(".headquarters__select").show();
    }
  },

  this.goBack = function(e) {
      window.history.back();
  },

  this.submitForm = function(e) {

    var that = this



      NProgress.start();

      // Find the form we need to submit
      form_element = that.__find("form")
      if ($(e.currentTarget).attr("data-submit") && $(e.currentTarget).attr("data-submit").length > 0) {
        form_element = that.__find("form#"+$(e.currentTarget).attr("data-submit"))
        if (!form_element || form_element.length == 0) {
          debug_error("Unable to locate form with ID '"+$(e.currentTarget).attr("data-submit")+"' (component_form.js -> _processForm)")
        }
      }else if($("#smartwizard").length > 0){
        form_element = $(e.currentTarget).closest('form');
      }


      modifiedForm = 0;
      that._processForm(form_element, {},
        function(response_options, success) {
            // Custom handler if desired, for after the form processes (or fails)
          NProgress.done();
        }
      );


    stopProp(e);
  };

  this.closeErrorBox = function(e) {
    $(e.currentTarget).closest(".lp__error_box").removeClass("show")
  };

  this.changeRestaurantRadiusOptions = function(e) {
    selected = $(e.currentTarget).val()
    if (selected == "advanced") {
      current_val = $(".targ__basic_radius input[type=number]").first().val()
      if (current_val != undefined) {
        $(".targ__advanced_radius").find("input[type=number]").val(parseInt(current_val))
      }
      $(".targ__basic_radius").addClass("lp__hide")
      $(".targ__advanced_radius").removeClass("lp__hide")
    } else {
      $(".targ__basic_radius").removeClass("lp__hide")
      $(".targ__advanced_radius").addClass("lp__hide")
    }
  };


  this._processForm = function(form_element, options, callback_function) {
    that = this;

    url = $(form_element).attr("action")
    method = $(form_element).attr("method") || "get"

    params = {}
    if (method == "post" || method == "put" || method == "patch") {
      params = form_element.serialize();
    }

    if (!(url && method)) {
      debug_error("Missing URL or METHOD for form post (component_form.js -> _processForm)")
      return;
    }

    Requests._request(method, url, params,
      function(successResponse) {
        var resp = successResponse

        that._handleRedirect(resp)
        callback_function(resp, true)
      },
      function(errorResponse) {
        var resp = errorResponse.responseJSON // responseJSON is only returned on errors
        that._showErrors(resp.general_error, resp.errors, {})
        callback_function(resp, false)
      }
    );

  };
  this.initFlatPickr = function(className){
    flatpickr(className,
    {altInput: true,
      altFormat: "F j, Y",
      dateFormat: "Y-m-d"
    });
  };


  this._handleRedirect = function(resp) {
    if (resp && resp.redirect) {
      window.location = resp.redirect;
      return;
    } else if (resp && resp.reload) {
      window.location.reload(true);
      return;
    }
  };

  this._showErrors = function(general_message, errors, options) {
    that = this;
    if (general_message == undefined) {
      general_message = "System error (500)"
    }

    that.__find(".lp__error_box").remove();

    if($("#smartwizard").length > 0){
      if($("li.nav-item.active a").length > 0 && $("li.nav-item.active a").attr('href').length > 0){
        step = $("li.nav-item.active a").attr('href');
        form_element = $("div " + step + " form");
        $(form_element).prepend("<div class='lp__error_box'><a class='lp__close'><span class='oi oi-x' title='close' aria-hidden='true'></span></a></div>");
        $(form_element).find(".lp__error_box").append("<p>"+general_message+"</p>");
      }
    }else{
      that.__find("form").prepend("<div class='lp__error_box'><a class='lp__close'><span class='oi oi-x' title='close' aria-hidden='true'></span></a></div>");

      that.__find(".lp__error_box").append("<p>"+general_message+"</p>");
    }

    if (errors && errors.length > 0) {
      that.__find(".lp__error_box").append("<ul></ul>");

      for (var i=0; i < errors.length; i++) {
        that.__find(".lp__error_box ul").append("<li>"+errors[i]+"</li>");
      }
    }

    setTimeout(function() {
      that.__find(".lp__error_box").addClass("show");
    }, 20);

  //         <div class="lp__error_box">
  //   <a class="lp__close"><span class="oi oi-x" title="icon name" aria-hidden="true"></span></a>

  //   <p>There were a number of errors in trying to save this form. Please note the below:</p>
  //   <ul>
  //     <li>You smell funny</li>
  //   </ul>
  // </div>
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

  this.initProviderSelectize = function(){
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
    $.ajax({
      url: '/api/frontend/providers/titles',
      type: 'GET',
      success: function(data) {
       var items = data.titles;
       $('#provider_title').selectize({
          plugins: ['remove_button'],
          labelField: "title",
          valueField: "title",
          options: items,
          searchField: 'title',
          maxItems: 1
        });
      }
    });
  };

  this.initCompanySelectize = function(){
    $.ajax({
      url: '/api/frontend/companies',
      type: 'GET',
      success: function(data) {
        var items = data.companies;
        $('#appointment_sales_rep_company_id').selectize({
          plugins: ['remove_button'],
          options: items,
          valueField: 'id',
          labelField: 'name',
          searchField: 'name',
          maxItems: 1,
          mode: 'multi',
          openOnFocus: false,
          create: true
        });
      }
    });
  };
  this.initSalesRepSpecialitiesSelectize = function(){
    $.ajax({
      url: '/api/frontend/providers/specialties',
      type: 'GET',
      success: function(data) {
       specialties = data.specialties;
       var items = specialties.map(function(x) { return { item: x }; });
       $('#sales_rep_specialties').selectize({
          plugins: ['remove_button'],
          labelField: "item",
          valueField: "item",
          searchField: 'item',
          options: items,          
          placeholder: "Select specialties for this Sales Rep"
        });
      }
    });
  }
  this.initCuisineSelectize = function(){
    $.ajax({
      url: '/api/frontend/restaurants/cuisines',
      type: 'GET',
      success: function(data) {
       cuisines = data.cuisines;
       var items = cuisines.map(function(x) { return { item: x }; });
       $('#restaurant_cuisines').selectize({
          plugins: ['remove_button'],
          labelField: "item",
          valueField: "item",
          searchField: 'item',
          options: items,
          placeholder: "Select cuisines for this restaurant"
        });
      }
    });
  };

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

    debug("Component handlers bound for LPForm (comp__form)")
  };

  this.init();
  headquarters_id = $("#restaurant_headquarters_id").val();
  if(headquarters_id){
    $(".headquarters__select").show();
  };
  if($("#provider_specialties").length){
    this.initProviderSelectize();
  }else if($("#appointment_sales_rep_company_id").length){
    this.initCompanySelectize();
  }

  if($("#restaurant_cuisines").length){
    this.initCuisineSelectize();
  }

  if($("#end_date").length && $("#start_date").length){
    this.initFlatPickr(".date-field-starts-at");
    this.initFlatPickr(".date-field-ends-at");
  }

  if($("#appointment_slot_days").length){
    this.initSlotDayOfWeeksSelectize();
  }
  if($("#sales_rep_specialties").length){
    this.initSalesRepSpecialitiesSelectize();
  }

 //if datepicker fields
  if($(".reward-date-field").length){
    this.initFlatPickr(".reward-date-field");
  }  

};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPForm_Initializer = function() {
  var component_name = "comp__form"

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPForm(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPForm(object)
      $(object).addClass("__comp_active")
    }
  });
}
