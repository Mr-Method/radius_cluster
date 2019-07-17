<div class='box box-theme'>
   <div class='box-header with-border'><h4 class='box-title'>
        _{ICARDS}_ </h4>
    </div>
    <div class='box-body form form-horizontal'>
        <form action='$SELF_URL' METHOD='POST' name='form_card_add' class=''>
            <input type='hidden' name='sid' value='$FORM{sid}'>
            <input type='hidden' name='index' value='$index'>
            <input type='hidden' name='UID' value='$FORM{UID}'>


            <div class='form-group'>
                <label class='control-label col-md-3 col-sm-3'>_{SERIAL}_:</label>

                <div class='col-md-9 col-sm-9'>
                    <input class='form-control' type='text' name='SERIAL' value='%SERIAL%'>
                </div>
            </div> 
            <div class='form-group'>
                <label class='control-label col-md-3 col-sm-3'>PIN:</label>

                <div class='col-md-9 col-sm-9'>
                    <input class='form-control' type='text' name='PIN'>
                </div>
            </div>
            <div class='box-footer'>
                <input type='submit' class='btn btn-primary' name='add' value='_{ACTIVATE}_' ID='submitButton'
                       onClick='showLoading()'>
            </div>
        </form>
    </div>
</div>

<div style='display: none;' id='shadow'></div>
<div style='display: none;' id='load' class='top_result_baloon'><span id='loading'>_{BALANCE_RECHARCHE}_ ...</span>
</div>
