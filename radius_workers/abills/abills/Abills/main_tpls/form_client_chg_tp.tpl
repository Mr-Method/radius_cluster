<form action='$SELF_URL' METHOD='POST' name='user' ID='user' class='pswd-confirm'>
    <input type=hidden name=sid value='$sid'>
    <input type=hidden name=ID value='%ID%'>
    <input type=hidden name=UID value='%UID%'>
    <input type=hidden name=m value='%m%'>
    <input type=hidden name='index' value='$index'>

    <div class='box box-primary'>
        <div class='box-header with-border text-center'>
            <h4>_{TARIF_PLANS}_</h4>
        </div>
        <div class='box-body form form-horizontal'>
            <div class='form-group'>
                <label class='col-md-2 control-label'>_{CURRENT}_:</label>
                <label class='cold-md-10 control-label'>$user->{TP_ID} %TP_NAME% </label>
            </div>
            <div class='form-group'>
                <label class='col-md-2 control-label'>_{CHANGE}_ _{ON}_:</label>

                <div class='col-md-10'>%TARIF_PLAN_TABLE%</div>
            </div>
            <div class='form-group'>
                %PARAMS%
            </div>
            <div class='form-group'>
                %SHEDULE_LIST%
            </div>
        </div>
        <div class='box-footer'>
            <div name='modalOpen_TP_CHG' class='btn btn-primary' id='modalOpen_TP_CHG'
                   data-toggle='modal' data-target='#changeTPModal'>%LNG_ACTION%</div>
        </div>
    </div>

    <div class='modal fade' id='changeTPModal'>
        <div class='modal-dialog'>
            <div class='modal-content'>
                <div class='modal-header text-center'>
                    <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
                            aria-hidden='true'>&times;</span></button>
                    <h4>_{CHANGE}_ _{TARIF_PLAN}_</h4>
                </div>
                <div class='modal-body' style='padding:20px;'>
                    <div class='form-group text-center'>
                        <label class='control-label text-center'>_{ACCEPT}_:</label>
                        %ACTION_FLAG%
                        <input type=checkbox value='_{HOLD_UP}_' id='ACCEPT_RULES' name='ACCEPT_RULES'>
                    </div>
                </div>
                <div class='modal-footer'>
                    <input type='submit' value='_{SET}_' name='%ACTION%' class='btn btn-primary' form='user'>
                </div>
            </div>
        </div>
    </div>


</form>
