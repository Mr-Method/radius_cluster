<script type="text/javascript">
	function autoReload (){
		jQuery('#REPORT').remove();
		jQuery('#REPORTS_SHOW').submit();
	}
</script>

<form action=$SELF_URL METHOD=post class='form-inline' role='form' id='REPORTS_SHOW'>
<input type=hidden name=index value=$index>

GID:
<div class='form-group'>
%GROUP_SEL% 
</div>

_{REPORTS}_:
<div class='form-group'>
%REPORTS_SEL% 
</div>
 
<input type=submit class='btn btn-default' name=SHOW value='_{SHOW}_'>
</form>