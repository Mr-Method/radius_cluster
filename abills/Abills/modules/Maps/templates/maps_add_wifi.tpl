<form action=$SELF_URL name=WIFI_ADD_FORM id=WIFI_ADD_FORM class='form-inline'>
  <input type=hidden name=index value=$index>
  <input type=hidden name='COORDX' value=%COORDX%>
  <input type=hidden name='COORDY' value=%COORDY%>

  <input type='hidden' name='LAYER_ID' value='2'/>
  <input type='hidden' name='get_index' value='maps_add_2'/>
  <input type='hidden' name='header' value='2'/>
  <input type='hidden' name='add' value='1'/>
  <input type='hidden' name='AJAX' value='1'/>

  _{ADD_WIFI_RADIUS}_: <input type=text name=RADIUS value='%RADIUS%' size=10 class='form-control'> _{METERS_SHORT}_

  <input type=submit name=add_wifi value=_{ADD}_ class='btn btn-primary'>

</form>

<script>
  // Sending form as AJAX request, to prevent tab reloading
  var form_id = 'WIFI_ADD_FORM';
  var form = jQuery('form#' + form_id);

  form.on('submit', function (e) {
    e.preventDefault();

    var formData = form.serialize();

    form.find('input[type="submit"]').addClass('disabled');

    jQuery.post(form.attr('action'), formData, function (data) {
      aModal.updateBody(data);
    });
  });
</script>
