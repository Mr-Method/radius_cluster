<FORM action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=AID value=$FORM{chg}>

<div class='box box-theme'>
<div class='box-body'>


<div class='form-group'>
    <label class='control-label col-md-3' for='ADMIN'>_{ADMIN}_</label>
	 <div class='col-md-9'>
	 	 %ADMIN%
	 </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='CHAPTER'>_{CHAPTERS}_</label>
</div>

%CHAPTERS%

    <input type=submit name=change value=_{CHANGE}_ class='btn btn-primary'>
</FORM>

</div>
</div>
