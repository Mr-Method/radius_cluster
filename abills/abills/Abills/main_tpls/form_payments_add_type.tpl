<form action=$SELF_URL METHOD=POST class='form-horizontal'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <div class="box box-theme box-form">
        <div class="box-header with-border">
            <div class="box-title">
                %BUTTON_NAME%
            </div>
        </div>
        <div class="box-body">
            <div class="form-group">
                <label class="control-label col-md-3">_{NAME}_:</label>
                <div class="col-md-9">
                    <input class="form-control" required name="NAME" value="%NAME%" type="text">
                </div>
            </div>
            <div class="form-group">
                <label class="control-label col-md-3">_{COLOR}_</label>
                <div class="col-md-9">
                    <input class="form-control" name="COLOR" value="%COLOR%" type="color">                    </div>
                </div>
            </div>
            <div class="box-footer">
                <p align="center">
                    <input class="btn btn-primary pull-center" name="%BUTTON_LABALE%" value="%BUTTON_NAME%" type="submit">   </p>         </div>
                </div>

            </form>