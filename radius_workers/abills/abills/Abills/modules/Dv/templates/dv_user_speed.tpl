<style>
    select {
        max-width: inherit !important;
    }
</style>

<FORM action='$SELF_URL' METHOD=POST class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=CID value='%ISG_CID_CUR%'>
    <input type=hidden name=sid value='$sid'>

    <div class='box box-theme'>
        <div class='box-header with-border text-center'><h4 class='box-title'>TURBO _{MODE}_</h4></div>

        <div class='box-body form form-horizontal text-center'>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{SPEED}_ (kb):</label>

                <div class='col-md-9'>%SPEED_SEL%</div>
            </div>
            <div class='form-group text-center'>
                <input type=submit name=change value='_{ACTIVATE}_' class='btn btn-primary'>
            </div>
        </div>
    </div>
</FORM>
