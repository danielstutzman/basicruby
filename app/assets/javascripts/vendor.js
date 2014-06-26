//= require_self
//= require_directory ../../../vendor/assets/javascripts

var oldDebug = window.console.debug;
window.console.debug = function() {
  if (arguments[0] === 'Download the React DevTools for a better development experience: http://fb.me/react-devtools') { return; }
  oldDebug.apply(window.console, arguments);
};

