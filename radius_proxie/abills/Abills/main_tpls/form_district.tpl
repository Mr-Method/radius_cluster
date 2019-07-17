<form action='$SELF_URL' class='form-horizontal' METHOD='post' enctype='multipart/form-data' name=add_district>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<div class='box box-theme box-form'>
	<div class='box-header with-border'>_{DISTRICTS}_</div>
<div class='box-body'>
<div class='form-group'>
  <label class='control-label col-sm-3' for='NAME'>_{NAME}_:</label>
  <div class='col-sm-9'>
      <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='COUNTRY_SEL'>_{COUNTRY}_:</label>
  <div class='col-md-9'>
     %COUNTRY_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-sm-3' for='CITY'>_{CITY}_:</label>
  <div class='col-sm-9'>
      <input id='CITY' name='CITY' value='%CITY%' placeholder='%CITY%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-sm-3' for='ZIP'>_{ZIP}_:</label>
  <div class='col-sm-9'>
      <input id='ZIP' name='ZIP' value='%ZIP%' placeholder='%ZIP%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-sm-3' for='ZIP'>_{MAP}_ (*.jpg, *.gif, *.png):</label>
  <div class='col-sm-9'>
      <input id='FILE_UPLOAD' class='fixed' name='FILE_UPLOAD' value='%FILE_UPLOAD%' placeholder='%FILE_UPLOAD%' class='form-control' type='file'>
  </div>
</div>
<div class='form-group'>
  <label class='control-label col-sm-3' for='IMPORT'>_{IMPORT}_:</label>
  <div class='col-sm-9'>
      <input id='IMPORT' class='fixed' name='IMPORT' value='%IMPORT%' placeholder='%IMPORT%' class='form-control' type='file'>
  </div>
</div>

<div class='form-group'>
    <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_:</label>
    <div class='col-md-9'>
      <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
    </div>
   </div>
   </div>
<div class='box-footer'>
   <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
</div>
	</div>


</form>
