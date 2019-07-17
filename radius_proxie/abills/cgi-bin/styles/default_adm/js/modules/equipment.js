/**
 * Created by Anykey on 24.02.2016.
 *
 *   Javascript functions for Equipment/templates/equipment_model.tpl
 *
 */

$(function () {

  var portCounter = 0;

  var hasExtraPortsInput = $('#HAS_EXTRA_PORTS');
  var $form = $('#EQUIPMENT_MODEL_INFO_FORM');

  var $rowsNumInput = $form.find('#ROWS_COUNT_id');

  //cache DOM
  var $wrapper = $('#extraPortWrapper');
  var $controls = $('#extraPortControls');

  var $addBtn = $controls.find('#addPortBtn');
  var $remBtn = $controls.find('#removePortBtn');

  var $templateSelectWrapper = $wrapper.find('#templateWrapper');
  var labelText = $templateSelectWrapper.find('label').text();
  var $portTypes = $templateSelectWrapper.find('option');

  var portTypesHTML = "";
  $.each($portTypes, function (i, option) {
    portTypesHTML += option.outerHTML;
  });

  $templateSelectWrapper.remove();

  //bind Events
  $addBtn.on('click', function (e) {
    e.preventDefault();
    addNewPortSelect();
  });

  $remBtn.on('click', function (e) {
    e.preventDefault();
    removeLastPort();
  });

  $form.on('submit', function () {
    if (portCounter > 0) {
      hasExtraPortsInput.val(portCounter);
    }
  });

  $rowsNumInput.on('change', function(){
    updateMaxRowsValue($(this).val())
  });

  $(function(){
    updateMaxRowsValue($rowsNumInput.val());
  });

  function updateMaxRowsValue(number){
    console.log(number);
    if (typeof(number) !== 'undefined' && number > 0){
      $('.extraPortRow').attr('max', number);
    }
  }

  fillExistingPorts($('#extraPortsJson').val());

  function addNewPortSelect() {
    $wrapper.append(getNewSelect(++portCounter));

    function getNewSelect(number) {
      var $selectDiv = $('<div class="form-group" id="EXTRA_PORT_' + number + '">' +
        '<label class="control-label col-md-5">' + labelText + ' ' + number + '</label>' +
        '<div class="col-md-4">' +
        '<select class="form-control" name="EXTRA_PORT_' + number + '"></select>' +
        '</div>' +
        '<div class="col-md-3">' +
        '<input type="number" min="1" value="1" class="form-control extraPortRow" name="EXTRA_PORT_ROW_' + number + '">' +
        '</div>' +
        '</div>');

      $selectDiv.find('select').html(portTypesHTML);
      $selectDiv.find('select').chosen(CHOSEN_PARAMS);

      return $selectDiv;
    }
  }

  function removeLastPort() {
    $('#EXTRA_PORT_' + portCounter--).remove();
  }

  function fillExistingPorts(jsonString) {
    try {
      if (typeof(jsonString) !== 'undefined' && jsonString.length > 0) {
        var port_rows = JSON.parse(jsonString);
        $.each(port_rows, function (i, row) {
          appendRow(i, row);
        })
      }

    } catch (Error) {
      console.log(jsonString);
      alert("[ Equipment.js ] Error parsing existing ports : " + Error);
    }

    function appendRow(rowNumber, row) {
      for (var portNumber in row) {
        if (!row.hasOwnProperty(portNumber)) continue;

        var portType = row[portNumber];
        $wrapper.append(getFilledExtraPortGroup(rowNumber, portNumber, portType));

        //renewChosenValue($('#EXTRA_PORT_' + portNumber), portType);

        portCounter++;
      }
    }

    function getFilledExtraPortGroup(rowNumber, number, portType) {

      var $selectDiv = $('<div class="form-group" id="EXTRA_PORT_' + number + '">' +
        '<label class="control-label col-md-5">' + labelText + ' ' + number + '</label>' +
        '<div class="col-md-4">' +
        '<select class="form-control" name="EXTRA_PORT_' + number + '"></select>' +
        '</div>' +
        '<div class="col-md-3">' +
        '<input type="number" min="1" value="' + parseInt(+rowNumber + 1) + '" class="form-control extraPortRow" name="EXTRA_PORT_ROW_' + number + '">' +
        '</div>' +
        '</div>');

      var $select = $selectDiv.find('select');

      $select.html(portTypesHTML);

      var optionToSelect = $select.children('option')[portType];
      $(optionToSelect).prop('selected', true);

      $select.chosen(CHOSEN_PARAMS);

      return $selectDiv;
    }
  }
});

