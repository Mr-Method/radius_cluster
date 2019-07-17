<form name='PATHES' id='form_PATHES' method='post' class='form form-horizontal'>
        <input type='hidden' name='index'  value='$index' />
        <input type='hidden' name='action' value='%ACTION%' />

<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>%PANEL_HEADING% %FILE_NAME%</h4></div>
  <div class='box-body'>

    <div class='form-group'>
      <label class='col-md-6 control-label'>_{WEB_SERVER_USER}_</label>
      <div class='col-md-6'>
        <input class='form-control' name='WEB_SERVER_USER' placeholder='www' value=%WEB_SERVER_USER% >
      </div>
    </div>
<hr>
    <div class='form-group'>
      <label class='col-md-6 control-label'>Apache _{CONF_DIR}_</label>
      <div class='col-md-6'>
        <input class='form-control' name='APACHE_CONF_DIR' placeholder='/etc/apache2/sites-enabled/' value=%APACHE_CONF_DIR% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>RADIUS _{CONF_DIR}_</label>
      <div class='col-md-6'>
        <input class='form-control' name='RADIUS_CONF_DIR' placeholder='/etc/radius/confdir' value=%RADIUS_CONF_DIR% >
      </div>
    </div>
<hr>
    <div class='form-group'>
      <label class='col-md-6 control-label'>_{RESTART}_ MYSQL</label>
      <div class='col-md-6'>
        <input class='form-control' name='RESTART_MYSQL' placeholder='/etc/init.d/mysqld' value=%RESTART_MYSQL% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>_{RESTART}_ RADIUS</label>
      <div class='col-md-6'>
        <input class='form-control' name='RESTART_RADIUS' placeholder='/etc/init.d/freeradius' value=%RESTART_RADIUS% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>_{RESTART}_ Apache</label>
      <div class='col-md-6'>
        <input class='form-control' name='RESTART_APACHE' placeholder='/etc/init.d/apache2' value=%RESTART_APACHE% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>_{RESTART}_ DHCP</label>
      <div class='col-md-6'>
        <input class='form-control' name='RESTART_DHCP' placeholder='/etc/init.d/isc-dhcp-server' value=%RESTART_DHCP% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>_{RESTART}_ MPD</label>
      <div class='col-md-6'>
        <input class='form-control' name='RESTART_MPD' placeholder='/etc/init.d/mpd' value=%RESTART_MPD% >
      </div>
    </div>

<hr>
    <div class='form-group'>
      <label class='col-md-6 control-label'>PING</label>
      <div class='col-md-6'>
        <input class='form-control' name='PING' placeholder='/bin/ping' value=%PING% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>MYSQLDUMP</label>
      <div class='col-md-6'>
        <input class='form-control' name='MYSQLDUMP' placeholder='/usr/bin/mysqldump' value=%MYSQLDUMP% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>GZIP</label>
      <div class='col-md-6'>
        <input class='form-control' name='GZIP' placeholder='/bin/gzip' value=%GZIP% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>SSH</label>
      <div class='col-md-6'>
        <input class='form-control' name='SSH' placeholder='/usr/bin/ssh' value=%SSH% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>SCP</label>
      <div class='col-md-6'>
        <input class='form-control' name='SCP' placeholder='/usr/bin/scp' value=%SCP% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>CURL</label>
      <div class='col-md-6'>
        <input class='form-control' name='CURL' placeholder='/usr/bin/curl' value=%CURL% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>SUDO</label>
      <div class='col-md-6'>
        <input class='form-control' name='SUDO' placeholder='/usr/bin/sudo' value=%SUDO% >
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-6 control-label'>ARP</label>
      <div class='col-md-6'>
        <input class='form-control' name='ARP' placeholder='/usr/sbin/arp' value=%ARP% >
      </div>
    </div>

  </div>
  <div class='box-footer text-center'>
      <input type='submit' form='form_PATHES' class='btn btn-primary' name='button' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

</form>  