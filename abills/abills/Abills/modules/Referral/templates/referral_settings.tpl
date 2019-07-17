<div class='box box-theme box-form'>
    <div class='box-header with-border text-center'><h5>_{REFERRAL_SYSTEM}_</h5></div>
    <div class='box-body'>

        <form name='REFERRAL_SETTINGS' id='form_REFERRAL_SETTINGS' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index'/>

            <div class='form-group'>
                <label class='control-label col-md-3' for='MAX_LEVEL_id'>_{MAX}_ _{LEVEL}_</label>
                <div class='col-md-9'>
                    <input type='number' min='0' max='100' class='form-control'
                           data-tooltip='<b>_{MIN}_</b>: 0 <br> <b>_{MAX}_</b>:100'
                           name='MAX_LEVEL' value='%REFERRAL_MAX_LEVEL%' id='MAX_LEVEL_id'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='MAX_LEVEL_id'>_{REDUCTION}_</label>
                <div class='col-md-9'>
                    <input type='number' min='0' class='form-control'
                           data-tooltip='<b>_{MIN}_</b>: 0'
                           name='DISCOUNT_COEF' value='%REFERRAL_DISCOUNT_COEF%' id='LEVEL_COEF_id'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='MAX_LEVEL_id'>_{NEXT}_ _{REDUCTION}_</label>
                <div class='col-md-9'>
                    <input type='number' min='0' max='100' class='form-control'
                           data-tooltip='<b>_{MIN}_</b>: 0'
                           name='DISCOUNT_NEXT_COEF' value='%REFERRAL_DISCOUNT_NEXT_COEF%' id='NEXT_LEVEL_COEF_id'/>
                </div>
            </div>
        </form>

    </div>
    <div class='box-footer'>
        <input type='submit' form='form_REFERRAL_SETTINGS' class='btn btn-primary' name='action' value='_{CHANGE}_'>
    </div>
</div>

