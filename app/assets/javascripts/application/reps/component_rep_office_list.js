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


function LPRepOfficeList(component) {
  this.base_component = component,

  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
    "office_detail" : ["targ__office_detail"]
  },


  this.endpoints = {
    "post__office_search_path" : "/rep/offices/search?list_type=all_offices",
    "post__office_list_path" : "/rep/offices/search?list_type=offices",
    "post__provider_list_path" : "/rep/offices/search?list_type=providers",
    "post__office_search_appts_path" : "/rep/offices/search?list_type=all_offices_appts",
    "post__office_list_appts_path" : "/rep/offices/search?list_type=offices_appts",
    "post__office_search_orders_path" : "/rep/offices/search?list_type=all_offices_orders",
    "post__office_list_orders_path" : "/rep/offices/search?list_type=offices_orders",
    "get__office_detail_path" : "/rep/offices/<id>",
    "get__office_detail_appointments_path" : "/rep/offices/<id>/appointments",
    "get__office_detail_about_path" : "/rep/offices/<id>/about",
    "get__office_detail_notes_path" : "/rep/offices/<id>/notes"
  },

  this.events = {
    "click [data-comp-detail-id]" : "showOffice",
    "change [name=searchType]" : "changeFilter",
    "change [name=newType]" : "changeNewOfficeView",
    "submit form.lp__find_offices" : "searchMyOffices",
    "submit form.lp__find_new_offices" : "searchAllOffices",
    "submit form.lp__find_new_offices_appts" : "searchAllOfficesAppts",
    "submit form.lp__find_offices_appts" : "searchMyOfficesAppts",
    "submit form.lp__find_offices_orders" : "searchMyOfficesOrders"
  },

  this.showOfficeOnLoad = function(){
    var that = this;
    endpoint_path = Requests.buildPath(that.endpoints['get__office_detail_path'], {"id" : selectedOffice})
    that._updateComponentTemplate(endpoint_path, "office_detail")
    $("[data-comp-detail-id ='" + selectedOffice + "']").addClass('list-active');
  },

  this._updateComponentTemplate = function(url, data_target) {
    that = this;

    if (!(url && data_target)) {
      debug_error("Missing URL or data_target on getComponentTemplate")
      return;
    }

    Requests.getRequestWithState(url,
      function(successResponse) {
        forEach(that.data_targets[data_target], function(target, index) {
          if (successResponse.templates && successResponse.templates[target]) {
            $("."+target).html(successResponse.templates[target]);
            //if tab param was passed in, set tab/pane active
            if(selectedTab){
              $("[data-tab='"+selectedTab+"'").addClass('active');
              $("#"+selectedTab+"").addClass('active');
              selectedTab = null;
            }else{
              $("[data-tab='appointments']").addClass('active');
              $("[data-tab='orders']").addClass('active');
              $("#my-appointments, #my-orders").addClass('active');
            }
          }
        });
      },
      function(errorResponse) {
        debug_error("We got an error response");
        debug_error(errorResponse);
      }
    );
  };

  var selectedOffice = $(component).attr("data-comp-office-load-id");
  var selectedTab = $(component).attr("data-comp-office-load-tab");
  if(selectedOffice){this.showOfficeOnLoad();}
  var selectedProvider;
  

  this.searchMyOffices = function(e) {
    that = this;
    

    form = $(e.currentTarget);
    if($("#providers").is(':checked')){
      that.filterSearch("post__provider_list_path", form);
    }else{
      that.filterSearch("post__office_list_path", form);
    }

    stopProp(e);

    return false;
  };

  this.searchAllOffices = function(e) {
    that = this;

    form = $(e.currentTarget);
    that.filterSearch("post__office_search_path", form);

    stopProp(e);

    return false;
  };

  this.searchMyOfficesAppts = function(e) {
    that = this;  
    form = $(e.currentTarget);
    that.filterSearch("post__office_list_appts_path", form);
    stopProp(e);

    return false;
  };

  this.searchAllOfficesAppts = function(e) {
    that = this;

    form = $(e.currentTarget);
    that.filterSearch("post__office_search_appts_path", form);

    stopProp(e);

    return false;
  };

  this.searchMyOfficesOrders = function(e){
    that = this;

    form = $(e.currentTarget);
    that.filterSearch("post__office_list_orders_path", form);

    stopProp(e);

    return false;
  };
  this.changeNewOfficeView = function(e) {
    that = this;

    that.__find(".form-check-label.checked").removeClass("checked");
    $(e.currentTarget).closest(".form-check-label").addClass("checked");

    form = $(e.currentTarget).closest("form");

    if ($(e.currentTarget).val() == "existing") {
      that.__find(".targ__office_search").show()
      that.__find(".targ__all_office_search").hide()
    } else if ($(e.currentTarget).val() == "new") {
      that.__find(".targ__all_office_search").show()
      that.__find(".targ__office_search").hide()
    }

    stopProp(e);

    return false;
  };

  this.changeFilter = function(e) {
    that = this;
    $(".form-check-label.checked").removeClass("checked");
    form = $(e.currentTarget).closest("form");
    if ($(e.currentTarget).val() == "offices") {
      that.filterSearch("post__office_list_path", form);
      $(".offices-label").addClass("checked");
    } else if ($(e.currentTarget).val() == "providers") {
      that.filterSearch("post__provider_list_path", form);
      $(".providers-label").addClass("checked");
    }
    stopProp(e);

    return false;
  };

  this.filterSearch = function(endpoint, form) {
    that = this;

    url = that.endpoints[endpoint];
    target = "targ__tab_results";
    if(endpoint == "post__office_search_appts_path"){target = "targ__tab_new_office_results";}
    data = form.serialize();
    Requests._request("post", url, data,
      function(successResponse) {
        if (successResponse.templates && successResponse.templates[target]) {
          $("."+target).html(successResponse.templates[target]);
          //'persist' the active state of selected office or provider
          if(endpoint == "post__office_list_path"){
            $("[data-comp-detail-id ='" + selectedOffice + "']").addClass('list-active');
          }else{
            $("[data-comp-provider-id ='" + selectedProvider + "']").addClass('list-active');
          }
        }
      },
      function(errorResponse) {
      }
    );
    return false;
  };

  this.showOffice = function(e) {
    var that = this

    // describe_workflow([
    //   "Validate that we have a data-comp-detail-id value",
    //   "Make a call to the office_detail_path end point",
    //   "Load the detail template within the appropriate holder for the office",
    //   "Show the office detail template post-load",
    // ])

    this.handleSelection($(e.currentTarget));

    show_in = $(e.currentTarget).attr("data-comp-show-in")

    endpoint_path = Requests.buildPath(that.endpoints['get__office_detail_path'], {"id" : selectedOffice})
    if ($(e.currentTarget).attr("data-url") != undefined) {
      endpoint_path = $(e.currentTarget).attr("data-url")
    }
   
    if (show_in != undefined && show_in == "modal") {
      $(document).trigger("lp.show_modal", [{url: endpoint_path}])
    } else if (show_in != undefined && show_in == "new") {
      window.location = endpoint_path
    } else {
      that._updateComponentTemplate(endpoint_path, "office_detail")
    }

    stopProp(e);
    return false;
  };

  //logic to handle selection of office or provider
  this.handleSelection = function(target){
    //compare newly selected office to old selected office, if different, remove selected provider.
    newSelectedOffice = target.attr("data-comp-detail-id"); 
    newSelectedProvider = target.attr("data-comp-provider-id"); 

    if(selectedOffice != newSelectedOffice){selectedProvider = null;}
    selectedOffice = newSelectedOffice;

    //if a provider is selected, assign to selectedProvider
    if(newSelectedProvider){selectedProvider = target.attr("data-comp-provider-id");}

    //remove current active, add new active.. simple solution
    $('.list-active').removeClass('list-active');
    target.addClass("list-active");  

    $('.targ__office_detail').show();
    $('.targ__office_policies').hide();
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

    debug("Component handlers bound for LPRepOfficeList (comp__rep_office_list)")
  };

  this.init();

};

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRepOfficeList_Initializer = function() {
  var component_name = "comp__rep_office_list"

  $("."+component_name).each(function (idx) {
      obj = new LPRepOfficeList(this)
      $(this).addClass("__comp_active")
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRepOfficeList(object)
      $(object).addClass("__comp_active")
    }
  });
}

