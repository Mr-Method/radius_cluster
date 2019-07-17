<form method='post'>
  <input type='hidden' name='index' value='$index'>
  <div class='box box-theme box-form form-horizontal'>
  <div class='box-body'>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{YEAR}_</label>
    <div class='col-md-6'>
    %YEARS_SELECT%
    </div>
    <div class='col-md-3'>
    <input class='btn btn-primary' type='submit' value='_{SHOW}_' name='SHOW'>
    </div>
  </div>
  </div>
  </div>
</form>

<div class='row'>
  <div class='col-md-12 col-sm-12'>
    <div class='box box-theme  form-horizontal'>
    <div class="box-header with-border">
      <h3 class="box-title">_{DIFFERENCE_PUBLIC_UTILITIES_FOR_PERIODS}_</h3>
        <div class="box-tools pull-right">
        <button type="button" class="btn btn-box-tool" data-widget="collapse"><i class="fa fa-minus"></i></button>
        </div>
        <!-- /.box-tools -->
    </div>
    <div class='box-body'>
      %CHART_COUNTER%
    </div>
    </div>
  </div>

  <div class='col-md-12 col-sm-12'>
    <div class='box box-theme  form-horizontal'>
    <div class="box-header with-border">
      <h3 class="box-title">_{SPENT_MONEY_FOR_PUB_UTILITIES_FOR_PERIODS}_</h3>
        <div class="box-tools pull-right">
        <button type="button" class="btn btn-box-tool" data-widget="collapse"><i class="fa fa-minus"></i></button>
        </div>
        <!-- /.box-tools -->
    </div>
    <div class='box-body'>
      %CHART_MONEY%
    </div>
    </div>
  </div>
  
  <div class='col-md-12 col-sm-12'>
    <div class='box box-theme  form-horizontal'>
    <div class="box-header with-border">
      <h3 class="box-title">_{AMOUNT_MONEY_SPENT}_</h3>
        <div class="box-tools pull-right">
        <button type="button" class="btn btn-box-tool" data-widget="collapse"><i class="fa fa-minus"></i></button>
        </div>
        <!-- /.box-tools -->
    </div>
    <div class='box-body'>
      %CHART_MONEY_TOTAL%
    </div>
    </div>
  </div>

</div>