/**
 * Created by Anykey on 10.11.2016.
 */
/**
 * Created by Anykey on 13.11.2015.
 *
 */
'use strict';

var AFiberDrawer         = null;
var ACommutationControls = null;

var SCHEME_OPTIONS;
var paper = null;

var cables = document['CABLES'] || [];
var links  = document['LINKS'] || [];
//var options = document['OPTIONS'] || {};

var DEFAULT_SCHEME_OPTIONS = {
  CABLE_SHELL_HEIGHT : 30,
  CABLE_HEIGHT_MARGIN: 6,
  
  MODULE_WIDTH: 5,
  FIBER_WIDTH : 4,
  FIBER_HEIGHT: 25,
  FIBER_MARGIN: 6,
  
  ROUTER_WIDTH        : 25,
  ROUTER_HEIGHT_MARGIN: 5,
  OPPOSITE_SHIFT      : 3
};

$(function () {
  
  //Instaniate classes
  AFiberDrawer         = new AFiberDrawerAbstract();
  ACommutationControls = new CommutationControlsAbstract();
  
  cablecatMain();
  var $body = $('body');
  $body.on('expanded.pushMenu collapsed.pushMenu', function () {
    setTimeout(redraw, 400);
  });
  jQuery(window).on('resize', redraw);
});

function redraw() {
  paper = null;
  $('#drawCanvas').empty();
  cablecatMain();
}

function initOptions(options) {
  
  var scale = options['scale'] || 1;
  
  // Width of page container
  var max_width  = $('#drawCanvas').parent().width();
  var max_height = $('#content-wrapper').height();
  
  // (Height of cable + height of fiber) x 3
  var width_margin = (DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT + DEFAULT_SCHEME_OPTIONS.FIBER_HEIGHT * 2) * 2.5;
  
  // First height and width are equal to minimal values
  var width  = options.minWidth || max_width;
  var height = options.minHeight || max_height;
  
  console.log('init: width', width, 'height', height, 'scale', scale);
  
  scale = (width > max_width)
      ? (Math.ceil(((max_width / (width + width_margin)) * 100) / 100))
      : scale;
  
  width *= (options.minWidth) ? scale : 1;
  height *= (options.minHeight) ? scale : 1;
  
  console.log('result: width', width, 'height', height, 'scale', scale);
  
  SCHEME_OPTIONS = {
    SCALE: scale,
    
    CABLE_SHELL_HEIGHT : DEFAULT_SCHEME_OPTIONS['CABLE_SHELL_HEIGHT'] * scale,
    CABLE_HEIGHT_MARGIN: DEFAULT_SCHEME_OPTIONS['CABLE_HEIGHT_MARGIN'] * scale,
    CABLE_COLOR        : DEFAULT_SCHEME_OPTIONS['CABLE_COLOR'],
    
    MODULE_WIDTH: DEFAULT_SCHEME_OPTIONS['MODULE_WIDTH'] * scale,
    
    FIBER_WIDTH   : DEFAULT_SCHEME_OPTIONS['FIBER_WIDTH'] * scale,
    FIBER_HEIGHT  : DEFAULT_SCHEME_OPTIONS['FIBER_HEIGHT'] * scale,
    FIBER_MARGIN  : DEFAULT_SCHEME_OPTIONS['FIBER_MARGIN'] * scale,
    OPPOSITE_SHIFT: DEFAULT_SCHEME_OPTIONS['OPPOSITE_SHIFT'] * scale,
    
    ROUTER_WIDTH        : DEFAULT_SCHEME_OPTIONS['ROUTER_WIDTH'] * scale,
    ROUTER_HEIGHT_MARGIN: DEFAULT_SCHEME_OPTIONS['ROUTER_HEIGHT_MARGIN'] * scale,
    ROUTER_COLOR        : DEFAULT_SCHEME_OPTIONS['ROUTER_COLOR'],
    
    FONT      : 'Roboto',
    FONT_SIZE : 8,
    FONT_COLOR: 'black'
  };
  
  
  SCHEME_OPTIONS['CANVAS_WIDTH']  = width;
  SCHEME_OPTIONS['CANVAS_HEIGHT'] = height;
  
  // Should always match page width
  SCHEME_OPTIONS['CONTAINER_WIDTH']  = max_width;
  SCHEME_OPTIONS['CONTAINER_HEIGHT'] = height;
  
  SCHEME_OPTIONS['CANVAS_Y_CENTER'] = SCHEME_OPTIONS['CANVAS_HEIGHT'] / 2;
  SCHEME_OPTIONS['CANVAS_X_CENTER'] = SCHEME_OPTIONS['CANVAS_WIDTH'] / 2;
  SCHEME_OPTIONS['ZOOM']            = (scale < 1.5);
}

function cablecatMain() {
  
  var dimensions = calculateMinHeightAndWidth(cables);
  
  initOptions({
    scale    : 2,
    minHeight: dimensions.height,
    minWidth : dimensions.width
  });
  
  paper = new Raphael('drawCanvas', SCHEME_OPTIONS['CANVAS_WIDTH'], SCHEME_OPTIONS['CANVAS_HEIGHT']);
  
  $('#drawCanvas').css({
    width : SCHEME_OPTIONS['CONTAINER_WIDTH'],
    height: SCHEME_OPTIONS['CONTAINER_HEIGHT']
  });
  
  if (SCHEME_OPTIONS['ZOOM']) {
    initZoom(paper);
  }
  
  ACableDrawer.drawGrid(25, 0.1);
  
  $.each(cables, function (i, e) {
    ACableDrawer.drawCable(e);
    AInformation.renderTooltips(e);
  });
  
  ALinkManager.init(cables, links);
  AFiberDrawer.init(cables);
  
  AInformation.initContextMenus();
}

var ACableDrawer = (function () {
  
  function drawGrid(step, strokeWidth) {
    var path_command = '';
    for (var xx = 0; xx <= SCHEME_OPTIONS['CANVAS_WIDTH']; xx += step) {
      path_command += makePathCommand([{x: xx, y: 0}, {x: xx, y: SCHEME_OPTIONS['CANVAS_HEIGHT']}]);
    }
    
    for (var yy = 0; yy <= SCHEME_OPTIONS['CANVAS_HEIGHT']; yy += step) {
      path_command += makePathCommand([{x: 0, y: yy}, {x: SCHEME_OPTIONS['CANVAS_WIDTH'], y: yy}]);
    }
    
    paper.path(path_command).attr({
      'stroke-color': 'silver',
      'stroke-width': strokeWidth
    });
  }
  
  function drawCable(cable) {
    var position = getPositionRelatedParams(cable);
    
    // Cable outer shell
    var rect = paper.rect(position.cable.x, position.cable.y, position.cable.width, position.cable.height)
        .attr({
          fill          : cable.image.color || SCHEME_OPTIONS['CABLE_COLOR'],
          'class'       : 'cable',
          'stroke-width': SCHEME_OPTIONS['SCALE']
        });
    
    $(rect.node).data({
      'cable-id': cable.id
    });
    
    var meta = {
      x       : position.cable.x,
      y       : position.cable.y,
      width   : position.cable.width,
      height  : position.cable.height,
      vertical: position.cable.vertical,
      way     : position.cable.way
    };
    rect.data(meta);
    rect.meta = meta;
    
    rect.modules = drawModules(position.modules);
    rect.fibers  = drawFibers(position.fibers);
    
    cable.rendered = rect;
    
    function checkColorsLength(colors_array, desired_length) {
      // If color scheme has more colors, need to splice
      if (colors_array.length > desired_length) {
        colors_array = colors_array.slice(0, desired_length);
      }
      else if (colors_array.length < desired_length) {
        alert('Check color scheme. Color scheme is not enough to show cable : ' + cable.meta.name);
        return false;
      }
      
      return colors_array;
    }
    
    function filterMarked(colors_array) {
      var marked = {};
      for (var i = 0; i < colors_array.length; i++) {
        if (colors_array[i].indexOf('+') > 0) {
          marked[i]       = true;
          colors_array[i] = colors_array[i].substr(0, colors_array[i].indexOf('+'));
        }
      }
      return marked;
    }
    
    function drawModules(params) {
      var modules_colors = checkColorsLength(cable.image.modules_color_scheme, cable.image.modules);
      if (!modules_colors) return false;
      
      // Saving hash of marked colors
      var marked              = filterMarked(modules_colors);
      var modulesColorPalette = new AColorPalette(modules_colors);
      
      paper.setStart();
      
      for (var i = 0; i < cable.image.modules; i++) {
        paper.rect(params.x + params.ox * i, params.y + params.oy * i, params.width, params.height)
            .attr({
              fill          : modulesColorPalette.getNextColorHex(),
              'stroke-width': SCHEME_OPTIONS['SCALE']
            });
      }
      // TODO: show marked
      
      
      return paper.setFinish();
    }
    
    function drawFibers(params) {
      var fiber_colors = checkColorsLength(cable.image.color_scheme, cable.image.fibers / cable.image.modules);
      if (!fiber_colors) return false;
      
      var marked             = filterMarked(fiber_colors);
      var fibersColorPalette = new AColorPalette(fiber_colors);
      
      var set = [];
      for (var i = 0; i < cable.image.fibers; i++) {
        
        var color      = fibersColorPalette.getNextColorHex();
        var fiber_rect = paper.rect(params.x + params.ox * i, params.y + params.oy * i,
            params.width, params.height
        ).attr({
          fill          : color,
          'stroke-width': SCHEME_OPTIONS['SCALE']
        });
        
        var edge = {
          x: params.x + params.ox * i + params.edge_x_offset,
          y: params.y + params.oy * i + params.edge_y_offset
        };
        
        if (marked[i] == true) {
          drawLine(
              edge,
              {
                x: params.x + params.ox * i + params.start_x,
                y: params.y + params.oy * i + params.start_y
              },
              'black', 2
          );
        }
        
        $(fiber_rect.node)
            .addClass('fiber')
            .data('fiber_id', cable.meta.fibers[i + 1].id);
        
        fiber_rect.rendered = {
          meta : {
            connected   : false,
            fiber_params: params,
            number      : i
          },
          edge : edge,
          color: color
        };
        
        set[set.length] = fiber_rect;
      }
      
      return paper.set(set);
    }
    
    function getPositionRelatedParams(cable) {
      
      var cable_params   = getCableParams(cable);
      var modules_params = getModulesParams(cable, cable_params);
      var fibers_params  = getFiberParams(cable_params, modules_params);
      
      function getCableParams(cable) {
        var position     = cable.meta.position;
        var fibers_count = cable.image.fibers;
        
        var mirrored = ((position === 'bottom') || (position === 'right'));
        var vertical = ((position === 'top') || (position === 'bottom'));
        
        //if mirrored, should be drawn in negative way
        var way = (mirrored) ? -1 : 1;
        
        //width depends on fibers count
        var width = fibers_count
            * (SCHEME_OPTIONS['FIBER_WIDTH'] + SCHEME_OPTIONS['FIBER_MARGIN'])
            + SCHEME_OPTIONS['CABLE_HEIGHT_MARGIN'];
        
        var height = SCHEME_OPTIONS['CABLE_SHELL_HEIGHT'];
        
        var x;
        if (vertical) {
          x = ((SCHEME_OPTIONS['CANVAS_WIDTH'] - width) / 2) + 50;
          if (mirrored) x += SCHEME_OPTIONS['OPPOSITE_SHIFT'];
        }
        else {
          x = (mirrored) ? SCHEME_OPTIONS['CANVAS_WIDTH'] - height + SCHEME_OPTIONS['OPPOSITE_SHIFT'] : 0;
        }
        
        var y;
        if (vertical) {
          y = (mirrored) ? SCHEME_OPTIONS['CANVAS_HEIGHT'] - height + SCHEME_OPTIONS['OPPOSITE_SHIFT'] : 0;
        }
        else {
          y = ((SCHEME_OPTIONS['CANVAS_HEIGHT'] - width) / 2);
          if (mirrored) y += SCHEME_OPTIONS['OPPOSITE_SHIFT'];
        }
        
        //if not vertical, flip height and width
        if (!vertical) {
          var temp = height;
          //noinspection JSSuspiciousNameCombination
          height   = width;
          width    = temp;
        }
        
        return {
          x       : x,
          y       : y,
          width   : width,
          height  : height,
          vertical: vertical,
          way     : way
        };
      }
      
      function getModulesParams(cable, cable_params) {
        var y = cable_params.y + cable_params.height;
        var x = cable_params.x + SCHEME_OPTIONS['CABLE_HEIGHT_MARGIN'] / 2;
        
        if (!cable_params.vertical) {
          y = cable_params.y + SCHEME_OPTIONS['CABLE_HEIGHT_MARGIN'] / 2;
          x = cable_params.x + SCHEME_OPTIONS['MODULE_WIDTH'] * cable_params.way;
        }
        
        if (cable_params.vertical) {
          if (cable_params.way < 0) {
            y -= cable_params.height + SCHEME_OPTIONS['MODULE_WIDTH'];
          }
        }
        else {
          if (cable_params.way >= 0) {
            x += SCHEME_OPTIONS['CABLE_SHELL_HEIGHT'] - SCHEME_OPTIONS['MODULE_WIDTH'];
          }
        }
        
        var width  = cable.image.fibers * (SCHEME_OPTIONS['FIBER_WIDTH'] + SCHEME_OPTIONS['FIBER_MARGIN']) / cable.image.modules;
        //noinspection JSSuspiciousNameCombination
        var height = SCHEME_OPTIONS['MODULE_WIDTH'];
        
        var offset_y = 0;
        var offset_x = width;
        
        if (!cable_params.vertical) {
          offset_x = 0;
          //noinspection JSSuspiciousNameCombination
          offset_y = width;
        }
        
        //if not vertical, flip height and width
        if (!cable_params.vertical) {
          [height, width] = [width, height];
        }
        
        return {
          x     : x,
          y     : y,
          ox    : offset_x,
          oy    : offset_y,
          width : width,
          height: height
        }
      }
      
      function getFiberParams(cable_params, modules_params) {
        
        var width  = SCHEME_OPTIONS['FIBER_WIDTH'];
        var height = SCHEME_OPTIONS['FIBER_HEIGHT'];
        
        var offset_x = SCHEME_OPTIONS['FIBER_WIDTH'] + SCHEME_OPTIONS['FIBER_MARGIN'];
        var offset_y = 0;
        
        var first_x, first_y, edge_x_offset, edge_y_offset, start_x, start_y;
        
        if (cable_params.vertical) {
          first_x = modules_params.x + SCHEME_OPTIONS['FIBER_MARGIN'] / 2;
          
          if (cable_params.way < 0) { // Bottom
            first_y       = modules_params.y - SCHEME_OPTIONS['FIBER_HEIGHT'];
            edge_x_offset = SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
            edge_y_offset = 0;
            
            start_y = SCHEME_OPTIONS['FIBER_HEIGHT'];
          }
          else { // Up
            first_y       = modules_params.y + SCHEME_OPTIONS['MODULE_WIDTH'];
            edge_x_offset = SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
            edge_y_offset = SCHEME_OPTIONS['FIBER_HEIGHT'] * cable_params.way;
            start_y       = 0;
          }
          
          start_x = edge_x_offset;
        }
        else {
          first_x = modules_params.x + SCHEME_OPTIONS['MODULE_WIDTH'];
          first_y = modules_params.y + SCHEME_OPTIONS['FIBER_MARGIN'] / 2;
          
          offset_x = 0;
          offset_y = SCHEME_OPTIONS['FIBER_WIDTH'] + SCHEME_OPTIONS['FIBER_MARGIN'];
          
          // Swap height and width
          [width, height] = [height, width];
          
          if (cable_params.way < 0) { // Right
            first_x -= SCHEME_OPTIONS['FIBER_HEIGHT'] + SCHEME_OPTIONS['MODULE_WIDTH'];
            
            edge_x_offset = 0;
            edge_y_offset = SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
            
            start_x = SCHEME_OPTIONS['FIBER_HEIGHT'];
            
          }
          else { // Left
            edge_x_offset = SCHEME_OPTIONS['FIBER_HEIGHT'] * cable_params.way;
            edge_y_offset = SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
            
            start_x = 0;
          }
          
          start_y = edge_y_offset;
        }
        
        return {
          x            : first_x,
          y            : first_y,
          ox           : offset_x,
          oy           : offset_y,
          width        : width,
          height       : height,
          edge_x_offset: edge_x_offset,
          edge_y_offset: edge_y_offset,
          start_x      : start_x,
          start_y      : start_y
        }
      }
      
      return {
        cable  : cable_params,
        modules: modules_params,
        fibers : fibers_params
        
      }
    }
  }
  
  return {
    drawGrid : drawGrid,
    drawCable: drawCable
  }
})
();

var AInformation = (function () {
  
  function renderTooltips(cable) {
    
    var rect = cable.rendered;
    
    var x = rect.data('x');
    var y = rect.data('y');
    
    var width  = rect.data('width');
    var height = rect.data('height');
    
    var vertical = rect.data('vertical');
    
    drawText(cable);
    
    function drawText(cable) {
      var description = cable.meta.name;
      
      var text_x = x + width / 2;
      var text_y = y + height / 2;
      
      var text = paper.text(text_x, text_y, description);
      
      var color = SCHEME_OPTIONS['FONT_COLOR'];
      
      if (cable.image.color == 'black' || cable.image.color == ('#000000')) {
        color = '#ffffff';
      }
      
      text.attr({
        'font-family': SCHEME_OPTIONS['FONT'],
        'font-size'  : SCHEME_OPTIONS['FONT_SIZE'] * SCHEME_OPTIONS['SCALE'],
        'font-weight': 400,
        fill         : color
      });
      
      //if cable is horizontal, need to rotate text
      if (!vertical) {
        var angle = 90;
        if (rect.data('way') < 0) {
          angle = 270;
        }
        
        text.attr({
          transform: 'r' + angle
        })
      }
    }
  }
  
  function initContextMenus() {
    //Init fiber context-menu
    $.contextMenu({
      // define which elements trigger this menu
      selector      : ".fiber",
      trigger       : 'left',
      itemClickEvent: "click",
    
      build: function ($trigger, e) {
        var fiber_id = $trigger.data('fiber_id');
      
        var cable = ALinkManager.getCableForFiber(fiber_id);
        var fiber = ALinkManager.getFiberById(fiber_id);
      
        // Connection options
        var connection_option = (fiber.rendered.meta.connected)
            ? {
              name    : _translate('Delete link'),
              icon    : 'delete',
              callback: function () { ALinkManager.removeLinkForFiber(fiber_id)}
            }
            : {
              name    : _translate('Connect'),
              icon    : 'add',
              callback: function () { AFiberDrawer.fiberClicked({target: $trigger}) }
            };
      
        var full_name = cable.meta.name + ':' + (fiber.rendered.meta.number + 1);
      
        return {
          items: {
            // Fiber label
            full_name : {name: full_name, callback: $.noop},
            connection: connection_option
          }
        };
      
      }
    });
  
    //Init link context-menu
    $.contextMenu({
      // define which elements trigger this menu
      selector      : ".link-circle",
      trigger       : 'left',
      itemClickEvent: "click",
    
      build: function ($trigger, e) {
        var link_id = $trigger.data('link-id');
      
        var link = ALinkManager.getLinkById(link_id);
        if (!link) {
          alert('Error creating menu. can\'t find link');
          return false;
        }
      
        return {
          items: {
            // Fiber label
            full_name  : {name: link.name, callback: $.noop()},
            connection : {
              name    : _translate('Delete link'),
              icon    : 'delete',
              callback: function () { ALinkManager.removeLink(link)}
            },
            attenuation: {
              name    : _translate('Attenuation'),
              'icon'  : 'fa-signal',
              callback: link.editAttenuation.bind(link)
            },
            comments   : {
              name    : _translate('Comments'),
              icon    : 'fa-comments-o',
              callback: link.editComments.bind(link)
            }
          }
        };
      
      }
    });
  
    //Init cable context-menu
    $.contextMenu({
      // define which elements trigger this menu
      selector      : ".cable",
      trigger       : 'left',
      itemClickEvent: "click",
    
      build: function ($trigger, e) {
        var cable_id = $trigger.data('cable-id');
      
        var cable = ALinkManager.getCableById(cable_id);
        if (!cable) {
          alert('Error creating menu. can\'t find cable');
          return false;
        }
      
        return {
          items: {
            // Fiber label
            full_name : {
              name : cable.meta.name,
              icon : 'preview',
              items: {
                change : {
                  name    : _translate('Change'),
                  icon    : 'fa-external-link',
                  callback: function () {
                    var url = '?get_index=cablecat_cables&full=1&chg=' + cable_id;
                    window.open(url, '_blank');
                  }
                },
                map_btn: {
                  name    : _translate('Map'),
                  icon    : 'fa-map',
                  callback: function () {
                    var url = '?' + cable.meta.map_btn;
                    window.open(url, '_blank');
                  }
                },
                well_1 : {
                  name    : cable.meta.well_1,
                  icon    : 'fa-external-link',
                  callback: function () {
                    var url = '?get_index=cablecat_wells&full=1&chg=' + cable.meta.well_1_id;
                    window.open(url, '_blank');
                  }
                },
                well_2 : {
                  name    : cable.meta.well_2,
                  icon    : 'fa-external-link',
                  callback: function () {
                    var url = '?get_index=cablecat_wells&full=1&chg=' + cable.meta.well_2_id;
                    window.open(url, '_blank');
                  }
                }
              }
            },
            connection: {
              name    : _translate('Remove cable from scheme'),
              icon    : 'delete',
              callback: function () { ALinkManager.removeCable(cable_id)}
            }
          }
        }
      }
    });
  
    //Init connected fiber context-menu
    $.contextMenu({
      // define which elements trigger this menu
      selector      : ".fiber-connected-another",
      trigger       : 'left',
      itemClickEvent: "click",
    
      build: function ($trigger, e) {
        var another_commutation_id = $trigger.data('another-commutation_id');
        var fiber_id               = $trigger.data('fiber-id');
      
        if (!fiber_id) {
          alert('Error creating menu. can\'t read fiber_id');
          return false;
        }
      
        return {
          items: {
            // Fiber label
            name: {
              name    : _translate('Go to commutation'),
              icon    : 'fa-external-link',
              callback: function () {
                location.href = '?get_index=cablecat_commutation&full=1&ID=' + another_commutation_id
              }
            }
          }
        };
      
      }
    });
    
  }
  
  return {
    renderTooltips  : renderTooltips,
    initContextMenus: initContextMenus
  }
})();

/**
 * ALinkManager - holds information about links
 * among fibers and manages fiber meta information
 *
 * @type {{init, getFiber, getFiberById, getCableForFiber, addLink}}
 */
var ALinkManager = (function () {
  
  var cableHolder = {};
  var fibers      = {};
  var links       = [];
  
  function init(cablesArr, linksArr) {
    $.each(cablesArr, function (i, cable) {
      cableHolder[cable.id] = cable;
      
      // Save shortcut
      cableHolder[cable.id]['fibers'] = cable.rendered.fibers;
      
      $.each(cableHolder[cable.id].fibers.items, function (i, fiber) {
        var id           = $(fiber.node).data('fiber_id');
        fibers[id]       = fiber;
        fibers[id].cable = cable;
      })
    });
    
    $.each(linksArr, function (i, link_raw) {
      var start_id = link_raw.cable_id_1 + '_' + link_raw.fiber_num_1;
      var end_id   = link_raw.cable_id_2 + '_' + link_raw.fiber_num_2;
      
      var start_present = typeof (fibers[start_id]) !== 'undefined';
      var end_present   = typeof (fibers[end_id]) !== 'undefined';
      
      if (start_present && end_present) {
        var link = new Link(link_raw);
        links.push(link);
        link.render();
        
        AFiberDrawer.setFiberConnected(start_id);
        AFiberDrawer.setFiberConnected(end_id);
      }
      else {
        // Assuming at least one of them is present
        if (start_present || end_present) {
          var present_fiber_id = (start_present)
              ? start_id
              : end_id;
          
          fibers[present_fiber_id].rendered.meta.connected = true;
          
          AFiberDrawer.setFiberConnected(present_fiber_id, link_raw['commutation_id']);
        }
        else {
          console.log('Got links that not exists in all cables.' +
              ' This may happen if somebody changed cable type after commutation was created', start_id, end_id);
          // TODO: ask and delete
        }
      }
    });
  }
  
  function getCables() {
    return cableHolder;
  }
  
  function getFiber(cableId, fiberNum) {
    return cableHolder[cableId].fibers.items[fiberNum];
  }
  
  function getFiberById(fiber_id) {
    return fibers[fiber_id] || console.log(fibers, fiber_id);
  }
  
  function getCableForFiber(fiberId) {
    //console.log(fiberId);
    return fibers[fiberId].cable;
  }
  
  function getCableById(cableId) {
    return cableHolder[cableId] || console.log(cableHolder, cableId);
  }
  
  function removeCable(cable_id) {
    ACommutationControls.removeCableFromScheme(cable_id);
  }
  
  function addLink(link, callback) {
    link.sendToServer(function (success) {
      if (success) {
        links.push(link);
        link.render();
        callback(true);
      }
      else {
        callback(false);
        console.log('Error hapenned');
      }
    });
  }
  
  function getLinkById(link_id) {
    var links_with_id = links.filter(function (e) { return e.id == link_id });
    if (links.length) {
      return links_with_id[0];
    }
    
    return false;
  }
  
  function removeLink(link) {
    
    link.removeFromServer(function (success) {
      if (success) {
        links.splice(links.indexOf(link), 1);
        link.remove();
        // Set fibers not connected
        link.startFiber.rendered.meta.connected = false;
        link.endFiber.rendered.meta.connected   = false;
        
        //Remove edge circle (connected visualization)
        link.startFiber.rendered.edge.circle.remove();
        link.endFiber.rendered.edge.circle.remove();
        
      }
      else {
        alert('Error happened')
      }
    });
    
  }
  
  function createLink(cable_id_1, fiber_num_1, cable_id_2, fiber_num_2, callback) {
    var start_id = cable_id_1 + '_' + fiber_num_1;
    var end_id   = cable_id_2 + '_' + fiber_num_2;
    
    // Check if link exists
    if (fibers[start_id].rendered.meta.connected || fibers[end_id].rendered.meta.connected) {
      if (callback) callback(true);
      return false;
    }
    
    var link = new Link({
      cable_id_1 : cable_id_1,
      cable_id_2 : cable_id_2,
      fiber_num_1: fiber_num_1,
      fiber_num_2: fiber_num_2
    });
    
    link.sendToServer(function (success) {
      if (success) {
        links.push(link);
        link.render();
        
        AFiberDrawer.setFiberConnected(start_id);
        AFiberDrawer.setFiberConnected(end_id);
        
        if (callback) callback(true);
      }
      else {
        if (callback) callback(false);
      }
    });
    
  }
  
  function removeLinkForFiber(fiber_id) {
    
    var link = links.filter(function (link) {
      return (link.start == fiber_id || link.end == fiber_id)
    })[0];
    
    removeLink(link);
  }
  
  return {
    init     : init,
    getCables: getCables,
    
    getFiber    : getFiber,
    getFiberById: getFiberById,
    
    getCableForFiber: getCableForFiber,
    getCableById    : getCableById,
    removeCable     : removeCable,
    
    addLink           : addLink,
    createLink        : createLink,
    getLinkById       : getLinkById,
    removeLinkForFiber: removeLinkForFiber,
    removeLink        : removeLink
  }
})();

var AFiberDrawerAbstract = function () {
  
  var self = this;
  
  this.cables      = null;
  this.edgeCircles = [];
  
  this.init = function (cablesArr) {
    //save
    this.cables = cablesArr;
    
    //init
    this.bindStartFiberClick();
  };
  
  this.bindStartFiberClick = function () {
    
  };
  
  this.fiberClicked = function (event) {
    //get clicked fiber
    var fiber = event.target;
    
    //init new link
    var fiberId     = $(fiber).data('fiber_id');
    this.startFiber = ALinkManager.getFiberById(fiberId);
    
    this.bindEndFiberClick();
  };
  
  this.drawEdgeCircle = function (index, fiber) {
    var fiberStartId = $(fiber.node).data('fiber_id');
    var fiberEl      = ALinkManager.getFiberById(fiberStartId);
    if (fiberEl.rendered.meta.connected) return;
    
    var edge = fiberEl.rendered.edge;
    
    if (!isDefined(edge)) {
      console.log(1);
    }
    
    var circle = paper.circle(edge.x, edge.y, SCHEME_OPTIONS['FIBER_WIDTH'])
        .click(self.endFiberClicked.bind(self))
        .attr({
          fill: fiberEl.rendered.color
        })
        .hover(
            function () {    //hover in
              circle.attr({
                fill: 'black'
              })
            }, function () { //hover out
              circle.attr({
                fill: fiberEl.rendered.color
              })
            });
    
    $(circle.node).data('fiber_id', fiberStartId);
    
    fiberEl.rendered.circle = circle;
    this.edgeCircles.push(circle);
  };
  
  this.bindEndFiberClick = function () {
    
    //draw circles
    $.each(this.cables, function (index, cable) {
      cable.rendered.fibers.unclick();
      $.each(cable.rendered.fibers.items, self.drawEdgeCircle.bind(self));
    });
    
    //removing circle from fiber that was clicked
    this.startFiber.rendered.circle.remove();
  };
  
  this.endFiberClicked = function (event) {
    //clear circles
    $.each(this.edgeCircles, function (index, circle) {
      circle.remove();
    });
    //get info about fiber
    var circle = event.target;
    
    var fiberStartId = $(this.startFiber.node).data('fiber_id');
    var fiberEndId   = $(circle).data('fiber_id');
    
    // id will be set after adding
    var newLink = new Link({
      startFiberId: fiberStartId,
      endFiberId  : fiberEndId
    });
    
    ALinkManager.addLink(newLink, function (success) {
      if (success) {
        self.setFiberConnected(fiberStartId);
        self.setFiberConnected(fiberEndId);
      }
    });
    
    this.bindStartFiberClick();
  };
  
  this.setFiberConnected = function (fiber_id, commutation_id) {
    var fiberEl = ALinkManager.getFiberById(fiber_id);
    
    if (!isDefined(fiberEl)) {
      return false;
    }
    
    fiberEl.rendered.meta.connected = true;
    var edge                        = fiberEl.rendered.edge;
    
    edge['circle'] = paper.circle(edge.x, edge.y, SCHEME_OPTIONS['FIBER_WIDTH'] / 2)
        .attr({
          fill : 'black',
          title: 'connected'
        });
    
    $(edge['circle'].node).data('fiber-id', fiber_id);
    
    if (typeof (commutation_id) !== 'undefined' && commutation_id !== document['COMMUTATION_ID']) {
      edge['circle'].attr({'class': 'fiber-connected-another'});
      $(edge['circle'].node).data('another-commutation_id', commutation_id);
    }
    
  }
};

function Link(rawLink) {
  var self   = this;
  this.image = null;
  
  this.points = [];
  
  this.id    = rawLink.id || null;
  this.start = (rawLink.startFiberId)
      ? rawLink.startFiberId
      : rawLink.cable_id_1 + '_' + rawLink.fiber_num_1;
  
  this.end = (rawLink.endFiberId)
      ? rawLink.endFiberId
      : rawLink.cable_id_2 + '_' + rawLink.fiber_num_2;
  
  // Saving raw attributes to self
  this.attributes = ['attenuation', 'direction', 'comments'];
  this.attributes.forEach(function (attr_name) {
    self[attr_name] = rawLink[attr_name];
  });
  
  this.startFiber = null;
  this.endFiber   = null;
  
  this.name = '';
  
  if (this.start && this.end) {
    this.startFiber = ALinkManager.getFiberById(this.start);
    this.endFiber   = ALinkManager.getFiberById(this.end);
    
    //this.startFiber.rendered.meta.connected = true;
    //this.endFiber.rendered.meta.connected   = true;
  }
}

Link.prototype.setId = function (id) {
  this.id = id;
  return this;
};

Link.prototype.render = function () {
  
  var points = this.points;
  
  //compute path
  computePath(this.start, this.end);
  
  //draw path
  var color              = this.startFiber.rendered.color;
  var center_point_index = parseInt(this.points.length / 2);
  
  var path_attr = {
    'stroke'         : color,
    'stroke-width'   : SCHEME_OPTIONS['FIBER_WIDTH'] / 2,
    'stroke-linejoin': 'round',
    'stroke-linecap' : 'round',
    'class'          : 'fiber-link',
    'text'           : this.id
  };
  
  var path = paper.set();
  if (this.startFiber.rendered.color === this.endFiber.rendered.color) {
    var command = makePathCommand(points);
    path.push(paper.path(command).attr(path_attr));
  }
  else {
    // Calculate middle point where should change color to opposite
    
    // Split points array
    var left_command  = makePathCommand(points.slice(0, center_point_index + 1));
    var right_command = makePathCommand(points.slice(center_point_index));
    
    // Draw first part
    var first_part = paper.path(left_command).attr(path_attr);
    
    // Change color after half part and draw second
    path_attr.stroke = this.endFiber.rendered.color;
    var second_part  = paper.path(right_command).attr(path_attr);
    
    // Save to Raphael.set
    path.push(first_part, second_part);
  }
  
  // Draw circle on connection place
  var circle = paper.circle(
      points[center_point_index].x,
      points[center_point_index].y,
      SCHEME_OPTIONS['FIBER_WIDTH'] / 2
  ).attr({
    'fill'        : color,
    'class'       : 'link-circle',
    'stroke-width': SCHEME_OPTIONS['SCALE']
  }).toFront();
  
  $(circle.node).data({'link-id': this.id});
  
  this.circle = circle;
  
  //animate on hover
  path.mouseover(function () {
    path.animate({
      'stroke-width': SCHEME_OPTIONS['FIBER_WIDTH']
    }).toFront();
    circle.toFront();
  });
  
  path.mouseout(function () {
    path.animate({
      'stroke-width': SCHEME_OPTIONS['FIBER_WIDTH'] / 2
    })
  });
  
  this.path = path;
  
  function computePath(start, end) {
    var startCable = ALinkManager.getCableForFiber(start);
    var endCable   = ALinkManager.getCableForFiber(end);
    
    var startFiber = ALinkManager.getFiberById(start);
    var endFiber   = ALinkManager.getFiberById(end);
    
    var startPoint = startFiber.rendered.edge;
    var endPoint   = endFiber.rendered.edge;
    
    points[points.length] = (startPoint);
    
    var sameCable = (startCable == endCable);
    if (sameCable) {
      points.push(endPoint);
      return;
    }
    
    var sameAxis = (startCable.rendered.data('vertical') == endCable.rendered.data('vertical'));
    
    if (sameAxis) {
      //4-2 points path
      var offset = SCHEME_OPTIONS['FIBER_MARGIN'] * getLeftToRightFiberWayNumber(startFiber, endFiber);//* -1;
      
      //# FIXME: offset is too big on narrow scheme
      offset /= SCHEME_OPTIONS['SCALE'];
      
      var first_point, second_point;
      if (startCable.rendered.data('vertical')) {
        var middle_y =
                SCHEME_OPTIONS['CANVAS_Y_CENTER'] + offset;
        
        if (startPoint.x == endPoint.x) {
          points.push({x: startPoint.x, y: middle_y});
        }
        else {
          first_point  = {
            x: startPoint.x,
            y: middle_y
          };
          second_point = {
            x: endPoint.x,
            y: middle_y
          };
          Array.prototype.push.apply(points, [first_point, getPointBeetween(first_point, second_point), second_point]);
        }
      }
      else {
        var middle_x =
                SCHEME_OPTIONS['CANVAS_X_CENTER'] + offset;
        
        if (startPoint.y == endPoint.y) {
          points.push({x: middle_x, y: startPoint.y});
        }
        else {
          first_point  = {
            x: middle_x,
            y: startPoint.y
          };
          second_point = {
            x: middle_x,
            y: endPoint.y
          };
          Array.prototype.push.apply(points, [first_point, getPointBeetween(first_point, second_point), second_point]);
        }
      }
      
    }
    else {
      //3-2 points path
      points[points.length] = {
        x: getCloserPoint(startPoint.x, endPoint.x, SCHEME_OPTIONS['CANVAS_WIDTH']),
        y: getCloserPoint(startPoint.y, endPoint.y, SCHEME_OPTIONS['CANVAS_HEIGHT'])
      };
    }
    
    points[points.length] = (endPoint);
    
    /**
     * Return coordinate that is closer to value
     * @param p1 - coordinate of first point
     * @param p2 - coordinate of second point
     * @param value - CANVAS size parameter (height or width)
     * @returns coordinate
     */
    function getCloserPoint(p1, p2, value) {
      var del1 = Math.abs(value / 2 - p1);
      var del2 = Math.abs(value / 2 - p2);
      return (Math.max(del1, del2) == del1) ? p2 : p1;
    }
    
    /**
     * Returns coords of point that has minimal and equal distance from both points
     * @param p1 - point
     * @param p2 - point
     * @returns {{x: number, y: number}}
     */
    function getPointBeetween(p1, p2) {
      return {
        x: (p1.x + p2.x) / 2,
        y: (p1.y + p2.y) / 2
      }
    }
    
    function getLeftToRightFiberWayNumber(fiber1, fiber2) {
      return (fiber1.cable.rendered.meta.way == 1)
          ? fiber1.rendered.meta.number
          : fiber2.rendered.meta.number
    }
  }
};

Link.prototype.remove = function () {
  this.path.remove();
  this.circle.remove();
};

Link.prototype.editAttribute = function (attr_name) {
  var self  = this;
  var value = self[attr_name.toLowerCase()] || '';
  
  var form_group = getSimpleRow(
      attr_name.toUpperCase(),
      attr_name.toUpperCase(),
      _translate(capitalizeFirst(attr_name)),
      value
  );
  
  aModal.clear()
      .setSmall(true)
      .setBody(form_group)
      .addButton(_translate('Set'), 'modalSetBtn', 'default')
      .show(function () {
        $('#modalSetBtn').on('click', function () {
          var value = $('#' + attr_name.toUpperCase()).val();
          self.saveAttribute(attr_name, value);
          aModal.hide();
        })
      });
  
};

Link.prototype.saveAttribute = function (attr_name, value, callback) {
  var self          = this;
  var current_value = self[attr_name.toLowerCase()];
  
  if (current_value && current_value === value) {
    console.log('no changed ', attr_name);
    return;
  }
  
  var params = {
    qindex     : INDEX,
    json       : 1,
    header     : 2,
    commutation: 1,
    change     : this.id
  };
  
  params[attr_name.toUpperCase()] = value;
  
  var xhr = $.getJSON(SELF_URL, params, function (response) {
    if (response.MESSAGE && response.MESSAGE.type === 'info') {
      self[attr_name.toLowerCase()] = value;
      if (callback) callback(true);
    }
  });
  
  xhr.fail(function (error) {
    aTooltip.displayError(error);
    if (callback) callback(false);
  });
};

Link.prototype.editAttenuation = function () {
  this.editAttribute('attenuation');
};

Link.prototype.saveAttenuation = function (value, callback) {
  this.saveAttribute('attenuation', value);
};

Link.prototype.editComments = function () {
  this.editAttribute('comments');
};

Link.prototype.saveComments = function (value, callback) {
  this.saveAttribute('comments', value);
};


function drawLine(point1, point2, color, stroke_w_) {
  var stroke_w = stroke_w_
      ? stroke_w_ * SCHEME_OPTIONS['SCALE']
      : SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
  
  return paper.path('M' + point1.x + ',' + point1.y + 'L' + point2.x + ',' + point2.y).attr({
    'stroke'         : color,
    'stroke-width'   : stroke_w,
    'stroke-linejoin': 'round',
    'stroke-linecap' : 'round'
  });
}

function makePathCommand(pointsArr) {
  // Move cursor to first point
  var command = 'M ' + pointsArr[0].x + ',' + pointsArr[0].y;
  
  // Apply 'lineto' for every other point
  for (var i = 1; i < pointsArr.length; i++) {
    command += ' L' + pointsArr[i].x + ',' + pointsArr[i].y;
  }
  
  return command;
}

Link.prototype.sendToServer = function (callback) {
  var self = this;
  
  var params = {
    qindex        : INDEX,
    json          : 1,
    header        : 2,
    commutation   : 1,
    add           : 1,
    COMMUTATION_ID: document['COMMUTATION_ID'],
    CABLE_ID_1    : this.startFiber.cable.id,
    FIBER_NUM_1   : this.startFiber.rendered.meta.number + 1,
    CABLE_ID_2    : this.endFiber.cable.id,
    FIBER_NUM_2   : this.endFiber.rendered.meta.number + 1
  };
  
  $.getJSON(SELF_URL, params, function (response) {
    if (response.MESSAGE && response.MESSAGE.type === 'info') {
      self.saved = true;
      self.id    = response.MESSAGE.ID;
      
      if (callback) callback(true);
    }
    else {
      if (callback) callback(false);
    }
  }).fail(function (error) {
    aTooltip.displayError(error);
    if (callback) callback(false);
  });
  
};

Link.prototype.removeFromServer = function (callback) {
  var params = {
    qindex     : INDEX,
    json       : 1,
    header     : 2,
    commutation: 1,
    del        : this.id
  };
  
  $.getJSON(SELF_URL, params, function (response) {
    if (response.MESSAGE && response.MESSAGE.type === 'info') {
      if (callback) callback(true);
    }
  })
      .fail(function (error) {
        aTooltip.displayError(error);
        if (callback) callback(false);
      });
  
};

function calculateMinHeightAndWidth(cablesArr) {
  // Get maximal fibers for present cables
  var max_horizontal_fibers_count = 0;
  var max_vertical_fibers_count   = 0;
  
  for (var i = 0; i < cablesArr.length; i++) {
    
    var fibers_count = +cablesArr[i].image.fibers;
    
    if (+cablesArr[i].meta.vertical === 1) {
      
      if (fibers_count > max_horizontal_fibers_count)
        max_horizontal_fibers_count = fibers_count;
    }
    else {
      if (fibers_count > max_vertical_fibers_count)
        max_vertical_fibers_count = fibers_count;
    }
  }
  
  var base_fiber_width  = DEFAULT_SCHEME_OPTIONS.FIBER_WIDTH + DEFAULT_SCHEME_OPTIONS.FIBER_MARGIN;
  var base_cable_height = DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT + DEFAULT_SCHEME_OPTIONS.FIBER_HEIGHT * 2;
  
  console.log('calculateMinHeightAndWidth hor ver', max_horizontal_fibers_count, max_vertical_fibers_count);
  
  return {
    height: (max_horizontal_fibers_count > 0)
        ? (base_fiber_width * max_horizontal_fibers_count) + base_cable_height * 3
        : 0,
    width : (max_vertical_fibers_count > 0)
        ? (base_fiber_width * max_vertical_fibers_count) + base_cable_height * 3
        : 0
  };
}

function initZoom(paper) {
  var panZoom;
  panZoom = paper.panzoom({
    initialZoom    : 0,
    initialPosition: {x: 0, y: 0},
    redrawCallback : function () {
      Events.emit('commutation.zoom_changed', panZoom);
    }
  });
  panZoom.enable();
  
  //Events.on('commutation.zoom_changed', function (panzoom) {
  //  var zoom = panzoom.getCurrentZoom();
  //  var pan  = panzoom.getCurrentPosition();
  //
  //  // Set zoomCenter to center of current pan
  //
  //
  //console.log(zoom, pan);
  //})
}

function CommutationControlsAbstract() {
  this.$panel = $('#scheme_controls');
  
  var self = this;
  
  this.$plus_dropdown = this.$panel.find('ul.dropdown-menu.plus-options');
  this.$adv_dropdown  = this.$panel.find('ul.dropdown-menu.advanced-options');
  this.$info_btn      = this.$panel.find('button#info-btn');
  
  this.commutation_id = document['COMMUTATION_ID'];
  this.connecter_id   = document['CONNECTER_ID'];
  this.well_id        = document['WELL_ID'];
  
  this.addCable = function () {
    
    loadToModal('?qindex=' + INDEX
        + '&header=' + 2
        + '&WELL_ID=' + this.well_id
        + '&CONNECTER_ID=' + this.connecter_id
        + '&COMMUTATION_ID=' + this.commutation_id
        + '&operation=LIST_CABLES'
    );
  };
  
  this.removeCableFromScheme = function (cable_id) {
    Events.once('modal_loaded', function () {
      setTimeout(function () {
        location.reload(true)
      }, 1000);
    });
    
    loadToModal('?qindex=' + INDEX
        + '&header=' + 2
        + '&WELL_ID=' + this.well_id
        + '&CONNECTER_ID=' + this.connecter_id
        + '&COMMUTATION_ID=' + this.commutation_id
        + '&CABLE_ID=' + cable_id
        + '&operation=DELETE_CABLE'
    );
    
  };
  
  this.connectTwoCablesByNumbers = function () {
    var first_cable  = cables[0];
    var second_cable = cables[1];
    
    // Find minimal
    var fibers_count = Math.min(first_cable.image.fibers, second_cable.image.fibers);
    
    var recursive_add = function (fiber_num) {
      if (fiber_num > fibers_count) return true;
      
      ALinkManager.createLink(first_cable.id, fiber_num, second_cable.id, fiber_num, function (success) {
        if (success) recursive_add(++fiber_num);
      });
    };
    
    recursive_add(1);
  };
  
  this.clearCommutation = function () {
    Events.once('modal_loaded', function () {
      setTimeout(function () {
        location.reload(true)
      }, 1000);
    });
    
    loadToModal('?qindex=' + INDEX
        + '&header=' + 2
        + '&WELL_ID=' + this.well_id
        + '&CONNECTER_ID=' + this.connecter_id
        + '&COMMUTATION_ID=' + this.commutation_id
        + '&operation=CLEAR_COMMUTATION'
    );
  };
  
  this.addLink = function () {
    alert('Add link');
  };
  
  this.initOptionsList = function ($ul, options_table) {
    for (var option in options_table) {
      if (!options_table.hasOwnProperty(option)) continue;
      
      var $option = $('<li></li>');
      var $btn    = $('<a></a>');
      
      $btn.text(_translate(option));
      $btn.on('click', options_table[option].bind(self));
      
      $ul.append($option.append($btn));
    }
  };
  
  this.add_options = {
    'Cable': this.addCable,
    'Link' : this.addLink
  };
  
  this.advanced_options = {
    'Clear': this.clearCommutation,
  };
  
  if (cables.length == 2 && cables[0].image.fibers == cables[1].image.fibers) {
    this.advanced_options['Connect by number'] = this.connectTwoCablesByNumbers;
  }
  
  this.initOptionsList(this.$plus_dropdown, this.add_options);
  this.initOptionsList(this.$adv_dropdown, this.advanced_options);
  
  //this.$info_btn.on('click', this.sayHello.bind(this));
  // Add options
  
}

function _translate(text) {
  var translated = document['LANG'][text.toUpperCase()];
  
  if (typeof translated === 'undefined') {
    console.log('untranslated', text);
    return text;
  }
  
  translated = translated.replace(/&#39;/gm, '\'');
  
  return translated;
}