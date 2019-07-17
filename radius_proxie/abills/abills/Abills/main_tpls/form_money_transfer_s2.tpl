<style>
    .box-body div:nth-of-type(2n-1) {
        background-color: #f0f0f0;
    }
</style>
<form action=$SELF_URL method=post class='pswd-confirm'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='RECIPIENT' value='%RECIPIENT%'>
    <input type='hidden' name='SUM' value='%SUM%'>
    <input type='hidden' name='sid' value='$sid'>

    <div class='box box-primary center-block' style='max-width: 400px'>
        <div class='box-header with-border'>
            _{MONEY_TRANSFER}_
        </div>
        <div class='box-body form form-horizontal'>
            <div class='form-group'>
                <label class='col-md-6 text-right'>UID:</label>
                <label class='col-md-6'>
                    %RECIPIENT%
                </label>
            </div>
            <div class='form-group'>
                <label class='col-md-6 text-right'>_{FIO}_:</label>
                <label class='col-md-6'>
                    %FIO%
                </label>
            </div>
            <div class='form-group'>
                <label class='col-md-6 text-right'>_{SUM}_:</label>
                <label class='col-md-6'>
                    %SUM%
                </label>
            </div>
            <div class='form-group'>
                <label class='col-md-12 text-center text-danger'>%COMMISSION%</label>
            </div>
            <div class='form-group'>
                <label class='col-md-6 text-right' for='ACCEPT'>_{ACCEPT}_:</label>

                <div class='col-md-6'>
                    <input class='form-control-sm' type='checkbox' id='ACCEPT' name=ACCEPT value=1>
                </div>
            </div>
        </div>
        <div class='box-footer '>
            <input class='btn btn-primary center-block' type='submit' name='transfer' value='_{SEND}_'/>
        </div>
    </div>
</form>
 