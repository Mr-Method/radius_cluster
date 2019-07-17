<div class='well well-sm'>

    <form name='MSGS_EMPLOYEES_TASKS' id='form_MSGS_EMPLOYEES_TASKS' method='post' class='form form-inline'>
        <input type='hidden' name='index' value='$index'/>


        <label class='control-label required' for='AID'>_{ADMIN}_</label>
        %AID_SELECT%


        <label class='control-label' for='DATE_id'>_{DATE}_ _{TYPE}_</label>
        %DATE_TYPE_SELECT%
        <input type='text' class='form-control datepicker' name='DATE' id='DATE_id' placeholder='$DATE' value='$FORM{DATE}'/>

        <input type='submit' class='btn btn-primary' name='action' value='_{SHOW}_'/>

    </form>

</div>