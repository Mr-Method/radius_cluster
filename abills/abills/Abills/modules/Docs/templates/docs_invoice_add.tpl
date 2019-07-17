%MENU%

<form action='$SELF_URL' method='post' name='invoice_add' id='invoice_add' class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='DOC_ID' value='%DOC_ID%'>
  <input type=hidden name='sid' value='$FORM{sid}'>
  <input type=hidden name='OP_SID' value='%OP_SID%'>
  <input type=hidden name='VAT' value='%VAT%'>
  <input type=hidden name='SEND_EMAIL' value='1'>
  <input type=hidden name=INCLUDE_DEPOSIT value=1>

  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h4 class='box-title'>%CAPTION%</h4>

      <span class='pull-right'>
        <a href='$SELF_URL?full=1&get_index=docs_invoice_company&UID=%UID%' class='btn btn-xs btn-success' >_{NEXT_PERIOD_INVOICE}_</a>
      </span>

    </div>
    <div class='box-body'>

      %FORM_INVOICE_ID%

      <div class='form-group'>
        <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>
        <div class='col-md-9'>
          %DATE_FIELD%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CUSTOMER'>_{CUSTOMER}_</label>
        <div class='col-md-9'>
          <input type='text' id='CUSTOMER' name='CUSTOMER' value='%CUSTOMER%' placeholder='%CUSTOMER%'
                 class='form-control'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PHONE'>_{PHONE}_</label>
        <div class='col-md-9'>
          <input type='text' id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%' class='form-control'>
        </div>
      </div>

      <div class='form-group'>
        <div class="col-md-12">
          <table class='table table-bordered table-hover' id='tab_logic'>
            <thead>
            <tr>
              <th class='text-center col-md-1'>
                #
              </th>
              <th class='text-center'>
                _{NAME}_
              </th>
              <th class='text-center col-md-1'>
                _{COUNT}_
              </th>
              <th class='text-center col-md-2'>
                _{SUM}_
              </th>
            </tr>
            </thead>
            <tbody>

            <tr id='addr1'>
              <td>
                <input type=hidden name=IDS value='1'>
                1
              </td>
              <td>
                <input type='text' name='ORDER_1' value='%ORDER_1%' placeholder='_{ORDER}_' class='form-control'/>
              </td>
              <td>
                <input type='text' name='COUNTS_1' value='%COUNTS_1%' placeholder='1' class='form-control'/>
              </td>
              <td>
                <input type='text' name='SUM_1' value='%SUM_1%' placeholder='0.00' class='form-control'/>
              </td>
            </tr>
            <tr id='addr2'></tr>
            </tbody>
          </table>
          <a id='add_row' class='btn btn-sm btn-default pull-left'>
            <span class='glyphicon glyphicon-plus'></span>
          </a>
          <a id='delete_row' class='btn btn-sm btn-default pull-right'>
            <span class='glyphicon glyphicon-minus'></span>
          </a>
        </div>
      </div>

    </div>

    <div class='box-footer'><input type=submit name=create value='_{CREATE}_' class='btn btn-primary'></div>

  </div>


  <!-- <input type=submit name=pre value='_{PRE}_'>  -->
</form>

<!-- http://bootsnipp.com/snippets/featured/dynamic-table-row-creation-and-deletion -->

<script>
  jQuery(document).ready(function () {

    var i = 2;
    jQuery('#add_row').click(function () {
      jQuery('#addr' + i).html("<td>" + i + " <input type=hidden name=IDS value='" + i + "'>" + "</td><td><input name='ORDER_" + i + "' type='text' placeholder='_{ORDER}_' class='form-control input-md'  /> </td><td><input  name='COUNTS_" + i + "' type='text' placeholder='1'  class='form-control input-md'></td><td><input  name='SUM_" + i + "' type='text' placeholder='0.00'  class='form-control input-md'></td>");
      jQuery('#tab_logic').append('<tr id="addr' + (i + 1) + '"></tr>');
      i++;
    });

    jQuery('#delete_row').click(function () {
      if (i > 1) {
        jQuery("#addr" + (i - 1)).html('');
        i--;
      }
    });
  });

</script>