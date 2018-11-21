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


function LPPopup(component) {
  this.base_component = component,
  this._loadingDelay = 500,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    //"nothing" : ["targ__nothing"]
  };

  this.endpoints = {
    //"get__office_detail_path" : "/rep/offices/<id>",
  };

  // Events that should trigger on the entire document (not scoped to component)
  this.document_events = {
    "click [data-popup]" : "showPopup",
    "click [data-method]": "disableLink"
    // "click [data-submit]" : "submitForm"
  };

  // Component only events
  this.events = {
    "click a.targ-close" : "hidePopup",
    "submit form": 'disableSubmit',
    "submit .edit_restaurant": 'submitRestaurantForm'
  };

  this.disableSubmit = function(e){
    $(e.currentTarget).find(":submit").prop("disabled", 'disabled');
    
  };
  this.showPopup = function(e) {
    var that = this

    title = ""
    if ($(e.currentTarget).attr("data-popup-title")) {
      title = $(e.currentTarget).attr("data-popup-title")
    }

    h2_title = $(".comp__popup").find(".__header h2").text()
    $(".comp__popup").find(".__header h2").text(h2_title.replace("{{TITLE}}", title))

    if ($(e.currentTarget).attr("data-popup-large")) {
      $(".comp__popup").addClass("sz-large")
    } else {
      $(".comp__popup").removeClass("sz-large")
    }

    $(".comp__popup").addClass("show")
    $(".comp__popup .__popup").addClass("show")



    url = $(e.currentTarget).attr("href")
    Requests._getRequest(url,
      function(successResponse) {
        $(".comp__popup .__popup_content").html(successResponse.html)
      },
      function(errorResponse) {

      }
    );


    stopProp(e);
  };

  this.hidePopup = function(e) {
    var that = this

    $(".comp__popup").removeClass("show")
    $(".comp__popup .__popup").removeClass("show")

    stopProp(e);
  };

  this.submitRestaurantForm = function(e){
    e.preventDefault();
    var formData = new FormData(e.currentTarget);
    $(e.currentTarget).find(":submit").prop("disabled", 'disabled');
    $.ajax({
      type: 'POST',
      url: $(e.currentTarget).attr('action'),
      data: formData,
      cache: false,
      contentType: false,
      processData: false,
      success: function(data) {
        if(data.reload_logo){
          var that = this;
          $(".comp__popup").removeClass("show")
          $(".comp__popup .__popup").removeClass("show")
          modifiedForm = 0;
          var upload_path = "/admin/restaurants/<id>/upload_partial"
          var restaurant_id = $('.targ__restaurant_image_upload').attr("data-restaurant-id");
          endpoint_path = Requests.buildPath(upload_path, {"id": restaurant_id});
          target = "targ__restaurant_image_upload"
          Requests.getRequestWithState(endpoint_path,
            function(successResponse) {
                if (successResponse.templates && successResponse.templates[target]) {
                  $("."+target).html(successResponse.templates[target]);
                }
            },
            function(errorResponse) {
              debug_error(errorResponse);
            }
          );
        }
      },
      error: function(data) {
        $(e.currentTarget).find(":submit").prop("disabled", false);
        $(e.currentTarget).find(":submit").removeClass("disabled");
      }
    });
  };

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

          }
        });
      },
      function(errorResponse) {
        debug_error(errorResponse);
      }
    );

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

    if ($(this.base_component).find("table").hasClass("autoload")) {
      this.reloadTable();
    }
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

    debug("Component handlers bound for LPPopup (comp__popup)")
  };

  this.init();

};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPPopup_Initializer = function() {
  var component_name = "comp__popup"

  // Initialize a popup holder that will be used for any necessary popups
  $(".__base").prepend("<div class='comp__popup'><div class='__popup'><div class='__header'><h2>{{TITLE}}</h2><a class='targ-close'><span class='oi oi-x'></span></a></div><div class='__popup_content'></div></div></div>")

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPPopup(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPPopup(object)
      $(object).addClass("__comp_active")
    }
  });
}
