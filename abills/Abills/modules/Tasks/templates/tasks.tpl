<style>
.card, .card:hover {
  display: inline-block;
  vertical-align: middle;
  border-radius: 3px;
  position: relative;
  padding: 15px 5px;
  margin: 0 0 10px 10px;
  width: 160px;
  height: 130px;
  text-align: left;
  font-size: 14px;
}
.card-success, .card-success:hover {
  color: #155724;
  background-color: #d4edda;
  border-color: #c3e6cb;
}
.card-warning, .card-warning:hover {
  color: #856404;
  background-color: #fff3cd;
  border-color: #ffeeba;
}
.card-danger, .card-danger:hover {
  color: #721c24;
  background-color: #f8d7da;
  border-color: #f5c6cb;
}
.card-info, .card-info:hover  {
  color: #0c5460;
  background-color: #d1ecf1;
  border-color: #bee5eb;
}
.card-grey, .card-grey:hover {
    color: #383d41;
    background-color: #e2e3e5;
    border-color: #d6d8db;
}
.card-selected, .card-selected:hover {
   border: 1px solid;
}
.card>.badge {
    position: absolute;
    top: 0px;
    right: 0px;
    font-size: 10px;
    font-weight: 400;
}
.card>div {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.card>hr {
  margin-top: 10px;
  margin-bottom: 10px;
}
</style>
<form>
  <div class='row text-left'>
    <div class='col-md-12' style="padding: 15px 10px;">%TASK_BOX%</div>
    <ul class='nav nav-tabs' id='tasks_tab'>
      <li class='%LI_ACTIVE_1%'><a data-toggle='tab' href='#t1'>_{MY_TASKS}_ <span class="label label-danger">%M_COUNT%</span></a></li>
      <li class='%LI_ACTIVE_2%'><a data-toggle='tab' href='#t2'>_{TASKS}_ <span class="label label-primary">%P_COUNT%</span></a></li>
    </ul>
    <div class='col-md-12'>
      <div class='tab-content'>
        <div id='t1' class='tab-pane fade %DIV_ACTIVE_1%'><br>%MY_TASKS%</div>
        <div id='t2' class='tab-pane fade %DIV_ACTIVE_2%'><br>%TASKS%</div>
      </div>
    </div>
  </div>
</form>