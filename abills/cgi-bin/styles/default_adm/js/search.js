/**
 * Created by Anykey
 * Version 0.15
 *
 *  Uses dynamicForms.js;
 *
 */
'use strict';
if (typeof(window['getMultiSimpleRow']) === 'undefined')
  $.getScript('/styles/default_adm/js/dynamicForms.js');

/*Global section*/
$('#clear_results').click(function (event) {
  $(this).parents('.input-group').find('input').attr('value', '');
});


function fill_template_popup(buttonNumber) {
  fill_template_based(modalsArray[buttonNumber]);
}

function fill_array_popup(buttonNumber) {
  fill_one_row_array_based(modalsSearchArray[buttonNumber]);
}

/**
 * Makes one row form for going to specified index with a GET parameter;
 * @param params
 */
function fill_one_row_array_based(params) {
  var label         = params[0];
  var name          = params[1];
  var index         = params[2];
  var url           = params[3];
  var custom_params = params[4] || '';
  var id            = 'popup_' + name;
  
  var data =
          "<div class='modal-content'>" +
          "<div class='modal-header'>" +
          "<button type='button' class='close' data-dismiss='modal' aria-label='Close'><span aria-hidden='true'>&times;</span></button>" +
          "<div class='modal-title'>Search for <b>" + name + "</b></div>" +
          "</div>" +
          "<div class='modal-body form-horizontal'>" +
          getSimpleRow(name, id, label) +
          "</div>" +
          "<div class='modal-footer'>" +
          "<a id='btn_popup_" + name + "' class='btn btn-primary' href='';>" + "Go</a>" +
          "</div>" +
          "</div>";
  
  aModal.clear()
      .setRawMode(true)
      .setBody(data)
      .show(function () {
        $('#' + id).on('change', function () {
          $('#btn_popup_' + name).attr('href', href(url, index, name, custom_params));
        });
      })
  
}

/**
 * fill Array based multi-row search popup window
 */
function fill_array_based(params) {
  var modalData = get_in_search_form(getMultiSimpleRow(params));
  loadDataToModal(modalData);
}

function fill_array_based_search(params, stringCSV_URL) {
  var modalData = get_in_search_form(getMultiSimpleRow(params), stringCSV_URL);
  loadDataToModal(modalData);
}

/**
 * get some variables values from DOM input with specified name
 *
 * $("input[name|=SELECTOR]").val();
 * @param strInputName
 */
function get_input_val(strInputName) {
  return $("input[name|=" + strInputName + "]").val();
}

function setup_search_form(popup_name) {
  // Set up inner window logic
  var $search_button = $('button#search');
  var have_results   = $('.clickSearchResult').length > 0;
  
  if ($search_button.length) {
    $search_button.on('click', function () {
      getDataURL(formURL, function () {
        make_choosable_tr(popup_name);
      });
    });
  }
  
  if (have_results) {
    make_choosable_tr(popup_name);
  }
  
  if (typeof (should_open_results_tab) !== 'undefined' && should_open_results_tab === '1') {
    enableResult_Pill();
  }
  console.log('setuop');
}

function fill_template_based(template_params) {
  var formURL           = template_params[0];
  var popup_name        = template_params[1];
  var parent_input_name = template_params[2];
  var searchString      = template_params[3];
  var window_type       = template_params[4];
  
  if (parent_input_name != '') {
    searchString += "&" + parent_input_name + "=" + get_input_val(parent_input_name);
  }
  
  console.log('search_string : \'' + searchString + "\'");
  
  if (window_type == 'choose') {
    loadRawToModal(formURL + '?' + searchString,
        function () {
          make_choosable_td(popup_name);
          bind_click_search_result(popup_name);
        });
    
    setup_search_form(popup_name);
  }
  
  
  if (window_type == 'search') {
    loadRawToModal(formURL + '?' + searchString, function(){
      setup_search_form(popup_name)
    });
  }
}

function make_choosable_td(popup_name) {
  $('td').on('click', function () {
    console.log('td_click');
    $("input[name|='" + popup_name + "']").val($(this).text());
    $("input[name|='" + popup_name + "1']").val($(this).text());
    aModal.hide();
  });
}

function make_choosable_tr(popup_name) {
  
  if (!popup_name){
    console.warn('Wrong popup_name', popup_name);
    return false;
  }
  
  $('tr').on('click', function () {
    var $clickSearchResult =  $(this).find('.clickSearchResult');
    
    // Looking for id in first column of row
    var id = $(this).find('td').first().text();
    
    //Looking for name in attribute or inner text
    var name = $clickSearchResult.attr('name') || $clickSearchResult.text() || id;
    
    $("input[name|='" + popup_name + "']").val(id);
    $("input[name|='" + popup_name + "1']").val(name);
    aModal.hide();
  });
}

function bind_click_search_result(popup_name) {
  $('.clickSearchResult').on('click', function (event) {
    event.stopPropagation();
    fill_search_results(popup_name, $(this).attr('value'));
    aModal.hide();
  });
  console.log('clickSearch');
}

function fill_search_results(popup_name, value) {
  console.log(popup_name);
  $("input[name|='" + popup_name + "']").val(value);
  $("input[name|='" + popup_name + "1']").val(value);
  aModal.hide();
  $('#modalContent').html('');
}

function get_in_search_form(formContent, formSearchURL) {
  var str_func_close = '$("#PopupModal").hide();';
  
  var ddata = '';
  ddata += "<div class='modal-content'>";
  ddata += "  <div class='modal-header'>";
  ddata += "    <div class='row'>";
  ddata += "      <div class='hidden-xs col-sm-4 col-md-4 col-lg-4'></div>";
  ddata += "      <div class='hidden-xs col-md-4'>";
  ddata += "        <div class='text-centered'>";
  ddata += "          <input type='button' class='btn' data-toggle='dropdown' onclick='enableSearch_Pill();' value='Search' />";
  ddata += "          <input type='button' class='btn' data-toggle='dropdown' onclick='enableResult_Pill();' value='Result' />";
  ddata += "        </div>";
  ddata += "      </div>";
  ddata += "      <div class='hidden-xs col-sm-3 col-md-3 col-lg-3'></div>";
  ddata += "      <div class='col-md-1 col-xs-1 col-lg-1 col-sm-1 pull-right'>";
  ddata += "        <button type='button' class='close' onclick='" + str_func_close + "'>";
  ddata += "          <span aria-hidden='true'>&times;</span>";
  ddata += "        </button>";
  ddata += "      </div>";
  ddata += "    </div>";
  ddata += "   </div>";
  ddata += " <div class='modal-body'>";
  ddata += "<div id='search_pill' class='dropdown-toggle'>";
  ddata += '<form id="form-search" name="frmSearch" class="form-horizontal">';
  ddata += getWrappedInForm('frmSearch', 'form-horizontal', formContent);
  ddata += "</form>";
  ddata += "</div>";
  ddata += "<div id='result_pill' class='dropdown-toggle hidden'>";
  ddata += "<h1 class='text-centered'>Please search before trying get result</h1>";
  ddata += "</div>";
  ddata += " </div>";
  ddata += "  <div class='modal-footer'>";
  ddata += getGetDataURLBtn(formSearchURL);
  ddata += "  </div>";
  ddata += "</div>";
  
  return ddata;
}

/**
 *  function forms GET request and returns reply in modal #Result_pill;
 */
function getDataURL(formURL, callback) {
  
  var request_string = $('#form-search').serialize();
  console.log(request_string);
  $.get(
      formURL, request_string,
      function (data) {
        enableResult_Pill();
        $('#result_pill').empty().append(data);
        
        if (callback) callback();
      }
  );
}

function href(url, index, name, custom_params) {
  var value   = $('#popup_' + name).val();
  var request = "?" + custom_params + "&index=" + index + "&" + name + "=" + value;
  return url + request;
}

function hrefIndex(url, index) {
  return url + "?index=" + index;
}

function hrefValue(url, index, name, value) {
  return hrefIndex(url, index) + "&" + name + "=" + get_input_val(name);
}

function replace(url) {
  location.replace(url);
}

function getGetDataURLBtn() {
  return "<button class='btn btn-primary form-control' onclick='getDataURL()' > Search </button>"
}


//buttons
function enableSearch_Pill() {
  if ($('#search_pill').hasClass('hidden')) {
    $('#search_pill').removeClass('hidden');
    $('#result_pill').addClass('hidden');
    $('button#search').removeClass('hidden');
  }
}

function enableResult_Pill() {
  if ($('#result_pill').hasClass('hidden')) {
    $('#search_pill').addClass('hidden');
    $('#result_pill').removeClass('hidden');
    $('button#search').addClass('hidden');
  }
}
