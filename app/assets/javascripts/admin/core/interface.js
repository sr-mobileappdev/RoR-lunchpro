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



function LPInterface(component) {
  this.base_component = component,
  this._loadingDelay = 500,

  // Component only events
  this.events = {
    "click .alert .lp__close" : "alertClose",
    "click a.lp__close_slidein" : "toggleSlideIn",
    "click [data-slide-in]" : "toggleSlideIn",
    "click .targ-back" : "goBack",
    "click [data-ping]" : "pingUrl",
    "click a.trig-show-search" : "openSearch",
    "click li[data-href]" : "goToNotification",
    "click .__remove-notification" : "removeNotification",
    "click a[data-add-template-row]" : "addTemplateRow",
    "click a[data-remove-template]" : "removeTemplateRow",
    "click .lp__add_child" : "addNewMenuOption",
    // "click [data-submit]" : "submitForm"
  };

  // Form Templating

  this.addNewMenuOption = function(e) {
    var that = this;
    time = new Date().getTime();
    regexp = new RegExp($(e.currentTarget).data('id'), 'g');
    fields = $(e.currentTarget).data('fields');
    if($(e.currentTarget).hasClass('add_option')){
      $(e.currentTarget).closest('.child-form').find('.__template').append(fields.replace(regexp, time));
    }else{
      $(e.currentTarget).before(fields.replace(regexp, time));
      $('.additional_item_cols').show();
    }

    stopProp(e);
  };

  this.removeTemplateRow = function(e) {
    that = this;
    template_id = $(e.currentTarget).attr("data-remove-template")

    if ($(e.currentTarget).attr("data-index") != undefined && $(e.currentTarget).attr("data-index") == "0") {
      return;
    }
    type = $(e.currentTarget).data("remove-template");
    id = $(e.currentTarget).data("index");
    if(id > 0){
      $(e.currentTarget).closest(".child-form").find("#"+type+"_"+id+"_status").val("inactive");
      $(e.currentTarget).closest("[data-template-id="+template_id+"]").hide();
    }else{
      $(e.currentTarget).closest("[data-template-id="+template_id+"]").remove();
    }    

    e.preventDefault();

  };

  this.addTemplateRow = function(e) {
    $(".link_to_add_options").find('a.lp__add_child').click()
    template_id = $(e.currentTarget).attr("data-add-template-row")
    // holder = $("[data-template-id='"+template_id+"']").first()
    destination = $(e.currentTarget).closest('.__menu_option').find('.__template')
    holder = $(e.currentTarget).closest('.__menu_option').find('.link_to_add_options').find("[data-template-id='"+template_id+"']").detach();
    if (holder != undefined) {
      new_element = holder.appendTo(destination)
    }
    stopProp(e);
  };

  // Search Stuff

  this.openSearch = function(e) {

    $(e.currentTarget).closest(".comp__table").find(".lp__search_fields").toggleClass("show");
    stopProp(e);

  };

  // General Nav

  this.removeNotification = function(e) {

    url = $(e.currentTarget).attr("href")
    Requests._getRequest(url,
      function(successResponse) {
        debug("Ping request was successful")
      },
      function(errorResponse) {
        debug("Ping failed")
      }
    );

    $(e.currentTarget).closest("li").remove()

    stopProp(e);

  };

  this.goToNotification = function(e) {
    that = this;

    url = $(e.currentTarget).attr("data-href")
    window.location = url;
  };

  this.goBack = function(e) {
    that = this;

    url = $(e.currentTarget).find("a").attr("href")
    if (url == undefined || url == "") {
      window.history.back();
    } else {
      window.location = url;
    }

    stopProp(e);
  };

  // Alert stuff

  this.toggleSlideIn = function(e) {
    that = this;

    $(".comp__slide_in .targ_title").text($(e.currentTarget).attr("data-title"));
    $(document).find(".comp__slide_in").toggleClass("open")
    $(document).find("body").toggleClass("slide-in-open")

    if ($(document).find(".comp__slide_in").hasClass("open")) {
      // If open, load the template
      url = $(e.currentTarget).attr("href")

      Requests.getRequestWithState(url,
        function(successResponse) {
          setTimeout(function() {
            $(".comp__slide_in .targ_slide_in_content").html(successResponse.html)
          }, that._loadingDelay);
        },
        function(errorResponse) {

        }
      , true);
    }

    stopProp(e);
  };

  this.alertClose = function(e) {

    $(e.currentTarget).closest(".alert").remove();

  };

  this.pingUrl = function(e) {
    that = this;

    url = $(e.currentTarget).attr("href")

    Requests._getRequest(url,
      function(successResponse) {
        debug("Ping request was successful")
      },
      function(errorResponse) {
        debug("Ping failed")
      }
    );


    stopProp(e);
  };



  if($("#_destroy_[value='false'").length){
    $('.additional_item_cols').show();
  }
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
    this.bind_ajax_callbacks();
  };

  this.bind_handlers = function() {
    var _handler = this
    Object.keys(_handler.events).forEach(function (key) {
      this_event = key.split(" ");
      var method_name = _handler.events[key];
      event_action = this_event.splice(0, 1)[0]
      event_target = this_event.join(" ")
      $(document).on(event_action, event_target, function(e) {
        _handler[method_name](e)
      });
    });

    debug("Component handlers bound for LPInterface")
  };

  this.bind_ajax_callbacks = function() {

    $(document).on("ajax:beforeSend", "a.__ajax_link", function(e) {
      if ($(e.currentTarget).hasClass("btn-spinning") || $(e.currentTarget).hasClass("btn-finished")) {
        // Nope!
        return false;
      }
      $(e.currentTarget).attr("data-prior-text", $(e.currentTarget).text())
      $(e.currentTarget).addClass("btn-spinning")
      $(e.currentTarget).text($(e.currentTarget).attr("data-loading-text") || "Saving")
    });

    $(document).on("ajax:success", "a.__ajax_link", function(e, data, status, xhr) {
      $(e.currentTarget).removeClass("btn-spinning").addClass("btn-finished")
      $(e.currentTarget).text($(e.currentTarget).attr("data-done-text") || "Done")
      //$(e.currentTarget).removeClass("btn-spinning")
    });

    $(document).on("ajax:error", "a.__ajax_link", function(e, xhr, status, error) {
      //$(e.currentTarget).removeClass("btn-spinning")
      if ($(e.currentTarget).hasClass("btn-finished")) {
        return
      }
      $(e.currentTarget).removeClass("btn-spinning")
      $(e.currentTarget).text($(e.currentTarget).attr("data-prior-text"))
    });

  }

  this.init();

};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPInterface_Initializer = function() {
  var component_name = "__base"

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPInterface(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPInterface(object)
      $(object).addClass("__comp_active")
    }
  });
}
