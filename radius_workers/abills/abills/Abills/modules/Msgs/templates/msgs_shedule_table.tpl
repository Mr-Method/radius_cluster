<link rel='stylesheet' href='/styles/default_adm/css/msgs.css'>
<script src='/styles/default_adm/js/msgs/shedule_table.js'></script>
<script>
    var tasksInfo = {};
</script>

%OPTIONS_SCRIPT%

<div class='row well well-sm'>
    <form class='form form-inline' action=''>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='ID' value='$FORM{ID}'/>

        <label class='control-label' for='FORM_DATE'>_{DATE}_: </label>
        <input type='text' class='tcal form-control' name='DATE' value='$FORM{DATE}' id='FORM_DATE'/>

        <label class='control-label' for='TASK_STATUS_SELECT'>_{STATUS}_: </label>
        %TASK_STATUS_SELECT%

        <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>
    </form>
</div>

<div class='row text-left'>
    <div id='new-tasks'></div>
</div>
<div class='row'>
    <div id='hour-grid'></div>
</div>


<div class='box-footer'>
    <form id='tasksForm' method='POST' action='$SELF_URL'>
        <div class='row'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='jobs' id='jobsNew' />
            <input type='hidden' name='popped' id='jobsPopped' />

            <div class='center-block text-center'>
                <button class='btn btn-default' type='reset' id='cancelBtn'>_{CANCEL}_</button>
                <input type='submit' class='btn btn-primary' id='saveBtn' name='change' value='_{CHANGE}_'>
            </div>
        </div>
    </form>
</div>

<style>
    div#hour-grid > table {
        border: 1px solid silver;
    }

    div#hour-grid > table > tr > td {
        width: 110px;
        height: 30px;
    }
</style>

