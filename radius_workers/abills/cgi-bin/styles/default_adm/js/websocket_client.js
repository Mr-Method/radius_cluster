'use strict';

var socket_state = {
  CONNECTING: 0,
  OPEN      : 1,
  CLOSING   : 2,
  CLOSED    : 3
};

var counter                       = 0;
var try_to_connect_again          = true;
var is_in_connection_retrieval    = false;
var unsuccessful_connection_tries = 0;

var ws = null;
$(function () {
      var socket_link = document['WEBSOCKET_URL'];
      if (socket_link !== '') {
        ws = connect_to_socket(socket_link);
      }
      else {
        console.log('[ WebSocket ] Will not connect to socket without $conf{WEBSOCKET_URL}. It\'s normal if you haven\'t configured WebSockets');
      }
    }
);

function request_close_socket() {
  ws.send('{ "type" :  "close_request"}');
  try_to_connect_again = false;
}


function try_to_connect_again_in_(seconds) {
  
  seconds = Math.min(seconds, 60);
  
  ws = new WebSocket(document['WEBSOCKET_URL']);
  
  ws.onopen = function () {
    Events.emit('WebSocket.connected');
    unsuccessful_connection_tries = 0;
    is_in_connection_retrieval    = false;
    ws                            = setup_socket(ws);
  };
  
  ws.onerror = function () {
    unsuccessful_connection_tries++;
    if (unsuccessful_connection_tries > 10) {
      console.log('[ WebSocket ] Giving up after %i tries', unsuccessful_connection_tries);
      return;
    }
    console.log('Will try again in %i seconds', seconds);
    setTimeout(function () {
      try_to_connect_again_in_(seconds * 2)
    }, seconds * 1000);
  };
  
  if (ws !== null && ws.readyState == socket_state['OPEN']) {
    ws = setup_socket(ws);
  }
  
  
}

function setup_socket(websocket) {
  
  websocket.onopen = function () {
    Events.emit('WebSocket.connected');
    unsuccessful_connection_tries = 0;
    is_in_connection_retrieval    = false;
  };
  
  websocket.onclose = function () {
    Events.emit('WebSocket.error');
    if (!is_in_connection_retrieval) {
      is_in_connection_retrieval = true;
      try_to_connect_again_in_(3);
    }
  };
  
  websocket.onerror = function () {
    if (!is_in_connection_retrieval) {
      is_in_connection_retrieval = true;
      try_to_connect_again_in_(3);
    }
  };
  
  websocket.ping = function () {
    if (websocket.readyState == socket_state.OPEN){
      websocket.send('{"TYPE" : "PING"}');
    }
  };
  
  websocket.onmessage = on_message;
  
  return websocket;
}

function connect_to_socket(url) {
  
  ws = new WebSocket(url);
  
  setup_socket(ws);
  return ws;
}

function on_message(event) {
  var message = null;
  try {
    message = JSON.parse(event.data);
  }
  catch (Error) {
    console.log("[ WebSocket ] Fail to parse JSON: " + event.data);
    return;
  }
  
  switch (message.TYPE) {
    case 'close':

      ws.close(1000); // Normal
      if (message.REASON) {
        console.log("[ WebSocket ] Connection closed by server : " + message.REASON);
      }
      break;
    case 'PING':
      ws.send('{"TYPE" : "PONG"}');
      break;
    case 'PONG':
      console.warn("I should not receive this :",  message);
      break;
    default:
      AMessageChecker.processData(message);
      ws.send('{"TYPE":"RESPONCE","RESPONCE":"RECEIVED"}');
      break;
  }
  
}

document.onunload = function () {
  try_to_connect_again = false;
};