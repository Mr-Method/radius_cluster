<form class='form-horizontal'>

<input type='hidden' name='index' value='%index%'>
<input type='hidden' name='visual' value='1'>
<input type='hidden' name='sub' value='2'>
<input type='hidden' name='NAS_ID' value='%NAS_ID%'>

<div class='box box-theme'>
  <div class='box-header with-border'><h4>_{ADD}_ Vlan</h4></div>
  <div class='box-body'>
    <div class='form-inline col-md-7'>
      <label>_{PORTS}_ </label>
      <input type='number' class='form-control' name='ports_from' value = '1'>
      <label> -- </label>
      <input type='number' class='form-control' name='ports_to' value = '%PORTS%'>
    </div>
    <div class='form-inline col-md-5'>
      <label>VLAN _{FROM}_</label>
      <input type='number' class='form-control' name='VLAN'>
      <input type='submit' class='btn btn-primary' style='margin-left : 10px;' name='vlans_add' value='_{CREATE}_'>
    </div>
  </div>
</div>

</form>
