<form action='$SELF_URL' METHOD='POST' class='form-inline' name=admin_form>
    
    <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>
    <input type=hidden name='PHONE' value='%PHONE%'>
    <input type=hidden name='mac' value='%mac%'>

    <fieldset>
        <div class='box box-theme'>
            <div class='box-body'>
                Перезвоните на номер <a href="tel:%AUTH_NUMBER%">%AUTH_NUMBER%</a>
            </div>
        </div>
        %BUTTON%

    </fieldset>

</form>
<script>
jQuery(function(){
  setInterval(function(){ check_call(); }, 3000);
});

function check_call() {
  jQuery.ajax({
    url: '$SELF_URL?ajax=1&mac=%mac%&PHONE=%PHONE%',
    success: function(result){
      if(result == '1') {
        document.location.href = 'http://google.com';
      }
    }
  });
}

</script>
