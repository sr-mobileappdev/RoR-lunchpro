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


function LPRepAppointments(component) {
  this.base_component = component,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "office_detail" : ["targ__office_detail"],
    "new_appointment_view" : ["targ__new_appointment"]
  },

  this.endpoints = {
    "post__reserve_slot" : "/rep/offices/<id>/reserve_slot?type=<type>",
    "post__undo_reserve_slot": "/rep/offices/<id>/cancel_reserve",
    "post__filter_slots": "/rep/offices/<id>/filter_slots",
    "post__rep_confirm" : "/rep/appointments/<id>/confirm",
    "post__rep_cancle_confirm" : "/rep/appointments/<id>/cancel_confirm",
    "get__appointment__existing_office_path" : "/rep/orders/office_search",
    "get__appointment__new_office_path" : "/rep/orders/appointment_list",
    "get__display_booked_appointment": "/rep/appointments/<id>/display_booked?is_modal=true",
    "get__display_duplicate_appointment": "/rep/appointments/display_duplicate?is_modal=true&date=<date>&slot_id=<slot_id>&office_id=<office_id>"
  },

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    "calendar:select_week" : "changeWeek",
  },

  this.events = {
    "click [data-toggleable]" : "toggleFilter",
    "click [data-toggle-slot]" : "toggleReserveSlot",
    "click .trig__reserve_appointment" : "reserveSlot",
    "click .trig__undo_appointment" : "undoReserveSlot",
    "click .trig__undo_appointment_review" : "undoReserveSlotReview",
    "click .trig__confirm_appointment" : "confirmAppointment",
    "click .__select_tab" : "showTab"
  },

  this.changeWeek = function(e, element, params) {
    $('#skip').css("display", "none"); //hide skip

    that = this;

    to_date = params.date;

    //grab active filters and get the ids to pass into controller... don't lose the filter
    var activeFilters = $(".lp__filters_provider.active");
    var filterIds = [];
    if(activeFilters.length > 0){
      activeFilters.each(function(i, filter){
        filterIds.push($(filter).attr("data-off-value"));
      });
    }

    endpoint_path = Requests.buildPath(that.endpoints.post__filter_slots, {"id" : $('.comp__rep_appointments').attr("data-office-id")});

    data = { "start_date": to_date,
              "provider_ids": filterIds
           };
    target = $(".targ-rep-appointments");
    //$(e.currentTarget)

    Requests._request("post", endpoint_path, data,
      function(successResponse) {
        if (successResponse.template) {
          $(target).html(successResponse.template);
          if (target.find("li").length > 0) {
            //appmnts
          }
          else
          {
            $('#skip').css("display", ""); //show skip
          }
        }
      },
      function(errorResponse) {

      }
    );

    stopProp(e);

  },
  this.showTab = function(e){
    var that = this;
    
    that.__find(".nav-link.active").removeClass("active");
    $(e.currentTarget).toggleClass("active");

    if ($(e.currentTarget).data("comp-detail-tab") == "existing_office") {
      that.__find(".targ__office_search").show()
      that.__find(".targ__all_office_search").hide()
    } else if ($(e.currentTarget).data("comp-detail-tab")== "new_office") {
      that.__find(".targ__all_office_search").show()
      that.__find(".targ__office_search").hide()
    }

    return false;
  },
  this.toggleFilter = function(e) {
    that = this;

    $(e.currentTarget).toggleClass("active");

    $(".lp__filters_provider").toggleClass("disabled");
    $(".lp__filters_provider").prop("disabled", "disabled");
    //grab active filters and get the ids to pass into controller
    var activeFilters = $(".lp__filters_provider.active");
    var filterIds = [];
    if(activeFilters.length > 0){
      activeFilters.each(function(i, filter){
        filterIds.push($(filter).attr("data-off-value"));
      });
    }

    var slot_date = $("ul#appointments-list li.appointment-list-slot:first-child .vertical-nav-li-header:first-child ").data("date");

    endpoint_path = Requests.buildPath(that.endpoints.post__filter_slots, {"id" : $(e.currentTarget).attr("data-office-id")});

    data = { "slot_id": $(e.currentTarget).attr("data-reserve-slot-id"),
             "start_date": slot_date,
              "provider_ids": filterIds
           };
    target = $(".targ-rep-appointments");

    //$(e.currentTarget)
    Requests._request("post", endpoint_path, data,
      function(successResponse) {
        if (successResponse.template) {
          $(target).html(successResponse.template);
          
          $(".lp__filters_provider").toggleClass("disabled");
          $(".lp__filters_provider").prop("disabled", false);
        }
      },
      function(errorResponse) {
      }
    );

    stopProp(e);
  },

  this.confirmAppointment = function(e) {
    that = this;

    endpoint_path = Requests.buildPath(that.endpoints['post__rep_confirm'], {"id" : $(e.currentTarget).attr("data-appointment-id")});
    data = {};
    target = $(e.currentTarget).closest(".targ__slot");

    //$(e.currentTarget)
    Requests._request("post", endpoint_path, data,
      function(successResponse) {
        if (successResponse.template) {

          $(target).html(successResponse.template);
        }
      },
      function(errorResponse) {
      }
    );

    stopProp(e);
  },

  this.toggleReserveSlot = function(e) {
    that = this;

    if(!$(e.currentTarget).find('.text-info').length){
      $(e.currentTarget).closest(".trig__toggle_on_open").toggleClass("open");
    }

  },

  this.reserveSlot = function(e) {
    that = this;

    $(e.currentTarget).addClass("disabled");

    endpoint_path = Requests.buildPath(that.endpoints['post__reserve_slot'], 
      {"id" : $(e.currentTarget).attr("data-office-id"), "type": $(e.currentTarget).attr("data-type")});


    data = { "slot_id": $(e.currentTarget).attr("data-reserve-slot-id"),
             "slot_date": $(e.currentTarget).attr("data-reserve-date")
           };
    target = $(e.currentTarget).closest(".targ__slot");

    //$(e.currentTarget)
    Requests._request("post", endpoint_path, data,
      function(successResponse) {
        if(successResponse.display_duplicate){
          modal_anchor = $(target).find("a#display-duplicate");
          date = successResponse.date;
          slot_id = successResponse.slot_id;
          office_id = successResponse.office_id;  
          endpoint_path = Requests.buildPath(that.endpoints['get__display_duplicate_appointment'],
            {"date": date, "slot_id": slot_id, "office_id": office_id});   
          modal_anchor.attr("href", endpoint_path);
          modal_anchor.trigger("click");
          $(e.currentTarget).removeClass("disabled");
        }
        if(successResponse.template) {
          if(successResponse.trigger_booked_modal == true && successResponse.appt_id){
            $(target).html(successResponse.template);
            $('#office_calendar').fullCalendar( 'refetchEvents' );
            $('.lp__finish_button').prop('disabled', false);
            //grab newly created appt, create endpoint to display booked modal, assign href to anchor, trigger click.
            appt_id = successResponse.appt_id;
            modal_anchor = $(target).find("a#display-booked");       
            endpoint_path = Requests.buildPath(that.endpoints['get__display_booked_appointment'], {"id" : appt_id});   
            modal_anchor.attr("href", endpoint_path);
            modal_anchor.trigger("click");
          }else if(successResponse.book_duplicate){
            target = $(".targ__slot a[data-reserve-slot-id=" + successResponse.slot_id +"]");
            target = target.closest(".targ__slot");
            $(target).html(successResponse.template);
            $('#office_calendar').fullCalendar( 'refetchEvents' );
            $('.lp__finish_button').prop('disabled', false);
            //grab newly created appt, create endpoint to display booked modal, assign href to anchor, trigger click.
            appt_id = successResponse.appt_id;
            modal_anchor = $(target).find("a#display-booked");       
            endpoint_path = Requests.buildPath(that.endpoints['get__display_booked_appointment'], {"id" : appt_id});   
            modal_anchor.attr("href", endpoint_path);
            modal_anchor.trigger("click");
          }
        }
      },
      function(errorResponse) {
      }
    );

    stopProp(e);

  },
  this.undoReserveSlotReview = function(e) {
    that = this;
      
    $(e.currentTarget).addClass("disabled");
    endpoint_path = Requests.buildPath(that.endpoints['post__undo_reserve_slot'], {"id" : $(e.currentTarget).attr("data-office-id")});
    data = {  "review": true,
              "appointment_id": $(e.currentTarget).attr("data-appointment-id"),
           };
    
    Requests._request("post", endpoint_path, data,
      function(successResponse) {
        that._handleRedirect(successResponse);
        
      },
      function(errorResponse) {

      }
    );

    stopProp(e);

  },
  this.undoReserveSlot = function(e) {
    that = this;
    
    $(e.currentTarget).addClass("disabled");
    endpoint_path = Requests.buildPath(that.endpoints['post__undo_reserve_slot'], {"id" : $(e.currentTarget).attr("data-office-id")});
    data = { "slot_id": $(e.currentTarget).attr("data-reserve-slot-id"),
              "appointment_id": $(e.currentTarget).attr("data-appointment-id"),
              "slot_date": $(e.currentTarget).attr("data-reserve-date")
           };
    target = $(e.currentTarget).closest(".targ__slot");

    //$(e.currentTarget)
    Requests._request("post", endpoint_path, data,
      function(successResponse) {
        if (successResponse.template) {

          $('#office_calendar').fullCalendar( 'refetchEvents' );
          $(target).html(successResponse.template);
        }
      },
      function(errorResponse) {
      }
    );

    stopProp(e);

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

    debug("Component handlers bound for LPRepAppointments(comp__rep_appointments)");
  },

  this.init();
  
  var $officeSearchInput = $("#repOfficeSearchTerm");
  if($officeSearchInput != null){
  	var typingTimer;
  	var doneTypingInterval = 1000;
  	var doneTypingCallback = function(){
		$officeSearchInput.closest("form").submit();
  	};
  	
	$officeSearchInput.on('keyup', function () {
 	 	clearTimeout(typingTimer);
	 	typingTimer = setTimeout(doneTypingCallback, doneTypingInterval);
	});

	$officeSearchInput.on('keydown', function () {
	  clearTimeout(typingTimer);
	});
  }
}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRepAppointments_Initializer = function() {
  var component_name = "comp__rep_appointments";

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPRepAppointments(this);
      $(this).addClass("__comp_active");
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRepAppointments(object);
      $(object).addClass("__comp_active");
    }
  });
};
