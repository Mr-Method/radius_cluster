
<script language='JavaScript'>
    function autoReload() {
        document.iptv_user_info.add_form.value = '1';
        document.iptv_user_info.submit();
    }
</script>

<style>
    .paysys-chooser{
        background-color: white;
    }

    input:checked + .paysys-chooser-box  {
        transform: scale(1.01,1.01);
        box-shadow: 8px 8px 3px #AAAAAA;
        z-index: 100;
    }

    input:checked + .paysys-chooser-box > .box-footer{
        background-color: lightblue;
    }

    .paysys-chooser:hover{
        transform: scale(1.05,1.05);
        box-shadow: 10px 10px 5px #AAAAAA;
        z-index: 101;
    }
</style>

<form method='POST' action='$SELF_URL' class='form form-horizontal' id='iptv_user_info' name='iptv_user_info'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='sid' value='$sid'>
    <input type='hidden' name='add_form' value=1>

    <div class='box box-primary'>
        <div class='box-header with-border text-center'><h4 class='box-title'>_{SUBCRIBES}_</h4></div>
        <div class='box-body'>

            <div class='form-group text-center'>
                <label class='col-md-12 bg-primary text-center'>_{CHOOSE_SYSTEM}_</label>
                %SERVICE_SEL%
            </div>

            <div class='panel panel-default'>
              %TP_SEL%
            </div>

            <div class='form-group text-center'>
                <label class='col-md-3 bg-primary'>E-Mail</label>
                <div class='col-md-9'>
                <input type='text' name='EMAIL' value='%EMAIL%' class='form-control'>
                </div>
            </div>
        </div>

        <div class='box-footer'><input class='btn btn-primary' type='submit' name=add value='_{ADD}_'></div>
    </div>
</form>
