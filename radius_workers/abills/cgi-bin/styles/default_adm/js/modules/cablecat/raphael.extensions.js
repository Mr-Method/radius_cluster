/**
 * Too many times I've seen or written stuff like this that drives me mad:
 *
 * this.ox = this.type == 'rect' ? this.attr('x') : this.attr('cx');
 * this.oy = this.type == 'rect' ? this.attr('y') : this.attr('cy');
 *
 * {...10,000 words of rant skipped here...}
 *
 * The last one simplifies it to:
 * this.o();    // and better, it supports chaining
 *
 * @copyright   Terry Young <terryyounghk [at] gmail.com>
 * @license     WTFPL Version 2 ( http://en.wikipedia.org/wiki/WTFPL )
 */
Raphael.el.is = function (type) { return this.type == (''+type).toLowerCase(); };
Raphael.el.x = function () { return this.is('circle') ? this.attr('cx') : this.attr('x'); };
Raphael.el.y = function () { return this.is('circle') ? this.attr('cy') : this.attr('y'); };
Raphael.el.o = function () { this.ox = this.x(); this.oy = this.y(); return this; };


/**
 * Another one of my core extensions.
 * Raphael has getBBox(), I guess the "B" stands for Basic,
 * because I'd say the "A" in getABox() here stands for Advanced.
 *
 * It's just to free myself from calculating the same stuff over and over and over again.
 * {...10,000 words of rant skipped here...}
 *
 * @author      Terry Young <terryyounghk [at] gmail.com>
 * @license     WTFPL Version 2 ( http://en.wikipedia.org/wiki/WTFPL )
 */
Raphael.el.getABox = function ()
{
  var b = this.getBBox(); // thanks, I'll take it from here...
  
  var o =
      {
        // we'd still return what the original getBBox() provides us with
        x:              b.x,
        y:              b.y,
        width:          b.width,
        height:         b.height,
    
        // now we can actually pre-calculate the following into properties that are more readible for humans
        // x coordinates have three points: left edge, centered, and right edge
        xLeft:          b.x,
        xCenter:        b.x + b.width / 2,
        xRight:         b.x + b.width,
    
    
        // y coordinates have three points: top edge, middle, and bottom edge
        yTop:           b.y,
        yMiddle:        b.y + b.height / 2,
        yBottom:        b.y + b.height
      };
  
  
  // now we can produce a 3x3 combination of the above to derive 9 x,y coordinates
  
  // center
  o.center      = {x: o.xCenter,    y: o.yMiddle };
  
  // edges
  o.topLeft     = {x: o.xLeft,      y: o.yTop };
  o.topRight    = {x: o.xRight,     y: o.yTop };
  o.bottomLeft  = {x: o.xLeft,      y: o.yBottom };
  o.bottomRight = {x: o.xRight,     y: o.yBottom };
  
  // corners
  o.top         = {x: o.xCenter,    y: o.yTop };
  o.bottom      = {x: o.xCenter,    y: o.yBottom };
  o.left        = {x: o.xLeft,      y: o.yMiddle };
  o.right       = {x: o.xRight,     y: o.yMiddle };
  
  // shortcuts to get the offset of paper's canvas
  o.offset      = $(this.paper.canvas).parent().offset();
  
  return o;
};


/**
 * Routine drag-and-drop. Just el.draggable()
 *
 * So instead of defining move, start, end and calling this.drag(move, start, end)
 * over and over and over again {10,000 words of rant skipped here}...
 *
 * @author      Terry Young <terryyounghk [at] gmail.com>
 * @license     WTFPL Version 2 ( http://en.wikipedia.org/wiki/WTFPL )
 */
Raphael.el.draggable = function (options)
{
  $.extend(true, this, {
    margin: 0               // I might expand this in the future
  },options || {});
  
  var start = function () {
        this.o().toFront(); // store original pos, and zIndex to top
      },
      move = function (dx, dy, mx, my, ev) {
        var b = this.getABox(); // Raphael's getBBox() on steroids
        var px = mx - b.offset.left,
            py = my - b.offset.top,
            x = this.ox + dx,
            y = this.oy + dy,
            r = this.is('circle') ? b.width / 2 : 0;
    
        // nice touch that helps you keep draggable elements within the canvas area
        var x = Math.min(
            Math.max(0 + this.margin + (this.is('circle') ? r : 0), x),
                this.paper.width - (this.is('circle') ? r : b.width) - this.margin),
            y = Math.min(
                Math.max(0 + this.margin + (this.is('circle') ? r : 0), y),
                this.paper.height - (this.is('circle') ? r : b.height) - this.margin);
    
        // work-smart, applies to circles and non-circles
        var pos = { x: x, y: y, cx: x, cy: y };
        this.attr(pos);
      },
      end = function () {
        // not cool
      };
  
  this.drag(move, start, end);
  
  return this; // chaining
};


/**
 * Makes Raphael.el.draggable applicable to Raphael Sets, and chainable
 *
 * @author      Terry Young <terryyounghk [at] gmail.com>
 * @license     WTFPL Version 2 ( http://en.wikipedia.org/wiki/WTFPL )
 */
Raphael.st.draggable = function (options) {
  for (var i in this.items) this.items[i].draggable(options);
  return this; // chaining
};

//
// This is a modified version of the jQuery context menu plugin. Credits below.
//

// jQuery Context Menu Plugin
//
// Version 1.01
//
// Cory S.N. LaViska
// A Beautiful Site (http://abeautifulsite.net/)
//
// More info: http://abeautifulsite.net/2008/09/jquery-context-menu-plugin/
//
// Terms of Use
//
// This plugin is dual-licensed under the GNU General Public License
//   and the MIT License and is copyright A Beautiful Site, LLC.
//
(function($)
{
  $.extend($.fn,
      {
        contextMenu: function(options)
        {
          // Defaults
          var defaults =
              {
                fadeIn:        150,
                fadeOut:       75
              },
              o = $.extend(true, defaults, options || {}),
              d = document;
          
          // Loop each context menu
          $(this).each( function()
          {
            var el = $(this),
                offset = el.offset(),
                $m = $('#' + o.menu);
            
            // Add contextMenu class
            $m.addClass('contextMenu');
            
            // Simulate a true right click
            $(this).mousedown( function(e) {
              
              // e.stopPropagation(); // Terry: No, thank you
              $(this).mouseup( function(e) {
                // e.stopPropagation(); // Terry: No, thank you
                var target = $(this);
                
                $(this).unbind('mouseup');
                
                if( e.button == 2 ) {
                  // Hide context menus that may be showing
                  $(".contextMenu").hide();
                  // Get this context menu
                  
                  if( el.hasClass('disabled') ) return false;
                  
                  // show context menu on mouse coordinates or keep it within visible window area
                  var x = Math.min(e.pageX, $(document).width() - $m.width() - 5),
                      y = Math.min(e.pageY, $(document).height() - $m.height() - 5);
                  
                  // Show the menu
                  $(document).unbind('click');
                  $m
                      .css({ top: y, left: x })
                      .fadeIn(o.fadeIn)
                      .find('A')
                      .mouseover( function() {
                        $m.find('LI.hover').removeClass('hover');
                        $(this).parent().addClass('hover');
                      })
                      .mouseout( function() {
                        $m.find('LI.hover').removeClass('hover');
                      });
                  
                  if (o.onShow) o.onShow( this, {x: x - offset.left, y: y - offset.top, docX: x, docY: y} );
                  
                  // Keyboard
                  $(document).keypress( function(e) {
                    var $hover = $m.find('li.hover'),
                        $first = $m.find('li:first'),
                        $last  = $m.find('li:last');
                    
                    switch( e.keyCode ) {
                      case 38: // up
                        if( $hover.size() == 0 ) {
                          $last.addClass('hover');
                        } else {
                          $hover.removeClass('hover').prevAll('LI:not(.disabled)').eq(0).addClass('hover');
                          if( $hover.size() == 0 ) $last.addClass('hover');
                        }
                        break;
                      case 40: // down
                        if( $hover.size() == 0 ) {
                          $first.addClass('hover');
                        } else {
                          $hover.removeClass('hover').nextAll('LI:not(.disabled)').eq(0).addClass('hover');
                          if( $hover.size() == 0 ) $first.addClass('hover');
                        }
                        break;
                      case 13: // enter
                        $m.find('LI.hover A').trigger('click');
                        break;
                      case 27: // esc
                        $(document).trigger('click');
                        break
                    }
                  });
                  
                  // When items are selected
                  $m.find('A').unbind('click');
                  $m.find('LI:not(.disabled) A').click( function() {
                    var checked = $(this).attr('checked');
                    
                    switch ($(this).attr('type')) // custom attribute
                    {
                      case 'radio':
                        $(this).parent().parent().find('.checked').removeClass('checked').end().find('a[checked="checked"]').removeAttr('checked');
                        // break; // continue...
                      case 'checkbox':
                        if ($(this).attr('checked') || checked)
                        {
                          $(this).removeAttr('checked');
                          $(this).parent().removeClass('checked');
                        }
                        else
                        {
                          $(this).attr('checked', 'checked');
                          $(this).parent().addClass('checked');
                        }
                        
                        //if ($(this).attr('hidemenu'))
                      {
                        $(".contextMenu").hide();
                      }
                        break;
                      default:
                        $(document).unbind('click').unbind('keypress');
                        $(".contextMenu").hide();
                        break;
                    }
                    // Callback
                    if( o.onSelect )
                    {
                      o.onSelect( $(this), $(target), $(this).attr('href'), {x: x - offset.left, y: y - offset.top, docX: x, docY: y} );
                    }
                    return false;
                  });
                  
                  // Hide bindings
                  setTimeout( function() { // Delay for Mozilla
                    $(document).click( function() {
                      $(document).unbind('click').unbind('keypress');
                      $m.fadeOut(o.fadeOut);
                      return false;
                    });
                  }, 0);
                }
              });
            });
            
            // Disable text selection
            if( $.browser ) { // latest version of jQuery no longer supports $.browser()
              if( $.browser.mozilla ) {
                $m.each( function() { $(this).css({ 'MozUserSelect' : 'none' }); });
              } else if( $.browser.msie ) {
                $m.each( function() { $(this).bind('selectstart.disableTextSelect', function() { return false; }); });
              } else {
                $m.each(function() { $(this).bind('mousedown.disableTextSelect', function() { return false; }); });
              }
            }
            // Disable browser context menu (requires both selectors to work in IE/Safari + FF/Chrome)
            el.add($('UL.contextMenu')).bind('contextmenu', function() { return false; });
            
          });
          return $(this);
        },
        // Destroy context menu(s)
        destroyContextMenu: function() {
          // Destroy specified context menus
          $(this).each( function() {
            // Disable action
            $(this).unbind('mousedown').unbind('mouseup');
          });
          return( $(this) );
        }
        
      });
})(jQuery);


/***
 * raphael.pan-zoom plugin 0.2.1
 * Copyright (c) 2012 @author Juan S. Escobar
 * https://github.com/escobar5
 *
 * licensed under the MIT license
 */
$(function(){function b(e){var h=e.offsetLeft,f=e.offsetTop,g;while(e.offsetParent){if(e===document.getElementsByTagName("body")[0]){break}else{h=h+e.offsetParent.offsetLeft;f=f+e.offsetParent.offsetTop;e=e.offsetParent}}g=[h,f];return g}function a(h,g){var f,j,i;if(h.pageX||h.pageY){f=h.pageX;j=h.pageY}else{f=h.clientX+document.body.scrollLeft+document.documentElement.scrollLeft;j=h.clientY+document.body.scrollTop+document.documentElement.scrollTop}i=b(g);f-=i[0];j-=i[1];return{x:f,y:j}}var d={enable:function(){this.enabled=true},disable:function(){this.enabled=false},zoomIn:function(e){this.applyZoom(e)},zoomOut:function(e){this.applyZoom(e>0?e*-1:e)},pan:function(f,e){this.applyPan(f*-1,e*-1)},isDragging:function(){return this.dragTime>this.dragThreshold},getCurrentPosition:function(){return this.currPos},getCurrentZoom:function(){return this.currZoom}},c=function(f,s){var g=f,e=g.canvas.parentNode,p=this,j={},h={x:0,y:0},l=0,k=0,q=(/Firefox/i.test(navigator.userAgent))?"DOMMouseScroll":"mousewheel";this.enabled=false;this.dragThreshold=5;this.dragTime=0;s=s||{};j.maxZoom=s.maxZoom||9;j.minZoom=s.minZoom||0;j.zoomStep=s.zoomStep||0.1;j.initialZoom=s.initialZoom||0;j.initialPosition=s.initialPosition||{x:0,y:0};this.currZoom=j.initialZoom;this.currPos=j.initialPosition;function i(){p.currPos.x=p.currPos.x+l;p.currPos.y=p.currPos.y+k;var u=g.width*(1-(p.currZoom*j.zoomStep)),t=g.height*(1-(p.currZoom*j.zoomStep));if(p.currPos.x<0){p.currPos.x=0}else{if(p.currPos.x>(g.width*p.currZoom*j.zoomStep)){p.currPos.x=(g.width*p.currZoom*j.zoomStep)}}if(p.currPos.y<0){p.currPos.y=0}else{if(p.currPos.y>(g.height*p.currZoom*j.zoomStep)){p.currPos.y=(g.height*p.currZoom*j.zoomStep)}}g.setViewBox(p.currPos.x,p.currPos.y,u,t)}function r(x){if(!p.enabled){return false}var v=window.event||x,w=g.width*(1-(p.currZoom*j.zoomStep)),u=g.height*(1-(p.currZoom*j.zoomStep)),t=a(v,e);l=(w*(t.x-h.x)/g.width)*-1;k=(u*(t.y-h.y)/g.height)*-1;h=t;i();p.dragTime+=1;if(v.preventDefault){v.preventDefault()}else{v.returnValue=false}return false}function o(t,u){if(!p.enabled){return false}p.currZoom+=t;if(p.currZoom<j.minZoom){p.currZoom=j.minZoom}else{if(p.currZoom>j.maxZoom){p.currZoom=j.maxZoom}else{u=u||{x:g.width/2,y:g.height/2};l=((g.width*j.zoomStep)*(u.x/g.width))*t;k=(g.height*j.zoomStep)*(u.y/g.height)*t;i()}}}this.applyZoom=o;function m(v){if(!p.enabled){return false}var t=window.event||v,w=t.detail||t.wheelDelta*-1,u=a(t,e);if(w>0){w=-1}else{if(w<0){w=1}}o(w,u);if(t.preventDefault){t.preventDefault()}else{t.returnValue=false}return false}i();e.onmousedown=function(u){var t=window.event||u;if(!p.enabled){return false}p.dragTime=0;h=a(t,e);e.className+=" grabbing";e.onmousemove=r;document.onmousemove=function(){return false};if(t.preventDefault){t.preventDefault()}else{t.returnValue=false}return false};e.onmouseup=function(t){document.onmousemove=null;e.className=e.className.replace(/(?:^|\s)grabbing(?!\S)/g,"");e.onmousemove=null};if(e.attachEvent){e.attachEvent("on"+q,m)}else{if(e.addEventListener){e.addEventListener(q,m,false)}}function n(u,t){l=u;k=t;i()}this.applyPan=n};c.prototype=d;Raphael.fn.panzoom={};Raphael.fn.panzoom=function(e){var f=this;return new c(f,e)}}());