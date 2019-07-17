<form name='form_RANGE_PICKER' id='form_RANGE_PICKER' method='GET' class='form form-horizontal'>
    <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4 class='box-title'>_{FILLING_TIMETRACKER}_ %CAPTION%</h4></div>
        <div class='box-body'>

            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='add_form' value='1'>

            %FORM_GROUP%

            %DATEPICKER%
        </div>

        <div class='box-footer text-center'>
            <input type='submit' form='form_RANGE_PICKER' class='btn btn-primary' name='%ACTION%' value='%BTN%'>
        </div>
    </div>
</form>

<script>
  jQuery('input#DATE').on('change', function(){

    var new_value = this.value;

    jQuery.getJSON('/admin/index.cgi', {
      qindex : '$index',
      // json : 1,
      // header : 1,
      get_time_for_date : new_value
    }, function(data){

      // If multiple values
// #{
// #  support : '0.22',
// #  dev : '5.25'
// #}

      for (var input_name in data){
        jQuery('input#' + input_name).val(data[input_name]);
      }

    })
  });
</script>