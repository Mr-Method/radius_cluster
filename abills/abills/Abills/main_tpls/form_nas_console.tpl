<div class="btn-group">
    %QUICK_CMD%
</div>


<form action=$SELF_URL METHOD=post name=FORM_NAS class='form-horizontal'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='NAS_ID' value='%NAS_ID%'>
    <input type=hidden name='console' value='1'>
    <input type=hidden name='change'  value='%change%'>
    <fieldset>

        <div class='box box-theme box-big-form'>
            <div class='box-header with-border'>
                <h4 class='box-title'> _{MANAGE}_ </h4>
            </div>
            <div class='nav-tabs-custom box-body'>


            <div class='form-group'>

            <label class='control-label col-md-3' for='NAS_MNG_IP_PORT'>IP:PORT</label>
            <div class='col-md-9'>
                <input id='NAS_MNG_IP_PORT' name='NAS_MNG_IP_PORT' value='%NAS_MNG_IP_PORT%'
                       placeholder='%NAS_MNG_IP_PORT%' class='form-control' type='text'>
            </div>

            <label class='control-label col-md-3' for='NAS_MNG_USER'>_{USER}_</label>
            <div class='col-md-9'>
                <input id='NAS_MNG_USER' name='NAS_MNG_USER' value='%NAS_MNG_USER%' placeholder='%NAS_MNG_USER%'
                       class='form-control' type='text'>
            </div>


            <label class='control-label col-md-3' for='NAS_MNG_PASSWORD'>_{PASSWD}_</label>
            <div class='col-md-9'>
                <input id='NAS_MNG_PASSWORD' name='NAS_MNG_PASSWORD' value='%NAS_MNG_PASSWORD%'
                       placeholder='%NAS_MNG_PASSWORD%' class='form-control' type='password'>
            </div>
        </div>

        <div class='form-group'>
            <label class='control-label col-md-3' for='type'>_{TYPE}_</label>
            <div class='col-md-9'>
              %TYPE_SEL%
            </div>
        </div>

        <div class='form-group'>
            <label class='control-label col-md-3' for='type'>_{COMMENTS}_</label>
            <div class='col-md-9'>
                <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
            </div>
        </div>

        <div class='form-group'>
            <div class='col-md-12'>
                <textarea class='form-control' id='CMD' name='CMD' rows='3' placeholder='CMD'>%CMD%</textarea>
            </div>
        </div>
            </div>

            <div class='box-footer'>
                <input type='submit' class='btn btn-primary' name='ACTION' value='_{SEND}_'>
                <label class='checkbox-inline pull-right'><input type='checkbox' name='SAVE' value='1'><strong>_{SAVE}_</strong></label>
            </div>
        </div>
    </fieldset>
</form>

<script>
  jQuery(function () {
    var removeBtns = jQuery('.removeIpBtn');
    var saveBtn    = jQuery('.export-btn');

    function removeAddress(context) {
      var cont = jQuery(context);

      var command = "/ip firewall address-list remove numbers=" + cont.attr('data-address-number');

      var params = {
        qindex : '$index',
        console: 1,
        full   : 1,
        header : 2,
        ACTION : 1,
        NAS_ID : '$FORM{NAS_ID}',
        CMD    : command
      };

      cont.find('.glyphicon').addClass('fa-spin');

      jQuery.get(SELF_URL, params, function () {
        cont.parent().parent().hide();
      });

    }

    function exportText() {
      var fullText = "";
      var rows = jQuery('#CONSOLE_RESULT_ > tbody > tr > td');
      jQuery.each(rows, function( index, value ) {
        fullText = fullText + jQuery(value).text() + "\n";
      });

      var blob = new Blob([fullText], {type: "text/plain;charset=utf-8"});
      var link = window.URL.createObjectURL(blob);
      // window.location = link;
      var a = document.createElement("a");
      a.href = link;
      a.download = "mikrotik.txt";
      document.body.appendChild(a);
      a.click();
    };

    removeBtns.on('click', function () {
      removeAddress(this);
    });

    saveBtn.on('click', function (e) {
      e.preventDefault();
      exportText();
    });

  })
</script>

