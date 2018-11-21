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


function LPOmCalendar(component) {
  this.base_component = component,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    
  },

  this.endpoints = {
    "post__filter_slots": "/office/slots?start_date=<start_date>&end_date=<end_date>&provider_ids=<provider_ids>",
  },

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
  },

  this.events = {
    "click [data-toggleable]" : "toggleFilter",
    "click .trig__appointments_until" : "initApptUntil",
  },

  $.calendar = $("#calendar"),
  $.appt_until_calendar = $("#appointments-until-calendar"),
  $.provider_ids = null,
  $.start_date = null,
  $.end_date = null,

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
    endpoint_path = Requests.buildPath(that.endpoints.post__filter_slots, {"start_date": $.start_date,
             "end_date": $.end_date,
              "provider_ids": filterIds
           });
    $.provider_ids = filterIds;
    Requests.getRequestWithState(endpoint_path,
      function(successResponse) {
        events = successResponse.data.events;
        //add currently filtered ids to data attribute, remove current events and add filtered events
        $('#calendar').fullCalendar('removeEvents');
        $('#calendar').fullCalendar('addEventSource', events);
        $(".lp__filters_provider").toggleClass("disabled");
        $(".lp__filters_provider").prop("disabled", false);
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


  //this is used in the appointment_until modal, sets the date value of a hidden field in the form
  this.setDate = function(date, calendar, id){
    $("#office_appointments_until").val(date.format("YYYY-MM-DD")); //set value of hidden field
    $('td').removeClass('order-select');  //remove active classes
    $('td').removeClass('fc-highlight');
    $(id + " .fc-content-skeleton [data-date = '" + date.format("YYYY-MM-DD") + "']").addClass("order-select");
    $('.lp__finish_button').attr('disabled', false);
  },

  //this sets the start and end date that will be used in the ajax request to grab appointment slots. always grabs the full month's slots, even if week view.
  setDates = function(){
    //set start and end date
    if(calendar.fullCalendar('getView').name == "agendaWeek"){
      $.start_date = calendar.fullCalendar("getView").intervalStart.startOf('month').subtract(7, "days").format("YYYY-MM-DD");
      $.end_date = calendar.fullCalendar("getView").intervalEnd.endOf('month').add(14, "days").format("YYYY-MM-DD");
    }else{
      $.start_date = calendar.fullCalendar("getView").start.toJSON();
      $.end_date = calendar.fullCalendar("getView").end.toJSON();
    }
  },

  this.initCalendars = function(){

    that = this;
    calendar = $.calendar;
    $(".until").remove();
    until = calendar.attr("data-calendar-until");
    calendar.fullCalendar({
      header: {
          left: 'month,agendaWeek',
          center: 'title',
          right: 'today prev,next'
      },
      views: {
          month: {
              titleFormat: 'MMMM YYYY'
          },
          agendaWeek: {
              titleFormat: 'MMMM YYYY'
          }
      },
      allDaySlot: false,
      eventLimit: 4,
      minTime: calendar.data("min-time"),
      maxTime: calendar.data("max-time"),
      height: 'parent',
      slotMinutes: 15,
      slotDuration: '00:15:00',
      businessHours: {
          // days of week. an array of zero-based day of week integers (0=Sunday)
          dow: calendar.attr("data-availability"),
          start: "0:00:00",
          end: "24:00:00"
      },
      events: function(start, end, timezone, callback) {
        $.ajax({
            url: '/office/slots',
            dataType: 'json',
            data: {
                office_id: calendar.attr("data-office-id"),
                start_date: start.format("YYYY-MM-DD"),
                end_date: end.format("YYYY-MM-DD"),
                provider_ids: $.provider_ids   //currently filtered provider_ids are stored in this attribute, so when change month occurs, it will automatically filter
            },
            success: function(response) {
                var events = response.data.events;
                $('#calendar').fullCalendar('removeEvents');
                callback(events);
                calendar.fullCalendar('select', new Date());
            }
        });
      },
      eventRender: function (event, element){ 
        //manipulate the event title based on week view vs month view
        if(event.className == "excluded"){
          element.hide();

          $(".fc-day[data-date='" + event.slot_date +"']").addClass('fc-unavailable');
          $(".fc-day[data-date='" + event.slot_date +"']").closest(".fc-bg").next('.fc-content-skeleton').find("> table").addClass("calendar-excluded");
        }else{
          $(".fc-day[data-date='" + event.slot_date +"']").closest(".fc-bg").next('.fc-content-skeleton').find("> table").removeClass("calendar-excluded");
          var title = element.find( '.fc-title' );   
          if(element.hasClass("fc-day-grid-event")){
            if(event.className == "open"){
              title.html(event.key + " - OPEN");
            }else{
              if (event.excluded){
                title.html(event.key + " - UNAVAILABLE");
              }else{
                if(event.appointment_title){
                  title.html(event.key + " - " + (event.appointment_title));
                }else{
                  title.html(event.key + " - " + (event.sales_rep));
                }
              }
            }
          }else{
            element.attr("data-modal", 'true');
            element.attr("data-modal-title", "");
            
            //add modal logic, depending if appointment exists, or is open slot
            if(event.appointment_id){
              element.attr("href", "/office/appointments/" + event.appointment_id);
              if(event.appointment_title){
                element.attr("data-modal-size", "sm");
              }
            }else{
              element.attr("href", "/office/slots/" + event.id + "?date=" + event.slot_date);
              element.attr("data-modal-size", "sm");
            }
            if(event.className == "open"){
              title.html(
                "<label class='h6 mt-1'>" + event.title + " - " + event.start.format("h:mm a") + "</label>" +
                "<p class='mt-2'> Open Slot</p>"
                );
            }else{
              if(event.appointment_title){
                title.html(
                  "<label class='h6 mt-1'>" + event.appointment_title + " - " + event.start.format("h:mm a") + "</label>" +
                  "<p>"+ event.title + "</p>"
                  );
              }else if(event.excluded){
                element.attr("data-modal-size", "sm");
                title.html(
                  "<label class='h6 mt-1'>UNAVAILABLE</label>" +
                  "<p>"+ event.title + "</p>"
                  );
              }else{
                title.html(
                  "<label class='h6 mt-1'>" + event.title + " - " + event.start.format("h:mm a") + "</label>" +
                  "<p class='mb-0 mt-2'>"+ event.restaurant + "</p>" + 
                  "<p class='mb-0 mt-2'>" + event.sales_rep + "</p>" +
                  "<p class='mt-1'>" + event.company + "</p>"
                  );
              }
            }
          }
        }
      },
      dayRender: function (date, cell) {
      },
      viewRender: function(view){
        //filter to 'grey' out dates in the past, and dates past the 'appointments_until' attribute
        setDates();
        $('.fc-day').filter(
          function(index){
          return (moment( $(this).data('date') ).isAfter(moment(until, 'MM-DD-YYYY')) || moment( $(this).data('date') ).isBefore(moment().subtract(1, 'd')))
        }).addClass('fc-unavailable');
      },           
      dayClick: function(date, jsEvent, view){
        if(view.name == "month"){
          $('#calendar').fullCalendar('changeView', 'agendaWeek', date);
        }
      },
      eventClick: function(calEvent, jsEvent, view) {
        if(view.name == "month"){
          $('#calendar').fullCalendar('changeView', 'agendaWeek', calEvent.start);
        }
      }
    });
    //get the office's available_until and insert into title
    calendar.find('.fc-toolbar > .fc-center')
    .append('<p class="until">Calendar is open until:' +
      '<a class="text-success trig__appointments_until" data-modal-size="sm" data-modal="true" href="/office/appointments_until" data-modal-title="">' + until + '</a></span>');
    
    //make today btn btn link
    $(".fc-today-button").addClass("btn btn-link");
   
    var current_appointment_until = $("#office_appointments_until").val();
    if(current_appointment_until){
      $(".display_appointments_until").html("<p>Your Calendar is currently open until " + moment(current_appointment_until).format("MM/DD/YYYY") + "</p>");
    }
    //calendar used for setting appointment until
    $.appt_until_calendar.fullCalendar({
      columnFormat: 'dd',
      header: {
          left: '',
          center: 'title',
          right: 'prev,next'
      },
      height: 'auto',
      allDaySlot: false,
      eventLimit: 2,
      selectable: false,
      dayRender: function(date, cell){
        if(current_appointment_until == date.format("YYYY-MM-DD")){
          that.setDate(date, this, "#appointments-until-calendar");
        }
      },
      dayClick: function(date, jsEvent, view) {         
        if(date.isBefore(moment())) {
          $.appt_until_calendar.fullCalendar('unselect');
          return false;
        }else{
          that.setDate(date, this, "#appointments-until-calendar");
          $(".display_appointments_until").html("<p>Your Calendar Will Now Be Open Until " + date.format("MM/DD/YYYY") + "</p>");
        }
      },  
      eventClick: function(calEvent, jsEvent, view) {
          // Select the date on which the event starts
      },
      viewRender: function(){
        setDates();
      }
    });
  },  
  this.initApptUntil = function(){
    LPOmCalendar_Initializer();
    LPOmForm_Initializer();
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

    debug("Component handlers bound for LPOmCalendar(comp__om_calendar)");
  },

  this.init(),
  this.initCalendars();

}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPOmCalendar_Initializer = function() {
  var component_name = "comp__om_calendar";

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPOmCalendar(this);
      $(this).addClass("__comp_active");
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPOmCalendar(object);
      $(object).addClass("__comp_active");
    }
  });
};
