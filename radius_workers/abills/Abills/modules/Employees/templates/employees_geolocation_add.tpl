<form action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type='hidden' name='index' value='%index%'>
<input type='hidden' name='EID' value='%EID%'>

<div class='box'>

<div class='row'>
	%GEOLOCATION_TREE%
</div>
<div class='checkbox'>
    <label>
      <input type='checkbox' name='CLEAR' value=1> _{CLEAR}_
    </label>
</div>
<input type='submit' class='btn btn-primary' name='BUTTON' value='%BTN_NAME%'>

</div>
</form>