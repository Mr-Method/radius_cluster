<!-- Main container -->
<script src='/styles/default_adm/js/jquery.marcopolo.min.js'></script>


<!-- Main Header -->
<header class='main-header'>

  <!-- Logo -->
  <a href='index.cgi' class='logo'>
    <!-- mini logo for sidebar mini 50x50 pixels -->
    <span class='logo-mini'><b><span style='color: red;'>A</span></b></span>
    <!-- logo for regular state and mobile devices -->
    <span class='logo-lg'><b><span style='color: red;'>A</span></b>BillS</span>
  </a>

  <!-- Header Navbar -->
  <nav class='navbar navbar-static-top %HEADER_FIXED_CLASS% ' role='navigation'>
    <!-- Sidebar toggle button-->
    <a href='#' class='sidebar-toggle' data-toggle='offcanvas' role='button' title='_{PRIMARY}_ _{MENU}_'>
      <span class='sr-only'>Toggle navigation</span>
    </a>
    <a href='$SELF_URL' class='header-btn-link visible-xs' role='button'>
      <span class='glyphicon glyphicon-home'></span>
    </a>
    <!-- Navbar Right Menu -->
    <div class='navbar-custom-menu'>
      <ul class='nav navbar-nav'>
        %GLOBAL_CHAT%
        <!-- Messages: style can be found in dropdown.less-->
        <li class='dropdown messages-menu hidden' id='messages-menu' data-meta='{%ADMIN_MSGS%}'>
          <!-- Menu toggle button -->
          <a href='#' class='dropdown-toggle' data-toggle='dropdown' title='_{MESSAGES}_ _{ALL}_'>
            <i class='fa fa-envelope-o'></i>
            <span id='badge_messages-menu' class='icon-label label label-danger hidden'></span>
            <span id='badge2_messages-menu' class='icon-label label2 label-warning hidden'></span>
          </a>
          <ul class='dropdown-menu' id='dropdown_messages-menu'>
            <li class='header' id='header_messages-menu'>
              <div class='row'>
                <div class='col-md-8 header_text'></div>
                <!-- Search-Button of Messages Dropdown menu -->
                <div class='col-md-2' style='padding: 0px'>
                  <div class='pull-right'>
                    <form action='$SELF_URL' class='form-horizontal'>
                      <div class='btn btn-xs btn-primary ' align='right' id='dropdown_search_button'>
                        <i class='fa fa-search' role='button'></i>
                      </div>
                    </form>
                  </div>
                </div>
                <div class='col-md-2'>
                  <button class='btn btn-xs btn-success header_refresh'>
                    <i class='fa fa-refresh' role='button'></i>
                  </button>
                </div>
              </div>
            </li>
            <!-- Search-Form of Messages Dropdown menu -->
            <li id='drop_search_form' style='display: none'>
              <form action='$SELF_URL' class='form-horizontal'>
                <input type='hidden' name='get_index' value='msgs_admin'>
                <input type='hidden' name='full' value='1'>
                <div class='input-group input-group-sm' style='padding: 2px 10px'>
                  <input class='form-control' id='search_input' name='chg' type='text'>
                  <span id='search_addon' class='input-group-btn'>
                  <button name='search' class='btn btn-default' type='submit'>
                    <i class='fa fa-search'></i>
                  </button>
                </span>
                </div>
              </form>
            </li>
            <li>
              <!-- Inner Menu: contains the notifications -->
              <ul class='menu' id='menu_messages-menu'>
                <li class='text-center'><i class='fa fa-spinner fa-pulse fa-2x'></i></li>
              </ul>
            </li>
            <li class='footer' id='footer_messages-menu'>
              <a href='$SELF_URL?get_index=msgs_admin&full=1'>$lang{SHOW} $lang{ALL}</a>
            </li>
          </ul>
        </li>
        <!--/.messages-menu-->
        <!-- Messages: style can be found in dropdown.less-->
        <li class='dropdown messages-menu hidden' id='responsible-menu' data-meta='{%ADMIN_RESPONSIBLE%}'>
          <!-- Menu toggle button -->
          <a href='#' class='dropdown-toggle' data-toggle='dropdown' title='_{MESSAGES}_ _{RESPOSIBLE}_'>
            <i class='fa fa-flag-o'></i>
            <span id='badge_responsible-menu' class='icon-label label label-danger hidden'></span>
            <span id='badge2_responsible-menu' class='icon-label label2 label-warning hidden'></span>
          </a>
          <ul class='dropdown-menu' id='dropdown_responsible-menu'>
            <li class='header' id='header_responsible-menu'>
              <div class='row'>
                <div class='col-md-10 header_text'></div>
                <div class='col-md-2'>
                  <button class='btn btn-xs btn-success header_refresh'>
                    <i class='fa fa-refresh' role='button'></i>
                  </button>
                </div>
              </div>
            </li>
            <li>
              <!-- Inner Menu: contains the notifications -->
              <ul class='menu' id='menu_responsible-menu'>
                <li class='text-center'><i class='fa fa-spinner fa-pulse fa-2x'></i></li>
              </ul>
            </li>
            <li class='footer' id='footer_responsible-menu'>
              <a href='$SELF_URL?get_index=msgs_admin&STATE=0&RESPOSIBLE=%AID%&full=1'>$lang{SHOW} $lang{ALL}</a>
            </li>
          </ul>
        </li>
        <!--/.responsible-menu-->

        <!-- Messages: style can be found in dropdown.less-->
        <li class='dropdown messages-menu hidden' id='events-menu' data-meta='{
          "UPDATE" : "?get_index=events_notice&header=2&AJAX=1",
          "AFTER" : 30,"REFRESH" : 30, "ENABLED" : "%EVENTS_ENABLED%"
          }'>
          <!-- Events menu toggle button -->
          <a href='#' class='dropdown-toggle' data-toggle='dropdown' title='_{EVENTS}_'>
            <i class='fa fa-bell-o'></i>
            <span id='badge_events-menu' class='icon-label label label-danger hidden'></span>
            <span id='badge2_events-menu' class='icon-label label2 label-warning hidden'></span>
          </a>
          <ul class='dropdown-menu' id='dropdown_events-menu'>
            <li class='header' id='header_events-menu'>
              <div class='row'>
                <div class='col-md-10 header_text'></div>
                <div class='col-md-2'>
                  <button class='btn btn-xs btn-success header_refresh'>
                    <i class='fa fa-refresh' role='button'></i>
                  </button>
                </div>
              </div>
            </li>
            <li>
              <!-- Inner Menu: contains the notifications -->
              <ul class='menu' id='menu_events-menu'>
                <li class='text-center'><i class='fa fa-spinner fa-pulse fa-2x'></i></li>
              </ul>
            </li>
            <li class='footer' id='footer_events-menu'>
              <a href='$SELF_URL?get_index=events_profile&full=1'>$lang{SHOW} $lang{ALL}</a>
            </li>
          </ul>
        </li>
        <!--/.events-menu-->


        <!--Search Menu-->
        <li class='dropdown search-menu'>
          <form class='no-live-select UNIVERSAL_SEARCH_FORM' id='SMALL_SEARCH_FORM' action='$SELF_URL'>
            <input type='hidden' name='index' value='7'>
            <input type='hidden' name='search' value='1'>
          </form>
          <a href='#' class='dropdown-toggle' data-toggle='dropdown'>
            <i class='fa fa-search'></i>
          </a>
          <ul class='dropdown-menu' onClick='cancelEvent(event)'>
            <li>
              <div class='search_selector'>
                %SEL_TYPE_SM%
              </div>
            </li>
            <li>
              <div class='input-group margin'>
                <input type='text' name='LOGIN' class='form-control UNIVERSAL_SEARCH'
                       placeholder='_{SEARCH}_...' form='SMALL_SEARCH_FORM'>
                <span class='input-group-btn'>
                    <button type='submit' name='search' class='btn btn-flat'
                            onclick=jQuery('form#SMALL_SEARCH_FORM').submit()>
                      <i class='fa fa-search'></i>
                    </button>
                  </span>
              </div>
            </li>
          </ul>
        </li>

        <li class='search_form'>
          <form class='no-live-select UNIVERSAL_SEARCH_FORM' action='$SELF_URL'>
            <input type='hidden' name='index' value='7'>
            <input type='hidden' name='search' value='1'>
            <div class='search_selector'>%SEL_TYPE%</div>
            <div class='search_input'>
              <div class='input-group margin search'>
                <input name='LOGIN' type='text' placeholder='_{SEARCH}_...' required='required'
                       class='form-control input-sm UNIVERSAL_SEARCH'/>
                <span class='input-group-btn'>
                  <button type='submit' id='search-btn' class='btn btn-sm btn-flat'>
                    <i class='fa fa-search'></i>
                  </button>
                </span>
              </div>
            </div>
          </form>
        </li>

        <!-- Wiki link -->
        <li id='wiki-link' class='hidden-xs'>
          <a href='http://abills.net.ua/wiki/doku.php/abills:docs:manual:admin:%FUNCTION_NAME%'
             target='_blank' rel='noopener' title='ABillS Wiki'>
            <i class='fa fa-question'></i>
          </a>
        </li>

        <li class='hidden-xs'>
          <a href='#' title='QRCode'
             onclick='showImgInModal(\"$SELF_URL?$ENV{QUERY_STRING}&amp;qrcode=1&amp;qindex=100000&amp;name=qr_code\")'>
            <i class='fa fa-qrcode'></i>
          </a>
        </li>

        <!-- Control Sidebar Toggle Button -->
        <li id='control-sidebar-open-btn'>
          <a href='#' data-toggle='control-sidebar' title='_{EXTRA}_ _{MENU}_'><i class='fa fa-gears'></i></a>
        </li>

      </ul>
    </div>
  </nav>
</header>
<script>
  jQuery(function () {
    var EVENT_PARAMS = {
      portal        : 'admin',
      link          : '/admin/index.cgi?get_index=form_events&even_show=1&AID=$admin->{AID}',
      soundsDisabled: ('$admin->{SETTINGS}{NO_EVENT_SOUND}' == '1'),
      disabled      : ('$admin->{SETTINGS}{NO_EVENT}' == '1'),
      interval      : parseInt('$conf{EVENTS_REFRESH_INTERVAL}') || 30000
    };

    AMessageChecker.start(EVENT_PARAMS);
  });
</script>
<!-- END header -->
%TECHWORK%
<!-- Left side column. contains the logo and sidebar -->
<aside class='main-sidebar'>

  <!-- sidebar: style can be found in sidebar.less -->
  <section class='sidebar dropdown'>

    <!-- Sidebar user panel (optional) -->
    <div class='user-panel'>
      <div class='pull-left image'>
        <a href='$SELF_URL?index=9'>
          <img src='/styles/lte_adm/dist/img/avatar5.png' class='img-circle' alt='User Image'>
        </a>
      </div>
      <div class='pull-left info'>
        <p>$admin->{A_FIO}</p>
        <!-- Status -->
        <a href='#' id='admin-status' data-tooltip='%ONLINE_USERS%'>Online&nbsp;<span class='label label-success'>%ONLINE_COUNT%</span></a>
      </div>
    </div>
    <!-- Sidebar Menu -->
    %MENU%
    <!-- /.sidebar-menu -->
  </section>
  <!-- /.sidebar -->
</aside>

<!-- Content Wrapper. Contains page content -->
<div class='content-wrapper' id='content-wrapper'>
  <script>
    if (jQuery('nav.navbar.navbar-static-top.navbar-fixed-top').length) {
      jQuery('div.content-wrapper').css({'padding-top': '50px'});
    }
  </script>
  <!-- Content Header (Page header) -->
  <section class='content-header'>
    %BREADCRUMB%
  </section>

  <!-- Main content -->
  <section class='content' id='main-content' align='center'>

    <!-- Your Page Content Here -->
