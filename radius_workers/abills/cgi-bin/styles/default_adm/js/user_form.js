/**
 * Created by Anykey on 26.05.2016.
 */
var AContacts = (function () {
  "use strict";
  // Cache DOM
  var $contacts_controls = $('#contacts_controls');
  var $contacts_wrapper  = $('#contacts_wrapper');

  var $add_btn = $contacts_controls.find('#contact_add');
  var $del_btn = $contacts_controls.find('#contact_remove');
  var $sub_btn = $contacts_controls.find('#contact_submit');

  var $response_span = $contacts_controls.find('#contacts_response');

  // Parse input JSON
  var contacts_json_str = $('#contacts_json').text();
  var contacts_json     = JSON.parse(contacts_json_str).json;
  var contacts_raw = contacts_json.contacts || [];
  var options      = contacts_json.options;

  var contact_types = {};
  $.each(options.types, function(i, e){
    contact_types[e.id] = e;
  });

  // Parse templates
  var contact_template    = $('#contact_template').html();
  var contacts_modal_body = $('#contacts_modal_body').html();
  Mustache.parse(contact_template);
  Mustache.parse(contacts_modal_body);

  var rendered = {};

  // If in reg wizard, we need to delete buttons and change form for inputs
  if (contacts_json.options.in_reg_wizard == 1) {
    $add_btn.remove();
    $del_btn.remove();
    $sub_btn.remove();

    renew_contacts(contacts_raw);
    return false;
  }

  function check_for_default_types(contacts_raw, types) {
    var types_present = [];

    $.each(contacts_raw, function (i, contact) {
      types_present[contact.type_id] = 1;
    });

    $.each(types, function (i, type) {
      if (type.is_default == 1 && !types_present[type.id]) {
        contacts_raw.push({
          type_id : type.id,
          name    : type.name,
          value   : '',
          priority: 10
        });
      }
    });
  }

  check_for_default_types(contacts_raw, options.types);

  // Entry point
  renew_contacts(contacts_raw);

  // Attach handlers
  $add_btn.on('click', add_new_contact);
  $del_btn.on('click', remove_last_contact);
  $sub_btn.on('click', submit_contacts);

  function renew_contacts(contacts_array) {

    // Sort contacts by priority
    contacts_raw.sort(function (a, b) {
      return (a.priority - b.priority);
    });

    // Clear contacts block
    $contacts_wrapper.empty();

    // Render and paste to contacts block
    $.each(contacts_array, function (i, contact) {
      var $rendered = get_contact(contact);

      $contacts_wrapper.append($rendered);

      $rendered.find('input').on('input', function () {
        set_changed_status(true);
      });

    });
  }

  // Make this function global
  window.renew_contacts = renew_contacts;

  function get_contact(contact_json) {

    if (contacts_json.options.in_reg_wizard) {
      contact_json.name    = options.types[contact_json.type_id - 1].name;
      contact_json.type_id = 'CONTACT_TYPE_' + contact_json.type_id;
      contact_json.form    = null;
    }
    else {
      contact_json.form = 'some_random_input';
      contact_json.name = get_contact_type_name(contact_json.type_id);
    }

    var rendered = Mustache.render(contact_template, contact_json);

    var $rendered = $(rendered);

    return $rendered;
  }

  function get_contact_type_name(type_id){
    return contact_types[type_id].name;
  }

  function add_new_contact(e) {
    e.preventDefault();

    var add_contact_form = new AModal();

    console.log(options);

    // Lazy rendering for static templates
    rendered['modal_add'] = rendered['modal_add'] || Mustache.render(contacts_modal_body, options);

    add_contact_form
        .setId('add_contact_modal')
        .isForm(true)
        .setHeader(translate('CONTACTS'))
        .setBody(rendered['modal_add'])
        .addButton(translate('CANCEL'), 'add_contact_modal_btn_cancel', 'default')
        .addButton(translate('ADD'), 'add_contact_modal_btn_add', 'primary')
        .show(setup_add_contact_modal_form);

    function setup_add_contact_modal_form(add_contact_form) {
      // Init chosen for select
      CHOSEN_PARAMS.width = '100%';
      $('#contacts_type_select').chosen(CHOSEN_PARAMS);


      // Button handlers
      $('#add_contact_modal_btn_cancel')
        .on('click', add_contact_form.hide);

      $('#add_contact_modal_btn_add').on('click', read_and_process_add_contact_modal);

      function read_and_process_add_contact_modal(e) {
        e.preventDefault();
        
        var type_id = add_contact_form.$modal.find('select#contacts_type_select').val();
        var value   = add_contact_form.$modal.find('input#contacts_type_value').val();

        contacts_raw.push({
          value  : value,
          type_id: type_id
        });

        renew_contacts(contacts_raw);

        add_contact_form.hide();

        set_changed_status(true);
      }
    }
  }

  function remove_last_contact(e) {
    e.preventDefault();

    var last_index = contacts_raw.length - 1;
    if (last_index == -1) return false;

    var last_contact = contacts_raw[last_index];

    if (confirm(translate('REMOVE') + ' ' + last_contact.name + ' : ' + last_contact.value + ' ?')) {
      contacts_raw.splice(last_index, 1);
      renew_contacts(contacts_raw);
    }

    set_changed_status(true);
  }

  function submit_contacts(e) {
    e.preventDefault();

    var $sub_btn_icon = $sub_btn.find('span');
    var $inputs       = $contacts_wrapper.find('input');

    $sub_btn.prop('disabled', true);
    $sub_btn_icon.attr('class', 'fa fa-spinner fa-pulse');

    var contacts_to_send = [];

    // Trasnform form to hash
    $.each($inputs, function (index, contact) {
      var $contact = $(contact);

      contacts_to_send.push(
          {
            TYPE_ID : $contact.attr('name'),
            VALUE   : $contact.val(),
            PRIORITY: index
          }
      );

    });

    // Forming request
    if (contacts_json.options.AID) {
      var request = {
        'qindex'  : options.callback_index,
        'header'  : 2,
        //'json'     : 1,
        'AID'     : options.AID,
        'subf'    : options.subf,
        'CONTACTS': JSON.stringify(contacts_to_send)
      };
    }
    else{
    // Forming request
    var request = {
      'qindex'  : options.callback_index,
      'header'  : 2,
      //'json'    : 1,
      'uid'     : options.uid,
      'CONTACTS': JSON.stringify(contacts_to_send)
    };
}
    // Sending contacts to backend
    $.post(SELF_URL, request, function (data) {

      var object = null;

      try {
        object = JSON.parse(data);
      }
      catch (JSONParseError) {
        (new ATooltip()).displayError(JSONParseError.toString());
      }

      // Unlock submit button
      $sub_btn.prop('disabled', false);
      $sub_btn_icon.attr('class', 'glyphicon glyphicon-ok');

      if (object == null) return false;

      $response_span.text(object.message);

      if (object.status == 0) {
        setTimeout(function () {
          $response_span.text('');
        }, 3000);
        set_changed_status(false);
      }
      else {
        (new ATooltip()).displayError(object.message);
        return false;
      }

    });

  }

  function set_changed_status(boolean) {
    if (boolean) {
      $sub_btn.attr('class', 'btn btn-sm btn-warning');

    }
    else {
      $sub_btn.attr('class', 'btn btn-xs btn-primary disabled');
    }
  }

  function translate(e) {
    return CONTACTS_LANG[e] || e;
  }

})();
