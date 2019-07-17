<form action='$SELF_URL' METHOD='POST' name='user' class='form-horizontal'>
    <input type=hidden name='ID' value='$FORM{chg}'>
    <input type=hidden name='index' value='$index'>

    <!--<fieldset>-->
    <!--<legend>_{TARIF_PLANS}_</legend>-->


    <!--<div class='form-group'>-->
    <!--<label class='control-label col-md-6 for=' TP_ID_MAIN'>_{MAIN}_</label>-->
    <!--<div class='col-md-3'>-->
    <!--%TP_ID_MAIN_SEL%-->
    <!--</div>-->
    <!--</div>-->

    <!--<div class='form-group'>-->
    <!--<label class='control-label col-md-6' for='TP_ID_BONUS'>_{BONUS}_</label>-->
    <!--<div class='col-md-3'>-->
    <!--%TP_ID_BONUS_SEL%-->
    <!--</div>-->
    <!--</div>-->

    <!--<label class='control-label col-md-6' for='PERIOD'>_{PERIOD}_ (_{MONTH}_):</label>-->
    <!--<div class='col-md-2'>-->
    <!--<input type=text class='form-control' name=PERIOD value='%PERIOD%'>-->
    <!--</div>-->

    <!--<label class='control-label col-md-6' for='PERIOD'>_{COMMENTS}_:</label>-->
    <!--<div class='col-md-2'>-->
    <!--<input type=text class='form-control' name=COMMENTS value='%COMMENTS%'>-->
    <!--</div>-->


    <!--<div class='form-group'>-->
    <!--<div class='col-sm-offset-2 col-sm-8'>-->
    <!--<input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>-->
    <!--</div>-->
    <!--</div>-->


    <!--</fieldset>-->
    <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4>_{TARIF_PLANS}_</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-4' for='TP_ID_MAIN'>_{MAIN}_</label>
                <div class='col-md-8'>
                    %TP_ID_MAIN_SEL%
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4' for='TP_ID_BONUS'>_{BONUS}_</label>
                <div class='col-md-8'>
                    %TP_ID_BONUS_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4' for='PERIOD'>_{PERIOD}_ (_{MONTH}_):</label>
                <div class='col-md-8'>
                    <input required='' type='text' class='form-control' id="PERIOD" name='PERIOD' value='%PERIOD%'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4' for='COMMENTS'>_{COMMENTS}_:</label>
                <div class='col-md-8'>
                    <input required='' type='text' class='form-control' id="COMMENTS" name='COMMENTS'
                           value='%COMMENTS%'/>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' class='btn btn-primary' name=%ACTION% value='%LNG_ACTION%'>
        </div>
    </div>
</form>