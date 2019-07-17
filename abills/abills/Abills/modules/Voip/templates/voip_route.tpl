<div class='noprint'>
    <form action='$SELF_URL' method='post' class='form-horizontal'>
        <input type=hidden name='index' value='$index'>
        <input type=hidden name=chg value='%ROUTE_ID%'>
        <input type=hidden name=PARENT_ID value='%PARENT_ID%'>
        <input type=hidden name=ROUTE_ID value='$FORM{ROUTE_ID}'>

        <div class='box box-theme box-form'>
            <div class='box-header with-border'>_{ROUTES}_</div>
            <div class='box-body'>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{PREFIX}_</label>
                    <div class='col-md-9'>
                        <input class='form-control' type=text name=ROUTE_PREFIX value='%ROUTE_PREFIX%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{NAME}_</label>
                    <div class='col-md-9'>
                        <input class='form-control' type=text name=ROUTE_NAME value='%ROUTE_NAME%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{DISABLE}_</label>
                     <div class='col-md-9'>
                         <input type=checkbox name=DISABLE value='1' %DISABLE%>
                      </div>
                </div>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{DESCRIBE}_</label>
                    <div class='col-md-9'>
                        <input class='form-control' type=text name=DESCRIBE value='%DESCRIBE%'>
                    </div>
                </div>
            </div>
            <div class='box-footer'>
                <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
            </div>
        </div>

    </form>
</div>
