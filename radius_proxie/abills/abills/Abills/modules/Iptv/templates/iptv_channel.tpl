<div class='box box-theme box-form'>
<div class='box-body'>

<form action='$SELF_URL' method='post' class='form-horizontal'>
<input type=hidden name='index' value='$index'>
<input type=hidden name=ID value='$FORM{chg}'>

<fieldset>
 <div class='form-group'>
  <label class='control-label col-md-3' for='NUM'>_{NUM}_:</label>
  <div class='col-md-9'>
    <input id='NUM' name='NUM' value='%NUM%' placeholder='%NUM%' class='form-control' type='text'>
  </div>
 </div>
 <div class='form-group'>
  <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
  <div class='col-md-9'>
    <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
  </div>
 </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='PORT'>_{PORT}_:</label>
  <div class='col-md-9'>
    <input id='PORT' name='PORT' value='%PORT%' placeholder='%PORT%' class='form-control' type='text'>
  </div>
 </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='FILTER_ID'>FILTER_ID:</label>
  <div class='col-md-9'>
    <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='DISABLE'>_{DISABLE}_:</label>
  <div class='col-md-9'>
    <input id='DISABLE' name='DISABLE' value=1 placeholder='%DISABLE%' type='checkbox' %DISABLE%>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='URL'>URL:</label>
  <div class='col-md-9'>
    <input id='STREAM' name='STREAM' value='%STREAM%' placeholder='%URL%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='GENRE'>_{GENRE}_:</label>
  <div class='col-md-9'>
    %GENRE_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='STATE'>_{STATE}_:</label>
  <div class='col-md-9'>
    %STATE_SEL%
  </div>
</div>



<div class='form-group'>
  <label class='control-label col-md-3' for='COMMENTS'>_{DESCRIBE}_</label>
  <div class='col-md-9'>
    <textarea name=COMMENTS rows=5 class='form-control'>%COMMENTS%</textarea>
  </div>
</div>

</div>
  
  <div class='panel-footer'>
   <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
  </div>  
  

  
  </fieldset>

 </form>
</div>

