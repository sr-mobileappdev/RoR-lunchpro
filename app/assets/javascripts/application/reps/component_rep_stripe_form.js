4// Component
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


function LPRepStripeForm(component) {
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
    "click [data-submit-stripe]" : "submitFormStripe",
    "click [data-cancel]" : "removeStripeElements"    
  },

  // Component only events
  this.events = {
    "click .lp__error_box .lp__close" : "closeErrorBox",
  },
  $.elements = $.stripe.elements();
  $.card = $.elements.create('cardNumber', {'classes': {'base':"form-control form-control-sm"}, 'placeholder':''});
  $.cardCVV = $.elements.create('cardCvc', {'classes': {'base':"form-control form-control-sm"}, 'placeholder':''});
  $.cardExpiry = $.elements.create('cardExpiry', {'classes': {'base':"form-control form-control-sm"}, 'placeholder':''});

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
            if(url == "/rep/profile/new_payment_method"){LPRepStripeForm_Initializer();}
            if(url == "/rep/profile/change_password"){LPRepForm_Initializer();}
          }
        });
      },
      function(errorResponse) {
        debug_error("We got an error response");
        debug_error(errorResponse);
      }
    );

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
        that._handleRedirect(resp);
        //callback_function(resp, true);
            
      },
      function(errorResponse) {
        var resp = errorResponse.responseJSON;// responseJSON is only returned on errors
        that._showErrors(resp.general_error, resp.errors, {});
        //callback_function(resp, false);
        $(form_element).find('[data-submit-stripe]').prop("disabled", false);
        $(form_element).find('[data-submit-stripe]').removeClass("disabled");

      }
    );


  },

  this.submitFormStripe = function(e) {
    var that = this;
    var form_element = that.__find("form");
    $(form_element).find('[data-submit-stripe]').prop("disabled", 'disabled');
    $(form_element).find('[data-submit-stripe]').addClass("disabled");
    var cardData = { };
    $.each(form_element.serializeArray(), function() {
          cardData[this.name] = this.value;
    });
    if(!$('#payment_method_stripe_identifier').val() && (!$('#existing_payment_method_id').val() || $('#existing_payment_method_id').val() == '0')){
      if(!cardData.length && (cardData.name.length === 0 || !cardData.name.trim())){
        that._showErrors("You must provide the Name on Card.");       
        $(form_element).find('[data-submit-stripe]').prop("disabled", false);
        $(form_element).find('[data-submit-stripe]').removeClass("disabled");
        stopProp(e);
        return;
      }
      Pace.options.minTime = 5000;
      Pace.options.maxProgressPerFrame = 5;
      Pace.options.easeFactor = 0.75;
      Pace.options.restartOnRequestAfter = 5;
      Pace.restart();
      $.stripe.createToken($.card, cardData).then(function(result) {
        if(result.error){
          Pace.options.minTime = 0;
          Pace.stop();
          that._showErrors(result.error.message);
        }else{
          token = result.token.id;
          form_element.append($("<input type=\"hidden\" name=\"card_token\" />").val(token));
          that._processForm(form_element, {},
            function(response_options, success) {

            }
          );
       }
      });
    }else{
      Pace.restart();
      that._processForm(form_element, {},
        function(response_options, success) {
        
        }
      );
    }
    stopProp(e);
  },


  this._handleRedirect = function(resp) {
    Pace.options.minTime = 200;
    Pace.restart();
    if (resp && resp.redirect) {
      window.location = resp.redirect;
      Pace.stop();
      return;
    } else if (resp && resp.reload) {
      window.location.reload(true);
      Pace.stop();
      return;
    }
  },

  this._showErrors = function(general_message, errors, options) {
    that = this;
    if (general_message == undefined) {
      general_message = "System error (500)";
    }

    that.__find(".lp__error_box").remove();
    that.__find("form").prepend("<div class='lp__error_box'><a class='lp__close'><span class='oi oi-x' title='close' aria-hidden='true'></span></a></div>");

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
    Pace.restart();
    if (this.base_component == undefined) { console.error("Missing component during init of new object"); return; }
    var form_element = this.__find("form");

     if(!$('#payment_method_stripe_identifier').val()){
      $.card.mount('#card-element');
      $.cardCVV.mount('#card-cvv');    
      $.cardExpiry.mount('#card-expiry');
    }
    this.bind_handlers();
    $("[data-comp-detail-tab='profile__financial_info']").addClass("profile-active");
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

    debug("Component handlers bound for LPStripeForm (comp__form)");
  },

  this.init();

}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRepStripeForm_Initializer = function() {
  var component_name = "comp__rep_stripe_form";
  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPRepStripeForm(this);
      $(this).addClass("__comp_active");
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRepStripeForm(object);
      $(object).addClass("__comp_active");
    }
  });
};

