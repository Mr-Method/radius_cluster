/**
 * Created by Anykey on 22.02.2016.
 *
 *   AJAX based new message checker
 *   Calls cross_modules in ABillS
 *
 */
'use strict';

var AMessageChecker = (function () {
  var self = {};
  
  self.last_id = 0;
  
  self.loader = null;
  
  self.extensions = {
    MESSAGE: [function (event_data, events_count) {
      var parsed = parseMessage(event_data);
      
      if (event_data.MODULE) {
        Events.emit('messageChecker.gotMessage.' + event_data.MODULE, event_data);
        
        if (event_data.MODULE !== 'Msgs' || typeof CLIENT_INTERFACE !== 'undefined') {
          showMessage(parsed);
          return;
        }
        
      }
      showMessage(parsed);
    }],
    EVENT  : [function (event_data, events_count) {
      Events.emit('messageChecker.gotEvent', event_data);
    }],
    DEFAULT: function (event_data) {
      console.log("[ AMessageChecker ] Got unknown event type : " + event_data.TYPE);
    }
  };
  
  function start(parameters) {
    // accept parameters
    $.extend(self, parameters);
    if (!self.disabled) {
      setSoundsDisabled(self.soundsDisabled);
      
      self.loader = new JSONLoaderCached({
        id         : 'message_checker',
        url        : self.link + '&AJAX=1',
        refresh    : self.interval,
        ignoreCache: true,
        after      : 0,
        callback   : handleData,
        fail       : function () {
          console.log("[ AMessageChecker ] Got non-JSON response");
        }
      });
    }
  }
  
  function stop() {
    if (self.intervalHandler !== null) {
      clearInterval(self.intervalHandler);
    }
  }
  
  function handleData(events) {
    if (events.length > 0) {
      
      $.each(events, function (i, event) {
        processData(event, events.length);
      });
    }
  }
  
  function processData(event_data, events_length) {
    if (typeof (self.extensions[event_data.TYPE]) !== 'undefined') {
      $.each(self.extensions[event_data.TYPE], function (i, processor) {
        processor(event_data, events_length);
      });
    }
    else {
      self.extensions['DEFAULT'](event_data, events_length);
    }
    
    self.last_id++;
  }
  
  function extend(extension) {
    var type = extension.TYPE;
    var cb   = extension.CALLBACK;
    
    if (typeof  (cb) !== 'function') {
      console.warn('[ AMessageChecker ] extension.CALLBACK should be a function');
      return false;
    }
    
    if (typeof (self.extensions[type]) !== 'undefined') {
      if (self.extensions[type].indexOf(cb) != -1) {
        console.warn('[ AMessageChecker ] Extension has been already registered : ' + type);
        return false;
      }
      self.extensions[type].push(cb);
    }
    else {
      self.extensions[type] = [cb];
    }
    
    console.log('[ AMessageChecker ] Successfully registered ' + type);
  }
  
/*  function updateBadge(count) {
    if (typeof CLIENT_INTERFACE !== 'undefined') {
      var $badgeHolder = $('#msgs_user').find('span');
      if ($badgeHolder.length > 0) {
        var text = $badgeHolder.text();

        var hasNumber = text.match("[(]([0-9]{1,})[)]");

        if (hasNumber != null) {
          text = text.substr(0, hasNumber.index);
        }

        $badgeHolder.text(text + ' (' + count + ')');

      }
    }
  }*/
  
  function parseMessage(data) {
    var message = {};
    
    //prevent undefined errors
    data.SENDER = data['SENDER'] || {};
    
    message.uid   = data.SENDER['UID'] || '';
    message.login = data.SENDER['LOGIN'] || '';
    
    message.caption     = data['TITLE'] || '';
    message.text        = data['TEXT'] || '';
    message.num         = data['MSGS_ID'] || '';
    message.extra       = data['EXTRA'] || '';
    message.responsible = data['RESPOSIBLE'] || '';
    message.seen_url    = data['NOTICED_URL'] || '';
    
    message.id       = data['ID'] || 0;
    message.group_id = data['GROUP_ID'] || 0;
    
    if (message.text.length > 60) {
      message.text = message.text.substr(0, 60) + "...";
    }
    return message;
  }
  
  function showMessage(message) {
    
    //var messageText = "<b>" + message.num + "</b> " + message.text;
    var messageText = message.text;
    
    if (message.extra != '') {
      message.caption = "<a href='" + message.extra + "'>" + message.caption + '</a>';
    }
    
    if (message.uid) {
      messageText = "<a class='link_button' href='/admin/index.cgi?index=15&UID=" + message.uid + "'>" + message.login + "</a>&nbsp" + messageText;
    }
    
    QBinfo("<b>" + message.caption + "</b>",
        messageText,
        message.group_id,
        message.id,
        message.seen_url
    );
    
  }
  
  function unsubscribe(qb_id, group_id) {
    Events.emit('MessageChecker.unsubscribe', group_id);
    hideQBinfo(qb_id);
    var url = '?AJAX=1&get_index=events_unsubscribe&GROUP_ID=' + group_id;
    
    $.get(url, '', function () {
      (new ATooltip).display('<h3>Unsubscribed from group ' + group_id + '</h3>', 2000);
    });
  }
  
  function seenMessage(qb_id, seen_url) {
    hideQBinfo(qb_id);
    $.get(seen_url, Events.emitAsCallback('MessageChecker.seenMessage'));
  }
  
  return {
    start      : start,
    stop       : stop,
    extend     : extend,
    processData: processData,
    unsubscribe: unsubscribe,
    seenMessage: seenMessage,
    showMessage: showMessage
  }
})();

function JSONLoaderCached(options) {
  
  var self = this;
  
  self.id      = options.id;
  self.url     = options.url;
  self.refresh = options.refresh;
  
  self.callback        = options.callback;
  self.format_callback = options.format;
  self.fail            = options.fail || function () {console.log(self.id, 'Got bad JSON')};
  
  self.after       = options.after || 0;
  self.ignoreCache = options.ignoreCache || false;
  
  
  self.intervalHandler = null;
  self.once            = options.once || false;
  
  
  this.checkUpdates = function (force, callback) {
    var currentTimestamp = (new Date()).getTime();
    var lastUpdate       = aStorage.getValue(self.id + '_last_update', currentTimestamp);
    var timeleft         = (parseInt(lastUpdate) + parseInt(self.refresh)) - parseInt(currentTimestamp);
    
    if (timeleft <= 0 || force) {
      $.getJSON(self.url, function (data) {
        var formatted = data;
        
        if (self.format_callback) {
          formatted = self.format_callback(data);
        }
        
        self.callback(formatted);
        
        aStorage.setValue(self.id + '_cache', JSON.stringify(formatted));
        aStorage.setValue(self.id + '_last_update', currentTimestamp);
        
        if (callback) callback();
      }).fail(self.fail);
    }
    else if (self.ignoreCache) return;
    else {
      var data   = aStorage.getValue(self.id + '_cache', '[]');
      var parsed = [];
      try {
        parsed = JSON.parse(data);
      }
      catch (parseError) {
        console.warn(self.id, parseError);
      }
      self.callback(parsed);
    }
    
    return self.timeleft;
  };
  
  this.stop = function () {
    if (self.intervalHandler) {
      clearInterval(self.intervalHandler);
    }
  };
  
  self.timeleft = self.checkUpdates();
  
  if (!self.once) {
    // Is updating now
    if (self.timeleft <= 0) {
      setTimeout(function () {
        self.intervalHandler = setInterval(self.checkUpdates, self.refresh);
      }, self.after);
    }
    // Need to be updated later
    else {
      setTimeout(function () {
        self.intervalHandler = setInterval(self.checkUpdates, self.refresh);
      }, self.timeleft + self.after);
    }
  }
  
  aStorage.subscribeToChanges(self.id + '_cache', function () {
    self.checkUpdates(false);
  });
}

function NavbarDropdownMenu(id, options) {
  this.$wrapper = $('li.dropdown#' + id);
  
  if (!this.$wrapper.length) {
    throw new Error("Error init NavbarDropdownMenu" + id);
  }
  
  this.meta = this.$wrapper.data('meta');
  if (!this.meta || typeof (this.meta) === 'undefined') { this.meta = null }
  
  this.$button = this.$wrapper.find('a.dropdown-toggle');
  this.$icon   = this.$button.find('i.fa');
  this.$badge  = this.$button.find('span#badge_' + id);
  this.$badge2 = this.$button.find('span#badge2_' + id);
  
  this.prevColorClass = null;
  
  this.$list_wrapper = this.$wrapper.find('ul#dropdown_' + id);
  
  this.$header      = this.$list_wrapper.find('li#header_' + id);
  this.$header_text = this.$header.find('.header_text');
  this.$refresh_btn = this.$header.find('.header_refresh');
  this.$footer      = this.$list_wrapper.find('li#footer_' + id);
  this.$list        = this.$list_wrapper.find('ul#menu_' + id);
  
  this.$lines = this.$list.children();
  
  this.setHeader = function (headerText) {this.$header_text.html(headerText)};
  this.setFooter = function (footerText) {this.$footer.html(footerText)};
  this.setIconColor = function(colorClass){
    if (this.prevColorClass !== null){
      this.$icon.removeClass(this.prevColorClass);
    }
    this.prevColorClass = colorClass;
    this.$icon.addClass(colorClass);
  };
  this.setBadge  = function (badgeText) {
    if (badgeText === 0) {this.$badge.addClass('hidden')}
    else {
      this.$badge.removeClass('hidden')
    }
    this.$badge.text(badgeText);
  };
  this.setBadge2 = function (badgeText) {
    if (badgeText === 0) {this.$badge2.addClass('hidden')}
    else {
      this.$badge2.removeClass('hidden')
    }
    this.$badge2.text(badgeText);
  };
  this.getBadge  = function () {
    return this.$badge.text();
  };
  this.getBadge2 = function () {
    return this.$badge2.text();
  };
  this.getMeta   = function () {return this.meta};
  
  this.clear = function () {
    this.$list.html('');
    this.$lines = this.$list.children();
    if (!options['BADGE_CUSTOM']) this.setBadge(0);
  };
  
  this.addLine = function (content, position_) {
    // Renew lines
    this.$lines = this.$list.children();
    
    // Calculate position
    var position = (typeof position_ === 'undefined')
        ? 0 // At start
        : (position_ > this.$lines.length)
        ? this.$lines.length - 1 // After last line
        : position_;
    
    // Append new content
    (this.$lines.length > 0)
        ? $(this.$lines[position]).before(content)
        : this.$list.html(content);
    
    // Renew lines
    this.$lines = this.$list.children();
    
    // Update badge
    if (!options['BADGE_CUSTOM'])
      this.setBadge(this.$lines.length);
    
  };
  
  if (this.meta) {
    if (this.meta['BADGE']) {
      this.setBadge(this.meta['BADGE']);
    }
    if (this.meta['BADGE2']) {
      this.setBadge2(this.meta['BADGE2']);
    }
    if (this.meta['HEADER']) {
      this.setHeader(this.meta['HEADER']);
    }
    if (this.meta['DISABLED']) {
      this.disabled = true;
      this.$wrapper.addClass('hidden');
    }
  }
  
  if (this.$refresh_btn && options.onRefresh) {
    this.$refresh_btn.on('click', function (event) {
      cancelEvent(event);
      
      var $this = $(this);
      
      $this.find('.fa').addClass('fa-spin');
      
      options.onRefresh(function () {
        $this.find('.fa').removeClass('fa-spin');
      });
      
    })
  }
  else {
    this.$refresh_btn.hide();
  }
}

var MessagesMenu = function (id, options) {
  var self = this;
  
  this.$menu            = null;
  this.module           = 'Msgs';
  this.meta             = null;
  this.default_interval = 30000; // 30 seconds
  
  this.filter = options.filter || function () {return true};
  
  this.messages = {};
  this.unread_counter = 0;
  
  this.init = function () {
    try {
      this.$menu = new NavbarDropdownMenu(id, {
        BADGE_CUSTOM: true,
        onRefresh   : function (callback) {
          self.forceUpdate(callback);
        }
      });
      
      this.meta = this.$menu.getMeta();
      
      if (this.meta && this.meta['UPDATE']) {
        var refresh = this.meta['REFRESH'] ? this.meta['REFRESH'] * 1000 : this.default_interval;
        // Start loader
        self.loader = new JSONLoaderCached({
          id      : id,
          url     : this.meta['UPDATE'],
          refresh : refresh,
          once    : true,
          after   : this.meta['AFTER'] || 0,
          callback: function (parsed) {
            self.clear();
            parsed.map(self.addEvent);
          },
          format  : function (rawData) {
            var result = [];
            if (rawData['DATA_1'] && $.isArray(rawData['DATA_1'])) {
              $.each(rawData['DATA_1'], function (i, message) {
                if (self.filter(message))
                  result.push(self.parseMessage(message));
              });
            }
            return result;
          }
        });
        $('#' + id).removeClass('hidden');
      }
      else {
        // No need to show element if has no update link
        return false;
      }
      
      if (this.meta && this.meta['AID']) {
        self.aid = this.meta['AID'];
      }
      
      // Link to messageChecker
      Events.on('messageChecker.gotMessage.' + this.module, function (message) {
        // We want to see reply instead of subject
        message['SUBJECT'] = message['TEXT'];
        message['ID']      = message['MSGS_ID'];
        
        if (self.aid && (!message['RESPONSIBLE'] || self.aid != message['RESPONSIBLE'])) {
          return false;
        }
        
        //This is really fresh message
        message['ADMIN_READ'] = 0;
        
        self.addEvent(message);
      });
      return true;
    }
    catch (Error) {
      return false;
    }
  };
  
  this.parseMessage = function (message) {
    return {
      TYPE      : "MESSAGE",
      MODULE    : "Msgs",
      SENDER    : {UID: message['uid'], LOGIN: message['client_id']},
      EXTRA     : '/admin/index.cgi?get_index=msgs_admin&full=1&UID=' + message['uid'] + '&chg=' + message['id'],
      ID        : message['id'],
      MSGS_ID   : message['id'],
      SUBJECT   : message['subject'],
      CREATED   : message['datetime'],
      ADMIN_READ: (message['admin_read'] && message['admin_read'] !== '0000-00-00 00:00:00' ) ? 1 : 0,
      PRIORITY  : message['priority_id'] || 0
    }
  };
  
  this.forceUpdate = function (callback) {
    if (self.loader != null) {
      self.clear();
      self.loader.checkUpdates(true, callback);
    }
    else {
      self.$menu.$refresh_btn.addClass('disabled');
      callback();
    }
  };
  
  this.getPriorityClass = function (priorityNum) {
    
    switch (parseInt(priorityNum)) {
      case 0:
        return 'text-muted';
      case 1:
        return 'text-aqua';
      case 3:
        return 'text-yellow';
      case 4:
        return 'text-red';
      case 2:
      default:
        return '';
    }
  };
  
  this.formEventHTML = function (message) {
    
    var icon = '<div class="pull-left"><img src="/styles/lte_adm/dist/img/avatar0.png" class="img-circle" alt="User Image"></div>';
    
    var priority_class = this.getPriorityClass(message['PRIORITY']);
    
    var time    = '<small><i class="fa fa-clock-o"></i>&nbsp'
        + moment(message['CREATED'], 'YYYY-MM-DD hh:mm:ss').fromNow()
        + '</small>';
    var header  = '<h4>' + message['SENDER']['LOGIN'] + time + '</h4>';
    var subject = '<p class="' + priority_class + '">' + message['SUBJECT'] + '</p>';
    
    
    return icon + header + subject;
  };
  
  this.addEvent = function (message) {
    
    if (typeof self.messages[message['ID']] !== 'undefined') {
      // Already have such message
      return true;
    }
    else {
      self.messages[message['ID']] = message;
    }
    
    // Create element
    var new_line = $('<a></a>');
    new_line.attr('href', (message['EXTRA']) ? message['EXTRA'] : '#');
    new_line.html(self.formEventHTML(message));
    if (message['ID']) { new_line.attr('id', (message['ID']))}
    
    var new_li = $('<li></li>');
    new_li.html(new_line);
    
    if (message['ADMIN_READ'] === 0) {
      self.unread_counter = +self.$menu.getBadge2() + 1;
      self.$menu.setBadge2(self.unread_counter);
      Events.emit('favicon.set', self.unread_counter);
      new_li.addClass('bg-gray');
    }
  
    self.$menu.addLine(new_li);
  };
  
  this.clear = function () {
    this.messages = {};
    self.$menu.clear();
    self.$menu.setBadge2(0);
    Events.emit('favicon.clear');
  };
  
  this.menu = function () {
    return this.$menu;
  }
  
};

var EventsMenu = function (id, options) {
  var self = this;
  
  this.$menu             = null;
  this.meta              = null;
  this.default_interval  = 30000; // 30 seconds
  this.showed_in_session = {};
  
  this.filter = options.filter || function () {return true};
  
  this.events = {};
  
  this.init = function () {
    try {
      this.$menu = new NavbarDropdownMenu(id, {
        BADGE_CUSTOM: false,
        onRefresh   : function (callback) {
          self.forceUpdate(callback);
        }
      });
      
      this.meta = this.$menu.getMeta();
      
      if (this.meta && this.meta['UPDATE'] && this.meta['ENABLED']) {
        var refresh = this.meta['REFRESH'] ? this.meta['REFRESH'] * 1000 : this.default_interval;
        // Start loader
        self.loader = new JSONLoaderCached({
          id      : id,
          url     : this.meta['UPDATE'],
          refresh : refresh,
          once    : true,
          after   : this.meta['AFTER'] || 0,
          callback: function (parsed) {
            self.clear();
            parsed.map(self.addEvent);
          },
          format  : function (rawData) {
            var result = [];
            if (rawData['DATA_1'] && $.isArray(rawData['DATA_1'])) {
              $.each(rawData['DATA_1'], function (i, message) {
                if (self.filter(message))
                  result.push(self.parseMessage(message));
              });
            }
            return result;
          },
          fail    : function (error) {
            console.warn('Error loading events', error);
            $('#' + id).addClass('hidden')
          }
        });
        $('#' + id).removeClass('hidden');
      }
      else {
        return false;
      }
      
      // Link to messageChecker
      Events.on('messageChecker.gotEvent', function (event_data) {
        event_data['SUBJECT'] = event_data['MODULE'];
        //event_data['NOTICED_URL'] = event_data[]]
        
        //This is really fresh message
        event_data['ADMIN_READ'] = 0;
        
        self.addEvent(event_data);
      });
      Events.on('MessageChecker.seenMessage', function (){
        self.loader.checkUpdates(true);
      });
      Events.on('WebSocket.connected', function(){
        self.$menu.setIconColor('text-aqua');
      });
      Events.on('WebSocket.error', function(){
        self.$menu.setIconColor('text-danger');
      });
      return true;
    }
    catch (Error) {
      return false;
    }
  };
  
  this.parseMessage = function (event) {
    
    return {
      TYPE       : "EVENT",
      MODULE     : event['module'],
      EXTRA      : '?get_index=events_main&full=1&chg=' + event['id'],
      ID         : event['id'],
      SUBJECT    : event['module'],
      TEXT       : event['comments'],
      CREATED    : event['created'],
      ADMIN_READ : (event['state_id'] && event['state_id'] !== '1' ) ? 1 : 0,
      PRIORITY   : event['priority_id'] || 0,
      STATE      : event['state_id'],
      GROUP_ID   : event['group_id'],
      NOTICED_URL: "get_index=events_main&json=1&MESSAGE_ONLY=1&AJAX=1&header=2&STATE_ID=2&change=1&ID=" + event['id']
    }
  };
  
  this.forceUpdate = function (callback) {
    if (self.loader != null) {
      self.clear();
      self.loader.checkUpdates(true, callback);
    }
    else {
      self.$menu.$refresh_btn.addClass('disabled');
      callback();
    }
  };
  
  this.getPriorityClass = function (priorityNum) {
    
    switch (parseInt(priorityNum)) {
      case 0:
        return 'text-muted';
      case 1:
        return 'text-aqua';
      case 3:
        return 'text-yellow';
      case 4:
        return 'text-red';
      case 2:
      default:
        return '';
    }
  };
  
  this.formEventHTML = function (event) {
    var priority_class = this.getPriorityClass(event['PRIORITY']);
    
    var time    = '<small><i class="fa fa-clock-o"></i>&nbsp'
        + moment(event['CREATED'], 'YYYY-MM-DD hh:mm:ss').fromNow()
        + '</small>';
    var header  = '<h4>' + event['MODULE'] + time + '</h4>';
    var subject = '<p class="' + priority_class + '">' + event['TEXT'] + '</p>';
    
    var icon_class = 'fa fa-2x fa-bell-o ' + self.getPriorityClass(event['PRIORITY']);
    var icon       = '<div class="pull-left"><i class="' + icon_class + '"></i></div>';
    
    return icon + header + subject;
    
  };
  
  this.addEvent = function (event) {
    
    if (typeof self.events[event['ID']] !== 'undefined') {
      // Already have such message
      return true;
    }
    else {
      self.events[event['ID']] = event;
      
      if (event['STATE'] === '1') {
        if (!self.showed_in_session[event['ID']]) {
          AMessageChecker.showMessage({
            text    : event['TEXT'],
            extra   : event['EXTRA'],
            caption : event['MODULE'],
            id      : event['ID'],
            seen_url: '?get_index=events_main&json=1&MESSAGE_ONLY=1&AJAX=1&header=2&STATE_ID=2&change=1&ID=' + event['ID'],
            group_id: event['GROUP_ID']
          });
          self.showed_in_session[event['ID']] = true;
        }
      }
    }
    
    // Create element
    var new_line = $('<a></a>');
    new_line.attr('href', (event['EXTRA']) ? event['EXTRA'] : '#');
    new_line.html(self.formEventHTML(event));
    if (event['ID']) { new_line.attr('id', (event['ID']))}
    
    var new_li = $('<li></li>');
    new_li.html(new_line);
    
    if (event['ADMIN_READ'] === 0) {
      self.$menu.setBadge2(+self.$menu.getBadge2() + 1);
      new_li.addClass('bg-gray');
    }
    
    self.$menu.addLine(new_li);
  };
  
  this.clear = function () {
    this.events = {};
    self.$menu.clear();
    self.$menu.setBadge2(0);
  };
  
  this.menu = function () {
    return this.$menu;
  }
  
};