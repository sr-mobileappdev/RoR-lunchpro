// Requests
// ---
// A bit of syntax sugar wrapped around JQuery Ajax requests
//
// Dependancies
// ----
// forEach (https://github.com/toddmotto/foreach)

// EXAMPLE:
// Requests._getRequest(url,
//   function(successResponse) {
//     window.location = successResponse.redirect;
//   },
//   function(errorResponse) {

//   }
// );


var Requests = {

  events: {

  },

  initialize: function(self) {

  },

  _request: function(method, endpoint, params, successCallback, failureCallback) {

    if (method == "put") {
      this._putRequest(endpoint, successCallback, failureCallback)
    } else if (method == "post") {
      this._postRequest(endpoint, params, successCallback, failureCallback)
    } else if (method == "get") {
      this._getRequest(endpoint, successCallback, failureCallback)
    } else if (method == "delete") {
      this._deleteRequest(endpoint, successCallback, failureCallback)
    } else {
      failureCallback(null)
    }

  },

  // Includes a history pushstate based on a "href" param coming back from the endpoint called
  getRequestWithState: function(endpoint, successCallback, failureCallback, should_change_url) {
    Requests._getRequest(endpoint,
      function(data) {
        if (data && data.href && should_change_url) {
          history.pushState({turbolinks: {}}, null, data.href);
        } else if (data && data.replace_state && should_change_url) {
          history.replaceState({turbolinks: {}}, null, data.replace_state);
        }
        successCallback(data)
      },
      function(error) {
        failureCallback(error)
      }
    );
  },

  _getRequest: function(endpoint, successCallback, failureCallback) {
    $.get(endpoint, function(data) {
      successCallback(data)
    }).fail(function(error) {
      failureCallback(error)
    });
  },

  _postRequest: function(endpoint, params, successCallback, failureCallback) {
    $.post(endpoint, params, function(data) {
      successCallback(data)
    }).fail(function(error) {
      failureCallback(error)
    });
  },

  _deleteRequest: function(endpoint, params, successCallback, failureCallback) {
    $.delete(endpoint, params, function(data) {
      successCallback(data)
    }).fail(function(error) {
      failureCallback(error)
    });
  },

  _putRequest: function(endpoint, params, successCallback, failureCallback) {
    $.put(endpoint, params, function(data) {
      successCallback(data)
    }).fail(function(error) {
      failureCallback(error)
    });
  },

  buildPath: function(url, params_to_replace) {
    if (url === undefined || url === "") {
      return null;
    }

    if (params_to_replace) {
      forEach(params_to_replace, function (value, prop, obj) {
        url = url.replace("<"+prop+">", value)
      });

      return url
    } else {
      return url
    }
  }

};
