/*document.addEventListener("turbolinks:load", function() {

  (function() {
    $(document).on( "lunchpro.cable.internal_notice", function( event, details ) {
      // When we get an internal notice, what do we do?!
      debug(details)

      // Wait 2 second to present notice, so page can reload if needed

      setTimeout(function() {
        $(".targ-internal-notice-message").html(details.html)
        $(".lp__internal_notice").addClass("show")

        setTimeout(function() {
          $(".lp__internal_notice").removeClass("show")
        }, 5000);
      }, 2000);

    });


    $(document).on( "lunchpro.cable.notification", function( event, details ) {
      // When we get an internal notice, what do we do?!
      debug(details)
      debug("Should show a notification")
      $(".targ-badge-count").text(details.badge_count)

      if (parseInt(details.badge_count) > 0) {
        $(".targ-badge-count").removeClass("hide-badge")
      }

    });

    $(document).on( "lunchpro.cable.notification_refresh", function( event, details ) {
      // When we get an internal notice, what do we do?!
      if (parseInt(details.badge_count) > 0) {
        $(".targ-badge-count").text(details.badge_count)
        $(".targ-badge-count").removeClass("hide-badge")
      } else {
        $(".targ-badge-count").addClass("hide-badge")
      }

    });

  }).call(this);

});


// Admin notifications
App.cable.subscriptions.create({ channel: "AdminNotificationsChannel", priority: "urgent" }, {
  received: function(data) {
    debug("-/ -/ -/ -/ -/ -/ INCOMING COMMUNICATION: "+data.broadcast_type);
    $( document ).trigger( "lunchpro.cable."+data.broadcast_type, data.details );
  }
});
*/