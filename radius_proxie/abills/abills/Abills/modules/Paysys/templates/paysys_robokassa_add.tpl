<form action="https://merchant.roboxchange.com/Index.aspx" method=POST>
    
    <input type=hidden name=MrchLogin value=%LOGIN%>
    <input type=hidden name=OutSum value=%SUMMA%>
    <input type=hidden name=InvId value=%OID%>
    <input type=hidden name=Desc value=%DESCRIPTION%>
    <input type=hidden name=SignatureValue value=%SIGNTR%>
    <input type=hidden name=shp_Id value=%SHP_ID%>
    <input type=hidden name=IncCurrLabel value=%CURR%>
    <input type=hidden name=Culture value=%LANG%>
    <input type=hidden name=Encoding value=%ENCODE%>
    <input type=hidden name=IsTest value=%MODE%>
    
    
<div class='box box-primary'>
    <div class='box-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='box-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>ROBOKASSA</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> %SUMMA% </label>
    </div>
</div>
    <div class='box-footer'>
        <input class='btn btn-primary' type=submit value=_{PAY}_>
    </div>
</div>    

    

</div>
</form>