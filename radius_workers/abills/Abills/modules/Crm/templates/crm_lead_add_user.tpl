<script>
 jQuery(function(){
   jQuery('#add_uid').on('click', function () {
     console.log("Ready to proccess");
     jQuery.get('?qindex=$index&header=2&LEAD_ID=$FORM{LEAD_ID}&add_uid='+ jQuery('#UID_HIDDEN').val());
      location.reload();
   });
 });
</script>

<input type=hidden name=UID id='UID_HIDDEN' value='%UID%'/>
<div class="form-group">
  <div class='col-md-8'>
    <input type='text' form='unexistent' class='form-control' name='LOGIN' value='%USER_LOGIN%' id='LOGIN'
           readonly='readonly'/>
  </div>
  <div class='col-md-2'>
    %USER_SEARCH%
  </div>
  <div class='col-md-2'>
    <button type="button" class='btn btn-primary' id='add_uid'><span class="glyphicon glyphicon-check"></span></button>
  </div>
</div>
