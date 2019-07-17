<!DOCTYPE html>
<html>
<head>
  %REFRESH%
  <meta charset='utf-8'>
  <!-- Tell the browser to be responsive to screen width -->
  <meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>
  <meta http-equiv='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate,private, max-age=5'/>
  <meta http-equiv='Expires' CONTENT='-1'/>
  <meta http-equiv='Pragma' CONTENT='no-cache'/>
  <meta http-equiv='Content-Type' CONTENT='text/html; charset=%CHARSET%'/>
  <meta http-equiv='Content-Language' content='%CONTENT_LANGUAGE%'/>
  <meta name='Author' content='~AsmodeuS~'/>

  <title>%TITLE% %BREADCRUMB%</title>
  <link rel="shortcut icon" type="image/png" href="/favicon.ico">
  <!-- CSS -->
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/bootstrap.min.css'>
  <link rel='stylesheet' href='/styles/lte_adm/dist/css/AdminLTE.css'>

  <!-- Theme style -->
  <link rel='stylesheet' href='/styles/lte_adm/dist/css/skins/_all-skins.css'>

  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/currencies.css'>

  <link rel='stylesheet' href='/styles/lte_adm/plugins/pace/pace.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/lte_adm/plugins/datepicker/datepicker3.css'>
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/chosen.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/QBInfo.css'>

  <!-- Ionicons -->
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/font-awesome.min.css'>
  <link rel='stylesheet' href='/styles/default_adm/css/ionicons.min.css'>
  <!-- Pace style -->

  <!-- DataTables -->
  <link rel='stylesheet' type='text/css' href='/styles/lte_adm/plugins/datatables/dataTables.bootstrap.css'>
  <link rel='stylesheet' type='text/css' href='/styles/lte_adm/plugins/timepicker/bootstrap-timepicker.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/lte_adm/plugins/daterangepicker/daterangepicker.css'>
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/style.css'>

  <!-- Bootstrap -->
  <script src='/styles/default_adm/js/jquery.min.js'></script>
  <script src='/styles/default_adm/js/bootstrap.min.js'></script>

  <!-- ECMA6 functions -->
  <script src='/styles/default_adm/js/polyfill.js'></script>

  <!-- Cookies and LocalStorage from JavaScript -->
  <script src='/styles/default_adm/js/js.cookies.js'></script>
  <script src='/styles/default_adm/js/permanent_data.js'></script>

  <!-- temp -->
  <script src='/styles/default_adm/js/functions.js'></script>
  <script src='/styles/default_adm/js/functions-admin.js'></script>

  <!--Keyboard-->
  <script src='/styles/default_adm/js/keys.js'></script>

  <!-- Navigation bar saving show/hide state -->
  <script src='/styles/default_adm/js/navBarCollapse.js'></script>

  <!-- Custom <select> design -->
  <script src='/styles/default_adm/js/chosen.jquery.min.js'></script>

  <!--Javascript template engine-->
  <script src='/styles/default_adm/js/mustache.min.js'></script>

  <script src='/styles/default_adm/js/QBinfo.js'></script>

  <!--Event PubSub-->
  <script src='/styles/default_adm/js/events.js'></script>

  <!-- Modal popup windows management -->
  <script src='/styles/default_adm/js/modals.js'></script>

  <!-- AJAX Search scripts -->
  <script src='/styles/default_adm/js/search.js'></script>

  <script src='/styles/default_adm/js/messageChecker.js'></script>

  <script src='/styles/default_adm/js/msgs/jquery-ui.min.js'></script>

  <!-- date-range-picker -->
  <script src='/styles/lte_adm/plugins/moment/moment.min.js'></script>
  <script src='/styles/lte_adm/plugins/datepicker/bootstrap-datepicker.js'></script>
  <script src='/styles/lte_adm/plugins/pace/pace.js'></script>
  <script src='/styles/lte_adm/plugins/datatables/jquery.dataTables.min.js'></script>
  <script src='/styles/lte_adm/plugins/datatables/dataTables.bootstrap.min.js'></script>
  <script src='/styles/lte_adm/plugins/timepicker/bootstrap-timepicker.min.js'></script>
  <script src='/styles/lte_adm/plugins/daterangepicker/daterangepicker.js'></script>
  <!--<script src='/styles/lte_adm/plugins/slimScroll/jquery.slimscroll.min.js'></script>-->
  <!--<script src='/styles/lte_adm/plugins/input-mask/jquery.inputmask.js'></script>-->
  <!--<script src='/styles/lte_adm/plugins/input-mask/jquery.inputmask.date.extensions.js'></script>-->
  <!--<script src='/styles/lte_adm/plugins/input-mask/jquery.inputmask.extensions.js'></script>-->

  <script src='/styles/lte_adm/dist/js/app.js'></script>

  <script>
    var SELF_URL              = '$SELF_URL';
    var INDEX                 = '$index';
    var _COMMENTS_PLEASE      = '_{COMMENTS_PLEASE}_' || 'Comments please';
    document['WEBSOCKET_URL'] = '%WEBSOCKET_URL%';

    //CHOSEN INIT PARAMS
    var CHOSEN_PARAMS = {
      no_results_text      : '_{NOT_EXIST}_',
      allow_single_deselect: true,
      placeholder_text     : '--'
//      width                : '100%',
//      'min-width'                : '300px'
    };
    
    var DATERANGEPICKER_LOCALE = {
      separator       : '/',
      applyLabel      : '_{APPLY}_',
      cancelLabel     : '_{CANCEL}_',
      fromLabel       : '_{FROM}_',
      toLabel         : '_{TO}_',
      'Today'         : '_{TODAY}_' || 'Today',
      'Yesterday'     : '_{YESTERDAY}_' || 'Yesterday',
      'Last 7 Days'   : '_{LAST}_ 7 _{DAYS}_',
      'Last 30 Days'  : '_{LAST}_ 30 _{DAYS}_',
      'This Month'    : '_{CURENT}_ _{MONTH}_',
      'Last Month'    : '_{PREVIOUS}_ _{MONTH}_',
      customRangeLabel: '_{OTHER}_'
    };

    /*
    AdminLTEOptions = {
      //BoxRefresh Plugin

      //Bootstrap.js tooltip
      enableBSToppltip: true,

      sidebarPushMenu: true,

      navbarMenuSlimscroll: true,
      navbarMenuSlimscrollWidth: '3px', //The width of the scroll bar
    };
    */

    moment.locale('%CONTENT_LANGUAGE%');

    jQuery(function () {

//      jQuery('ul.sidebar-menu').slimScroll({
//        height: '500px',
//        width: 'auto'
//      });

      if (!'%FAVICO_DISABLED%' && typeof window['initFavicon'] !== 'undefined'){
        initFavicon();
      }

    });
  </script>


  <!-- Needs WEBSOKET_URL defined above -->
  <script src='/styles/default_adm/js/websocket_client.js'></script>


</head>
<body class='hold-transition
  sidebar-mini
  $admin->{SETTINGS}{SKIN}
  $admin->{SETTINGS}{FIXED_LAYOUT}
  $admin->{MENU_HIDDEN}
  %SIDEBAR_HIDDEN%
  $admin->{RIGHT_MENU_OPEN}'>
<div class='wrapper'>
  %CALLCENTER_MENU%

  <div class='modal fade' id='comments_add' tabindex='-1' role='dialog'>
    <form id='mForm'>
      <div class='modal-dialog modal-sm'>
        <div class='modal-content'>
          <div id='mHeader' class='modal-header alert-info'>
            <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
            <h4 id='mTitle' class='modal-title'>&nbsp;</h4>
          </div>
          <div class='modal-body'>
            <div class='row'>
              <input type='text' class='form-control' id='mInput' placeholder='_{COMMENTS}_'>
            </div>
          </div>
          <div class='modal-footer'>
            <button type='button' class='btn btn-default' data-dismiss='modal'>_{CANCEL}_</button>
            <button type='submit' class='btn btn-danger danger' id='mButton_ok'>_{EXECUTE}_!</button>
          </div>
        </div>
      </div>
    </form>
  </div>

  <!-- Modal search -->
  <div class='modal fade' tabindex='-1' id='PopupModal' role='dialog' aria-hidden='true'>
    <div class='modal-dialog'>
      <div id='modalContent' class='modal-content'></div>
    </div>
  </div>


  <!-- -->
  <!--This div is used to get row-highlight background color-->
  <div class='bg-success' style='display: none'></div>


  <!-- -->

