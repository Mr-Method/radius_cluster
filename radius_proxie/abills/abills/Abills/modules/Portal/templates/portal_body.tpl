<!DOCTYPE html>
<html>
<head>
  <meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>
  <link href='/styles/default_adm/css/font-awesome.min.css' rel='stylesheet'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/bootstrap.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/bootstrap-theme.min.css'>
  <script src='/styles/%HTML_STYLE%/js/jquery.min.js'></script>
  <!--[if lt IE 9]>
  <script src='/styles/default_adm/js/jquery-1.11.3.min.js' type='text/javascript'></script>
  <![endif]-->
  <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
  <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
  <!--[if lt IE 9]>
  <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
  <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
  <![endif]-->
  <!--[if (lt IE 8) & (!IEMobile)]>
  <p class="chromeframe">Sorry, our site supports Internet Explorer starting from version 9. You need to <a
      href="http://browsehappy.com/">upgrade your browser</a> or <a
      href="http://www.google.com/chromeframe/?redirect=true">activate Google Chrome Frame</a> to use the site.</p>
  <![endif]-->

  <!-- TRY TO WITHOUT IT -->
  <!-- <script src='/styles/%HTML_STYLE%/js/bootstrap.min.js'></script> -->
  <script src='/styles/%HTML_STYLE%/js/chosen.jquery.min.js'></script>
  <!-- <script src='/styles/default_adm/js/navBarCollapse.js' language='javascript'></script> -->
  <script src='/styles/lte_adm/plugins/datepicker/bootstrap-datepicker.js'></script>
  <script src='/styles/lte_adm/plugins/timepicker/bootstrap-timepicker.min.js'></script>

  <script type='text/javascript'>
    function selectLanguage() {
      var sLanguage = jQuery('#language').val() || '';
      var sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&language=' + sLanguage;
      document.location.replace(sLocation);
    }
    function set_referrer() {
      document.getElementById('REFERER').value = location.href;
    }
  </script>
  <script>
    \$(document).ready(function () {
      // Show the Modal on load
      if ('%WRONG_PASSWD_CHECK%' == 1 || '%WRONG_PASSWD_CHECK%' == 2) {
        console.log('HELLO WORLD');
        \$('#login_form').modal('show');
      }
    });
  </script>

  <title>$conf{WEB_TITLE} - Portal</title>


  <style>
  #form_login span.glyphicon {
    top : 0;
  }

  #form_login #input_wrapper{
    padding: 20px 30px 20px
  }

    .brand-logo {
      padding: 2px;
      margin-right: 4em;
    }

    .login-button {
      margin: 5px 5px;
    }

    .btn-group {
      padding-right:28px;
    }

    .timeline {
      margin-top: 15px;
    }

    .modal-header-primary {
      color: #fff;
      padding: 9px 15px;
      border-bottom: 1px solid #eee;
      background-color: #428bca;
      border-top-left-radius: 5px;
      border-top-right-radius: 5px;
    }

    .main-header .navbar {
      margin-left:0;
    }

    body {
      background-color: #ecf0f5;
    }
  </style>

</head>
<body class='skin-blue-light sidebar-collapse layout-boxed '>
<div id='login_form' class='modal fade' role='dialog'>
  <form method='post' class='form form-horizontal' id='form_login'
        action='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi'>

    <div class='modal-dialog modal-sm'>
      <div class='modal-content'>

        <div class='modal-header modal-header-primary text-center'>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
            <span aria-hidden='true'>&times;</span>
          </button>
          <label class='control-label'><h3>_{SIGN_IN}_</h3></label>
        </div>
        <div class='modal-body'>
          <div class='row' id='input_wrapper'>
            <div class='col-md-12 text-center'>%WRONG_PASSWD%</div>
            <div class='form-group has-feedback'>
            <div class='input-group'>
              <span class='input-group-addon glyphicon glyphicon-globe'></span>
              %SEL_LANGUAGE%
            </div>
          </div>

          <div class='form-group'>
            <div class='input-group'>
              <span class='input-group-addon glyphicon glyphicon-user'></span>
              <input type='text' id='user' name='user' value='%user%' class='form-control' placeholder='_{LOGIN}_'>
            </div>
          </div>

          <div class='form-group'>
            <div class='input-group'>
              <span class='input-group-addon glyphicon glyphicon-lock'></span>
              <input type='password' id='passwd' name='passwd' value='%password%' class='form-control'
                     placeholder='_{PASSWD}_'>
            </div>
          </div>

          <div class='row'>
            <!-- /.col -->

            <button type='submit' name='logined' class='btn btn-success btn-block btn-flat form-control'
                    onclick='set_referrer()'>_{ENTER}_
            </button>

            <!-- /.col -->
          </div>

        </div>
            </div>
            <div class='form-group text-center'>
              <p class="col-md-12">_{SOCIAL_NETWORKS}_</p>
              <link rel='stylesheet' href='/styles/default_adm/css/client_social_icons.css'>
              <ul class='social-network social-circle'>
                %SOCIAL_AUTH_BLOCK%
              </ul>
            </div>
        <div class='modal-footer'>
          <a href='registration.cgi?FORGOT_PASSWD=1' target='_blank'>_{FORGOT_PASSWORD}_?</a>
          
        </div>

      </div>
    </div>

  </form>
</div>

<div class='container'>

<header class='main-header'>
  <nav class='navbar navbar-static-top'>
    <div class='container-fluid'>
      <div class='navbar-header'>
        <a href='index.cgi' class='navbar-brand'>
        <!-- mini logo for sidebar mini 50x50 pixels -->
        <span class='logo-mini' title="ABillS">
          <b><span style="color: red;">A</span></b>BillS
        </span>
        </a>

        <button type='button' class='navbar-toggle collapsed' data-toggle='collapse' data-target='#navbar-collapse'>
          <i class='fa fa-bars'></i>
        </button>
       </div>



  
      <!-- Collect the nav links, forms, and other content for toggling -->
      <div class='collapse navbar-collapse' id='navbar-collapse'>
        <ul class='nav navbar-nav'>
          %MENU%
        </ul>
  
        <ul class='nav navbar-nav navbar-right'>
          <li>
          %REGISTRATION%
          </li>
          <li>
          <a href='#' class='' title='_{USER_PORTAL}_' data-toggle='modal' data-target='#login_form'>
            _{USER_PORTAL}_
          </a>
          </li>
        </ul>
      </div><!-- /.navbar-collapse -->
    </div><!-- /.container-fluid -->
  </nav>`
</header>

<div id='bodyPan'>
  
  <ul class="list-unstyled">
    %CONTENT%
  </ul>
  </div>

  <div id='bodyMiddlePan'>
  </div>

  <div id='footermainPan'>
    <div id='footerPan'>
    </div>
  </div>

</div>

</body>
</html>
