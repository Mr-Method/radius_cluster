<!-- Header Navbar -->
<nav class='navbar navbar-static-top' role='navigation'>
  <!-- Sidebar toggle button-->
  <a href='#' class='sidebar-toggle' data-toggle='offcanvas' role='button'>
    <span class='sr-only'>Toggle navigation</span>
  </a>
  <!--<a href='$SELF_URL' class='header-btn-link' role='button'>-->
    <!--<span class='glyphicon glyphicon-home'></span>-->
  <!--</a>-->
  <!-- Navbar Right Menu -->
  <div class='navbar-custom-menu'>
    <ul class="nav navbar-nav">
      %GLOBAL_CHAT%
    </ul>
    <ul class='nav navbar-nav hidden-xs hidden-sm hidden-md'>
      <li>
        <a href="#">
          <span><strong>_{DATE}_:</strong> %DATE% %TIME% </span>
        </a>
      </li>
      <li>
        <a href="#" >
          <span><strong>_{LOGIN}_:</strong> %LOGIN%</span>
        </a>
      </li>
      <li>
        <a href="#">
          <span><strong>IP:</strong> %IP%</span>
        </a>
      </li>
    </ul>
    <ul class='nav navbar-nav navbar-right hidden-xs hidden-sm'>
      <li>
        <a href="#">
          <span><strong>_{STATE}_:</strong> %STATE% <!-- %STATE_CODE% --></span>
        </a>
      </li>
      <li>
        <a href="#" style='padding-top: 6px; padding-bottom: 6px'>
          <span>%SELECT_LANGUAGE%</span>
        </a>
      </li>
    </ul>
    <ul class='nav navbar-nav visible-xs visible-sm'>
      <li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown">
          _{INFO}_
        </a>
        <ul class="dropdown-menu">
          <p><strong>_{DATE}_:</strong> %DATE% %TIME% </p>
          <p><strong>_{USER}_ </strong>%LOGIN%</p>
          <p><strong>IP:</strong> %IP%</p>
          <p><strong>_{STATE}_:</strong> %STATE% <!-- %STATE_CODE% --></p>
        </ul>
      </li>
      <li>

      </li>
    </ul>
  </div>
</nav>
</header>
<!-- menu -->
  <aside id='main-sidebar' class='main-sidebar sidebar'>
    %MENU%
  </aside>
  <div class='content-wrapper'>
    <section class="content" id='main-content'>
    %BODY%
      </section>

  </div>

</div>

<!-- client_start End -->

<!-- AdminLTE App -->
<script src="/styles/lte_adm/dist/js/app.js"></script>

<script>
  jQuery('#language').on('change', selectLanguage);
</script>
%PUSH_SCRIPT%
</body>