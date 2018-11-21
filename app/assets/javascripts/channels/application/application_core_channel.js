/*document.addEventListener("turbolinks:load", function() {

  (function() {
    $(document).on( "lunchpro.cable.app_notification_refresh", function( event, details ) {
      
      entity = $('body').attr('id').split('-')[0];
      if(entity == 'rep'){
        endpoint = "/rep/notifications";
      }else if (entity == 'office'){
        endpoint = "/office/notifications";
      }else if (entity == 'restaurant'){
        endpoint = "/restaurant/notifications";
      }

      if(endpoint){
        target = "lp__notification_dropdown";

        Requests.getRequestWithState(endpoint,
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
    });

  }).call(this);

});


// Admin notifications
App.cable.subscriptions.create({ channel: "ApplicationNotificationsChannel", priority: "urgent" }, {
  received: function(data) {
    debug("-/ -/ -/ -/ -/ -/ INCOMING COMMUNICATION: "+data.broadcast_type);
    $( document ).trigger( "lunchpro.cable."+data.broadcast_type, data.details );
  }
});
*/