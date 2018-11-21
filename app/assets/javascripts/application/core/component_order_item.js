function LPOrderItem(component) {
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
    "click .menu-subitem-label" : "changeOptionSelection",
    // "click [data-submit]" : "submitForm"
  };

  // Component only events
  this.events = {
    // "click a.targ-close" : "hideConfirm",
    // "click a.targ-complete" : "confirmUrl"
  };

  this.changeOptionSelection = function(e) {
    that = this;
    context = $(e.currentTarget).closest(".targ-items");
    max_options = context.find("[data-max-options]").attr("data-max-options");
    selected_option_count = context.find(".form-check-label.checked").length;

    if ($(e.currentTarget).hasClass("checked")) {
      $(e.currentTarget).removeClass("checked");
      $(e.currentTarget).find(".form-check-input").attr("checked", null)
    } else {
      if (selected_option_count < max_options) {
        $(e.currentTarget).addClass("checked");
        $(e.currentTarget).find(".form-check-input").attr("checked", true)
      } else {
        alert("You may only select a maximum of "+max_options+" options in this group.")
        //$(e.currentTarget).addClass("checked");
      }
    }

    stopProp(e);

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

    debug("Component handlers bound for LPOrderItem (comp__order_item)")
  };

  this.init();

};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPOrderItem_Initializer = function() {
  var component_name = "comp__order_item"

  // Initialize a popup holder that will be used for any necessary popups
  $(".__base").prepend("<div class='comp__confirm'><div class='__popup'><div class='__header'><h2>{{TITLE}}</h2><a class='targ-close'><span class='oi oi-x'></span></a></div><div class='__popup_content'></div></div></div>")

  $("."+component_name).each(function (idx) {
    if (!$(this).hasClass("__comp_active")) {
      obj = new LPOrderItem(this)
      $(this).addClass("__comp_active")
    }
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPOrderItem(object)
      $(object).addClass("__comp_active")
    }
  });
}
