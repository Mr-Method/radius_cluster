<div class='box box-theme box-form'>
    <div class='box-body'>

        <form class='form-horizontal' action='$SELF_URL' method='post' role='form'>
            <input type=hidden name='index' value='$index'>
            <input type=hidden name='AID' value='%AID%'>
            <input type=hidden name='ID' value='$FORM{chg}'>
            <input type=hidden name='subf' value='$FORM{subf}'>

            <div class='form-group'>
                <label class='col-md-3 control-label' for='DAYS'>_{DAY}_</label>

                <div class='col-md-9'>
                    %SEL_DAYS%
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label' for='BEGIN'>_{BEGIN}_</label>

                <div class='col-md-9'>
                    <input id='BEGIN' name='BEGIN' value='%BEGIN%' placeholder='%BEGIN%' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label' for='END'>_{END}_</label>

                <div class='col-md-9'>
                    <input id='END' name='END' value='%END%' placeholder='%END%' class='form-control' type='text'>
                </div>
            </div>


            <div class='form-group'>
                <label class='col-md-3 control-label' for='IP'>_{ALLOW}_ IP</label>

                <div class='col-md-4'>
                    <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control' type='text'>
                </div>

                <label class='col-md-2 control-label' for='BIT_MASK'>MASK</label>

                <div class='col-md-3'>
                    %BIT_MASK_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label' for='DISABLE'>_{DISABLE}_</label>

                <div class='col-md-9'>
                    <input id='DISABLE' name='DISABLE' value='1' type='checkbox' %DISABLE%>
                </div>
            </div>


            <div class='form-group'>
                <label class='col-md-3 control-label' for='COMMENTS'>_{COMMENTS}_</label>

                <div class='col-md-9'>
                    <textarea id='COMMENTS' name='COMMENTS' class='form-control' rows=3>%COMMENTS%</textarea>
                </div>
            </div>


            <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>

        </form>

    </div>
</div>