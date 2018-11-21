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
// 1.5 - Added additional param to event binding to allow passing in options


function LPModal(component) {
  this.base_component = component,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    // "office_detail" : ["targ__office_detail"]
  };

  this.endpoints = {
    // "get__office_detail_notes_path" : "/rep/offices/<id>/notes"
  };

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    "click [data-modal]" : "openModal",
    "lp.show_modal" : "openModalByEvent",
    "click .prompt_schedule" : "promptSchedule",
    "click .lp__cancel_appointment" : "showRepCancelApptForm",
    "click .lp__om_cancel_appointment" : "showOmCancelApptForm",
    "click .lp__edit_byo" : "showEditByoForm"
  };

  this.events = {
    // "click [data-comp-detail-id]" : "showOffice"
  };


  var modal_size = null;
  this.showEditByoForm = function(e){
    LPRepForm_Initializer();
    $(".lp__appointment_body").hide();
    $(".lp__edit_byo_form").show();
  }
  this.showRepCancelApptForm = function(e){
    LPRepForm_Initializer();
    $(".lp__appointment_body").hide();
    $(".lp__cancel_appointment_form").show();

  };
  this.showOmCancelApptForm = function(e){
    LPOmForm_Initializer();
    $(".lp__appointment_body").hide();
    $(".lp__cancel_appointment_form").show();

  };
  //used to prevent toggle multiple modals as required by invision :P
  this.promptSchedule = function(e){
    $(".existing-appointment").hide();
    $('#modal__core').addClass("modal-sm");
    $('#modal__core_dialog').addClass("modal-sm");
    $(".schedule-appointment").show();

  };

  this.openModalByEvent = function(e, options) {
    that = this;

    if (options != undefined && options.url != undefined) {
      that.openModelWithUrl(options.url)
    } else {
      console.error("Missing or bad url binding")
    }
  };

  this.openModal = function(e) {
    var that = this

    url = $(e.currentTarget).attr("href")
    if (url == undefined) {
      console.error("URL missing for modal")
      return;
    }
    $('#modal__core').removeClass("modal-" + modal_size);
    $('#modal__core_dialog').removeClass('modal-' + modal_size);
    modal_size = null;
    modal_size = $(e.currentTarget).attr("data-modal-size");

    if(modal_size){
      //reset modal size... add modal size
      $('#modal__core').attr('class', 'modal comp__modal __comp_active');
      $('#modal__core_dialog').attr('class', 'modal-dialog');
      $('#modal__core').addClass("modal-" + modal_size);
      $('#modal__core_dialog').addClass('modal-' + modal_size);
    }
    that.openModelWithUrl(url);
    stopProp(e);

  };

  this.openModelWithUrl = function(url) {
    if (url.indexOf('?') > 0) {
      url = url + '&is_modal=true';
    } else {
      url = url + '?is_modal=true';
    }

    Requests._getRequest(url,
      function(successResponse) {
        if(successResponse.html){
          $(".comp__modal .__model_content").html(successResponse.html)
          $('#modal__core').modal();
        }else{
          
        }
      },
      function(errorResponse) {
        $(".comp__modal .__model_content").html("")
        $('#model__core').modal()
      }
    );
  };



  /* adding logic to handle form submissions in modals, gotta love MODAL FORMS :^) */


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

    Object.keys(_handler.document_events).forEach(function (key) {
      this_event = key.split(" ");
      var method_name = _handler.document_events[key];
      event_action = this_event.splice(0, 1)[0]
      event_target = this_event.join(" ")
      $(document).on(event_action, event_target, function(e, options) {
        _handler[method_name](e, options)
      });
    });

    debug("Component handlers bound for LPModal (comp__modal)")
  };

  this.init();

};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPModal_Initializer = function() {
  var component_name = "comp__modal"

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPModal(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPModal(object)
      $(object).addClass("__comp_active")
    }
  });
}
