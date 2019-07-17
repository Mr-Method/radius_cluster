<link rel='stylesheet' href='/styles/default_adm/css/msgs.css'/>

<script>
    var tasksInfo = {};
</script>

<script src='/styles/default_adm/js/msgs/shedule_table.js'></script>


%OPTIONS_SCRIPT%

<div class='row well'>

    <div class='col-md-6'>
        <form class='form form-inline' action=''>
            <input type='hidden' name='index' value='$index'/>
            <label class='control-label'>_{STATUS}_: </label>
            %TASK_STATUS_SELECT%

            <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>
        </form>
    </div>
    <div class='col-md-6'>

        <a href='/admin/index.cgi?index=$index&DATE=%PREV_MONTH_DATE%'>
            <button type='submit' class='btn btn-default btn-sm'>
                <span class="glyphicon glyphicon-arrow-left" aria-hidden="true"></span>
            </button>
        </a>
        <label class='control-label' style='margin: 0 20px'>%MONTH_NAME% %YEAR%</label>
        <a href='/admin/index.cgi?index=$index&DATE=%NEXT_MONTH_DATE%'>
            <button type='submit' class='btn btn-default btn-sm'>
                <span class="glyphicon glyphicon-arrow-right" aria-hidden="true"></span>
            </button>
        </a>

    </div>
</div>


<div class='row text-left'>
    <div id='new-tasks'></div>
</div>

<div class='row'>

    %TABLE%
</div>

<div class='box-footer'>
    <form id='tasksFormMonth' method='POST' action='$SELF_URL'>
        <div class='row'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='DATE' value='%DATE%' />

            <input type='hidden' id='jobsNew' name='jobs'/>
            <input type='hidden' id='jobsPopped' name='popped'/>

            <div class='center-block text-center'>
                <button class='btn btn-default' type='reset' id='cancelBtn'>_{CANCEL}_</button>
                <input type='submit' class='btn btn-primary' id='saveBtn' name='change' value='_{CHANGE}_'>
            </div>
        </div>
    </form>
</div>


<!-- Styling calendar -->
<style>

    table.work-table-month > tbody > tr > td {
        vertical-align: top !important;
    }

    table.work-table-month > tbody > tr > td.active {
        cursor: not-allowed;
    }

    table.work-table-month td {
        width: 70px;
        height: 100px;

        border: 1px silver solid;
    }

    table.work-table-month a.mday {
        right: 0;
        text-align: right;
    }

    .workElement {
        background-color: lightblue;
        border: 1px solid lightblue;
        border-radius: 3px;
        margin: 1px 0;
        font-weight: 600;
    }

</style>
<script>

    var table = jQuery('table.work-table-month');
    var table_tds = table.find('td');

    table_tds.find('a.weekday').parent().addClass('bg-danger');
    table_tds.find('span.disabled').parent().addClass('active');

    table_tds.find('a.mday').parent().addClass('dayCell');

</script>
