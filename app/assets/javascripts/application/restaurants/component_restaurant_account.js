// Component
// ---
// It does stuff

// COMPONENT PROGRAMMING GUIDE
// -----
// Three core details make up a fully-deployed component.
// 1. The HTML detail(s) on the pages themselves, that have a .comp__XXXX style class assigned to them
// 2. A small binding / initialization function (shown near the bottom of this file) which loops through all details from the above class and instantiats the objects associated with them
// 3. The actual javascript component class itself (the bulk of the code below)

// USAGE
// -----
// Put this somewhere: <span class="comp__sample_me"><em>clickable thing</em></span>
// Click it, and it should replicate

// VERSION : Trying to keep track of when I improve the base
// -----
// 1.4 - Made component activation utilize a `component_name` variable to reduce things that must be re-written when creating a new comp
// 1.4 - New Component observer is `lp-component.added` which is LunchPro specific
// 1.4 - Changed initialization from jquery reday to using an initializer function that somebody must call (LPRestaurantOfficeList_Initializer)
// 1.4 - Integrated endpoints into JS component (instead of those living in the markup)


function LPRestaurantAccount(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
   "account_details" : ["targ__restaurant_account"]
  },


  this.endpoints = {
    "get__account__summary_path" : "/restaurant/account/summary",
    "get__account__contact_information_path" : "/restaurant/account/contact_information",
    "get__account__edit_restaurant_poc_path" : "/restaurant/account/restaurant_pocs/<id>/edit",
    "get__account__payment_information_path" : "/restaurant/account/payment_information",
    "get__account__payments_path" : "/restaurant/account/payments",
    "get__account__new_bank_account_path" : "/restaurant/account/bank_accounts/new",
    "get__account__edit_bank_account_path" : "/restaurant/account/bank_accounts/<id>/edit",
    "get__account__notifications_path" : "/restaurant/account/notifications",
    "get__account__faq_path" : "/restaurant/account/faq",
    "get__account__privacy_policy_path" : "/restaurant/account/terms",
    "get__account__terms_path" : "/restaurant/account/terms",
    "get__account__change_password_path" : "/restaurant/account/change_password",
    "get__account__reviews_path" : "/restaurant/account/reviews"
  },

  this.events = {
    "click [data-comp-detail-tab]" : "showTab",
    "click .lp__cancel_button" : "showTab"
  },

  this.document_events = {
    "click [data-confirm-check]" : "showConfirm"
    // "click [data-submit]" : "submitForm"
  };

  //logic for showing a tab on page load if param is passed in
  this.showTabOnLoad = function(tab){

    var that = this;

    endpoint_path = Requests.buildPath(that.endpoints['get__account__' + tab + '_path']);
    that._updateComponentTemplate(endpoint_path, "account_details", "account__" + tab);

    $("[data-comp-detail-tab='account__" + tab + "'").addClass("profile-active");
  },

  this._updateComponentTemplate = function(url, data_target, tab) {
    var that = this;
    if (!(url && data_target)) {
      debug_error("Missing URL or data_target on getComponentTemplate");
      return;
    }
    if(tab == "account__new_bank_account" || tab == "account__payment_information"){
      Pace.restart();
    }
    Requests.getRequestWithState(url,
      function(successResponse) {
        forEach(that.data_targets[data_target], function(target, index) {
          if (successResponse.templates && successResponse.templates[target]) {
            $("."+target).html(successResponse.templates[target]);
            //if tab is edit or new payment method, manually initialize stripe form initializer
            if(tab == "account__new_bank_account" || tab == "account__payment_information"){
              LPRestaurantStripeForm_Initializer();
            }
            if(url == "/restaurant/account/change_password" || tab == "account__summary" || tab == "account__contact_information"){
              LPRestaurantForm_Initializer();
            }

          }
        });
      },
      function(errorResponse) {
        debug_error("We got an error response");
        debug_error(errorResponse);
      }
    );

  },

  this.selectedTab = $(component).attr("data-comp-tab-load"),

  this.showTab = function(e){
    var that = this;

    show_in = $(e.currentTarget).attr("data-comp-show-in");

    tab = $(e.currentTarget).attr("data-comp-detail-tab");
    if($(e.currentTarget).attr("data-payment-id")){
      endpoint_path = Requests.buildPath(that.endpoints.get__account__edit_bank_account_path, {"id" : $(e.currentTarget).attr("data-payment-id")});
    }else{
      endpoint_path = Requests.buildPath(that.endpoints['get__' + tab + '_path']);
    }


    if (show_in != undefined && show_in == "modal") {
      $(document).trigger("lp.show_modal", [{url: endpoint_path}]);
    } else if (show_in != undefined && show_in == "new") {
      window.location = endpoint_path;
    } else {
      that._updateComponentTemplate(endpoint_path, "account_details", tab);
    }
    if(tab !== "account__change_password" && tab !== "account__new_bank_account" && tab !== "account__edit_bank_account"){
      $('.profile-active').removeClass('profile-active');
      $("[data-comp-detail-tab='" + tab + "'").addClass("profile-active");
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

    debug("Component handlers bound for LPRestaurantAccount (comp__restaurant_account)");
  },
  this.initProfileSelectize = function(){


  },
  this.init();
  if(this.selectedTab){
    this.showTabOnLoad(this.selectedTab);
  }

}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRestaurantAccount_Initializer = function() {
  var component_name = "comp__restaurant_account";

  $("."+component_name).each(function (idx) {
      obj = new LPRestaurantAccount(this);
      $(this).addClass("__comp_active");
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
  });
};
