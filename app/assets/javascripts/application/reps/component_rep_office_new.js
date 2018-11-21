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
// 1.4 - Changed initialization from jquery reday to using an initializer function that somebody must call (LPRepOfficeNew_Initializer)
// 1.4 - Integrated endpoints into JS component (instead of those living in the markup)


function LPRepOfficeNew(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "office_policies" : ["targ__office_policies"],
    "office_detail": ["targ__office_detail"]
  },

  this.endpoints = {
    "post__office_search_path" : "/rep/offices/search?list_type=all_offices",
    "get__office_detail_path" : "/rep/offices/<id>?new_office=<new_office>",
    "get__office_detail_notes_path" : "/rep/offices/<id>/notes",
    "get__office_detail_appointments_path" : "/rep/offices/<id>/appointments",
    "get__office_detail_about_path" : "/rep/offices/<id>/about",
    "get__office_detail_policies_path" : "/rep/offices/<id>/policies",
    "get__office_added_finish_path": "/rep/offices/<id>/finish?type=<type>",
    "post__new_office_path" : "/rep/offices/<id>/add"
  },

  this.events = {
  "click .__select_tab" : "changeOfficeTypeTab",
  "click [data-comp-detail-policies-id]" : "showOfficePolicies",
  "click [data-comp-detail-id]" : "showOffice",
  "click .lp__back" : "hideOfficePolicies",
  "click .lp__new_office_back" : "hideOffice",
  "click [data-comp-add-office-id]": "addOffice",
  "submit form.lp__find_new_offices" : "searchAllOffices",
},

this.showOfficeOnLoad = function(office){

  var that = this;
  endpoint_path = Requests.buildPath(that.endpoints.get__office_detail_path, {"id" : office, "new_office" : true});
  that._updateComponentTemplate(endpoint_path, "office_detail");
  $(".select-office").hide();

  },

  this.changeOfficeTypeTab = function(e){
    $(e.currentTarget).tab('show');
    stopProp(e);
  },
  this.searchAllOffices = function(e) {
    that = this;

    form = $(e.currentTarget);
    that.filterSearch("post__office_search_path", form);

    stopProp(e);

    return false;
  },
  this.filterSearch = function(endpoint, form) {
    that = this;

    url = that.endpoints[endpoint];
    target = "targ__tab_results"
    data = form.serialize();
    Requests._request("post", url, data,
      function(successResponse) {
        if (successResponse.templates && successResponse.templates[target]) {
          $("."+target).html(successResponse.templates[target]);
        }
      },
      function(errorResponse) {
      }
    );

  },
  this.showOffice = function(e) {
    var that = this;

    show_in = $(e.currentTarget).attr("data-comp-show-in");

    endpoint_path = Requests.buildPath(that.endpoints.get__office_detail_path, {"id" : $(e.currentTarget).attr("data-comp-detail-id"), "new_office" : true});
    if ($(e.currentTarget).attr("data-url") != undefined) {
      endpoint_path = $(e.currentTarget).attr("data-url");
    }
   
    that._updateComponentTemplate(endpoint_path, "office_detail");

    //hide office list, show office detail

    
    stopProp(e);
  },


  this.showOfficePolicies = function(e) {

    var that = this;

    endpoint_path = Requests.buildPath(that.endpoints.get__office_detail_policies_path, {"id" : $(e.currentTarget).attr("data-comp-detail-policies-id")});

    if (show_in != undefined && show_in == "modal") {
      $(document).trigger("lp.show_modal", [{url: endpoint_path}]);
    } else if (show_in != undefined && show_in == "new") {
      window.location = endpoint_path;
    } else {
      that._updateComponentTemplate(endpoint_path, "office_policies");
    }

    //hide office detail, show policies
    $(".targ__office_detail").hide();
    $(".targ__office_policies").show();
    stopProp(e);
  },

  //show office detail, hide policies
  this.hideOfficePolicies = function(e){

    $(".targ__office_detail").show();
    $(".targ__office_policies").hide();
    stopProp(e);
  },
  
  this.addOffice = function(e){
    endpoint_path = Requests.buildPath(that.endpoints.post__new_office_path, {"id" : $(e.currentTarget).attr("data-comp-add-office-id")});

    Requests.getRequestWithState(endpoint_path,
      function(successResponse) {
        endpoint_path = Requests.buildPath(that.endpoints.get__office_added_finish_path, {"id" : $(e.currentTarget).attr("data-comp-add-office-id"), "type" : 'add'});
        window.location = endpoint_path;
      },
      function(errorResponse) {
      }
    );

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
            if(data_target == "office_detail"){
               $(".select-office-detail").show();
               $(".select-office").hide();
            }
          }
        });
      },
      function(errorResponse) {
        debug_error(errorResponse);
      }
    );

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

    debug("Component handlers bound for LPRepOfficeNew (comp__rep_office_new)");
  },

  this.init();

  this.selectedOffice = $(component).attr("data-selected-office");
  if(this.selectedOffice){
    this.showOfficeOnLoad(this.selectedOffice);
  }
}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRepOfficeNew_Initializer = function() {
  var component_name = "comp__rep_office_new";

  $("."+component_name).each(function (idx) {
      obj = new LPRepOfficeNew(this);
      $(this).addClass("__comp_active");
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRepOfficeDetail(object);
      $(object).addClass("__comp_active");
    }
  });
};

