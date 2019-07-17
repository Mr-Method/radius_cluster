<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>

  <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
  <meta HTTP-EQUIV='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate,private, max-age=5'/>
  <meta HTTP-EQUIV='Expires' CONTENT='-1'/>
  <meta HTTP-EQUIV='Pragma' CONTENT='no-cache'/>
  <meta HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=%CHARSET%'/>
  <meta HTTP-EQUIV='Content-Language' content='%CONTENT_LANGUAGE%'/>
  <meta name='Author' content='~AsmodeuS~'/>

  <title>%TITLE%</title>
  <!-- Bootstrap -->
  <!--<link href='/styles/default_adm/css/bootstrap.min.css' rel='stylesheet'>-->
  <link rel="stylesheet" href="/styles/default_adm/css/bootstrap.min.css">
  <link rel="stylesheet" href="/styles/default_adm/css/ionicons.min.css">
  <link rel="stylesheet" href="/styles/%HTML_STYLE%/dist/css/AdminLTE.css">
  <link rel="stylesheet" href="/styles/%HTML_STYLE%/dist/css/skins/_all-skins.css">
  <link rel="stylesheet" href="/styles/%HTML_STYLE%/plugins/pace/pace.min.css">
  <link rel="stylesheet" href="/styles/default_adm/css/font-awesome.min.css">
  <link rel='stylesheet' href='/styles/default_adm/css/chosen.min.css'>
  <link rel='stylesheet' href='/styles/default_adm/css/QBInfo.css'>

  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/currencies.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/datepicker/datepicker3.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/datatables/dataTables.bootstrap.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/timepicker/bootstrap-timepicker.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/daterangepicker/daterangepicker.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/datetimepicker/datetimepicker.min.css'>

  <link href='/styles/default_adm/css/client.css' rel='stylesheet'>


  <!-- Cookies from JavaScript -->
  <script src='/styles/default_adm/js/jquery.min.js'></script>
  <!--[if lt IE 9]>
  <script src='/styles/default_adm/js/jquery-1.11.3.min.js' type='text/javascript'></script>
  <![endif]-->
  <script src='/styles/default_adm/js/bootstrap.min.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/pace/pace.js'></script>

  <script src='/styles/default_adm/js/js.cookies.js'></script>
  <script src='/styles/default_adm/js/permanent_data.js'></script>

  <script src='/styles/default_adm/js/functions.js'></script>
  <script src='/styles/default_adm/js/functions-client.js'></script>

  <script src='/styles/default_adm/js/keys.js'></script>
  <script src='/styles/default_adm/js/QBinfo.js'></script>

  <script src='/styles/default_adm/js/events.js'></script>
  <script src='/styles/default_adm/js/messageChecker.js'></script>

  <script src='/styles/default_adm/js/navBarCollapse.js' language='javascript'></script>

  <script src='/styles/default_adm/js/chosen.jquery.min.js'></script>


  <!-- Modal popup windows management -->
  <script src='/styles/default_adm/js/modals.js'></script>

  <script src='/styles/%HTML_STYLE%/plugins/moment/moment.min.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/datatables/jquery.dataTables.min.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/datatables/dataTables.bootstrap.min.js'></script>
  <!--<script src='/styles/%HTML_STYLE%/plugins/datatables/dataTables.bootstrap.min.js'></script>-->
  <script src='/styles/%HTML_STYLE%/plugins/daterangepicker/daterangepicker.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/datetimepicker/datetimepicker.min.js'></script>

  <script src="/styles/%HTML_STYLE%/plugins/datepicker/bootstrap-datepicker.js"></script>
  <script src="/styles/%HTML_STYLE%/plugins/timepicker/bootstrap-timepicker.min.js"></script>
  <script src='/styles/%HTML_STYLE%/plugins/datepicker/locales/bootstrap-datepicker.%CONTENT_LANGUAGE%.js'></script>
  <script>
    window['IS_ADMIN_INTERFACE'] = false;
    window['IS_CLIENT_INTERFACE'] = true;

    var SELF_URL  = '$SELF_URL';
    var SID = '$sid';
    var NO_DESIGN = '$FORM{NO_DESIGN}';

    var _COMMENTS_PLEASE = '_{COMMENTS_PLEASE}_' || 'Comment please';
    var CHOSEN_PARAMS    = {
      no_results_text      : '_{NOT_EXIST}_',
      allow_single_deselect: true,
      placeholder_text     : '--'
    };

      var EVENT_PARAMS = {
        portal  : 'client',
        link    : "/index.cgi?qindex=100002",
        disabled: ('$conf{USER_PORTAL_EVENTS_DISABLED}' === '1'),
        interval: 30000
      };

    jQuery(function () {
      jQuery('select:not(#type)').chosen(CHOSEN_PARAMS);
    });

    var CONTENT_LANGUAGE = '%CONTENT_LANGUAGE%';

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
  </script>
  <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
  <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
  <!--[if lt IE 9]>
  <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
  <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
  <![endif]-->
  <!--[if (lt IE 8) & (!IEMobile)]>
  <p class="chromeframe">Sorry, our site supports Internet Explorer starting from version 9. You need to <a href="http://browsehappy.com/">upgrade your browser</a> or <a target='_blank' href='https://www.google.ru/chrome/browser/desktop/index.html'>install Google Chrome</a> to use the site.</p>
  <![endif]-->
  <link rel='manifest' href='/manifest.json'>
</head>