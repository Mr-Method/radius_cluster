<style>
  /*Night mode styles*/
  .modal-backdrop {
    opacity: 0.7;
  }

  /*Removing black backround*/
  div.wrapper {
    box-shadow : none !important;
    background-color: transparent !important;
  }

  .login-wrapper {
    margin-top: 1em;
  }

  @media (min-device-height: 400px) {
    .login-wrapper {
      margin-top: 3em;
    }
  }

</style>

<nav class='navbar navbar-static-top' role='navigation'>
  <ul class='nav navbar-nav navbar-right'>
    <li data-visible='%REGISTRATION_ENABLED%'>
      <a href='/registration.cgi'>_{REGISTRATION}_</a>
    </li>
    <li data-visible='%HAS_REGISTRATION_PAGE%'>
      <a href='/registration.cgi?FORGOT_PASSWD=1'>_{FORGOT_PASSWORD}_</a>
    </li>
  </ul>
</nav>

</header>
<div class="login-wrapper">
  <div class='col-md-6 col-md-offset-3 text-center'>
    %LOGIN_ERROR_MESSAGE%
  </div>
  <form action='$SELF_URL' METHOD='post' name='form_login' id='form_login' class='form form-horizontal'>
    <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
    <input type='hidden' ID='REFERER' name='REFERER' value='$FORM{REFERER}'>
    <input type='hidden' id='location_x' name='coord_x'>
    <input type='hidden' id='location_y' name='coord_y'>

    <div class='col-md-push-4 col-lg-push-4 col-xs-12 col-sm-12 col-md-4 col-lg-4'>
      <div class='box box-info center-block' id='login_panel'>
        <div class='box-header with-border text-center'>
          <h4> %TITLE% </h4>
        </div>
        <div class='box-body'>
          <div class='form-group'>
            <label class='control-label col-md-4'>_{LANGUAGE}_:</label>

            <div class='col-md-8'>
              %SEL_LANGUAGE%
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-4' for='user'>_{USER}_:</label>

            <div class='col-md-8'>
              <div class='input-group'>
                <span class='input-group-addon'><span class='glyphicon glyphicon-user'></span></span>
                <input id='user' name='user' value='%user%' placeholder='_{USER}_' class='form-control'
                       type='text' required='required'>
              </div>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-4' for='passwd'>_{PASSWD}_:</label>

            <div class='col-md-8'>
              <div class='input-group'>
                <span class='input-group-addon'><span class='glyphicon glyphicon-lock'></span></span>
                <input id='passwd' name='passwd' value='%password%' placeholder='_{PASSWD}_'
                       class='form-control' type='password'>
              </div>
            </div>
          </div>
        </div>

        <div class='box-footer text-center'>
          <input class='btn btn-lg btn-success' id='login_btn' type='submit' name='logined' value='_{ENTER}_'
                 onclick='set_referrer()'>
        </div>

      </div>
      <!--Block for social networks buttons-->
      <div class='form-group text-center' id='social_network_block'>
        <link rel='stylesheet' href='/styles/default_adm/css/client_social_icons.css'>
        <ul class='social-network social-circle'>
          %SOCIAL_AUTH_BLOCK%
        </ul>
      </div>
    </div>


  </form>
</div>
<script>

  /* Geolocation */
  jQuery(function () {
    if ('$conf{CLIENT_LOGIN_GEOLOCATION}') {
      var loginBtn = jQuery('#login_btn');

      /* Disable login button */
      loginBtn.addClass('disabled');

      /* Enable button in 3 seconds in any case (If navigation has error) */
      setTimeout(enableButton, 3000);

      getLocation(enableButton);

      function enableButton() {
        loginBtn.removeClass('disabled');
      }
    }
    else {
      console.log('Geolocation is disabled');
    }

    if ('$conf{CLIENT_LOGIN_NIGHTMODE}') {
      var D = new Date(), Hour = D.getHours();
      if (Hour >= 18) {
        var div          = document.createElement('div');
        div.className    = 'modal-backdrop';
        div.style.zIndex = -2;

        jQuery('body').prepend(div);
        jQuery('.wrapper').addClass('modal-content');
      }
      else {
        console.log('Night mode is enabled, but it\'s not evening ( Hour < 18)');
      }
    }
  });

</script>