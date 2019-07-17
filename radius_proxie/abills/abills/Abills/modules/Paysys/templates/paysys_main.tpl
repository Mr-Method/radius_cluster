<style>
    .paysys-chooser {
        background-color: white;
    }

    input:checked + .paysys-chooser-box {
        transform: scale(1.01, 1.01);
        box-shadow: 8px 8px 3px #AAAAAA;
        z-index: 100;
    }

    input:checked + .paysys-chooser-box > .box-footer {
        background-color: lightblue;
    }

    .paysys-chooser:hover {
        transform: scale(1.05, 1.05);
        box-shadow: 10px 10px 5px #AAAAAA;
        z-index: 101;
    }
</style>

<form method='POST' action='$SELF_URL' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='sid' value='$sid'>
    <input type='hidden' name='IDENTIFIER' value='%IDENTIFIER%'>

    <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>

    <div class='box box-primary'>

        <div class='box-header with-border text-center'><h4 class='box-title'>_{BALANCE_RECHARCHE}_</h4></div>
        <div class='box-body'>

            <div class='form-group'>
                <label class='col-md-3 control-label'>_{TRANSACTION}_ #:</label>
                <label class='col-md-3 control-label'>%OPERATION_ID%</label>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label required'>_{SUM}_:</label>
                <div class='col-md-9'><input class='form-control' type='number' min='0' step='0.01' name='SUM' value='$FORM{SUM}' autofocus>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label'>_{DESCRIBE}_:</label>
                <div class='col-md-9'><input class='form-control' type='text' name='DESCRIBE' value='_{BALANCE_RECHARCHE}_'>
                </div>
            </div>

            <div class='form-group text-center'>

                %IPAY_HTML%
            </div>

            <div class='form-group text-center'>
                <label class='col-md-12 bg-primary text-center'>_{CHOOSE_SYSTEM}_</label>
                %PAY_SYSTEM_SEL%
            </div>
        </div>

        <div class='box-footer %HIDE_FOOTER%'><input class='btn btn-primary' type='submit' name=pre value='_{NEXT}_'></div>
    </div>


</form>


%MAP%
