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
// 1.4 - Changed initialization from jquery reday to using an initializer function that somebody must call (LPRepOfficeDetail_Initializer)
// 1.4 - Integrated endpoints into JS component (instead of those living in the markup)


function LPOmOrderDetail(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "order_detail" : ["targ__order_detail"]
  },


  this.endpoints = {
    "get__order_detail_path" : "/rep/orders/<id>"
  },

  this.events = {  
    "click [data-comp-detail-id]" : "showOrder",
    "click .form-check-input" : "selectOnTime",
    "click .lp__print_order" : "printOrderDetail",
    "click .cancel_button": "disableButton"
  },

  this.disableButton = function(e){    
    $(e.currentTarget).addClass("disabled");
  },
  this.selectOnTime = function(e){
    $(component).find(".form-check-label.checked").removeClass("checked");
    $(e.currentTarget).closest(".form-check-label").addClass("checked");
  },
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
            LPRepForm_Initializer();
            $('.list-active').removeClass('list-active');
            $("[data-comp-detail-id ='" + selectedOrder + "']").addClass('list-active');
            that.handleStars();
          }
        });
      },
      function(errorResponse) {
        debug_error(errorResponse);
      }
    );

  },
  this.showOrder = function(e) {
    var that = this;

    show_in = $(e.currentTarget).attr("data-comp-show-in");
    selectedOrder = $(e.currentTarget).attr("data-comp-detail-id");
    endpoint_path = Requests.buildPath(that.endpoints.get__order_detail_path, {"id" : selectedOrder});
    if ($(e.currentTarget).attr("data-url") != undefined) {
      endpoint_path = $(e.currentTarget).attr("data-url");
    }
   
    if (show_in != undefined && show_in == "modal") {
      $(document).trigger("lp.show_modal", [{url: endpoint_path}]);
    } else if (show_in != undefined && show_in == "new") {
      window.location = endpoint_path;
    } else {
      that._updateComponentTemplate(endpoint_path, "order_detail");
    }

    stopProp(e);
  };

  this.showOrderOnLoad = function(){
    var that = this;
    endpoint_path = Requests.buildPath(that.endpoints.get__order_detail_path, {"id" : selectedOrder});
    that._updateComponentTemplate(endpoint_path, "order_detail")
    $("[data-comp-detail-id ='" + selectedOrder + "']").addClass('list-active');
  };

  this.handleStars = function(){
    food_quality = $("#food_quality").attr("data-comp-checked-value");
    presentation = $("#presentation").attr("data-comp-checked-value");
    completion = $("#completion").attr("data-comp-checked-value"); 
    if(food_quality && presentation && completion){
      $("#quality" + food_quality).prop("checked", true);
      $("#presentation" + presentation).prop("checked", true);
      $("#completeness" + completion).prop("checked", true);
    }

    office_overall = $("#office_overall").attr("data-comp-checked-value");
    if(office_overall){
      $("#office_" + office_overall).prop("checked", true);
    }
  };

  this.printOrderDetail = function(e){
    selectedOrder = $(e.currentTarget).attr("data-order-id");
    endpoint_path = Requests.buildPath(that.endpoints.get__order_detail_path, {"id" : selectedOrder});
    Requests.getRequestWithState(endpoint_path,
      function(successResponse) {
        html = successResponse.templates['targ__order_detail'];
        frame = $("<iframe id='printlabel'>")    
          .hide()                    
          .appendTo("body");

        frame.contents().find('body').html(html);
        $("#printlabel").get(0).contentWindow.print();
      },
      function(errorResponse) {
        debug_error(errorResponse);
      }
    );
  };
  var selectedOrder = $(component).attr("data-comp-order-load-id");
  if(selectedOrder){this.showOrderOnLoad();}

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

    debug("Component handlers bound for LPOmOrderDetail (comp__om_order_detail)");
  },

  this.init();
  if($(component).data("initialize-stars")){
    this.handleStars();
  }
}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPOmOrderDetail_Initializer = function() {
  var component_name = "comp__om_order_detail";

  $("."+component_name).each(function (idx) {
      obj = new LPOmOrderDetail(this);
      $(this).addClass("__comp_active");
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPOmOrderDetail(object);
      $(object).addClass("__comp_active");
    }
  });
};

