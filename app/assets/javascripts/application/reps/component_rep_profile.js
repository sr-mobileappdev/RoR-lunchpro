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


function LPRepProfile(component) {
  this.base_component = component,
  // data_targets represent one or more templates we need to fill in with data coming back from an API / Ajax call
  this.data_targets = {
   "profile_details" : ["targ__rep_profile"]
  },


  this.endpoints = {
    "get__profile__summary_path" : "/rep/profile/summary",
    "get__profile__financial_info_path" : "/rep/profile/financial_info",
    "get__profile__new_payment_method_path" : "/rep/profile/payment_methods/new",
    "get__profile__edit_payment_method_path" : "/rep/profile/payment_methods/<id>/edit",
    "get__profile__partner_path" : "/rep/profile/partner",
    "get__profile__notifications_path" : "/rep/profile/notifications",
    "get__profile__rewards_path" : "/rep/profile/rewards",
    "get__profile__faq_path" : "/rep/profile/faq",
    "get__profile__general_information_path" : "/rep/profile/general_information",
    "get__profile__change_password_path" : "/rep/profile/change_password",
    "get__profile__office_budgets_form_path" : "/rep/profile/office_budgets"
  },

  this.events = {
    "click [data-comp-detail-tab]" : "showTab",
    "click .lp__cancel_button" : "showTab",
    "click .lp__toggle_partner" : "showPartner"
  },

  this.showBudget = function(e){
    $("#office-budgets").show();
    $("#account-profile").hide();
  },
  this.hideBudget = function(e){
    $("#office-budgets").hide();
    $("#account-profile").show();
  },
  this.showPartner = function(e){
    $(".lp__partner_form").show();
    LPRepForm_Initializer();
  },
  //logic for showing a tab on page load if param is passed in
  this.showTabOnLoad = function(tab){

    var that = this;
    //partner, partners both trigger partner tab on load
    tab = (tab == 'partners' ? 'partner' : tab);
    if(this.selectedRecord){
      endpoint_path = Requests.buildPath(that.endpoints['get__profile__' + tab + '_path'], {"id": this.selectedRecord});
    }else{
      endpoint_path = Requests.buildPath(that.endpoints['get__profile__' + tab + '_path']);
    }
    that._updateComponentTemplate(endpoint_path, "profile_details", "profile__" + tab);

    $("[data-comp-detail-tab='profile__" + tab + "']").addClass("profile-active");
  },

  this._updateComponentTemplate = function(url, data_target, tab) {
    var that = this;
    if (!(url && data_target)) {
      debug_error("Missing URL or data_target on getComponentTemplate");
      return;
    }
    Requests.getRequestWithState(url,
      function(successResponse) {
        forEach(that.data_targets[data_target], function(target, index) {        
          if (successResponse.templates && successResponse.templates[target]) {
            $("."+target).html(successResponse.templates[target]);
            //if tab is edit or new payment method, manually initialize stripe form initializer
            if(url == "/rep/profile/change_password" || tab == "profile__summary" || tab == "profile__budget"){
              LPRepForm_Initializer();
            }else if(tab == "profile__new_payment_method" || tab == "profile__edit_payment_method"){
              LPRepStripeForm_Initializer();
            }
            if(tab == "profile__summary"){that.initProfileSelectize();}
            if(tab == "profile__partner"){that.initPartnerSelectize();}

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
  this.selectedRecord = $(component).data("record-id"),

  this.showTab = function(e){
    var that = this;

    show_in = $(e.currentTarget).attr("data-comp-show-in");

    tab = $(e.currentTarget).attr("data-comp-detail-tab");
    if($(e.currentTarget).attr("data-payment-id")){
      endpoint_path = Requests.buildPath(that.endpoints.get__profile__edit_payment_method_path, {"id" : $(e.currentTarget).attr("data-payment-id")});
    }else{
      endpoint_path = Requests.buildPath(that.endpoints['get__' + tab + '_path']);
    }

   
    if (show_in != undefined && show_in == "modal") {
      $(document).trigger("lp.show_modal", [{url: endpoint_path}]);
    } else if (show_in != undefined && show_in == "new") {
      window.location = endpoint_path;
    } else {
      that._updateComponentTemplate(endpoint_path, "profile_details", tab);
    }
    if(tab !== "profile__change_password" && tab !== "profile__new_payment_method" && tab !== "profile__edit_payment_method" && tab !== "profile__office_budgets_form"){
      $('.profile-active').removeClass('profile-active');
      $("[data-comp-detail-tab='" + tab + "']").addClass("profile-active");
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

    debug("Component handlers bound for LPRepOfficeList (comp__rep_profile)");
  },
  this.initProfileSelectize = function(){
    company = $('#sales_rep_company_name').attr('data-companies');
    if(company) company = JSON.parse(company);
    $('#sales_rep_company_name').selectize({
      plugins: ['remove_button'],
      options: company,
      valueField: 'id',
      labelField: 'name',
      searchField: 'name',
      maxItems: 1,
      mode: 'multi',
      openOnFocus: false,
      create: true,
      score: function scoreFilter(search) {
        var ignore = search && search.length < 3;
        var score = this.getScoreFunction(search);
        //the "search" argument is a Search object (see https://github.com/brianreavis/selectize.js/blob/master/docs/usage.md#search).
        return function onScore(item) {
            if (ignore) {
                //If 0, the option is declared not a match.
                return 0;
            } else {
                var result = score(item);
                return result;
            }
        };
      },
      onDropdownOpen: function ( $dropdown ) {
        $dropdown.css( 'visibility', this.lastQuery.length ? 'visible' : 'hidden' );
      },
      onType: function (str) {
        if (str === "") {
          this.close();
        }
      }
    });

    drugs = $('#sales_rep_drugs').attr('data-drugs');
    if(drugs) drugs = JSON.parse(drugs);
    $('#sales_rep_drugs').selectize({
      plugins: ['remove_button'],
      options: drugs,
      valueField: 'id',
      labelField: 'brand',
      searchField: 'brand',
      closeAfterSelect: true,
      create: true,
      score: function scoreFilter(search) {
        var ignore = search && search.length < 3;
        var score = this.getScoreFunction(search);
        //the "search" argument is a Search object (see https://github.com/brianreavis/selectize.js/blob/master/docs/usage.md#search).
        return function onScore(item) {
            if (ignore) {
                //If 0, the option is declared not a match.
                return 0;
                $("#sales_rep_drugs").next("div.selectize-control").find(".selectize-dropdown").css( 'visibility', 'hidden');
            } else {
                $("#sales_rep_drugs").next("div.selectize-control").find(".selectize-dropdown").css( 'visibility', 'visible');
                
                var result = score(item);
                return result;
            }
        };
      },
      onDropdownOpen: function ( $dropdown ) {
        $dropdown.css( 'visibility', this.lastQuery.length ? 'visible' : 'hidden' );
      },
      onType: function (str) {
        if (str === "") {
          this.close();
        }
      }
    });
    $.ajax({
      url: '/api/frontend/providers/specialties',
      type: 'GET',
      success: function(data) {
       specialties = data.specialties;
       var items = specialties.map(function(x) { return { item: x }; });
       $('#sales_rep_specialties').selectize({
          plugins: ['remove_button'],
          labelField: "item",
          valueField: "item",
          searchField: 'item',
          options: items,          
          placeholder: "Select specialties for this Sales Rep"
        });
      }
    });
  },
  this.initPartnerSelectize = function(){
    partners = $('#sales_rep_partners').attr('data-partners');
    if(partners) partners = JSON.parse(partners);
    $('#sales_rep_partners').selectize({
      plugins: ['remove_button'],
      options: partners,
      valueField: 'id',
      labelField: 'name',
      searchField: 'name',
      render: {
        option: function(item, escape) {
            return '<div>' +
                ('<div class="name pb-2">' + escape(item.name) + '</div>') +
                ('<div class="email"><i>' + escape(item.company) + '</i></div>') +
            '</div>';
        }
      },
    });
  }

  this.init();
  if(this.selectedTab){
    this.showTabOnLoad(this.selectedTab);
  }

}

// Component Activation - Be sure these values are set fresh when you create a new component

var LPRepProfile_Initializer = function() {
  var component_name = "comp__rep_profile";

  $("."+component_name).each(function (idx) {
      obj = new LPRepProfile(this);
      $(this).addClass("__comp_active");
  });

  $(document).on( "lp-component.added", function( event, object ) {
    if ($(object) && $(object).hasClass("__comp_active")) {
      return;
    }
    if ($(object) && $(object).hasClass(component_name)) {
      obj = new LPRepOfficeList(object);
      $(object).addClass("__comp_active");
    }
  });
};

