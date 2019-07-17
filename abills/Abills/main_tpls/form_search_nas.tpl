<form id='form-search' name='nfrmSearchNAS' class='form-horizontal'>
    <input type='hidden' name='index' value='$index' form='form-search'/>
    <input type='hidden' name='POPUP' value='%POPUP%' form='form-search'/>
    <input type='hidden' name='NAS_SEARCH' value='1' form='form-search'/>

    <div class='box box-theme box-form'>
        <div class='box-body'>
            <div class='form-group'>
                <label for='NAS_ID' class='control-label col-xs-3'>ID :</label>
                <div class='col-xs-9'>
                    <input class='form-control' id='NAS_ID' placeholder='%NAS_ID%' name='NAS_ID' value='%NAS_ID%'
                           form='form-search'/>
                </div>
            </div>

            <div class='form-group'>
                <label for='NAS_IP' class='control-label col-xs-3'>IP:</label>
                <div class='col-xs-9'>
                    <input class='form-control' id='NAS_IP' placeholder='%NAS_IP%' name='NAS_IP' value='%NAS_IP%'
                           form='form-search'/>
                </div>
            </div>

            <div class='form-group'>
                <label for='NAS_NAME' class='control-label col-xs-3'>_{NAME}_:</label>
                <div class='col-xs-9'>
                    <input class='form-control' id='NAS_NAME' placeholder='%NAS_NAME%' name='NAS_NAME'
                           value='%NAS_NAME%'
                           form='form-search'/>
                </div>
            </div>

            <div class='form-group'>
                <label for='NAS_INDENTIFIER' class='control-label col-xs-3'>Radius NAS-Identifier:</label>
                <div class='col-xs-9'>
                    <input class='form-control' id='NAS_INDENTIFIER' placeholder='%NAS_INDENTIFIER%'
                           name='NAS_INDENTIFIER'
                           value='%NAS_INDENTIFIER%' form='form-search'/>
                </div>
            </div>

            <div class='form-group'>
                <label for='SEL_TYPE' class='control-label col-xs-3'>TYPE:</label>
                <div class='col-xs-9'>%SEL_TYPE%</div>
            </div>

            <div class='form-group'>
                <label for='MAC' class='control-label col-xs-3'>MAC:</label>
                <div class='col-xs-9'>
                    <input class='form-control' id='MAC' placeholder='%MAC%' name='MAC' value='%MAC%'
                           form='form-search'/>
                </div>
            </div>

            <div class='form-group'>
                <label for='NAS_GROUPS_SEL' class='control-label col-xs-3'>_{GROUPS}_:</label>
                <div class='col-xs-9'>%NAS_GROUPS_SEL%</div>
            </div>

            %SEARCH_BTN%
        </div>
    </div>

</form>


<!--/div-->

