/**
 * Created by Anykey on 27.10.2015.
 *
 *  Draggabble and droppable tasks + table
 *
 */

//Default options
var tableOptions = {
  container: '#hour-grid',
  administrators: [
    {"name": 'Mickey', id: 0},
    {"name": 'Donald', id: 1},
    {"name": 'Arnold', id: 2},
    {"name": 'Donatello', id: 3},
    {"name": 'Rembo', id: 4},
    {"name": 'Splinter', id: 5}
  ],

  hours: 9,
  startTime: 9,
  fraction: 60,
  timeUnit: 0,

  dinnerTime: 13,
  dinnerLength: 60,

  highlighted: 0
};

var isDayTable = false;
var isMonthTable = false;

$(function () {

  isDayTable = $('div#hour-grid').length > 0;
  isMonthTable = $('table.work-table-month').length > 0;

  console.assert(isDayTable !== isMonthTable, "Something goes wrong");

});


var AWorkTable = (function () {
  var $Table;
  var $base;

  var opts = {};
  var jobs = [];
  var tasks = [];

  var DEFAULTS = tableOptions;

  //bind events
  $(function () {

    $('#tasksForm').on('submit', function () {

      $('#jobsNew').val(JSON.stringify(jobs));
      $('#jobsPopped').val(JSON.stringify(ATasks.getTasks()));

    });

    $('#cancelBtn').on('click', function () {
      location.reload(false);
    });
  });


  function generate(options) {
    if (options) {
      for (var key in DEFAULTS) {
        opts[key] = options[key] || DEFAULTS[key];
      }
    } else {
      opts = DEFAULTS;
    }

    $Table = $('' + opts.container);

    var $table = $('<table></table>');
    $table.append(getTimeRow(opts.startTime, opts.hours, opts.fraction, opts.timeUnit));

    for (var i = 0; i < opts.administrators.length; i++) {

      var $tr = $('<tr></tr>');
      var $adminTd = $('<td></td>').text(opts.administrators[i].name);
      $adminTd.addClass('adminCaption');
      $tr.append($adminTd);

      //saving row reference
      opts.administrators[i].rowNum = i;
      opts.administrators[i].row = $tr;
      if (opts.timeUnit == 0) {
        for (var j = 0; j < opts.hours * 60 / opts.fraction; j++) {
          var $td = $('<td></td>');
          $td.attr('class', 'task taskFree');
          $td.attr('row', i);
          $td.attr('col', j);
          $tr.append($td);
        }
      } else if (opts.timeUnit == 1) {
        if ($.isArray(opts.hours)) {
          for (var j = 0; j < opts.hours.length; j++) {
            var $td = $('<td></td>');
            $td.attr('class', 'task taskFree');
            $td.attr('row', i);
            $td.attr('col', j);
            $tr.append($td);
          }
        } else {
          for (var j = 0; j < opts.hours; j++) {
            var $td = $('<td></td>');
            $td.attr('class', 'task taskFree');
            $td.attr('row', i);
            $td.attr('col', j);
            $tr.append($td);
          }
        }
      }

      $table.append($tr);
    }
    $table.addClass('table table-striped table-condensed');

    $base = $('<div></div>');
    $base.addClass('table-responsive');

    $base.append($table);

    return $base;
  }

  function render() {
    if ($base) {
      $Table.empty();
      $Table.append($base);
    }

    if (jobs.length > 0) {

      $.each(jobs, function (i, task) {
        //console.log(task);
        renderJob(task);
      });
    }

    calculateFreeSets();
  }

  function renderJob(job) {
    var admin = getAdministratorById(job.administrator);
    var $row = $(admin.row);

    $.each(job.tasks, function (i, task) {
      if (typeof task != 'undefined')
        fillTask(task.id, task.name, task.start, task.length, true);

      function fillTask(id, name, start, length, first) {
        var cell = $row.find('td') [start + 1];
        var $cell = $(cell);

        $cell.removeClass('taskFree');
        $cell.addClass('taskBusy');

        if (opts.highlighted != 0 && id == opts.highlighted) $cell.addClass('taskActive');

        $cell.attr('title', name);
        $cell.attr('taskId', id);

        if (tasksInfo[id]) {
          renderTooltip($cell, tasksInfo[id], 'down');
        }


        if (first) {
          var removeLink = '<a onclick="AWorkTable.unlinkTask(this)">' +
            '<span class="glyphicon glyphicon-remove"></span>' +
            '</a>&nbsp;&nbsp;';
          var detailLink = '<a href="?header=3&full=1&get_index=msgs_admin&chg=' + task.id + '" target="_blank">' +
            '<span class="glyphicon glyphicon-list-alt"></span>' +
            '</a>&nbsp;&nbsp;';

          $cell.html(removeLink + detailLink);
        }

        var newLength = length - 1;
        if (newLength > 0) {
          fillTask(id, name, start + 1, newLength, false);
        }
      }
    });
  }


  function calculateFreeSets() {
    $.each(opts.administrators, function (i, admin) {
      var $row = admin.row;
      var $cells = $row.find('td');
      processCells($cells);
    });

    function processCells($cells) {
      var counter = 0;
      for (var i = $cells.length; i >= 0; i--) {
        var $cell = $($cells[i]);
        if (isCellFree($cell)) {
          $cell.attr('lengthfree', counter++)
        } else {
          counter = 1;
        }
      }
    }
  }

  function isCellFree($cell) {
    return typeof ($cell.attr('taskId')) === 'undefined';
  }

  function renew() {
    generate(opts);
    render();
  }

  function getRow(index) {
    return $($Table.find('tr')[index]);
  }

  function getCell(row, col) {
    return getRow(row).find('td')[col];
  }

  function getTimeRow(startTime, hours, fraction, timeUnit) {
    var formatTime = function(minutes){
      var mins = minutes % 60;
      var hours = (minutes - mins) /60;
      
      return  ((hours < 10) ? '0' + hours : hours)
      +  ':'
      + ((mins < 10) ? '0' + mins : mins);
    };
    
    if (timeUnit === 0) {
      var quant = fraction;      //in minutes
      var start = startTime * 60; //in minutes from 00:00
      var end = start + (hours * 60); //in minutes from 00:00

      var $tr = $('<tr></tr>');
      $tr.addClass('timeRow');
      $tr.append($('<td></td>')); // adding first empty cell

      for (var j = start; j < end; j += quant) {
        var $td = $('<td></td>');
        $td.text(formatTime(j));
        $td.addClass('timeTd');
        $tr.append($td);
      }

      return $tr;
    } else if (timeUnit == 1) {
      if ($.isArray(hours)) {
        var quant = 1; //1 day
        var $tr = $('<tr></tr>');
        $tr.addClass('timeRow');
        $tr.append($('<td></td>')); // adding first empty cell

        for (var j = 0; j < hours.length; j += quant) {
          var $td = $('<td></td>');
          var text = hours[j];
          console.log(text);
          $td.text(text);
          $td.addClass('timeTd');
          $tr.append($td);
        }
        return $tr;
      } else {
        var quant = 1; //1 day
        var start = startTime;
        var end = start + hours;

        var $tr = $('<tr></tr>');
        $tr.addClass('timeRow');
        $tr.append($('<td></td>')); // adding first empty cell

        for (var j = start; j < end; j += quant) {
          var $td = $('<td></td>');
          var text = moment({}).day(j).format('DD');
          console.log(text);
          $td.text(text);
          $td.addClass('timeTd');
          $tr.append($td);
        }

        return $tr;
      }
    }
  }

  function getAdministratorById(id) {
    var admins = opts.administrators;
    for (var i = 0; i < admins.length; i++) {
      //console.log('Looking for: "' + id + '". Now at: "' + admins[i].id + '"');
      if (admins[i].id == id) return admins[i];
    }
    throw new Error('ADMIN NOT FOUND : ' + id);

  }

  function getAdministratorByRowNum(rowNum) {
    var admins = opts.administrators;
    for (var i = 0; i < admins.length; i++) {
      //console.log('Looking for: "' + rowNum + '". Now at: "' + admins[i].rowNum + '"');
      if (admins[i].rowNum == rowNum) return admins[i];
    }
    throw new Error('ADMIN NOT FOUND : ' + rowNum);

  }

  function addJob(job) {
    if (!(typeof(job) === 'undefined')) {
      jobs.push(job);

      $.each(job.tasks, function (i, task) {
        //alert('inside');
        tasks[task.id] = task;
      });

    }
    render();

  }

  function addJobs(jobs) {
    if (!(typeof(jobs) === 'undefined') && jobs.length > 0) {
      $.each(jobs, function (i, job) {
        addJob(job);
      })
    }
  }

  function unlinkTask(aLink) {
    var $cell = $(aLink).parent();
    var taskId = $cell.attr('taskId');

    $cell.popover('destroy');
    //find this task in inner array
    var task = popTaskById(taskId);
    //when found, add task to ATasksArray
    ATasks.addTask(task);
  }

  function popTaskById(taskId) {
    var result = -1;
    //iterate jobs
    $.each(jobs, function (i, job) {
      //iterate tasks in jobs
      $.each(job.tasks, function (j, task) {
        if (typeof task !== 'undefined')
          if (task.id + '' === taskId) {
            var result_arr = jobs[i].tasks.splice(j, 1);
            result = result_arr[0];
            renew();
          }
      });
    });
    if (result !== -1) {
      return result;
    }
    throw new Error('Task not found!');
  }


  return {
    init: generate,

    addJob: addJob,
    addJobs: addJobs,

    unlinkTask: unlinkTask,

    render: render,

    getAdministratorByRowNum: getAdministratorByRowNum
  }
})();

var AMonthWorkTable = (function () {
  var $Table = null;
  var year = null;
  var month = null;
  var dayCells = {};

  var rawJobs = [];
  var renderedJobs = [];

  $(function () {
    defineFormSubmitLogic();
  })

  function init() {
    $Table = $('table.work-table-month');
    year = $Table.attr('data-year');
    month = $Table.attr('data-month');

    var mdayLinks = $Table.find('a.mday');

    // Init hash for table cells
    if (mdayLinks.length > 0) {
      for (var i = 0; i < mdayLinks.length; i++) {
        var $mdayLink = $(mdayLinks[i]);
        var mday = $mdayLink.attr('data-mday');
        dayCells[mday] = $mdayLink.parent();
      }
    } else {
      _log(1, 'Msgs', 'Not a valid msgs_shedule2_month table. No mdayLinks inside');
    }
  }

  function addJob(ui, mday) {
    var task = ui.helper;

    addJobs([{
      id: task.attr('taskId'),
      name: task.attr('taskName'),
      plan_date: year + "-" + month + "-" + ensureLength(mday, 2)
    }]);

    task.popover('destroy');
    task.remove();
  }

  function addJobs(jobsArray) {
    if (jobsArray.length > 0) {
      // Fill tasks where date is defined
      if (jobsArray.length > 0) {
        for (var j = 0; j < jobsArray.length; j++) {
          renderJob(jobsArray[j])
        }
      }
    }
    else {
      _log(1, "Msgs", "Empty jobs array");
    }
  }

  function renderJob(task) {

    var jobDay = Number(task["plan_date"].split("-")[2]);

    rawJobs[task.id] = task;

    var $task = $('<div></div>');
    $task.addClass('workElement');

    var removeLink = '<a onclick="AMonthWorkTable.unlinkTask(this, ' + task.id + ')">' +
      '<span class="glyphicon glyphicon-remove"></span>' +
      '</a>&nbsp;&nbsp;';
    var detailLink = '<a href="?header=3&full=1&get_index=msgs_admin&chg=' + task.id + '" target="_blank">' +
      '<span class="glyphicon glyphicon-list-alt"></span>' +
      '</a>&nbsp;&nbsp;';
    var taskText = task.name;
    if (taskText.length > 20) {
      taskText = taskText.substr(0, 20) + "...";
    }
    $task.html(removeLink + detailLink + taskText);

    $task.attr('taskId', task.id);
    $task.attr('taskName', task.name);
    $task.attr('title', task.name);

    if (tasksInfo[task.id]) {
      renderTooltip($task, tasksInfo[task.id], 'right');
    }

    renderedJobs[task.id] = $task;

    dayCells[jobDay].append($task);
  }

  function unlinkTask(context, taskId) {
    var holder = $(context).parent();
    holder.popover("destroy");
    holder.remove();

    var task = rawJobs[taskId];
    delete task.plan_date;
    delete rawJobs[taskId];

    ATasks.addTask(task);
  }

  function defineFormSubmitLogic() {

    $('#tasksFormMonth').on('submit', function (event) {

      $('#jobsNew').val(JSON.stringify(desparseArray(rawJobs)));
      $('#jobsPopped').val(JSON.stringify(ATasks.getTasks()));

    });

    $('#cancelBtn').on('click', function () {
      location.reload(false);
    });

    function desparseArray(array) {
      var result = [];
      for (var i in array) {
        if (!array.hasOwnProperty(i)) continue;
        if (array[i] != null) result.push(array[i]);
      }
      return result;
    }
  }

  return {
    addJob: addJob,
    addJobs: addJobs,
    unlinkTask: unlinkTask,
    init: init
  }
})();

var ATasks = (function () {
  //cacheDOM
  var tasks = [];

  var $elementsWrapper;
  var gridWidth;
  var gridHeight;
  $(function () {
    $elementsWrapper = $('#new-tasks');
  });

  function render() {

    if (tasks.length > 0) {
      $elementsWrapper.empty();
      for (var id in tasks) {
        if (!tasks.hasOwnProperty(id)) continue;
        renderTask(tasks[id]);
      }
    }

    function renderTask(task) {

      var $task = $('<div></div>');
      $task.addClass('workElement');

      if (task.id == tableOptions.highlighted) {
        $task.addClass('taskActive');
      }

      var dragIcon = '&nbsp;<span class="glyphicon glyphicon-th"></span>&nbsp;';
      var taskText = '<span>' + task.name + '</span>';
      $task.html(dragIcon + taskText);
      $task.attr('taskLength', task.length);
      $task.attr('taskId', task.id);
      $task.attr('taskName', task.name);
      $task.attr('title', task.name);

      if (tasksInfo[id]) {
        renderTooltip($task, tasksInfo[id], 'down');
      }

      var cell = $('.taskFree');
      gridWidth = $(cell).css('width');
      gridHeight = $(cell).css('height');

      if (task.length > 1) {
        var unitlessWidth = gridWidth.replace('px', '');
        gridWidth = (Number(unitlessWidth) * task.length) + 'px';
      }
      $task.width(gridWidth);
      $task.height(gridHeight);

      $elementsWrapper.append($task);

      $task.draggable({
        snap: ".taskFree",
        snapMode: 'inner',
        start: initTargets,
        cursorAt: {
          top: 5,
          left: 1
        },
        revert: 'invalid'
      });
    }
  }

  function initTargets(event, ui) {
    //console.log(ui);
    var length = null;
    if (isDayTable) length = Number($(ui.helper).attr('taskLength'));

    var classForTarget = (isDayTable) ? 'taskFree' : 'dayCell';

    var dayTableDropFunction = function (event, ui) {
      var row = $(this).attr('row');
      var col = $(this).attr('col');
      ATasks.acceptTask(ui, row, col);
    };

    var monthTableDropFunction = function (event, ui) {
      var mday = $(this).find('a').attr('data-mday');
      delete tasks[ui.helper.attr('taskId')];
      AMonthWorkTable.addJob(ui, mday);
    };

    var droppableOptions = {
      accept: '.workElement',
      activeClass: "correctTarget",
      drop: (isDayTable) ? dayTableDropFunction : monthTableDropFunction,
      tolerance: 'pointer'
    };

    if (length != null && length > 1) {
      var $cells = $('.taskFree');
      $.each($cells, function (i, cell) {
        if ($(cell).attr('lengthFree') >= length) {
          $(cell).droppable(droppableOptions);
        }
      });
    }
    else {
      $('.' + classForTarget).droppable(droppableOptions);
    }
  }

  function addTask(task, renderBool) {
    tasks[task.id] = task;
    if (typeof(renderBool) === 'undefined')
      render();
  }

  function addTasks(taskArr) {
    if (!(typeof(taskArr) === 'undefined')) {
      $.each(taskArr, function (i, e) {
        addTask(e);
      });
      render();
    }
  }

  function acceptTask(ui, row, col) {
    var taskId = ui.draggable.attr('taskId');
    var taskLength = ui.draggable.attr('taskLength');
    var taskName = ui.draggable.attr('taskName');
    var start = Number(col);

    var task = {
      id: taskId,
      start: start,
      length: taskLength,
      name: taskName
    };

    var admin = AWorkTable.getAdministratorByRowNum(row);
    var newJob = {
      administrator: admin.id,
      tasks: [
        task
      ]
    };

    AWorkTable.addJob(newJob);

    delete tasks[taskId];
    ui.draggable.popover('destroy');
    ui.draggable.remove();
  }

  function getTasks() {
    var taskIds = [];
    if (tasks.length > 0) {
      for (var id in tasks) {
        if (!tasks.hasOwnProperty(id)) continue;
        taskIds.push(tasks[id].id);
      }
    }
    return taskIds;
  }


  return {
    render: render,

    acceptTask: acceptTask,

    addTask: addTask,
    addTasks: addTasks,

    getTasks: getTasks
  }


})();

