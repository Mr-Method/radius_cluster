'use strict';

var MainModal;
var modalContent;

var spinner = '<div class="text-center"><i class="fa fa-spinner fa-pulse fa-2x"></i></div>';
var aModal  = new AModal();

$(document).ready(function () {
  MainModal    = $('#PopupModal');
  modalContent = MainModal.find('#modalContent');
});

/*  Modal window open  */
if (modalsArray === undefined) {
  var modalsArray = [];
}

if (modalsSearchArray === undefined) {
  var modalsSearchArray = [];
}

/** Old-fashioned way to load modal windows
 *
 */
function openModal(buttonNumber, type_) {
  if (type_ == 'TemplateBased') {
    fill_template_popup(buttonNumber);
  }
  if (type_ == 'ArrayBased') {
    fill_array_popup(buttonNumber);
  }
}

/*  loads content of url in modal and shows it*/
function loadToModal(url, callback) {
  url += "&IN_MODAL=1";

  aModal.clear()
      .setSmall(false)
      .setId('CurrentOpenedModal')
      .setBody(spinner)
      .show(function () {

        $.get(url,
            function(data){
          var modalBody = $('#CurrentOpenedModal').find('.modal-body');
              modalBody.html(data);
              pageInit(modalBody);
              Events.emit('modal_loaded', modalBody);
            }, 'html')
            .fail(function (error) {
              alert('Fail' + JSON.stringify(error));
              
              Events.emit('modal_loaded', false);
            });

        if (callback) callback();
      });


}

/*  loads content of url in modal and shows it*/
function postAndLoadToModal(url, params, callback, close_callback) {
  params['IN_MODAL'] = 1;

  aModal.clear()
      .setSmall(false)
      .setId('CurrentOpenedModal')
      .setBody(spinner);

      if (close_callback)
        aModal.onClose(close_callback);

      aModal.show(function () {
        $.post(url, $.param(params), function(data){
          var modalBody = $('#CurrentOpenedModal').find('.modal-body');
          modalBody.html(data);
          pageInit(modalBody)
        } , 'html')
            .fail(function (error) {
              alert('Fail' + JSON.stringify(error));
            })
            .done(callback);
      })


}

function loadToModalSmall(url, callback) {
  url += "&IN_MODAL=1";
  $.get(url, function (data) {

    aModal.clear()
        .setSmall(true)
        .setBody(data)
        .show(function(){
          pageInit(data);
        });

    if (callback) callback();

  }, 'html');
}

/*  loads content of url in modal and shows it*/
function loadRawToModal(url, callback) {
  url += "&IN_MODAL=1";
  aModal.clear()
      .setRawMode(true)
      .setBody(spinner)
      .setId('CurrentOpenedModal')
      .show(function () {

        $.get(url, function (data) {
          var modalBody = $('#CurrentOpenedModal').find('.modal-content');
          modalBody.html(data);
          pageInit(modalBody);
          if (callback) callback();
        }, 'html')
            .fail(function (error) {
              alert('Fail' + JSON.stringify(error));
            });
      });
}

function showImgInModal(url) {
  loadDataToModal('<img src=' + url + ' class="center-block" alt="abills_image. You may need to install Imager module">', true, true);
}

/**
 * get modal body and load it to modal
 * @param data DOM elements to show in modal
 * @param decorated
 * @param withoutButton
 */
function loadDataToModal(data, decorated, withoutButton) {
  if (decorated) {
    getModalDecorated(data, null, withoutButton);
  } else {
    modalContent.empty().append(data);
  }
  MainModal.modal('show');
}

function getModalDecorated(data, onclick, withoutButton) {

  var formAction = 'getData()';
  if (onclick) formAction = onclick;

  var str_func_close = '$("#PopupModal").modal("hide");';

  var s = '';
  s += '<div class="modal-content">';
  s += '<div class="modal-header">';
  s += '<button type="button" class="close" onclick=' + str_func_close + '><span aria-hidden="true">&times;</span></button>';
  s += '</div>';
  s += '<div class="modal-body form-horizontal">';
  s += data;
  s += '</div>';
  s += '<div class="modal-footer">';
  if (!withoutButton)
    s += '<button class="btn btn-primary" onclick="' + formAction + '"  href="">Go</button>';
  s += '</div>';
  s += '</div>';

  modalContent.empty().append(s);
}

function AModal() {
  var counter = 0;

  var self = this;

  this.id = 'PopupModal';

  this.mainModal = null;
  this.$modal    = null;

  this.header  = '';
  this.footer  = '';
  this.body    = spinner;
  this.rawMode = false;
  this.is_form = false;
  this.timeout = 0;

  this.isSmall = false;

  this.callback = null;

  this.setId = function (id) {
    this.id = id;
    return this;
  };

  this.isForm = function (boolean) {
    this.is_form = boolean;
    return this;
  };

  this.setRawMode = function (boolean) {
    this.rawMode = boolean;
    return this;
  };

  this.setTimeout = function (milliseconds) {
    this.setTimeout(milliseconds);
  };

  this.setHeader = function (data) {
    this.header = data;
    return this;
  };

  this.setBody = function (data) {
    this.body = data;
    return this;
  };

  this.setSmall = function (boolean) {
    this.isSmall = boolean;
    return this;
  };

  this.setFooter = function (data) {
    this.footer = data;
    return this;
  };

  this.updateBody = function (content) {
    if (this.$modal){
      this.$modal.find('.modal-body').html(content);
      this.$modal.modal('handleUpdate')
    }
  };

  this.onClose = function(callback){
    if (callback) this.onClose = callback;
  };

  this.addButton = function (text, btnId, class_) {
    this.footer += '<button id="' + btnId + '" class="btn btn-' + class_ + '">' + text + '</button>';
    return this;
  };

  this.show = function (callback) {
    if (this.mainModal == null) this.mainModal = this.build();

    // Creating jQuery object from HTML
    var $modal = $(this.mainModal);

    if (callback)
      $modal.on('show.bs.modal', function () {
        callback(self);
      });

    // Adding HTML to page
    $('body').prepend($modal);

    // Open modal
    $modal.modal('show');

    $modal.on('hidden.bs.modal', function(){
      if (self.onClose) self.onClose();
      $(this).remove();
    });

    this.$modal = $modal;
  };

  this.hide = function () {
    // If modal is still presnt in body
    if (self.$modal) {
      self.$modal.modal('hide');
      $('#' + this.id).remove();
    }
    // Remove body
    else {
      $('#' + this.id).remove();
    }

    // Remove fade if any
    $('.modal-backdrop').remove();
    $('body')
      .removeClass('modal-open')
      .css('padding-right','0px');

    return this;
  };

  this.build = function () {
    var modalClass = (this.isSmall) ? 'modal-sm' : '';

    var str_func_close = '$("#' + this.id + '").modal("hide");';
    if (!this.rawMode) {
      var result = "<div class='modal fade' tabindex='-1' id='" + this.id + "' role='dialog' aria-hidden='true'>" +
          '<div class="modal-dialog ' + modalClass + '" style="z-index : 10000">' +
          '<div class="modal-content">' +
          '<div class="modal-header">' +
          this.header +
          '<button type="button" class="close" onclick=' + str_func_close + '>' +
          '<span aria-hidden="true">&times;</span>' +
          '</button>' +
          '</div>' +  //modal-header
          '<div class="modal-body form-horizontal">';

      if (this.is_form) {
        result += "<form class='form form-horizontal'>"
      }

      result += this.body;

      if (this.is_form) {
        result += "</form>"
      }

      result += '</div>';//modal-body
      if (this.footer) {
        result += '<div class="modal-footer">' +
            this.footer +
            '</div>';//footer
      }
      result += '</div>' +//modal-content
          '</div>' + //modal-dialog
          '</div>'; //modal
      return result;
    }
    else {
      return "<div class='modal' tabindex='-1' id='" + this.id + "' role='dialog' aria-hidden='true'>" +
          "<div class='modal-dialog'>" +
          '<div class="modal-content">' +
          this.body +
          '</div>' +//modal-content
          '</div>' + //modal-dialog
          '</div>'; //modal
    }
  };

  this.clear = function () {
    this.id = 'PopupModal' + ++counter;

    if (this.mainModal !== null){
      this.hide();
    }

    this.header  = '';
    this.footer  = '';
    this.body    = '<h1>Empty</h1>';
    this.rawMode = false;

    this.mainModal = null;

    return this;
  };

  /**
   * @deprecated because of undesired effects
   */
  this.destroy = function () {
    // If modal is still presnt in body
    if (self.$modal) {
      self.$modal.modal('hide');
      $('#' + this.id).remove();
    }
    // Remove body
    else {
      $('#' + this.id).remove();
    }

    // Remove fade if any
    $('.modal-backdrop').remove();

    return this;
  }

}

var aTooltip = new ATooltip();

ATooltip.counter = 0;

function ATooltip(text) {
  var self = this;

  this._id      = 0;
  this._text    = text || '';
  this._class   = 'success';
  this._timeout = 2000;

  this.ready = false;

  this.body = '';

  this.setTimeout = function (milliseconds) {
    this._timeout = milliseconds;
    return this;
  };

  this.setText = function (html) {
    this._text = html;
    return this;
  };

  this.setClass = function (alertClass) {
    this._class = alertClass;
    return this;
  };

  this.build = function () {
    this._id   = ATooltip.counter++;
    this.body = '<div id="modalTooltip_' + this._id + '" class="alert alert-' + this._class +
        '" style="display : none; position: fixed; z-index: 9999; top: 45vh; left: 35vw">' +
        this._text + '</div>';
  };

  this.show = function () {
    if (!this.ready) {
      this.build();
    }

    $('body').prepend(this.body);
    $('#modalTooltip_' + this._id).fadeIn(500);

    if (this._timeout > 0)
      setTimeout(function () {
        self.hide();
      }, this._timeout)

  };

  this.display = function (text, duration) {
    this.setText(text);
    this.setTimeout(duration || 2000);
    this.show();
  };

  this.displayError = function (Error) {
    this.setText('<h3>' + Error + '</h3>');
    this.setTimeout(5000);
    this.setClass('danger');
    this.show();
  };

  this.hide = function () {
    var tooltip = $('body').find('div#modalTooltip_' + this._id);
    tooltip.fadeOut(500, function () {
      tooltip.remove();
    });
  };
}

/** TEST **/
//$(function () {
//    aModal = new AModal();
//
//    aModal
//        .setId('modalTest')
//        .setHeader('Hello')
//        .setBody('<h2>Here I am</h2>')
//        .setFooter('Nothing special here')
//        .show();
//
//});

