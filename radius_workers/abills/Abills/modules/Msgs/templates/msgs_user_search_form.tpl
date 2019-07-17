<FORM action='$SELF_URL' METHOD='GET' enctype='multipart/form-data' name='MsgSearchForm' id='MsgSearchForm'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='sid' value='$sid'/>
    <input type='hidden' name='ID' value='%ID%'/>

    <div class='box box-primary'>
        <div class="box box-body">

            <div class='col-md-12'>
                <div class="input-group input-group-sm">

                    <span class="input-group-btn" id="search_addon" >
                        <button name="search_msgs" class="btn btn-primary" type="submit" value='_{SEARCH}_'>
                            <i class="fa fa-search"></i>
                        </button>
                    </span>

                    <input class="form-control"  name="SEARCH_MSG_TEXT" type="text">

                </div>
           </div>

        </div>
    </div>
</FORM>