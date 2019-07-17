'use strict';

function ContactChooser(admin_mode, contacts_list, type_select, value_wrapper) {
  var self = this;
  
  this.contacts_list  = contacts_list;
  this.$type_select   = type_select;
  this.$value_wrapper = value_wrapper;
  this.current_value  = null;
  this.in_edit_mode   = false;
  
  if (this.$type_select.length) {
    this.current_type = this.$type_select.val();
  }
  
  // Sort contacts by type_id
  this.updateContacts = function (contacts_list) {
    var contacts_by_type = {};
    for (var i = 0; i < contacts_list.length; i++) {
      var cont = contacts_list[i];
      if (typeof( contacts_by_type[cont.type_id]) === 'undefined' || !contacts_by_type[cont.type_id]) {
        contacts_by_type[cont.type_id] = [cont];
      }
      else {
        contacts_by_type[cont.type_id].push(cont);
      }
    }
    this.contacts_by_type = contacts_by_type;
  };
  
  this.findContactForTypeAndValue = function (type_id, value) {
    if (typeof(this.contacts_by_type[type_id]) === 'undefined') {
      return false
    }
    
    for (var i = 0; i < this.contacts_by_type[type_id].length; i++) {
      if (this.contacts_by_type[type_id][i].value === value) {
        return this.contacts_by_type[type_id][i];
      }
    }
    
    return false;
  };
  
  this.setValue = function (new_value) {
    this.current_value = new_value;
    
    if (!this.findContactForTypeAndValue(this.current_type, this.current_value)) {
      var new_contact = {type_id: this.current_type, value: this.current_value};
      
      if (typeof (this.contacts_by_type[this.current_type]) === 'undefined') {
        this.contacts_by_type[this.current_type] = [new_contact];
      }
      else {
        this.contacts_by_type[this.current_type].push(new_contact);
      }
    }
    
    this.updateValueView(this.current_type, this.current_value);
  };
  
  this.getType = function () {
    return this.$type_select.val();
  };
  
  this.changeType = function (new_type) {
    this.updateValueView(new_type);
  };
  
  this.updateValueView = function (type_id, value) {
    self.is_in_edit_mode = false;
    this.display         = new ContactValueView(this.contacts_by_type[type_id], type_id, value);
    this.display.insertViewTo(value_wrapper);
  };
  
  // Sort contacts by type_id
  this.updateContacts(this.contacts_list);
  
  this.$type_select.on('change', function () {
    self.current_type = self.$type_select.val();
    self.changeType(self.$type_select.val());
  });
  
  // Allow admin to change destination manually
  if (admin_mode) {
    $('button#MANUAL_EDIT_CONTACT_BTN').on('click', function (e) {
      cancelEvent(e);
      
      if (!self.is_in_edit_mode) {
        
        value_wrapper.html($('<input />', {
              name   : "DESTINATION",
              'class': 'form-control',
              value  : self.display.getValue()
            })
        );
        self.is_in_edit_mode = true;
      }
      else {
        self.updateValueView(self.getType());
        self.is_in_edit_mode = false;
      }
      
    });
    
  }
  
}

function ContactValueView(contacts_for_type, selected_type, value) {
  
  // Save args
  this.contacts_for_type = contacts_for_type;
  this.type              = selected_type;
  this.value             = value;
  
  this.getHumanizedContactValue = function (type_id, value) {
    switch (type_id) {
      case '6': // Telegram
      case '10': // Push
        return "OK";
        break;
      
      default:
        return value;
    }
  };
  
  this.getValue = function () {
    return this.value || null;
  };
  
  this.makeSelect = function (contacts_for_type_id) {
    var destination_select = jQuery('<select></select>', {
      'name' : 'DESTINATION',
      'class': 'form-control'
    });
    
    for (var i = 0; i < contacts_for_type_id.length; i++) {
      var cont = contacts_for_type_id[i];
      destination_select.append('<option value="' + cont.value + '">' + cont.value + '</option>');
    }
    
    return destination_select;
  };
  
  this.selectValue = function (select, value) {
    renewChosenValue(select, value);
  };
  
  this.makeAbsentContactText = function (type_id) {
    return '<p class="form-control-static">' + LANG["NO_CONTACTS_FOR_TYPE"] + '</p>';
    // TODO: registration link
  };
  
  this.makeText = function (type_id, value) {
    var humanized = this.getHumanizedContactValue(type_id, value);
    return '<input type="hidden" name="DESTINATION" value="' + value + '"/>'
        + '<p class="form-control-static">' + humanized + '</p>'
  };
  
  
  this.insertViewTo = function (jquery_element) {
    
    
    if (typeof(this.contacts_for_type) === 'undefined' || !this.contacts_for_type.length) {
      jquery_element.html(
          this.makeAbsentContactText(this.type)
      );
    }
    else if (this.contacts_for_type.length === 1) {
      /// Value can be absent in contacts
      if (!this.value) {
        this.value = this.contacts_for_type[0].value;
      }
      jquery_element.html(
          this.makeText(this.type, this.value)
      );
    }
    else {
      var select = this.makeSelect(this.contacts_for_type);
      
      jquery_element.html(select);
      select.chosen(CHOSEN_PARAMS);
      
      if (typeof (this.value) !== 'undefined') {
        this.selectValue(select, this.value)
      }
    }
  }
}

//
//function fillContactValue(type_id, value) {
//  // No contacts for type
//  if (typeof contacts_by_type[type_id] === 'undefined' || !value) {
//    destination_select_wrapper.html();
//  }
//  else if (contacts_by_type[type_id].length === 1) {
//    var cont            = contacts_by_type[type_id][0];
//    var humanized_value = getHumanizedContactValue(cont.type_id, cont.value);
//
//    destination_select_wrapper.html(
//        + '<p class="form-control-static">' + humanized_value + '</p>'
//    );
//
//  }
//  else {
//    fill_contacts_for_type(destination_select_wrapper, current_type);
//  }
//
//  return true;
//};
//
//
//function fill_contacts_for_type(destination_select_wrapper, type_id) {
//  console.log(type_id, contacts_by_type[type_id]);
//  submit.prop('disabled', false);
//
//  // No contacts
//  if (typeof contacts_by_type[type_id] === 'undefined') {
//    destination_select_wrapper.html('<p class="form-control-static">_{NO_CONTACTS_FOR_TYPE}_</p>');
//    submit.prop('disabled', true);
//    // TODO: registration link
//    return;
//  }
//
//  // Single contact
//  if (contacts_by_type[type_id].length === 1) {
//    fillContactValue(type_id, contacts_by_type[type_id][0].value);
//    return;
//  }
//};