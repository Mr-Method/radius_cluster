<div class='well well-sm'>
  <form class='form form-inline form-main' role='form' action='$SELF_URL' method='POST'>
    <input type='hidden' name='index' value='$index'>

    <div class='form-group'><label class='control-label col-md-3'>_{ADMIN}_</label>
      <div class='col-md-9'>
        %AID_SELECT%
      </div>
    </div>

    <input type='submit' name='show' value='_{SHOW}_' class='btn btn-primary'>
  </form>
</div>