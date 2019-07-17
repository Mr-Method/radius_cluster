/**
 * Created by Anykey on 04.10.2016.
 */

'use strict';
var GPS = 'GPS';
var GPS_ROUTE = 'GPS_ROUTE';

var GPS_ID = 8;
var GPS_ROUTE_ID = 9;

(function(){
  Events.on('layersready', function(){
    if (FORM['show_gps']) {
      MapLayers.enableLayer(GPS_ID);
    
      Events.on(LAYER_ID_BY_NAME[GPS] + '_ENABLED', function () {
        //get color for requested admin
        var objects = MapLayers.getLayerObjects(GPS_ID);
      
        var color = 17;
        var pos_x, pos_y;
      
        var found = false;
      
        $.each(objects, function (i, obj) {
          if (obj) {
            if (FORM['show_gps'] == obj.marker.metaInfo.ADMIN) {
              found = true;
            
              var marker = obj.marker;
              color      = marker.metaInfo['colorNo'];
              pos_x      = marker.metaInfo.x;
              pos_y      = marker.metaInfo.y;
              GPSControls.showRouteFor(FORM['show_gps'], color);
              changePosition(pos_x, pos_y, 18);
            }
          }
        });
      
        if (!found) {
          alert('No GPS information for administrator with this ID: ' + FORM['show_gps']);
        }
      });
    }
  })
})();

window['GPSControls'] = (function () {
  
  function showRouteFor(admin_id, color_no, from_btn) {

    var no_request = FORM['NO_ROUTE'];

    if (from_btn) {
      FORM['DATE']  = null;
      no_request = false;
    }

    if (!no_request)
      if (!FORM['DATE']) {

        var requestRouteLayer = function (formObject) {
          requestLayer(GPS_ROUTE_ID, admin_id, color_no, formObject.date, formObject.time_from, formObject.time_to);
        };

        Events.once('GPS_ROUTE_DATE_CHOOSED', requestRouteLayer);

        var requestDate = function () {
          var dateModal = aModal.clear();

          var dateModalBody =
                  '<div class="modal-body"><div class="row">'
                  + '<label class="control-label col-md-2">Date</label>'
                  + '<div class="col-md-10">'
                  + '<input type="text" id="dateModal_DATE" class="form-control datepicker">'
                  + '</div><hr/>'

                  + '<div class="row">'
                  + '<label class="control-label col-md-2">Time</label>'
                  + '<div class="col-md-5">'
                  + '<input type="text" id="dateModal_TIME1" value="00:00" class="form-control">'
                  + '</div>'

                  + '<div class="col-md-5">'
                  + '<input type="text" id="dateModal_TIME2" value="23:59" class="form-control">'
                  + '</div>'

                  + '</div></div>';

          dateModal
              .setBody(dateModalBody)
              .addButton('Submit', 'dateModal_SUBMIT', 'btn btn-primary')
              .setSmall(true)
              .show(dateModalConfigure);

          function dateModalConfigure() {
            //cache DOM
            var date_input      = $('#dateModal_DATE');
            var time_from_input = $('#dateModal_TIME1');
            var time_to_input   = $('#dateModal_TIME2');
            var submit_btn      = $('#dateModal_SUBMIT');

            // Get current date
            var date_default = new Date();
            var year         = date_default.getYear() + 1900;
            var month        = date_default.getMonth() + 1;
            var day          = date_default.getDate();

            var date_string = year
                + '-' + ensureLength(month, 2)
                + '-' + ensureLength(day, 2);

            date_input.val(date_string);
  
            //Date picker
            date_input.datepicker({
              autoclose     : true,
              format        : 'yyyy-mm-dd',
              startDate     : '-100y',
              todayHighlight: true,
              clearBtn      : true,
              forceParse    : false
            });
            
            //time_to_input.timepicker({
            //  showMeridian : false,
            //  defaultTime: false,
            //  explicitMode : false
            //});
            //
            //time_from_input.timepicker({
            //  showMeridian : false,
            //  defaultTime: false,
            //  explicitMode : false
            //});
            
            submit_btn.on('click', requestRouteForDate);

            function requestRouteForDate(e) {
              e.preventDefault();

              // Clear all event handlers
              submit_btn.off();

              Events.emit('GPS_ROUTE_DATE_CHOOSED', {
                "date"     : date_input.val(),
                "time_from": time_from_input.val(),
                "time_to"  : time_to_input.val()
              });
              
              dateModal.hide();
              dateModal.destroy();
            }
          }
        };

        requestDate();
      }
      else {
        requestLayer(GPS_ROUTE_ID, admin_id, color_no, FORM['DATE']);
      }
  }

  var processGPSRoute = function (GPSRoute, layer, colorNo) {
    var AMapSimpleDrawer = BillingObjectParser.getDrawer();
    $.each(GPSRoute, function (i, Route) {

      var newRoute = {
        markers : [],
        polyline: {},
      };
      
      //Color for route
      var colorHex = aColorPalette.getColorHex(colorNo);
      AMapSimpleDrawer.setColor(colorHex);

      //Process  route  markers
      $.each(Route['MARKERS'], function (i, marker) {
        // Set icon parameters
        marker.TYPE = 'position/' + colorNo;
        marker.SIZE = [15, 15];

        // Draw and save markers
        var routeMarker = AMapSimpleDrawer.drawMarker(marker);
        newRoute.markers.push(routeMarker);
      });


      // Check if animation available
      var animationAvailable = aMap.animatePolyline(true, Route['POLYLINE']);

      newRoute.polyline = AMapSimpleDrawer.drawPolyline(Route['POLYLINE']);
      newRoute.types = [ 'markers' ];

      // If animation available set animate handlers
      if (animationAvailable) {
        aMap.animatePolyline(false, newRoute.polyline);
      }

      MapLayers.pushToLayer(layer, newRoute);

      Events.emit(layer + '_RENDERED', true);
    });
  };

  function requestLayer(layer, admin_id, colorNo, date, time_from, time_to) {
    $.getJSON(aBillingAddressManager.getMarkersForLayer(
        'gps_route&AID=' + admin_id
        + '&colorNo=' + colorNo
        + '&DATE=' + date
        + "&TIME_FROM=" + time_from
        + "&TIME_TO=" + time_to
    ))
        .done(function (json) {

          if (json.length == 1 && json[0].MESSAGE) {
            new ATooltip()
                .setText('<h1>' + json[0].MESSAGE + '</h1>')
                .setClass('danger')
                .setTimeout(2000)
                .show();

            return false;
          }

          Events.on(layer + '_RENDERED', function () {
            MapLayers.enableLayer(layer);
          });

          processGPSRoute(json, layer, colorNo);
        })

        .fail(function (jqxhr, textStatus, error) {
          var err = textStatus + ", " + error;
          new ATooltip("<h4>Request Failed: " + err + "</h4>").setClass('danger').show();
        });
  }

  return {
    showRouteFor: showRouteFor
  }
})();
