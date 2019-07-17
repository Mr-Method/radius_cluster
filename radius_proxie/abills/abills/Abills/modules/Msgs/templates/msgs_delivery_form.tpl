    <style type="text/css">
     /* BOX-BODY DELIVERY STYLE */
     #new_delivery .row{
      padding: 0.5em;
     }
    </style>

<div class='box box-theme box-big-form collapsed-box %PARAMS%'>
 <div class='box-header with-border'>
   <h4 class='box-title'>_{DELIVERY}_</h4>
   <div class='box-tools pull-right'>
     <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
     </button>
   </div>
 </div>
 <div id='delivery' class='box-body'>

  <div class='form-group'>
  <div id='delivery_list'>
  <label class='control-label col-md-3'>_{DELIVERY}_</label>
    <div class='col-md-6'>
      <div class="input-group">
        <span class="input-group-addon">
          _{ADD}_
          <input  id=DELIVERY_CREATE name=DELIVERY_CREATE value=1 onClick='add_delivery();' title='_{CREATE}_ _{DELIVERY}_' type="checkbox" id='DELIVERY_CHECKBOCS' aria-label="Checkbox">
        </span>
        %DELIVERY_SELECT_FORM%
      </div>
    </div>
</div>

    <div id=new_delivery style='display: none'>

      <div class='row'>
          <label class='control-label col-md-2 ' for='DELIVERY_COMMENTS'>_{SUBJECT}_:</label>
          <div class='col-md-10'>
            <input  type=text id=DELIVERY_COMMENTS name=DELIVERY_COMMENTS value='%DELIVERY_COMMENTS%' class='form-control'>
          </div>
      </div>

      <div class="row">
        <label class='control-label col-md-2 ' for='TEXT'>_{MESSAGES}_:</label>
        <div class='col-md-10'>
          <textarea   class='form-control'  rows='5' %DISABLE% id='TEXT' name='TEXT'  placeholder='_{TEXT}_' >%TEXT%</textarea>
        </div>
      </div>

      <div class='row'>
        <label class='control-label col-md-2 ' for='DELIVERY_SEND_TIME'>_{SEND_TIME}_:</label>
        <div class='col-md-5'>
          %DATE_PIKER%
        </div>
        <div class='col-md-5'>
          %TIME_PIKER%
        </div>
      </div>

      <div class='row'>
        <label class='control-label col-md-2 ' for='STATUS'>_{STATUS}_:</label>
        <div class='col-md-10'>
          %STATUS_SELECT%
        </div>
      </div>
      <div class='row'>
        <label class='control-label col-md-2 ' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-10'>
          %PRIORITY_SELECT%
        </div>
      </div>

      <div class='row'>
        <label class='control-label col-md-2 ' for='SEND_METHOD'>_{SEND}_:</label>
        <div class='col-md-10'>
          %SEND_METHOD_SELECT%
        </div>
      </div>

  </div>
  </div>

</div>
</div>
