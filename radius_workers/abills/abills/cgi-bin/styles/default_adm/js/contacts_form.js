/**
 * Created by Anykey on 26.05.2016.
 *
 */
$(function () {
  "use strict";
  
  function renderContactsBlock(contacts_array) {
    
    // Sort contacts by priority
    contacts_raw.sort(function (a, b) {
      return (a.priority - b.priority);
    });
    
    // Clear contacts block
    $contacts_wrapper.empty();
    
    // Render and paste to contacts block
    $.each(contacts_array, function (i, contact) {
      $contacts_wrapper.append(renderContact(contact, i));
    });
    
    $contacts_wrapper.find('input').on('input', function () {
      setContactsChangedStatus(true);
    });
    
    // Enable Sortable
    $contacts_wrapper.sortable({
      update: function () {
        setContactsChangedStatus(true);
      }
    });
  
    $contacts_wrapper.find('.contact-remove-btn').on('click', function (e) {
      cancelEvent(e);
      var $btn = $(this);
      var id = $btn.data('id');
      console.log(id);
      if (id){
        removeContact(id);
      }
    })
  }
  
  // Make this function global
  window.renewContacts = renderContactsBlock;
  
  function parseCurrentDisplayedContacts() {
    var $inputs       = $contacts_wrapper.find('input');
    var result = [];
    // Transform form to hash
    $.each($inputs, function (index, contact) {
      var $contact = $(contact);
    
      result.push({
            TYPE_ID : $contact.attr('name'),
            VALUE   : $contact.val(),
            PRIORITY: index
          });
    
    });
    
    return result;
  }
  
  function showDefaultTypesIfNotPresent(contacts_raw, types) {
    var types_present = [];
    
    $.each(contacts_raw, function (i, contact) {
      types_present[contact.type_id] = 1;
    });
    
    $.each(types, function (i, type) {
      if (type.is_default == '1' && !types_present[type.id]) {
        contacts_raw.push({
          type_id    : type.id,
          name       : type.name,
          is_default : true,
          value      : '',
          priority   : 10
        });
      }
    });
  }
  
  
  function renderContact(contact_json, position) {
    if (CONTACTS_JSON.options.in_reg_wizard) {

      if (typeof options.types[contact_json.type_id - 1] === 'undefined'){
        return '';
      }

      contact_json.name    = options.types[contact_json.type_id - 1].name;
      contact_json.type_id = 'CONTACT_TYPE_' + contact_json.type_id;
      contact_json.form    = null;
    }
    else {
      contact_json.form = 'some_random_input';
      contact_json.name = getContactTypeName(contact_json.type_id);
    }
    contact_json.is_default = (contact_json.is_default === "1");

    contact_json.position = position;
    var rendered          = Mustache.render(contact_template, contact_json);
    
    return $(rendered);
  }
  
  function getContactTypeName(type_id) {
    return contact_types[type_id].name;
  }
  
  function addNewContact(e) {
    e.preventDefault();
    
    var add_contact_form = new AModal();
    
    // Lazy rendering for static templates
    rendered['modal_add'] = rendered['modal_add'] || Mustache.render(contacts_modal_body, options);
    
    var setupAddContactModalForm = function (add_contact_form) {
      // Init chosen for select
      CHOSEN_PARAMS.width = '100%';
      $('#contacts_type_select').chosen(CHOSEN_PARAMS);
      
      
      // Button handlers
      $('#add_contact_modal_btn_cancel')
          .on('click', add_contact_form.hide);
      
      var readAndProcessAddContactModal = function (e) {
        e.preventDefault();
        
        var type_id = add_contact_form.$modal.find('select#contacts_type_select').val();
        var value   = add_contact_form.$modal.find('input#contacts_type_value').val();
        
        contacts_raw.push({
          value  : value,
          type_id: type_id
        });
        
        renderContactsBlock(contacts_raw);
        
        add_contact_form.hide();
        
        setContactsChangedStatus(true);
      };
      
      $('#add_contact_modal_btn_add').on('click', readAndProcessAddContactModal);
    };
    
    add_contact_form
        .setId('add_contact_modal')
        .isForm(true)
        .setHeader(translate('CONTACTS'))
        .setBody(rendered['modal_add'])
        .addButton(translate('CANCEL'), 'add_contact_modal_btn_cancel', 'default')
        .addButton(translate('ADD'), 'add_contact_modal_btn_add', 'primary')
        .show(setupAddContactModalForm);
    
  }
  
  function removeContact(id) {
    var contact = null;
    var index = -1;
    
    for (var i =0; i < contacts_raw.length; i++){
      if (+contacts_raw[i].id === +id){
        contact = contacts_raw[i];
        index = i;
        break;
      }
    }
    
    if (contact === null){
      console.log('Cant found contact by id', id, contacts_raw);
      return false;
    }
    
    var this_event_name = 'ContactsForm.remove_' + randomString(10);
    console.log(this_event_name);
    Events.once(this_event_name, function () {
      contacts_raw.splice(index, 1);
      renderContactsBlock(contacts_raw);
      setContactsChangedStatus(true);
    });
    
    showCommentsModal(translate('REMOVE') + '<br/>' + contact.name + ' : ' + contact.value + ' ?', '', {
      type : 'confirm',
      event: this_event_name
    });
    
  }
  
  function submitContacts(e) {
    e.preventDefault();
    
    var $sub_btn_icon = $sub_btn.find('span');
    
    $sub_btn.prop('disabled', true);
    $sub_btn_icon.attr('class', 'fa fa-spinner fa-pulse');
    
    var contacts_to_send = parseCurrentDisplayedContacts();
    
    var request = null;
    // Forming request
    if (CONTACTS_JSON.options.AID) {
      request = {
        'qindex'  : options.callback_index,
        'header'  : 2,
        'AID'     : options.AID,
        'subf'    : options.subf,
        'CONTACTS': JSON.stringify(contacts_to_send)
      };
    }
    else {
      // Forming request
      request = {
        'qindex'  : options.callback_index,
        'header'  : 2,
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
      
      if (object === null) return false;
      
      $response_span.text(object.message);
      
      if (object.status === 0) {
        setTimeout(function () {
          $response_span.text('');
        }, 3000);
        setContactsChangedStatus(false);
      }
      else {
        (new ATooltip()).displayError(object.message);
        return false;
      }
      
    });
    
  }
  
  function setContactsChangedStatus(boolean) {
    if (boolean) {
      if ($sub_btn.data('active') !== true) {
        $sub_btn.data('active', true);
        $sub_btn
            .fadeOut(300)
            .attr('class', 'btn btn-xs btn-warning')
            .fadeIn(300)
      }
    }
    else {
      $sub_btn.attr('class', 'btn btn-xs btn-primary disabled');
      $sub_btn.data('active', false);
    }
  }
  
  function translate(e) {
    return CONTACTS_LANG[e] || e;
  }
  
  // Cache DOM
  var $contacts_controls = $('#contacts_controls');
  var $contacts_wrapper  = $('#contacts_wrapper');
  
  var $add_btn = $contacts_controls.find('#contact_add');
  var $sub_btn = $contacts_controls.find('#contact_submit');
  
  var $response_span = $contacts_controls.find('#contacts_response');
  
  // Parse input JSON
  var contacts_raw = CONTACTS_JSON.contacts || [];
  var options      = CONTACTS_JSON.options;
  
  var contact_types = {};
  $.each(options.types, function (i, e) {
    contact_types[e.id] = e;
  });
  
  // Parse templates
  var contact_template    = $('#contact_template').html();
  var contacts_modal_body = $('#contacts_modal_body').html();
  Mustache.parse(contact_template);
  Mustache.parse(contacts_modal_body);
  
  var rendered = {};
  
  // If in reg wizard, we need to delete buttons and change form for inputs
  if (CONTACTS_JSON.options.in_reg_wizard === 1) {
    $add_btn.remove();
    $sub_btn.remove();
    
    $contacts_wrapper.addClass('reg_wizard');
    
    renderContactsBlock(contacts_raw);
    return false;
  }
  
  showDefaultTypesIfNotPresent(contacts_raw, options.types);
  
  renderContactsBlock(contacts_raw);
  
  // Attach handlers
  $add_btn.on('click', addNewContact);
  $sub_btn.on('click', submitContacts);
  
});
