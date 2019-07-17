<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='UID' value='%UID%'/>
    <input type='hidden' name='BILL_ID' value='%BILL_ID%'/>
    <input type='hidden' name='bill_correction' value='1'/>


    <div class='box box-theme box-form'>
        <div class='box-body'>

            <fieldset>
                <legend>_{BILL}_</legend>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='BILL_ID'>ID:</label>
                    <div class='col-md-9'>
                        <input id='BILL_ID' name='BILL_ID' value='%BILL_ID%' class='form-control' type='text' disabled>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='DEPOSIT'>_{DEPOSIT}_:</label>
                    <div class='col-md-9'>
                        <input id='DEPOSIT' name='DEPOSIT' value='%DEPOSIT%' class='form-control' type='number' step='0.01'>
                    </div>
                </div>

                <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
            </fieldset>
        </div>
    </div>

</form>
