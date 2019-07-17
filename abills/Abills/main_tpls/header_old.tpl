<!-- Main container -->
<script src='/styles/default_adm/js/jquery.marcopolo.min.js'></script>

<nav class='navbar navbar-inverse navbar-fixed-top hidden-print' role='navigation'>
        <div id='toggler'>
            <a class='navbar-brand' href='#' onclick='toggleNavBar()'>
                <span class='sr-only'>Toggle navigation</span>
                <h4>
                    <span class='glyphicon glyphicon-th-list'></span>&nbsp;
                </h4>
            </a>
        </div>
        <div role='banner' id='navbar' class='navbar-collapse collapse' aria-expanded='false' aria-controls='navbar'>
            <div class='row hidden-xs'>
                <div class='navbar-left brand'>

                    <div id='brand'>
                        <a class='navbar-brand brand' href='index.cgi'>
                            <h4>
                                <span style='color: red;'>A</span>BillS
                            </h4>
                        </a>
                    </div>
                    <div id='status'>
                        <ul class='nav nav-pills'>
                            <li><p class='navbar-text'>%DATE% %TIME%</p></li>
                            <li><p class='navbar-text'>
                                <span class='glyphicon glyphicon-user'></span>
                                <a class='text-danger' href='$SELF_URL?index=50'>$admin->{A_LOGIN}
                                </a>header.tpl
                                <abbr title='%ONLINE_USERS%'>
                                    <a class='text-danger' href='$SELF_URL?index=50'
                                       title='%ONLINE_USERS%'>%ONLINE_COUNT%
                                    </a>
                                </abbr>
                            </p>
                            </li>
                        </ul>
                    </div>
                </div>
                <div class='navbar-right'>
                    <form class='navbar-form no-live-select' id='UNIVERSAL_SEARCH_FORM' action='$SELF_URL'>
                        <input type='hidden' name='index' value='7'>
                        <input type='hidden' name='search' value='1'>
                        %SEL_TYPE%

                        <input class='form-control input-sm UNIVERSAL_SEARCH' required='required' type='text' name='LOGIN' value=''
                               id='UNIVERSAL_SEARCH'
                               placeholder='_{SEARCH}_'>

                        <button class='btn btn-default btn-sm' type='submit'>Ok</button>

                        <a href='http://abills.net.ua/wiki/doku.php/abills:docs:manual:admin:%FUNCTION_NAME%'
                           class='btn btn-primary btn-sm' target='_blank'>?</a>

                        <a href='#'
                           onclick='showImgInModal(\"$SELF_URL?$ENV{QUERY_STRING}&amp;qrcode=1&amp;qindex=100000&amp;name=qr_code\")'
                           class='btn btn-default btn-sm'>
                            <span class='glyphicon glyphicon-qrcode'></span>
                        </a>
                    </form>
                </div>
            </div>
            <!--//Quick Menu-->
            <div class='row navbar-left hidden-xs' id='quick_menu_row'>
                <div class='btn-group blocks' style='background: none'>
                    <a href='$SELF_URL?index=110' class='btn btn-default btn-xs'><span class='glyphicon glyphicon-plus'></span> </a>
                    %QUICK_MENU%
                </div>
            </div>
        </div>
        <div class='pull-right visible-xs'>

            <button class='btn btn-default btn-sm' data-toggle='modal' data-target='#quickMenuModal'>
                <span class='fa fa-caret-down'></span>
            </button>
            <button class='btn btn-default btn-sm' data-toggle='modal' data-target='#searchMenuModal'>
                <span class='fa fa-search'></span>
            </button>

            <a href='http://abills.net.ua/wiki/doku.php/abills:docs:manual:admin:%FUNCTION_NAME%'
               class='btn btn-primary btn-sm' target='_blank'>?</a>

            <a href='#'
               onclick='showImgInModal(\"$SELF_URL?$ENV{QUERY_STRING}&amp;qrcode=1&amp;qindex=100000&amp;name=qr_code\")'
               class='btn btn-default btn-sm'>
                <span class='glyphicon glyphicon-qrcode'></span>
            </a>

        </div>
</nav>

<script>
    jQuery(function () {
        var EVENT_PARAMS = {
            portal: 'admin',
            link: '/admin/index.cgi?get_index=form_events&even_show=1&AID=$admin->{AID}',
            soundsDisabled: ('$admin->{SETTINGS}{NO_EVENT_SOUND}' == '1'),
            disabled: ('$admin->{SETTINGS}{NO_EVENT}' == '1'),
            interval: 30000
        };

        AMessageChecker.start(EVENT_PARAMS);
    });
</script>

<!-- END header -->
%TECHWORK%

<div id='wrapper' onclick='hideshowMenu()'>
    <div class='row'>
        <!-- menu -->

        <div id='sidebar-wrapper' class='hidden-print'>
            <script>
                showhideMenu();
            </script>
            %MENU%
        </div>
        <!--End navigat-->

        <!-- main objects -->
        <div id='page-content-wrapper' align='center'>
            %BREADCRUMB%

            <!-- Main content -->
