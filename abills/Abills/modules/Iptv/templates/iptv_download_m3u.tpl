<form method='post'>
<input type='hidden' name='index' value='$index' />

<div class='box box-primary form-horizontal'>
<div class='box-header with-border'>_{DOWNLOAD_CHANNELS}_</div>
<div class='box-body'>
%TABLE%

<div class='form-group'>
  <label class='col-md-3 control-label text-center required'>_{NAME}_ _{FILE}_</label>
  <div class='col-md-9'>
    <div class='input-group'>
    <input type='text' class='form-control' required name='FILENAME' value='%FILENAME%' placeholder='Channels IPTV'>
    <span class='input-group-addon'>.m3u</span>
    </div>
    <!-- <input type='text' class='form-control' name='FILENAME' value='%FILENAME%'> -->
  </div>

</div>
</div>
<div class='box-footer'><button type='submit' class='btn btn-primary'>_{EXPORT}_</button></div>
</div>

</form>