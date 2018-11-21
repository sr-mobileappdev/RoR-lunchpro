modifiedForm = 0;
window.onbeforeunload = function(e){
  if (modifiedForm == 1 && $("#smartwizard").length > 0){
    message = 'Unsaved changes! Please make sure you save your work before leaving this page.';
    e.returnValue = message;
    return message;
  }
}

document.addEventListener("turbolinks:load", function() {

  // Smart Wizard
  $('#smartwizard').smartWizard({
        selected: selectStep(),  // Initial selected step, 0 = first step
        keyNavigation:false, // Enable/Disable keyboard navigation(left and right keys are used if enabled)
        autoAdjustHeight:true, // Automatically adjust content height
        cycleSteps: false, // Allows to cycle the navigation of steps
        backButtonSupport: true, // Enable the back button support
        useURLhash: true, // Enable selection of the step based on url hash
        lang: {  // Language variables
            next: 'Next',
            previous: 'Previous'
        },
        toolbarSettings: {
            toolbarPosition: 'top', // none, top, bottom, both
            toolbarButtonPosition: 'right', // left, right
            showNextButton: true, // show/hide a Next button
            showPreviousButton: true, // show/hide a Previous button
            toolbarExtraButtons: [
              $("<button class='finish-btn' style='display: none;'></button>").text('Finish').addClass('btn btn-danger').on('click', function(e){
                e.preventDefault()
                finishWizard();
              })
            ]
        },
        anchorSettings: {
            anchorClickable: false, // Enable/Disable anchor navigation
            enableAllAnchors: false, // Activates all anchors clickable all times
            markDoneStep: true, // add done css
            enableAnchorOnDoneStep: true // Enable/Disable the done steps navigation
        },
        contentURL: null, // content url, Enables Ajax content loading. can set as data data-content-url on anchor
        disabledSteps: [],    // Array Steps disabled
        errorSteps: [],    // Highlight step with errors
        theme: 'arrows',
        transitionEffect: 'fade', // Effect on navigation, none/slide/fadea
        transitionSpeed: '400',
        ajaxSettings: {

        }
  });

    // Initialize the leaveStep event
  $("#smartwizard").on("showStep", function(e, anchorObject, stepNumber, stepDirection) {
    if($(".restaurant-registration").length > 0){
      if(stepNumber == 5){
        $('button.sw-btn-next').hide()
        $('button.finish-btn').show()
      }else{
        $('button.sw-btn-next').show()
        $('button.finish-btn').hide()
      }

    }
  });


  $("#smartwizard").on("leaveStep", function(e, anchorObject, stepNumber, stepDirection) {
    $(".lp__close").click();

      if(stepDirection == "forward" && modifiedForm == 1){
        if($(".restaurant-creation").length > 0){
          e.preventDefault();
        }
        postData();
      }else if(stepDirection == "backward" && modifiedForm == 1){
        if(($(".restaurant-registration").length > 0) && stepNumber == 5){
          e.preventDefault();
          postData();
        }else{
          if (confirm("Unsaved changes! Click 'OK' to continue without saving or 'Cancel' to return to the form")){
            modifiedForm = 0;
            $("form")[stepNumber].reset()
          }else{
            e.preventDefault();
          }
        }
      }else if(modifiedForm == 0 && $(".restaurant-creation").length > 0){
        e.preventDefault();
      }

  });

  //Set to remove the 'Next' button and add 'Finish'
  if($('.restaurant-registration').length > 0){
    step = $("li.nav-item.active a").attr('href');
    if(step == '#step-6'){
      $('button.sw-btn-next').hide()
      $('button.finish-btn').show()
    }
  }

  $("[data-image-upload]").on("click", function(e){

  })

  if($('.targ__restaurant_image_upload').length > 0){
    var that = this;
    var upload_path = "/admin/restaurants/<id>/upload_partial"
    var restaurant_id = $('.targ__restaurant_image_upload').attr("data-restaurant-id");
    endpoint_path = Requests.buildPath(upload_path, {"id": restaurant_id});
    updateComponent(endpoint_path, "targ__restaurant_image_upload");

  }

  //Form change handling
  $("input").change(function(){
    modifiedForm = 1;
  });

  $("select").change(function(){
    modifiedForm = 1;
  });

  $("textarea").change(function(){
    modifiedForm = 1;
  })

  function postData() {
    step = $("li.nav-item.active a").attr('href');
    form_element = $("div " + step + " form");
    params = {}
    params = form_element.serialize()
    endpoint = form_element.attr('action')
    $.post(endpoint, params, function(data) {
      if(data.success){
        if (data.redirect){
          modifiedForm = 0;
          window.location = data.redirect;
          return;
        }else if(data.reload_logo){
          modifiedForm = 0;
          reloadImage();
        }else if(data.reload){
          modifiedForm = 0;
          window.location.reload();
          return
        }
      }else{
        modifiedForm = 0;
        window.location.reload();
        return
      }
    }).fail(function(errorResponse) {
      var resp = errorResponse.responseJSON // responseJSON is only returned on errors
      showErrors(resp.general_error, resp.errors, {})
    });
  }

  function selectStep() {
    if($(".restaurant-creation").length > 0){
      return 0
    }else if($(".restaurant-registration").length > 0){
      return 1
    }
  }

  function showErrors(general_message, errors, options) {
    that = this;
    if (general_message == undefined) {
      general_message = "System error (500)"
    }

    $('.lp__error_box').first().remove();

    if($("li.nav-item.active a").attr('href').length > 0){
      step = $("li.nav-item.active a").attr('href');
      form_element = $("div " + step + " form");
      $(form_element).prepend("<div class='lp__error_box mt-3'><a class='lp__close'><span class='oi oi-x' title='close' aria-hidden='true'></span></a></div>");
      $(form_element).find(".lp__error_box").append("<p>"+general_message+"</p>");
    }else{
      that.__find("form").prepend("<div class='lp__error_box pt-3'><a class='lp__close'><span class='oi oi-x' title='close' aria-hidden='true'></span></a></div>");

      that.__find(".lp__error_box").append("<p>"+general_message+"</p>");
    }

    if (errors && errors.length > 0) {
      $(".lp__error_box").first().append("<ul></ul>");

      for (var i=0; i < errors.length; i++) {
        $(".lp__error_box ul").first().append("<li>"+errors[i]+"</li>");
      }
    }

    setTimeout(function() {
      $(".lp__error_box").first().addClass("show");
    }, 20);
  }

  function reloadImage() {
    var that = this;
    var upload_path = "/admin/restaurants/<id>/upload_partial"
    var restaurant_id = $('.targ__restaurant_image_upload').attr("data-restaurant-id");
    endpoint_path = Requests.buildPath(upload_path, {"id": restaurant_id});
    updateComponent(endpoint_path, "targ__restaurant_image_upload");
  }

  function updateComponent(url, target){
    that = this;
    Requests.getRequestWithState(url,
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

  function finishWizard(){
    var restaurant_id = $('.last-step').attr("data-restaurant-id");
    var path = "/admin/restaurants/<id>"
    endpoint_path = Requests.buildPath(path, {"id": restaurant_id});

    window.location = endpoint_path;
  }

});
