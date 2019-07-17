/**
 *
 * Created by Anykey and adrii on 12.08.2016.
 *
 */
'use strict';

var CASE_UPP  = 0;
var CASE_LOW  = 1;
var CASE_BOTH = 2;

var CHARS_NUM  = 0;
var CHARS_SPE  = 1;
var CHARS_BOTH = 2;

var PASSWORD_CHARS_UPPERCASE = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];
var PASSWORD_CHARS_LOWERCASE = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];

var PASSWORD_SPECIAL_CHARS = ["-", "_", "!", "&", "%", "@", "#", ":"];
var PASSWORD_NUMERIC_CHARS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];


function get_radio_value(name) {
  var $radios = $('input[name="' + name + '"]');
  
  if ($radios.length > 0) {
    var $active_radio = $radios.filter(function (i, e) { return $(e).prop('checked') }).first();
    return $active_radio.val();
  }
  else {
    console.warn(name, ' not found');
  }
  
  return '';
}

function generate_password(options) {
  
  var result = "";
  
  var password_chars = options.SYMBOLS || get_passwords_chars(options.CASE, options.CHARS);
  
  for (var i = 0; i < options.LENGTH; i++) {
    var rchar = get_random(password_chars.length);
    result += password_chars[rchar];
  }
  
  return result;
}

function get_passwords_chars(_case, chars) {
  var array = [];
  
  if (_case == CASE_UPP) {
    array = array.concat(PASSWORD_CHARS_UPPERCASE);
  }
  else if (_case == CASE_LOW) {
    array = array.concat(PASSWORD_CHARS_LOWERCASE);
  }
  else if (_case == CASE_BOTH) {
    array = array.concat(PASSWORD_CHARS_UPPERCASE.concat(PASSWORD_CHARS_LOWERCASE));
  }
  
  if (chars == CHARS_SPE) {
    array = array.concat(PASSWORD_SPECIAL_CHARS);
  }
  else if (chars == CHARS_NUM) {
    array = array.concat(PASSWORD_NUMERIC_CHARS);
  }
  else if (chars == CHARS_BOTH) {
    array = array.concat(PASSWORD_SPECIAL_CHARS.concat(PASSWORD_NUMERIC_CHARS));
  }
  
  return array;
}

function get_random(mx) {
  var mn = 0;
  mx     = mx - 1;
  return Math.floor(Math.random() * (mx - mn + 1)) + mn;
}
