<form>
<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value='%ID%'>

<div class='row'>

  %LEAD_PROFILE_PANEL%

  <div class='col-md-9'>
        %PROGRESSBAR%
  </div>
</div>

</form>

<script type="text/javascript">
  Events.on("AJAX_SUBMIT.form_CRM_LEAD_SEARCH", function(){
    location.reload(false)
  })
</script>