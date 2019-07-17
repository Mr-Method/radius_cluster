<style>
  .st_icon {
    color: #3c8dbc;
    font-size: 1.2em;
  }
  .input-group {
    margin-bottom: 15px;
  }
  select.normal-width {
    max-width: 100%!important;
  }
  div.fixed {
    position: fixed;
    width: 50%;
    bottom: 10px;
    font-size: 1.5em;
    margin-left: 50px;
  }

  div.wrapper {
    box-shadow: none !important;
    background-color: transparent !important;
  }
  @media screen and (max-width: 768px) {
    div.fixed {
      margin-left: 20px;
    }
  }
</style>
<div class='login-box'>
  <div class='login-logo'>
    <a href='/'><img src=''></a>
  </div>
  <div class='login-box-body'>
    <p class='login-box-msg' style='font-size: large; text-transform: uppercase'>_{USER_PORTAL}_</p>
    <div class='row'>
      <div class='col-xs-12'>
        <div class='info-box bg-yellow' style='display: none;' id='tech_works_block'>
          <span class='info-box-icon'>
            <i class='fa fa-wrench'></i>
          </span>
          <div class='info-box-content'>
            <span class='info-box-number'>%TECH_WORKS_MESSAGE%</span>
          </div>
        </div>
      </div>
    </div>
    <div class='row'>
      <div class='col-xs-12'>
        %LOGIN_ERROR_MESSAGE%
      </div>
    </div>
    <form action='$SELF_URL' METHOD='post' name='form_login' id='form_login'>
      <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
      <input type='hidden' ID='REFERER' name='REFERER' value='$FORM{REFERER}'>
      <input type='hidden' id='location_x' name='coord_x'>
      <input type='hidden' id='location_y' name='coord_y'>
      <div class="input-group">
        <span class="input-group-addon st_icon"><i class="fa fa-language"></i></span>
        %SEL_LANGUAGE%
      </div>
      <div class="input-group">
        <span class="input-group-addon st_icon"><i class="fa fa-user"></i></span>
        <input type='text' id='user' name='user' value='%user%' class='form-control' placeholder='_{LOGIN}_' autocomplete='off'>
      </div>
      <div class="input-group">
        <span class="input-group-addon st_icon"><i class="fa fa-lock"></i></span>
        <input type='password' id='passwd' name='passwd' value='%password%' class='form-control' placeholder='_{PASSWD}_' autocomplete='off'>
      </div>
      <div class='form-group'>
        <button type='submit' name='logined' class='btn btn-primary btn-block btn-flat' onclick='set_referrer()'>
          _{ENTER}_
        </button>
      </div>
    </form>
    <a data-visible='%HAS_REGISTRATION_PAGE%' style="float: right" href='/registration.cgi?FORGOT_PASSWD=1'>_{FORGOT_PASSWORD}_</a>
    <a data-visible='%REGISTRATION_ENABLED%' href='/registration.cgi'>_{REGISTRATION}_</a>
    <div class='row'>
      <div class='col-xs-12 text-center' id='social_network_block'>
        <link rel='stylesheet' href='/styles/default_adm/css/client_social_icons.css'>
        <ul class='social-network social-circle'>
          %SOCIAL_AUTH_BLOCK%
        </ul>
      </div>
    </div>
  </div>
</div>
</div>
<div class="fixed" >
  <div style="position: absolute; bottom: 5px;">
    <span class='logo-lg'  style='color: #02060a;'><b><span style='color: red;'>A</span></b>BillS</span>
  </div>
</div>

<script>

  /* Geolocation */
  jQuery(function () {
    jQuery('#language').on('change', selectLanguage);

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

    if ('%TECH_WORKS_BLOCK_VISIBLE%' === '1') {
      jQuery('#tech_works_block').css('display', 'block');
    }

  });

</script>