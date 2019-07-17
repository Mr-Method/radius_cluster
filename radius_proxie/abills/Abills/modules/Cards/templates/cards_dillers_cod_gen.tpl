<script language="JavaScript" type="text/javascript">
<!--
function make_unique() {
    var pwchars = "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ.,:";
    var passwordlength = 8;    // do we want that to be dynamic?  no, keep it simple :)
    var passwd  = document.getElementById('OP_SID');
    var sum     = document.getElementById('SUM');
    var sum_new = document.getElementById('SUM_NEW');

    passwd.value = '';

    for ( i = 0; i < passwordlength; i++ ) {
        passwd.value += pwchars.charAt( Math.floor( Math.random() * pwchars.length ) )
    }

    sum.value=sum_new.value;
    sum_new.value='0.00';

    return passwd.value;
}
-->
</script>

<form action='$SELF_URL' METHOD='POST' TARGET=New>

<input type='hidden' name='qindex' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<input type='hidden' name='OP_SID' value='%OP_SID%' ID=OP_SID>
<input type='hidden' name='sid' value='$sid'>
<input type='hidden' name='SUM' value='' ID='SUM'>

<div class='box box-form form-horizontal box-primary'>
<div class='box-header with-border'>_{ICARDS}_</div>
<div class='box-body'>
    <div class='form-group'>
        <label class='col-md-3 control-label'>_{COUNT}_:</label>
        <div class='col-md-9'>
            <input class='form-control' type='text' name='COUNT' value='%COUNT%'>
        </div>
    </div>
    <div class='form-group'>
        <label class='col-md-3 control-label'>_{SUM}_:</label>
        <div class='col-md-9'>
            <input class='form-control' type='text' name='SUM_NEW' value='0.00' ID=SUM_NEW>
        </div>
    </div>
</div>
<div class='box-footer text-center'>
<input class='btn btn-primary' type='submit' name='add' value='_{ADD}_' onclick=\"make_unique(this.form)\">
</div>
</div>

<!-- <table width=600 class=form>
<tr><th colspan=2 class=form_title>_{ICARDS}_</th></tr>
<tr><td>_{COUNT}_:</td><td><input type='text' name='COUNT' value='%COUNT%'></td></tr>
<tr><td>_{SUM}_:</td><td><input type='text' name='SUM_NEW' value='0.00' ID=SUM_NEW></td></tr>

<tr><th colspan=2 class=even><input type='submit' name='add' value='_{ADD}_' onclick=\"make_unique(this.form)\"></th></tr>
</table> -->


</form>

