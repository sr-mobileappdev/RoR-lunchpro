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



function LPNotification(component) {
  this.base_component = component,
  this._loadingDelay = 500,

  this.data_targets = {
    "notification_dropdown" : ["targ__notification_dropdown"]
  },

  // Component only events
  this.events = {
    "click .__remove-notification" : "removeNotification"
    /*
    "click .rep__trigger_notification_dropdown" : "displayRepNotifications",
    "click .om__trigger_notification_dropdown" : "displayOmNotifications",
    "click .rest__trigger_notification_dropdown" : "displayRestNotifications"*/
  },

  this.endpoints = {
    "get__rep_notifications_path" : "/rep/notifications",
    "get__om_notifications_path" : "/office/notifications",
    "get__rest_notifications_path" : "/rest/notifications"
  },



  this.removeNotification = function(e) {

    url = $(e.currentTarget).data("href");
    Requests._request("post", url, {},
      function(successResponse) {
        debug("Ping request was successful");
      },
      function(errorResponse) {
        debug("Ping failed");
      }
    );

    $(e.currentTarget).closest("div.dropdown-item").remove();

    stopProp(e);

  },

  this.displayOmNotifications = function(e){
    var that = this;

    url = Requests.buildPath(that.endpoints.get__om_notifications_path);
    $(e.currentTarget).closest("li.dropdown").toggleClass("show");
    $(e.currentTarget).attr("aria-expanded","true");

    if($(e.currentTarget).closest("li.dropdown").hasClass("show")){
      target = "notification_dropdown";

      Requests.getRequestWithState(url,
        function(successResponse) {
          if (successResponse.templates && successResponse.templates[target]) {
     
            $("."+target).html(successResponse.templates[target]);

          }
        },
        function(errorResponse) {
          debug_error("We got an error response");
          debug_error(errorResponse);
        }
      );
    }

   stopProp(e);
  },

  this.goBack = function(e) {
    that = this;

    url = $(e.currentTarget).find("a").attr("href")
    if (url == undefined || url == "") {
      window.history.back();
    } else {
      window.location = url;
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

    debug("Component handlers bound for LPNotification (comp__notification)");
  },

  this.init();


}
// Component Activation - Be sure these values are set fresh when you create a new component

var LPNotification_Initializer = function() {
  var component_name = "comp__notification";

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPNotification(this);
      $(this).addClass("__comp_active");
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPNotification(object);
      $(object).addClass("__comp_active");
    }
  });
};
