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


function LPOmForm(component) {
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
    "click [data-submit]" : "submitForm",
  },

  this.submitForm = function(e) {
    var that = this;
    // Find the form we need to submit
    //form_element = that.__find("form");
    var form_element = $(e.currentTarget).parents('form:first');
    if ($(e.currentTarget).attr("data-submit").length > 0) {
      form_element = that.__find("form#"+$(e.currentTarget).attr("data-submit"));
      if (!form_element || form_element.length == 0) {
        debug_error("Unable to locate form with ID '"+$(e.currentTarget).attr("data-submit")+"' (component_form.js -> _processForm)");
      }
    }
    $(form_element).find('[data-submit]').prop("disabled", 'disabled');    
    $(form_element).find('[data-submit]').addClass("disabled");
    Pace.restart();
    that._processForm(form_element, {},
      function(response_options, success) {
        // Custom handler if desired, for after the form processes (or fails)

        //if this form submission occurs in past appointment modal, display feedback message
        if(success){
          if($(component).attr('data-past-modal')){
            $('.lp__feedback').show();
            $(component).hide();
            that.handleStars(response_options.overall);
          }
        }else{
          if(!response_options.disable_save){
            $(form_element).find('[data-submit]').prop("disabled", false);
            $(form_element).find('[data-submit]').removeClass("disabled");
          }

        }
      }
    );

    stopProp(e);
  },

  this.handleStars = function(rating){ 
    if(rating){
      $("#review" + rating).prop("checked", true);
    }
  },
  this.closeErrorBox = function(e) {
    $(e.currentTarget).closest(".lp__error_box").removeClass("show");
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
          that._showSuccess();
        }
        that._handleRedirect(resp);
        callback_function(resp, true);
      },
      function(errorResponse) {
        var resp = errorResponse.responseJSON; // responseJSON is only returned on errors
        options = {};
        if(resp && resp.show_bottom){
          options = {show_bottom: true};
        }
        if(resp && resp.clear_passcode){          
          $(".passcode-submit").prop("disabled", true);
          $(".display-otp-box").val(null);
        }
        that._showErrors(resp.general_error, resp.errors, options);
        callback_function(resp, false);
      }
    );

  },

  this._showSuccess = function(){
    that.__find(".lp__error_box").remove();
    that.__find(".alert-success").remove();
    that.__find("form").prepend("<div class='alert alert-success alert-dismissable'><a href='#' class='close' data-dismiss='alert' aria-label='close'>&times;</a><label>Your changes were saved successfully!</label></div>");
  },

  this._showErrors = function(general_message, errors, options) {
    $(".inline-error").remove();
    that = this;
    if (general_message == undefined) {
      general_message = "System error (500)";
    }

    that.__find(".lp__error_box").remove();
    if(options.show_bottom){
      that.__find(":submit").parent().before("<div class='col-12 mt-4 inline-error'><div class='lp__error_box'><a class='lp__close'><span class='oi oi-x' title='close' aria-hidden='true'></span></a></div></div>");  
    }else{
      that.__find("form").prepend("<div class='col-12 px-4 mx-auto lp__error_box'><a class='lp__close'><span class='oi oi-x' title='close' aria-hidden='true'></span></a></div>");
    }

    that.__find(".lp__error_box").append("<p>"+general_message+"</p>");

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
  },

  this._handleRedirect = function(resp){
    Pace.restart();
  },

  this.initMultiSelectize = function(element){

    data = $(element).attr('data-attributes');
    if(data) data = JSON.parse(data);
    $(element).selectize({
      plugins: ['remove_button'],
      options: data,
      valueField: 'id',
      labelField: 'name',
      searchField: 'name',
      openOnFocus: false,
      placeholder: "Begin by typing the restaurant's name"
    });
  },

  this.initDrugSelectize = function(){
    drugs = $('#appointment_samples_requested').attr('data-drugs');
    if(drugs) drugs = JSON.parse(drugs);
    $('#appointment_samples_requested').selectize({
      plugins: ['remove_button'],
      options: drugs,
      valueField: 'id',
      labelField: 'brand',
      searchField: 'brand',
      placeholder: "Select which drugs to be requested"
    });
  }


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

    debug("Component handlers bound for LPOmForm (comp__om_form)");
  };
  if($("[data-multi-selectize]").data()){
    this.initMultiSelectize($("[data-multi-selectize]"));
  }else if($("#appointment_samples_requested").length){
    this.initDrugSelectize();
  }
  this.init();

}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPOmForm_Initializer = function() {
  var component_name = "comp__om_form";
  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPOmForm(this);
      $(this).addClass("__comp_active");
    }  });



  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPOmForm(object);
      $(object).addClass("__comp_active");
    }
  });
};

