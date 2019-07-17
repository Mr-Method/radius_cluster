<style type="text/css">
	.calend{
		max-width:1000px;
	}
</style>

<div class='box box-info calend'>

<div class='box-header with-border '>

	<a href='/admin/index.cgi?index=75&year=%LAST_YEAR%&month=%LAST_MONTH%'>
		<button type='submit' class='btn btn-default btn-xs' align='left'>
			<span class="glyphicon glyphicon-arrow-left" aria-hidden="true"></span>
		</button>
	</a>
	<label class='control-label'>%MONTH% %YEAR%</label>
	
	<a href='/admin/index.cgi?index=75&year=%NEXT_YEAR%&month=%NEXT_MONTH%'>
		<button type='submit' class='btn btn-default btn-xs' align='right'>
			<span class="glyphicon glyphicon-arrow-right" aria-hidden="true"></span>
		</button>
	</a>

</div>

<div class='table-responsive text-center' >
  <table class='table table-bordered no-highlight'>
		<thead>
			<tr>
				<td>$WEEKDAYS[1]</td>
				<td>$WEEKDAYS[2]</td>
				<td>$WEEKDAYS[3]</td>
				<td>$WEEKDAYS[4]</td>
				<td>$WEEKDAYS[5]</td>
				<td class='danger'>$WEEKDAYS[6]</td>
				<td class='danger'>$WEEKDAYS[7]</td>
			</tr>
		</thead>
		<tbody>
		  %DAYS%
		</tbody>
	</table>
</div>

</div>


</div>