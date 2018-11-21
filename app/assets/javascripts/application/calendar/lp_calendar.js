document.addEventListener("turbolinks:load", function() {
  if($("#appointment_appointment_on").length){
    $.order_appointment = true;
  }
  var calendar = null;
  if($("#office_calendar").length){
    calendar = $("#office_calendar");
    start_date = calendar.data("start-date");
    if(!start_date){
      min_date = moment().format("YYYY-MM-DD");
    }else{
      min_date = start_date
    }
    until = calendar.attr("data-calendar-until");
    initial_load = true;
    calendar.fullCalendar({
    columnFormat: 'dd',
    header: false,
    height: 'auto',
    allDaySlot: false,
    defaultDate: min_date,
    eventLimit: 2,
    selectable: false,
    events: function(start, end, timezone, callback) {
      //get the min_date for the calendar icons
      min_date = start.format("YYYY-MM-DD") < moment().format("YYYY-MM-DD") ? moment().format("YYYY-MM-DD") : start.format("YYYY-MM-DD")
      //update the url param for the last toggled date on the review appointments button, and the back button on office/calendar
      //which navigates user to policies
      $(".appt-back-btn").attr("href", $(".appt-back-btn").attr("href").split("&")[0] + "&start=" + min_date);
      //this is used so pace doesnt get triggered when selecting/deselecting appt slots
      if(start_date && start_date != start.format("YYYY-MM-DD")){
        $(".targ-rep-appointments").hide();
        Pace.options.minTime = 1500;
        Pace.restart();
      }
      //update start_date with the first day on the calendar
      start_date = start.format("YYYY-MM-DD");
      $.ajax({
          url: '/api/frontend/appointments',
          dataType: 'json',
          data: {
              office_id: calendar.attr("data-office-id"),
              for_office: true,
              start_date: min_date,
              end_date: end.format("YYYY-MM-DD")
          },
          success: function(response) {
              var events = response.data.events;
              callback(events);
              setTitle();
              calendar.fullCalendar('select', new Date());              
          }
      });
    },
    eventRender: function(event, element) {

        //TODO: Figure out a way to remove events where excluded without removing the key completely
      element.find(".fc-title").html(
          "<i title='"+event.title+"' class='event-dot "+event.className+"'></i>"
      );
      /*

      if(event.className == 'hidden-booked'){
        test = element.find(".fc-title");

        if(test.find('i').hasClass("current-booked") || test.find('i').hasClass("current-pending") || test.find('i').hasClass("open")){

        }else{
          element.addClass(event.className);
          element.find(".fc-title").html(
              "<i title='"+event.title+"' class='event-dot "+event.className+"'></i>"
          );
        }
      }else{
                //TODO: Figure out a way to remove events where excluded without removing the key completely
        element.removeClass("hidden-booked")l
        element.addClass(event.className);
        element.find(".fc-title").html(
            "<i title='"+event.title+"' class='event-dot "+event.className+"'></i>"
        );
      }
      */
      $(".targ-rep-appointments").show();
    },
    dayClick: function(date, jsEvent, view) {

      $(".appt-back-btn").attr("href", $(".appt-back-btn").attr("href").split("&")[0] + "&start=" + date.format("YYYY-MM-DD"));
      if(date.isBefore(moment()) || date.isAfter(moment(until, 'MM-DD-YYYY'))) {
        calendar.fullCalendar('unselect');
        return false;
      }else{
        calendar.fullCalendar('select', date);
        goToDate(date);
      }
    },
    eventClick: function(calEvent, jsEvent, view) {

      $(".appt-back-btn").attr("href", $(".appt-back-btn").attr("href").split("&")[0] + "&start=" + calEvent.start.format("YYYY-MM-DD"));
        // Select the date on which the event starts
      if(calEvent.start.isBefore(moment())) {
        calendar.fullCalendar('unselect');
        return false;
      }else{
        calendar.fullCalendar('select', calEvent.start);
        goToDate(calEvent.start);
      }
    },
    viewRender: function(view){
      //last date the rep toggled to before leaving the page
      nav_to_date = calendar.data("start-date");
      if((!initial_load && !nav_to_date) || (nav_to_date && !initial_load)){
        $( document ).trigger("calendar:select_week", [null, {date: view.start.format("YYYY-MM-DD") < moment().format("YYYY-MM-DD") ? moment().format("YYYY-MM-DD") : view.start.format("YYYY-MM-DD")}]);
        $('#scrollable-appointment-container').animate({
            scrollTop: 0
        }, 500);
      }else if(nav_to_date && initial_load){
        $( document ).trigger("calendar:select_week", [null, {date: nav_to_date < moment().format("YYYY-MM-DD") ? moment().format("YYYY-MM-DD") : nav_to_date}]);
        $('#scrollable-appointment-container').animate({
            scrollTop: 0
        }, 500);
      }
      $('.fc-day').filter(
        function(index){
        return (moment( $(this).data('date') ).isAfter(moment(until, 'MM-DD-YYYY'))) || moment( $(this).data('date') ).isBefore(moment().format("YYYY-MM-DD"));
      }).addClass('fc-nonbusiness');
      initial_load = false;
    },
  });


  }else if($("#order_calendar").length){
    calendar = $("#order_calendar");
    initial_load = true;
    calendar.fullCalendar({
      columnFormat: 'dd',
      header: false,
      height: 'auto',
      allDaySlot: false,
      eventLimit: 2,
      selectable: false,
      events: function(start, end, timezone, callback) {
        $.ajax({
            url: '/api/frontend/orders',
            dataType: 'json',
            data: {
                start_date: start.format("YYYY-MM-DD"),
                end_date: end.format("YYYY-MM-DD")
            },
            success: function(response) {
                var events = response.data.events;
                callback(events);
                if(events.length == 0){
                  $("#default_skip").show();
                }else{
                  $("#default_skip").hide();
                }
                setTitle();
                calendar.fullCalendar('select', new Date());
            }
        });
      },
      eventRender: function(event, element) {
          element.find(".fc-title").html(
              "<i title='"+event.title+"' class='event-dot "+event.className+"'></i>"
          );
      },
      dayClick: function(date, jsEvent, view) {
        calendar.fullCalendar('select', date);
        goToDate(date);
      },
      eventClick: function(calEvent, jsEvent, view) {
          // Select the date on which the event starts
          calendar.fullCalendar('select', calEvent.start);
          goToDate(calEvent.start);
      },
      viewRender: function(view, element) {
          if(!initial_load){
            $.ajax({
                url: '/rep/calendars/filter_orders',
                dataType: 'json',
                data: {
                    month: view.title
                },
                success: function(response) {
                  if (response.template) {
                    target = $(".targ-rep-appointments");
                    $(target).html(response.template);
                    $('#scrollable-appointment-container').animate({
                      scrollTop: 0
                    }, 300);
                  }

                }
            });
          }
          initial_load = false;
        }
    });
  }else if($("#set_delivery_calendar").length){
    calendar = $("#set_delivery_calendar");

    calendar.fullCalendar({
        columnFormat: 'dd',
        header: false,
        height: 'auto',
        allDaySlot: false,
        eventLimit: 2,
        selectable: false,
        events: function(start, end, timezone, callback) {
          if(!$.order_appointment){
            $.ajax({
                url: '/api/frontend/appointments',
                dataType: 'json',
                data: {
                    start_date: start.format("YYYY-MM-DD"),
                    end_date: end.format("YYYY-MM-DD")
                },
                success: function(response) {
                    var events = response.data.events;
                    callback(events);
                    setTitle();
                    calendar.fullCalendar('select', new Date());
                }
            });
          }else{
            setTitle();
          }
        },
        eventRender: function(event, element) {
            element.find(".fc-title").html(
                "<i title='"+event.title+"' class='event-dot "+event.className+"'></i>"
            );
        },
        dayClick: function(date, jsEvent, view) {
          if($.order_appointment){
            if(moment(date).add(1, 'days').isBefore(moment())) {
                calendar.fullCalendar('unselect');
                return false;
            }else{
              setAppointmentDate(date, this);
            }
          }else{
            calendar.fullCalendar('select', date);
            goToDate(date);
          }
        },
        eventClick: function(calEvent, jsEvent, view) {
            // Select the date on which the event starts
            calendar.fullCalendar('select', calEvent.start);
            goToDate(calEvent.start);
        }
    });
  }else if($("#current_calendar").length){
    calendar = $("#current_calendar");
    initial_load = true;
    calendar.fullCalendar({
        columnFormat: 'dd',
        header: false,
        height: 'auto',
        allDaySlot: false,
        eventLimit: 2,
        selectable: false,
        events: function(start, end, timezone, callback) {
          $.ajax({
              url: '/api/frontend/appointments',
              dataType: 'json',
              data: {
                  start_date: start.format("YYYY-MM-DD"),
                  end_date: end.format("YYYY-MM-DD")
              },
              success: function(response) {
                var events = response.data.events;
                callback(events);
                setTitle();
                calendar.fullCalendar('select', new Date());
              }
          });
        },
        viewRender: function(view, element) {
          $.ajax({
              url: '/rep/calendars/filter_appointments',
              dataType: 'json',
              data: {
                start_date: view.start.format("YYYY-MM-DD"),
                end_date: view.end.format("YYYY-MM-DD")
              },
              success: function(response) {
                if (response.template) {
                  target = $(".targ-rep-appointments");
                  $(target).html(response.template);
                  if(response.goToDate){
                    goToDate(moment(response.goToDate));
                  }else{
                    $('#scrollable-appointment-container').animate({
                      scrollTop: 0
                    }, 300);
                  }
                }

              }
          });
        },
        eventRender: function(event, element) {
            element.find(".fc-title").html(
                "<i title='"+event.title+"' class='event-dot "+event.className+"'></i>"
            );
        },
        eventClick: function(calEvent, jsEvent, view) {
            // Select the date on which the event starts
            calendar.fullCalendar('select', calEvent.start);
            goToDate(calEvent.start);
        },
        dayClick: function(date, jsEvent, view) {
          calendar.fullCalendar('select', date);
          goToDate(date);
        }
    });
  }else if($("#restaurant_calendar").length){
    calendar = $("#restaurant_calendar");
    initial_load = true;
    calendar.fullCalendar({
      columnFormat: 'dd',
      header: false,
      height: 'auto',
      allDaySlot: false,
      eventLimit: 2,
      selectable: false,
      events: function(start, end, timezone, callback) {
        $.ajax({
            url: '/api/frontend/orders',
            dataType: 'json',
            data: {
                start_date: start.format("YYYY-MM-DD"),
                end_date: end.format("YYYY-MM-DD"),
                restaurant: $(calendar).attr("data-restaurant-id")
            },
            success: function(response) {
                var events = response.data.events;
                callback(events);
                setTitle();
                calendar.fullCalendar('select', new Date());
            }
        });
      },
      eventRender: function(event, element) {
          element.find(".fc-title").html(
              "<i title='"+event.title+"' class='event-dot "+event.className+"'></i>"
          );
      },
      dayClick: function(date, jsEvent, view) {
        calendar.fullCalendar('select', date);
        goToDate(date);
      },
      eventClick: function(calEvent, jsEvent, view) {
          // Select the date on which the event starts
          calendar.fullCalendar('select', calEvent.start);
          goToDate(calEvent.start);
      },
      viewRender: function(view, element) {
          if(!initial_load){
            $.ajax({
                url: '/restaurant/orders/filter_orders',
                dataType: 'json',
                data: {
                    month: view.title
                },
                success: function(response) {
                  if (response.template) {
                    target = $(".targ-restaurant-orders");
                    $(target).html(response.template);
                    $('#scrollable-appointment-container').animate({
                      scrollTop: 0
                    }, 300);
                  }

                }
            });
          }
          initial_load = false;
        }
    });
  }

    /* Jumps to date in calendar view */
    function goToDate(date, animate) {
        animate = animate || true;        
        var $li = $('#appointments-list .appointments-header[data-date="' + date.format("YYYY-MM-DD") + '"]').first().parent();
        if ($li.length) {
            $('#scrollable-appointment-container').animate({
                scrollTop: $('#scrollable-appointment-container').scrollTop() - $('#scrollable-appointment-container').offset().top + $li.offset().top
            }, 500);

            /* TODO: move this to a class and just toggle a class */
            $li.css({
                "border-left": "30px solid #c9c9c9",
                "transition": "border-width .5s ease-in-out"
            });

            setTimeout(function(){
                $li.css({"border-left-width": "0px"});
            }, 850);
        } else {
          // Need to load this date and then scroll to it somehow...
          $( document ).trigger("calendar:select_week", [null, {date: date.format("YYYY-MM-DD")}]);
          if(animate){
            $('#scrollable-appointment-container').animate({
                scrollTop: 0
            }, 500);
          }
        }
    }

    /* Custom Header */
    $('.fc-next-button').click(function() {
        calendar.fullCalendar('next');
        setTitle();
    });
    $('.fc-prev-button').click(function() {
        calendar.fullCalendar('prev');
        setTitle();
    });
    $('.fc-today-button').click(function() {
        calendar.fullCalendar('today');
        calendar.fullCalendar('select', new Date());
        setTitle();
        if(calendar.attr('id') == 'office_calendar'){
          goToDate(moment());
        }

    });
    function setTitle(){
        $('.fc-calendar-title').text(getTitle());
    }
    function getTitle(){
        return calendar.fullCalendar('getDate').format("MMM YYYY");
    }
    function setAppointmentDate(date, element){
      $("#appointment_appointment_on").val(date.format("YYYY-MM-DD")); //set value of hidden field
      $(calendar).find('td').removeClass('order-select');  //remove active classes
      $(calendar).find('td').removeClass('fc-highlight');
      $(".fc-content-skeleton [data-date = '" + date.format("YYYY-MM-DD") + "']").addClass("order-select");
      $('.lp__finish_button').attr('disabled', false);
    }

});
