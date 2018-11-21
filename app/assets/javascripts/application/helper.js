function log(message) {
  if (message !== null && typeof message === 'object') {
    log_object(message)
  } else {

  }
}

function log_object(object) {
  
}

function error(message) {
  if (message !== null && typeof message === 'object') {
    console.error(message)
  } else {
    console.error("\n\n"+message+"\n\n")
  }
}

function debug(message) {
  if (window.debug_mode) {
    log(message);
  }
}

function debug_error(message) {
  if (window.debug_mode) {
    error(message);
  }
}


function describe_workflow(steps) {
  the_steps = ""
  forEach(steps, function (step, index) {
    the_steps += (index + 1) + ". " + step + "\n"
  });

  debug(the_steps)
}

function stopProp(e) {
  e.preventDefault();
  e.stopImmediatePropagation();
  e.stopPropagation();
  return;
}

/*! foreach.js v1.1.0 | (c) 2014 @toddmotto | https://github.com/toddmotto/foreach */
var forEach=function(t,o,r){if("[object Object]"===Object.prototype.toString.call(t))for(var c in t)Object.prototype.hasOwnProperty.call(t,c)&&o.call(r,t[c],c,t);else for(var e=0,l=t.length;l>e;e++)o.call(r,t[e],e,t)};
