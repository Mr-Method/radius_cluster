function make_tree(data, keys) {
  jQuery('#show_tree').on("click", ".children-toggle" , function() {
    jQuery(this).siblings('.ul-list').slideToggle();
    jQuery(this).children().siblings().toggle();
  });

  var keysArray = keys.split(',');
  var TreeHash = [];
  data.forEach(function(e) {
    var branch = TreeHash;
    for (var i = 0 ; i < keysArray.length; i++) {
      if (!branch[e[keysArray[i]]]) {
        if (i == keysArray.length-1 ) {
          branch[e[keysArray[i]]] = 1;
        }
        else {
          branch[e[keysArray[i]]] = [];
        }
      }
      branch = branch[e[keysArray[i]]];
    }
  });
  // console.log(TreeHash);
  drawTree(TreeHash);
  jQuery('#show_tree').html(name);
  name = "";
}
function drawTree(treeData) {
  name += "<ul class='ul-list'>";
  for (const key of Object.keys(treeData)) {
    if (key != "") {
      if (treeData[key] && treeData[key] != 1) {
        name += "<li class='ul-item '><a class='children-toggle' class='btn btn-lg'><i class='glyphicon glyphicon-plus-sign pl' style='display: none;'></i><i class='glyphicon glyphicon-minus-sign mn'></i></a><span class='parent'>" + key + "</span>";
        drawTree(treeData[key]);
      }
      else {
        name += "<li class='ul-item'><span class='parent'>" + key + "</span>";
      }
      name += "</li>";
    }
  }
  name += "</ul>";
}