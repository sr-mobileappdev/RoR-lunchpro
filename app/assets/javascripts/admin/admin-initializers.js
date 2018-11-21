document.addEventListener("DOMContentLoaded", function(event) {

  // -- NProgress (JS status bar)
  NProgress.configure({ showSpinner: false });

  $(document).on('turbolinks:click', function() {
    NProgress.start();
  });
  $(document).on('turbolinks:render', function() {
    NProgress.done();
    NProgress.remove();
  });

});
