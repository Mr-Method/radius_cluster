/**
 * Created by Anykey on 20.08.2015.
 *
 * Functions that are used in Uportal v5
 */
'use strict';

var CLIENT_INTERFACE = 1;

/**
 * Set's predefined icons for menu items
 *
 * Just add new id and glyphicon to decorate new menu element
 */
function setIcons() {
  
  var menu_icons = {
    form_info                    : 'glyphicon glyphicon-user',
    form_payments                : 'glyphicon glyphicon-euro',
    form_finance                 : 'glyphicon glyphicon-euro',
    dv_user_info                 : 'glyphicon glyphicon-globe',
    docs_invoices_list           : 'glyphicon glyphicon-briefcase',
    msgs_user                    : 'glyphicon glyphicon-comment',
    cards_user_payment           : 'glyphicon glyphicon-credit-card',
    logout                       : 'glyphicon glyphicon-log-out',
    voip_user_info               : 'glyphicon glyphicon-earphone',
    ureports_user_info           : 'glyphicon glyphicon-file',
    iptv_user_info               : 'glyphicon glyphicon-sound-dolby',
    abon_client                  : 'glyphicon glyphicon-list',
    form_passwd                  : 'glyphicon glyphicon-lock',
    ipn_user_activate            : 'glyphicon glyphicon-road',
    bonus_service_discount_client: 'glyphicon glyphicon-tower',
    bonus_user                   : 'glyphicon glyphicon-tower',
    mail_users_list              : 'glyphicon glyphicon-envelope',
    poll_user                    : 'glyphicon glyphicon-stats',
    megogo_user_interface        : 'fa fa-maxcdn',
    o_user                       : 'glyphicon glyphicon-book',
    sharing_user_main            : 'fa fa-share',
    cams_client_main             : 'glyphicon glyphicon-facetime-video'
  };
  
  var $sidebar = $('ul.sidebar-menu').children('li');
  var $menu_items = $sidebar.children('a');
  
  $.each($menu_items, function (i, entry) {
    
    var $entry = $(entry);
    var icon = (typeof (menu_icons[entry.id]) !== 'undefined')
        ? menu_icons[entry.id]
        : 'fa fa-circle';
  
    $entry.html('<i class="' + icon + '"></i><span>' +  $entry.html() + '</span>');
    
  });
  
  // Load custom icons
  $.getJSON('/images/client_menu_icons.js', function(custom_icons){
    
    $.each(Object.keys(custom_icons), function(i, id){
      var $a = $sidebar.find('a#' + id);
    
      // Removes default icon
      $a.find('.fa.fa-circle').remove();
    
      // Inserts icon <span> saving .chevron-left if have one
      $a.html('<i class="' + custom_icons[id] + '"></i><span>' +  $a.html() + '</span>');
    });
    
  });
}

function set_referrer() {
  document.getElementById('REFERRER').value = location.href;
}

function selectLanguage(){
  var sLanguage = jQuery('#language').val() || '';
  var sLocation = document['SELF_URL'] + '?'
      + (document['DOMAIN_ID'] ? '?DOMAIN_ID=' + document['DOMAIN_ID'] : '')
      + '&language=' + sLanguage;
  location.replace(sLocation);
}

function set_referrer() {
  document.getElementById('REFERER').value = location.href;
}

$(setIcons);


