<div class='box box-theme box-primary'>

<div class='box-header with-border'>
<h4 class='box-title'>_{IMPORT}_</h4>
</div>
  
<div class='box-body' id='ajax_upload_modal_body'>

    <form class='form form-horizontal' name='ajax_upload_form' id='ajax_upload_form' method='post'>
  
        <input type='hidden' name='get_index' value='%CALLBACK_FUNC%'/>  
        <input type='hidden' name='header' value='2'/>  
        <input type='hidden' name='import' value='1'/>  
        <input type='hidden' name='add' value='1'/>
  
        <div class='form-group'>  
            <label class='control-label col-md-3 required' for='IMPORT_TYPE'> _{TYPE}_</label>
            <div class='col-md-9'>  
                <select name='IMPORT_TYPE' class='form-control'>  
                  <option value='csv'>CSV (TAB)
                  <option value='JSON'>JSON
                  <!--
                  <option value='xml'>XML  
                  -->  
                </select>  
            </div>  
        </div>
  
        <div class='form-group'>  
            <label class='control-label col-md-3' for='IMPORT_FIELDS'>  
                _{FIELDS}_</label>
            <div class='col-md-9'>  
                 <input type='text' name='IMPORT_FIELDS' id='IMPORT_FIELDS' value='%IMPORT_FIELDS%' class='form-control'  
                       />
  
                 <!-- %IMPORT_FIELDS_SEL%  -->
  
            </div>  
        </div>
  
        <div class='form-group'>  
            <label class='control-label col-md-3 required' for='UPLOAD_FILE'>  
                _{FILE}_</label>
            <div class='col-md-9'>  
                <input type='file' name='UPLOAD_FILE' id='UPLOAD_FILE' class='control-element'  
                       required/>  
            </div>  
        </div>
  
        <div class='form-group'>  
            <label class='control-label col-md-3' for='UPLOAD_PRE'>  
                _{PRE}_</label>
            <div class='col-md-9'>  
                <input type='checkbox' name='UPLOAD_PRE' id='UPLOAD_PRE' value=1 class='control-element'  
                       />  
            </div>  
        </div>

%EXTRA_ROWS%
  
    </form>  
</div>  

<div class='box-footer text-right'>
    <button type='submit' class='btn btn-primary' id='ajax_upload_submit' form='ajax_upload_form'>_{ADD}_</button>
</div>
</div>



<script src='/styles/default_adm/js/ajax_upload.js'></script>
