    <script type="text/javascript">
      function add_delivery() {

        var DELIVERY_CREATE = document.getElementById('DELIVERY_CREATE');

        if (DELIVERY_CREATE.checked) {
          DELIVERY_CREATE.checked = false;
          comments = prompt('_{SUBJECT}_', '');

          var new_delivery = document.getElementById('new_delivery');
          var delivery_list = document.getElementById('delivery_list');
          var DELIVERY_COMMENTS = document.getElementById('DELIVERY_COMMENTS');

          if (comments == '' || comments == null) {
            alert('Enter comments');
            DELIVERY_CREATE.checked = false;
            new_delivery.style.display = 'none';
            delivery_list.style.display = 'block';
          }
          else {
            DELIVERY_CREATE.checked = true;
            DELIVERY_COMMENTS.value = comments;
            new_delivery.style.display = 'block';
            delivery_list.style.display = 'none';
          }
        }
        else {
          DELIVERY_CREATE.checked = false;
          DELIVERY_COMMENTS.value = '';
          new_delivery.style.display = 'none';
          delivery_list.style.display = 'block';
        }
      }
    </script>
    <style type="text/css">
     /* BOX-BODY DELIVERY STYLE */
     #delivery_box_body .row{
      padding: 0.5em;
     }
    </style>

  <fieldset>
    <div  id='delivery_list'>
      <div class="input-group">
        <span class="input-group-addon">
          _{ADD}_
          <input form="users_list" id=DELIVERY_CREATE name=DELIVERY_CREATE value=1 onClick='add_delivery();' title='_{CREATE}_ _{DELIVERY}_' type="checkbox" id='DELIVERY_CHECKBOCS' aria-label="Checkbox">
        </span>
        %DELIVERY_SELECT_FORM%
        <span class="input-group-addon"><a title="info" href="%DELIVERY_SPAN_ADDON_URL%"><span class="glyphicon glyphicon-list-alt"></span></a></span>
      </div>
    </div>

    <div id=new_delivery style='display: none'>
     <!-- BOX-BODY MU_DELIVERY-->
     <div class="box box-warning">
     <div class="box-body" id='delivery_box_body'>

      <div class='row'>
          <label class='control-label col-md-2 ' for='DELIVERY_COMMENTS'>_{SUBJECT}_:</label>
          <div class='col-md-10'>
            <input form="users_list"  type=text id=DELIVERY_COMMENTS name=DELIVERY_COMMENTS value='%DELIVERY_COMMENTS%' class='form-control'>
          </div>
      </div>

      <div class="row">
        <label class='control-label col-md-2 ' for='TEXT'>_{MESSAGES}_:</label>
        <div class='col-md-10'>
          <textarea  form="users_list" class='form-control'  rows='5' %DISABLE% id='TEXT' name='TEXT'  placeholder='_{TEXT}_' >%TEXT%</textarea>
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
</fieldset>
