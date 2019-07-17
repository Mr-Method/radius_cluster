/**
 * Created by Anykey on 19.05.2016.
 *
 */

'use strict';

var OPERATION_NORMAL = 0;
var OPERATION_ADD    = 1;
var OPERATION_REMOVE = 2;

var OPERATION_MODE = OPERATION_NORMAL;

//var ROUTE_LAYER        = 'ROUTE_LAYER';
//var WIFI_LAYER         = 'WIFI_LAYER';
//var WELL_LAYER         = 'WELL_LAYER';
//var BUILD_LAYER        = 'BUILD_LAYER';
//var GPS_LAYER          = 'GPS_LAYER';
//var EQUIPMENT_LAYER    = 'EQUIPMENT_LAYER';
//var GPS_ROUTE_LAYER    = 'GPS_ROUTE_LAYER';
//var TRAFFIC_LAYER      = 'TRAFFIC_LAYER';
//var CUSTOM_POINT_LAYER = 'CUSTOM_POINT_LAYER';

var MARKERS_POLYLINE = "MARKERS_POLYLINE";//"markers + polyline",
var MARKER_CIRCLE    = "MARKER_CIRCLE"; // "marker + circle",
var MARKER           = "MARKER"; //"marker",
var MARKERS          = "MARKERS";
var POLYLINE         = "POLYLINE";

window['ObjectsArray'] = [];

function addNewPoint(layer_id, object_id) {
  
  OPERATION_MODE = OPERATION_ADD;
  var layer      = MapLayers.getLayer(layer_id);
  var structure  = layer.structure;
  //var lang_name  = layer.lang_name;
  
  if (!structure) {
    throw new Error('Unsupported drawing mode', layer, structure);
  }
  
  var mapObject      = MapObjectTypesRefs.getMapObject(layer_id);
  mapObject.stucture = mapObject;
  
  if (isDefined(object_id)) {
    mapObject.setId(object_id);
  }
  
  //Initialize controllers
  aDrawController = new DrawController();
  
  if (isDefined(FORM['ICON'])) {
    aDrawController.setIcon(aMarkerBuilder.getIconFileName(FORM['ICON']));
  }
  
  aDrawController
      .setControlsEnabled(structure === MULTIPLE)
      .setLayerId(layer_id)
      .setCallback(overlayCompleteCallback)
      .init(map);
  
  aDrawController.setDrawingMode(structure);
  //aTooltip.display('<h3>' + _NOW_YOU_CAN_ADD_NEW + lang_name + _TO_MAP + '</h3>', 1000);
  
  $('#dropOperationCtrlBtn').find('button').attr('class', 'btn btn-danger');
  
  if (isDefined(mapObject.init)) {
    mapObject.init(layer);
  }
  
  if (MapLayers.hasLayer(layer_id)) {
    if (!MapLayers.isLayerVisible(layer_id)) {
      MapLayers.enableLayer(layer_id);
    }
    
    if (MapLayers.hasCustomSent(layer_id)) {
      var layer_obj = MapLayers.getLayer(layer_id);
      
      mapObject.setCustomParams({
        add_func: layer_obj['add_func'],
        module  : layer_obj['module']
      });
      
      // Allow returning params to module
      if (layer_obj.custom_params !== null) {
        mapObject.addCustomParams(layer_obj.custom_params);
      }
    }
  }
  
  aDrawController.setMapObject(mapObject);
  
  Events.emit('add_object_to_layer', layer_id);
  
  Events.once('currentmapobjectfinished', function () {
    // Finished editing
    if (drawing_last_overlay) aMap.removeObjectFromMap(drawing_last_overlay);
    
    dropOperation();
    aDrawController.clearDrawingMode();
  });
}


function toggleRemoveMarkerMode() {
  OPERATION_MODE = OPERATION_REMOVE;
  
  var markers = MapLayers.getAllVisibleMarkers();
  
  markers.forEach(function(marker){
    marker['remove_listener'] = aMap.addListenerToObject(marker, 'click', function () {
      console.log('click');
      showRemoveConfirmModal(marker);
    });
  });
  
  console.log('[ Remove ] Listeners set to ', markers.length);
  
  $('#dropOperationCtrlBtn').find('button').attr('class', 'btn btn-danger');
  
  new ATooltip('<h2>' + _CLICK_ON_A_MARKER_YOU_WANT_TO_DELETE + '</h2>')
      .setClass('info')
      .show();
  
}

function startEdit(layer_id, object_id) {
  var object = MapLayers.getObject(layer_id, object_id);
  closeInfoWindows();
  
  if (!object) {
    aTooltip.displayError('Layer doesn\'t implement editing');
    return false;
  }
  
  MapLayers.mapGeometry(object, function (geometry, type) {
    geometry.setDraggable(true);
    if (geometry.setEditable)
      geometry.setEditable(true);
  });
  
}

function finishEditing(object) {
  MapLayers.mapGeometry(object, function (geometry, type) {
    geometry.setDraggable(false);
    if (geometry.setEditable)
      geometry.setEditable(false);
  });
  
  var mapOverlay = MapObjectTypesRefs.getMapObject(object.layer_id);
  if (mapOverlay.update(object)) mapOverlay.send();
}

function showRemoveConfirmModal(marker) {
  console.log(marker);
  var id       = marker.id;
  var layer_id = marker.layer_id;
  
  if (!(layer_id && id)) {
    console.warn('No layer id or id', layer_id, id, marker);
    return false;
  }
  
  aModal.clear()
      .setBody('<div id="confirmModalContent">' + _REMOVE + '?</div>')
      .addButton(_NO, "confirmModalCancelBtn", "default")
      .addButton(_YES, "confirmModalConfirmBtn", "success")
      .show(bindBtnEvents);
  
  
  function bindBtnEvents(modal) {
    //modal.onClose(dropOperation);
    
    $('#confirmModalCancelBtn').on('click', function () {
      modal.hide();
      dropOperation();
    });
    
    $('#confirmModalConfirmBtn').on('click', function () {
      loadToModal(
          aBillingAddressManager.removeObject(layer_id, id),
          function () {
            closeInfoWindows();
            Events.emit('point_removed_' + layer_id, id);
          }
      );
    });
  }
  
}

function discardRemovingPoint() {
  
  var markers = MapLayers.getAllVisibleMarkers();
  
  for (var i = 0; i < markers.length; i++) {
    if (!markers[i]['remove_listener']) continue;
    aMap.removeListenerFromObject(markers[i], 'click', markers[i]['remove_listener']);
    delete markers[i]['remove_listener'];
  }
  
  return true;
}


function overlayCompleteCallback(e) {
  
  //getRegistrator
  var registrator = aDrawController.getObjectRegistrator();
  var layer_id    = aDrawController.getLayerId();
  var lang_name   = MapLayers.getLayer(layer_id)['lang_name'];
  
  //getObject
  var object           = registrator.getMapObject();
  drawing_last_overlay = e.overlay;
  
  //Pass overlay to object
  var isNotFinished = object.emit(e.overlay, e.feature);
  
  if (FORM['LOCATION_ID']) {
    // Ask user for confirmation
    showConfirmModal(lang_name);
  }
  else {
    // Confirm without asking
    confirmAddingPoint();
  }
  
  return isNotFinished === true;
}

function confirmAddingPoint() {
  // Hide modal
  confirmModal.hide();
  
  // Tell object he is ready to be sent
  aDrawController.getObjectRegistrator().send(function (success) {
    if (success) {
      delete FORM['OBJECT_ID'];
    }
  });
}

function discardAddingPoint() {
  //removing discarded marker
  if (drawing_last_overlay) drawing_last_overlay.setMap(null);
  
  confirmModal.hide();
}

function dropOperation() {
  switch (OPERATION_MODE) {
    case OPERATION_NORMAL:
      return;
      break;
    case OPERATION_ADD:
      if (aDrawController) aDrawController.clearDrawingMode();
      discardAddingPoint();
      break;
    case OPERATION_REMOVE:
      discardRemovingPoint();
      break;
  }
  
  $('#dropOperationCtrlBtn').find('button').attr('class', 'btn btn-primary');
  
  OPERATION_MODE = OPERATION_NORMAL;
}

function getClosestBuildsToThis(latLng, range_) {
  var range  = range_ || 100;
  var builds = MapLayers.getLayerObjects(LAYER_ID_BY_NAME['BUILD']);
  
  var closer = [];
  builds.map(function (build) {
    if (aMap.getDistanceBeetween(build.marker.latLng, latLng) <= range) {
      closer[closer.length] = build;
    }
  });
  
  return closer;
}

function polyline_zoom_listener(polyline, zoom) {
  var currentWidth = polyline.strokeWeight;
  var new_width    = currentWidth;
  
  if (zoom > 17) {
    // Increase zoom until 18
    if (zoom <= 19) {
      new_width = +polyline.initWeight + ((zoom - 17) * 2);
    }
    // Max zoom
    else {
      new_width = +polyline.initWeight + 4;
    }
  }
  // Minimal weight
  else if (zoom == 17) {
    new_width = +polyline.initWeight;
  }
  else if (zoom < 14) {
    aMap.removeObjectFromMap(polyline);
    return true;
  }
  
  if (zoom >= 15 && polyline.map == null) {
    aMap.addObjectToMap(polyline);
  }
  
  if (new_width != currentWidth) {
    polyline.setOptions({strokeWeight: new_width});
  }
  
}

var STRUCTURE_REFS = {};

function DistrictPolygoner(layer_id) {
  var self            = this;
  this.districtsArray = [];
  this.computed       = false;
  this.polygonsArray  = [];
  this.active         = false;
  
  this.addMarker = function (districtId, latLng) {
    var was_active = self.active;
    if (was_active) self.disable();
    this.computed = false;
    
    if (!isDefined(this.districtsArray[districtId])) {
      this.districtsArray[districtId] = [latLng];
    }
    else {
      this.districtsArray[districtId][this.districtsArray[districtId].length] = latLng;
    }
    
    if (was_active) self.enable();
    return this.districtsArray[districtId].length - 1;
  };
  
  this.removeMarker = function (district_id, marker_id) {
    var was_active = self.active;
    if (was_active) self.disable();
    
    var index = -1;
    var array = self.districtsArray[district_id];
    
    for (var i = 0, len = array.length; i < len; i++) {
      if (array[i].id == marker_id) {
        index = i;
        break;
      }
    }
    
    if (index == -1) {
      console.log('Cant\'t find marker with this id in array');
    }
    
    array.splice(index, 1);
    
    self.computed = false;
    if (was_active) self.enable();
  };
  
  this.toggle = function () {
    var btn = $('#polygonToggle').find('button');
    
    if (this.active) {
      this.hidePolygons();
      this.active = false;
      if (btn) {
        btn.removeClass('btn-primary');
        btn.addClass('btn-danger');
      }
    }
    else {
      this.showPolygons();
      this.active = true;
      if (btn) {
        btn.addClass('btn-primary');
        btn.removeClass('btn-danger');
      }
    }
  };
  
  this.enable = function () {
    if (!self.active) {
      self.toggle();
    }
  };
  
  this.disable = function () {
    if (self.active) {
      self.toggle();
    }
  };
  
  this.hidePolygons = function () {
    $.each(this.polygonsArray, function (i, e) {
      aMap.removeObjectFromMap(e);
    });
  };
  
  this.showPolygons = function () {
    if (!this.computed) this.compute();
    
    $.each(self.polygonsArray, function (i, e) {
      aMap.addObjectToMap(e);
    });
  };
  
  this.compute = function () {
    self.polygonsArray = [];
    
    var arr = this.districtsArray;
    aColorPalette.clear();
    
    for (var pointsArr in arr) {
      if (!arr.hasOwnProperty(pointsArr)) continue;
      
      var points = arr[pointsArr];
      if (points.length > 2) {
        createShell(points);
      }
    }
    this.computed = true;
  };
  
  function createShell(points) {
    //sort
    points.sort(sortPointY);
    points.sort(sortPointX);
    
    //Do some magic
    var hullPoints      = []; //output of magic algorithm
    var hullPoints_size = chainHull_2D(points, points.length, hullPoints);
    
    var color = aColorPalette.getNextColorHex();
    
    var polygon = PolygonBuilder.build({
      paths        : hullPoints,
      strokeColor  : color,
      strokeOpacity: 0.8,
      strokeWeight : 2,
      fillColor    : color,
      fillOpacity  : 0.35
    });
    
    self.polygonsArray.push(polygon); //save reference
  }
  
  function sortPointX(a, b) {
    return a.lng - b.lng
  }
  
  function sortPointY(a, b) {
    return a.lat - b.lat
  }
  
  function isLeft(a, b, c) {
    return (b.lng - a.lng) * (c.lat - a.lat) - (c.lng - a.lng) * (b.lat - a.lat)
  }
  
  function chainHull_2D(a, b, c) {
    var f, h, d = 0, e = -1, g = 0, i = a[0].lng;
    for (f = 1; b > f && a[f].lng == i; f++);
    if (h = f - 1, h == b - 1)return c[++e] = a[g], a[h].lat != a[g].lat && (c[++e] = a[h]), c[++e] = a[g], e + 1;
    var j, k = b - 1, l = a[b - 1].lng;
    for (f = b - 2; f >= 0 && a[f].lng == l; f--);
    for (j = f + 1, c[++e] = a[g], f = h; ++f <= j;)if (!(isLeft(a[g], a[j], a[f]) >= 0 && j > f)) {
      for (; e > 0 && !(isLeft(c[e - 1], c[e], a[f]) > 0);)e--;
      c[++e] = a[f]
    }
    for (k != j && (c[++e] = a[k]), d = e, f = j; --f >= h;)if (!(isLeft(a[k], a[h], a[f]) >= 0 && f > h)) {
      for (; e > d && !(isLeft(c[e - 1], c[e], a[f]) > 0);)e--;
      if (a[f].lng == c[0].lng && a[f].lat == c[0].lat)return e + 1;
      c[++e] = a[f]
    }
    return h != g && (c[++e] = a[g]), e + 1
  }
  
  // Bind self to layer state
  Events.on(layer_id + '_ENABLED', this.enable);
  Events.on(layer_id + '_DISABLED', this.disable);
  
  if (layer_id == 1){
    MapLayers.onLayerEnabled(4, self.disable )
  }
  
  // Add markers when added to layer
  Events.on('new_point_rendered_' + layer_id, function (object) {
    if (!(object.raw['DISTRICT'] && (object.raw['ID'] || object.raw['MARKER']['ID']))) {
      console.log('Added to layer, but without district or ID', object.raw['DISTRICT'], object.raw['ID'] + ' || ' + object.raw['MARKER']['ID']);
      return;
    }
    
    var d_id = object.raw['DISTRICT'];
    var o_id = object.raw['ID'] || object.raw['MARKER']['ID'];
    
    var new_obj = {
      lat: object.marker.latLng.lat(),
      lng: object.marker.latLng.lng(),
      id : o_id
    };
    
    self.addMarker(d_id, new_obj);
  });
  
  
  Events.on('point_removed_' + layer_id, function (object_id) {
    var object = MapLayers.getObject(layer_id, object_id);
    
    if (!(object.raw['DISTRICT'] && (object.raw['ID'] || object.raw['MARKER']['ID']))) {
      console.log('Removed, but without district or ID', object.raw['DISTRICT'], object.raw['ID'] + ' || ' + object.raw['MARKER']['ID']);
      return;
    }
    var d_id = object.raw['DISTRICT'];
    var o_id = object.raw['ID'] || object.raw['MARKER']['ID'];
    
    self.removeMarker(d_id, o_id);
  })
  
}

var LayerRequest = (function () {
  
  function requestAndRender(list_name) {
    
    if (typeof (list_name) === 'undefined') {
      console.warn('[ Maps.ABillingRequest ] List name not defined');
    }
    
    var link = aBillingAddressManager.getMarkersForLayer(list_name);
    
    $.getJSON(link)
        .done(BillingObjectParser.render)
        .fail(
            function (jqxhr, textStatus, error) {
              var err = textStatus + ", " + error;
              new ATooltip("<h3>Request Failed: " + err + "</h3>").setClass('danger').show();
            });
  }
  
  return {
    requestAndRender: requestAndRender
  }
})();

var BillingObjectParser = (function () {
  
  function render(data) {
    
    if (data.length == 1 && isDefined(data[0].MESSAGE)) {
      new ATooltip()
          .setText('<h1>' + data[0].MESSAGE + '</h1>')
          .setClass('danger')
          .setTimeout(2000)
          .show();
      
      return false;
    }
    
    var rendered_layer_ids = {};
    
    $.each(data, function (i, mapObject) {
      
      var newObject = {
        layer_id: 0,
        types   : []
      };
      
      if (mapObject['LAYER_ID']) {
        newObject.layer_id                     = mapObject['LAYER_ID'];
        rendered_layer_ids[newObject.layer_id] = 1;
      }
      
      // Structure independent rendering
      for (var key in mapObject) {
        if (!mapObject.hasOwnProperty(key)) continue;
        
        switch (key) {
          case 'ID':
          case 'LAYER_ID':
          case 'DISTRICT':
          case 'ADDRESS':
            break;
          case 'OBJECT_ID':
            newObject['OBJECT_ID'] = mapObject['OBJECT_ID'];
            break;
          case MARKER:
            newObject.marker                        = AMapSimpleDrawer.drawMarker(mapObject['MARKER']);
            newObject.marker.layer_id               = newObject.layer_id;
            newObject.types[newObject.types.length] = 'marker';
            break;
          case MARKERS:
            newObject.markers                       = mapObject['MARKERS'].map(AMapSimpleDrawer.drawMarker);
            newObject.types[newObject.types.length] = 'markers';
            break;
          case CIRCLE:
            newObject.circle                        = AMapSimpleDrawer.drawCircle(mapObject['CIRCLE']);
            newObject.types[newObject.types.length] = 'circle';
            break;
          case POLYLINE:
            newObject.polyline                      = AMapSimpleDrawer.drawPolyline(mapObject['POLYLINE']);
            newObject.types[newObject.types.length] = 'polyline';
            break;
          case POLYGON:
            newObject.polygon                       = AMapSimpleDrawer.drawPolygon(mapObject['POLYGON']);
            newObject.types[newObject.types.length] = 'polygon';
            break;
          default :
            console.warn('[ BillingObjectParser ]', key, 'not implemented');
        }
      }
      
      //Saving reference to original data
      newObject.raw = mapObject;
      
      // Tell others we have rendered new object
      Events.emit('new_point_rendered_' + newObject.layer_id, newObject);
    });
    
    // Iterate over hash keys
    $.each(Object.keys(rendered_layer_ids), function (i, id) {
      Events.emit(id + '_RENDERED');
    });
    
    return rendered_layer_ids;
  }
  
  var AMapSimpleDrawer = (function () {
    
    var color_ = 'green';
    
    function drawMarker(object) {
      var x              = object.COORDX;
      var y              = object.COORDY;
      var infoWindow     = object.INFO || '';
      var type           = object.TYPE || 'build';
      var meta           = object.META || null;
      var sizeArr        = object.SIZE || [32, 37];
      var offsetArr      = (object.CENTERED)
          ? [-sizeArr[0] / 2, -sizeArr[1] / 2]
          : [-sizeArr[0] / 2, -sizeArr[1]];
      var makeNavigation = object.NAVIGATION || '';
      
      var count = (object.COUNT) ? '' + object.COUNT : undefined;
      var id    = object.ID;
      
      var mb = new MarkerBuilder(map);
      mb
          .setPosition(aMap.createPosition(x, y))
          .setType(type)
          .setIcon(type, sizeArr)
          .setIconOffset(offsetArr)
          .setLabel(count)
          .setId(id);
      
      if (infoWindow) mb.setInfoWindow(infoWindow);
      if (meta) mb.setMetaInformation(meta);
      if (makeNavigation) mb.setNavigation(makeNavigation);
      
      var marker = mb.build();
  
      if (isDefined(object.NAME)) {
        marker.tooltip = new Tooltip({
          'marker'   : marker,
          'content': object.NAME,
          'cssClass'  : 'tooltip-hint',
          'map'    : map
        });
      }
      
      aMap.removeObjectFromMap(marker);
      
      if (object['OBJECT_ID']) {
        marker['OBJECT_ID'] = object['OBJECT_ID'];
        marker['object_id'] = object['OBJECT_ID'];
      }
      
      return marker;
    }
    
    function drawPolyline(object) {
      
      object.path         = object.POINTS.map(function (e) {return aMap.createPosition(e[0], e[1])});
      object.strokeColor  = object.strokeColor || color_;
      object.strokeWeight = object.strokeWeight || 1;
      
      var polyline        = PolylineBuilder.build(object);
      polyline.initWeight = object.strokeWeight;
      
      
      // Increase size on zoom
      polyline_zoom_listener(polyline, aMap.getZoom());
      aMap.addListenerToObject(map, 'zoom_changed', function () {
        polyline_zoom_listener(polyline, aMap.getZoom());
      });
  
      aMap.addListenerToObject(polyline, 'mouseover', function () {
        polyline.setOptions({strokeWeight : polyline.strokeWeight + 1});
      });
      aMap.addListenerToObject(polyline, 'mouseout', function () {
        polyline.setOptions({strokeWeight : polyline.strokeWeight - 1});
      });
      
      if (isDefined(object.name) && isDefined(window['Tooltip'])) {
        polyline.tooltip = new Tooltip({
          'poly'   : polyline,
          'content': object.name,
          'cssClass'  : 'tooltip-hint',
          'map'    : map
        });
      }
      
      aMap.removeObjectFromMap(polyline);
      
      return polyline;
    }
    
    function drawCircle(Circle, marker) {
      return CircleBuilder.build(Circle, marker);
    }
    
    function drawPolygon(Polygon) {
      Polygon.path = Polygon.POINTS.map(function (e) {return aMap.createPosition(e[0], e[1])});
      if (Polygon['COLOR'] && typeof Polygon['fillColor'] === 'undefined'){
        Polygon['fillColor'] = Polygon['COLOR'];
        Polygon['strokeColor'] = Polygon['COLOR'];
      }
      
      var polygon = PolygonBuilder.build(Polygon);
  
      if (isDefined(Polygon.name) && isDefined(window['Tooltip'])) {
        polygon.tooltip = new Tooltip({
          'poly'   : polygon,
          'content': Polygon.name,
          'cssClass'  : 'tooltip-hint',
          'map'    : map
        });
      }
      
      return polygon;
    }
    
    function setColor(color) {
      color_ = color;
    }
    
    return {
      drawMarker  : drawMarker,
      drawPolyline: drawPolyline,
      drawPolygon : drawPolygon,
      drawCircle  : drawCircle,
      setColor    : setColor
    }
  })();
  
  function getDrawer() {
    return AMapSimpleDrawer;
  }
  
  return {
    render   : render,
    getDrawer: getDrawer
  }
})();


//TODO: reserved for future optimizations
/*
 function LayerAbstract(layer_id, layerObj){
 var self = this;
 
 this.id                = layer_id;
 this.enabled           = false;
 this.name              = layerObj['name'];
 this.lang_name         = layerObj['lang_name'];
 this.module            = layerObj['module'] || 'Maps';
 this.structure         = layerObj['structure'] || MARKER;
 this.objects           = [];
 this.object_by_id      = {};
 this.clusterer         = aMap.getNewClusterer(map, clustererGridSize);
 this.clusteringEnabled = layerObj['clustering'] || 1;
 this.add_func          = layerObj['add_func'];
 this.custom_params     = layerObj['custom_params'] || null;
 
 Events.on('new_point_rendered_' + layer_id, function (newObject) {
 var object_id =
 newObject['raw']['ID']
 || (newObject['raw']['MARKER'] && newObject['raw']['MARKER']['ID'])
 || newObject['raw']['OBJECT_ID'] || false;
 
 // Prevent adding same object twice
 if (object_id && isDefined(Layers[layer_id].object_by_id[object_id]))
 return;
 else {
 // Save quick reference
 Layers[layer_id].object_by_id[object_id] = newObject;
 }
 
 pushToLayer(layer_id, newObject);
 
 if (object_id) {
 // If layer is already enabled, should add new object on map
 if (Layers[layer_id].enabled) {
 setLayerObjectVisibility(layer_id, object_id, true);
 }
 }
 });
 
 Events.on('point_removed_' + layer_id, function(object_id){
 MapLayers.setLayerObjectVisibility(layer_id, object_id, false);
 var object = getObject(layer_id, object_id);
 if (object){
 var index = Layers[layer_id].objects.indexOf(object);
 Layers[layer_id].objects.splice(index, 1);
 delete Layers[layer_id].object_by_id[object_id];
 }
 });
 }
 */


var MapLayers = (function () {
  
  var Layers = {};
  
  var clustering        = false;
  var clustererGridSize = 30;
  
  function createLayer(layerObj) {
    var layer_id = layerObj['id'];
    
    if (Layers[layer_id]) {
      console.warn('[ MapLayers ]', 'Creating same layer twice', layer_id);
      console.trace();
      return false;
    }
    
    Layers[layer_id] = {
      id               : layer_id,
      enabled          : false,
      name             : layerObj['name'],
      lang_name        : layerObj['lang_name'],
      module           : layerObj['module'] || 'Maps',
      structure        : layerObj['structure'] || MARKER,
      objects          : [],
      object_by_id     : {},
      clusterer        : aMap.getNewClusterer(map, clustererGridSize),
      clusteringEnabled: layerObj['markers_in_cluster'] || 1,
      add_func         : layerObj['add_func'],
      custom_params    : layerObj['custom_params'] || null,
      loading          : false
    };
    
    Events.on('new_point_rendered_' + layer_id, function (newObject) {
      var object_id =
              newObject['raw']['ID']
              || (newObject['raw']['MARKER'] && newObject['raw']['MARKER']['ID'])
              || false;
      
      // Prevent adding same object twice
      if (object_id && isDefined(Layers[layer_id].object_by_id[object_id]))
        return;
      else {
        // Save quick reference
        Layers[layer_id].object_by_id[object_id] = newObject;
      }
      
      pushToLayer(layer_id, newObject);
      
      if (object_id) {
        // If layer is already enabled, should add new object on map
        if (Layers[layer_id].enabled) {
          setLayerObjectVisibility(layer_id, object_id, true);
        }
      }
    });
    
    Events.on('point_removed_' + layer_id, function (object_id) {
      MapLayers.setLayerObjectVisibility(layer_id, object_id, false);
      var object = getObject(layer_id, object_id);
      if (object) {
        var index = Layers[layer_id].objects.indexOf(object);
        Layers[layer_id].objects.splice(index, 1);
        delete Layers[layer_id].object_by_id[object_id];
      }
    });
  }
  
  function setLayerVisible(layer_id, boolean) {
    var layer = Layers[(layer_id)];
    
    if (layer.enabled == boolean) return true;
    
    var layerObjects = layer.objects;
    var state        = (boolean) ? map : null;
    
    var clusterer          = layer.clusterer;
    var clusteringForLayer = layer.clusteringEnabled;
    var clusterCleared     = false;
    
    var setCachedObjectVisibility = (clusteringForLayer)
        ? function (marker) {
          boolean
              ? clusterer.addMarker(marker)
              : clusterCleared ? false : (function () {
                    clusterer.clearMarkers();
                    clusterCleared = true
                  })()
        }
        : function (marker) {
          boolean
              ? aMap.addObjectToMap(marker)
              : aMap.removeObjectFromMap(marker)
        };
    
    // TODO:  Change to structure independent
    switch (layer.structure) {
      case MARKER :
        (clusteringForLayer)
            ? boolean
                ? clusterer.addMarkers(layerObjects.map(function (object) {return object.marker}))
                : (function () {
                  clusterer.clearMarkers();
                  clusterCleared = true
                })()
            : $.each(layerObjects, function (i, object) {
              setCachedObjectVisibility(object.marker);
            });
        break;
      case MARKER_CIRCLE :
        $.each(layerObjects, function (i, object) {
          setCachedObjectVisibility(object.marker);
          object.circle.setMap(state);
        });
        break;
      case MARKERS_POLYLINE :
        $.each(layerObjects, function (i, object) {
          $.each(object.markers, function (i, marker) {
            setCachedObjectVisibility(marker);
          });
          object.polyline.setMap(state);
        });
        break;
      case POLYLINE :
      case POLYGON :
        $.each(layerObjects, function (i, object) {
          object[layer.structure.toLowerCase()].setMap(state);
        });
        break;
      case MULTIPLE :
        $.each(layerObjects, function (i, object) {
          var types = [CIRCLE, POINT, POLYGON, POLYLINE];
          $.each(types, function (i, type) {
            if (isDefined(object[type.toLowerCase()])) {
              (type === POINT)
                  ? setCachedObjectVisibility(object[type.toLowerCase()], state)
                  : boolean
                      ? aMap.addObjectToMap(object[type.toLowerCase()])
                      : aMap.removeObjectFromMap(object[type.toLowerCase()]);
            }
          });
        });
        break;
      default :
        console.warn('[ MapLayers ] Not defined logic for enabling : ' + layer.structure);
    }
    
    Layers[layer_id].enabled = boolean;
    Events.emit(layer_id + ((boolean) ? "_ENABLED" : '_DISABLED'), layer_id);
    Events.emit((boolean) ? 'layer_enabled' : 'layer_disabled', layer_id);
  }
  
  function setLayerMarkerVisibility(layer_id, marker, state) {
    if (Layers[layer_id].clusteringEnabled) {
      state ? Layers[layer_id].clusterer.addMarker(marker) : Layers[layer_id].clusterer.removeMarker(marker);
    }
    else {
      state ? aMap.addObjectToMap(marker) : aMap.removeObjectFromMap(marker);
    }
  }
  
  function setLayerObjectVisibility(layer_id, object_id, state) {
    var object = getObject(layer_id, object_id);
    
    object.types.forEach(function (type) {
      switch (type) {
        case ('marker'):
          setLayerMarkerVisibility(layer_id, object[type], state);
          break;
        case ('markers'):
          object[type].map(function () {setLayerMarkerVisibility(layer_id, object[type], state)});
          break;
        case ('circle'):
        case ('polyline'):
        case ('polygon'):
          state ? aMap.addObjectToMap(object[type]) : aMap.removeObjectFromMap(object[type]);
          break;
      }
    });
  }
  
  function addDefaultListeners(geometry) {
    // Adding default listeners
    aMap.addListenerToObject(geometry, 'click', function () {
      Events.emit('object_click', this);
    });
    aMap.addListenerToObject(geometry, 'rightclick', function () {
      if (this.draggable) {
        finishEditing(MapLayers.getObject(this.layer_id, this.id));
      }
      else {
        startEdit(this.layer_id, this.id);
      }
    });
  }
  
  function mapInnerObjects(mapObject, callback) {
    mapObject.types.forEach(function (type) {
      switch (type) {
        case ('marker'):
        case ('circle'):
        case ('polyline'):
        case ('polygon'):
          callback(mapObject[type], type);
          break;
        case ('markers'):
          mapObject['markers'].map(function (marker) {callback(marker, type)});
          break;
      }
    });
  }
  
  function enableLayer(layer_id) {
    var layer = Layers[layer_id];
    if (!layer) {
      console.warn('[ MapLayers ] enableLayer Unknown : ' + layer_id);
      return false;
    }
    
    if (layer.objects.length) {
      if (layer.enabled) return true;
      setLayerVisible(layer_id, true);
    }
    else {
      //If has no objects, request them from server
      if (layer.loading) return true;
      requestLayer(layer_id, layer.module);
    }
  }
  
  function disableLayer(layer_id) {
    if (!Layers[layer_id].enabled) return true;
    
    setLayerVisible(layer_id, false);
  }
  
  function toggleLayer(layer_id) {
    var currentState = Layers[layer_id].enabled;
    switch (currentState) {
      case true:
        disableLayer(layer_id);
        break;
      case false:
        enableLayer(layer_id);
        break;
    }
  }
  
  function requestLayer(layer_id, layer_module) {
    if (!Layers[layer_id]) {
      console.warn('[ MapLayers ] requestLayer', 'Unknown layer', layer_id);
      return false;
    }
    
    Events.on(layer_id + '_RENDERED', function () {
      setLayerVisible(layer_id, true);
      Layers[layer_id].loading = false;
    });
  
    Layers[layer_id].loading = true;
    
    var export_list_name = LAYER_LIST_REFS[layer_id];
    
    if (!isDefined(export_list_name)) {
      export_list_name = 'LAYER&LAYER_ID=' + layer_id;
    }
    // If it is not Maps module, will have to require it
    else if (isDefined(layer_module)) {
      export_list_name += '&MODULE=' + layer_module;
    }
    
    // Allow to show single object
    if (FORM['SINGLE'] === 1 && FORM['LAYER_ID'] === layer_id && ( isDefined(FORM['POINT_ID']) || isDefined(FORM['OBJECT_ID']) )){
      export_list_name += (isDefined(FORM['POINT_ID']))
          ? '&POINT_ID=' + FORM['POINT_ID']
          : (isDefined(FORM['OBJECT_ID']))
              ? '&OBJECT_ID=' + FORM['OBJECT_ID']
              : '';
      
      // But only once
      delete FORM['SINGLE'];
    }
    else if (layer_id === LAYER_ID_BY_NAME[BUILD]){
      // Should add params from upper panel
      
    }
    
    LayerRequest.requestAndRender(export_list_name);
  }
  
  function refreshLayer(layer_id) {
    if (isLayerVisible(layer_id)) disableLayer(layer_id);
    closeInfoWindows();
    Layers[layer_id].object_by_id = {};
    Layers[layer_id].objects      = [];
    enableLayer(layer_id);
  }
  
  function pushToLayer(layer_id, data) {
    Layers[layer_id].objects[Layers[layer_id].objects.length] = data;
    
    mapInnerObjects(data, addDefaultListeners);
  }
  
  function getLayerObjects(layer_id) {
    return Layers[layer_id].objects;
  }
  
  function getClusterer(layer_id) {
    return Layers[(layer_id)].clusterer;
  }
  
  function onLayerEnabled(layer_id, callback) {
    if (Layers[layer_id] && Layers[layer_id].enabled) {
      callback(layer_id);
    }
    else {
      Events.once(layer_id + '_ENABLED', callback);
    }
  }
  
  function onLayerDisabled(layer_id, callback) {
    if (Layers[layer_id].disabled) callback(layer_id);
    else
      Events.once(layer_id + '_DISABLED', callback);
  }
  
  function hasLayer(layer_id) {
    //console.warn ('Asked about layer', layer_id);
    return typeof (Layers[(layer_id)]) !== 'undefined';
  }
  
  function setClusteringEnabled(cluster_size) {
    clustering = true;
    if (Layers.length > 0)
      throw new Error("You have called setClusteringEnabled() too late. Call me before creating any layers");
    clustererGridSize = cluster_size || 30;
  }
  
  function isLayerVisible(layer_id) {
    return Layers[layer_id].enabled;
  }
  
  function getLayers() {
    return Layers;
  }
  
  function getLayer(layer_id) {
    return Layers[layer_id];
  }
  
  function getObject(layer_id, object_id) {
    if (!Layers[layer_id]) {
      console.warn('[ MapLayers ] Trying to show unknown layer', layer_id);
      return false;
    }
    
    // If has fast reference, use it
    if (Layers[layer_id].object_by_id[object_id]) {
      return Layers[layer_id].object_by_id[object_id];
    }
    
    var layer_objects = getLayerObjects(layer_id);
    
    for (var i = 0; i < layer_objects.length; i++) {
      var object = layer_objects[i];
      
      var key = (object.raw.hasOwnProperty('OBJECT_ID'))
          ? object.raw['OBJECT_ID']
          : (object.raw.hasOwnProperty('ID'))
              ? object.raw['ID']
              : false;
      
      if (!key) continue;
      if (key == object_id) {
        return object;
      }
    }
    
    return false;
  }
  
  function showObject(layer_id, object_id) {
    
    var object = false;
    if (isDefined(FORM['BY_POINT_ID'])){
      object = getObjectByPointId(layer_id, FORM['BY_POINT_ID']);
    }
    else {
      object = getObject(layer_id, object_id);
    }
    
  
    if (!object) {
      var message = '[ MapLayers ] showObject. ' + object_id + ' not found';
      aTooltip.displayError(message);
      console.warn(message);
      return false;
    }
    
    if (isDefined(object.polyline)) {
      var points = object.polyline.POINTS;
      var middle = Math.floor(points.length / 2);
      aMap.setCenter(points[middle][0], points[middle][1]);
    }
    else if (isDefined(object.marker)) {
      aMap.setCenter(object.marker.latLng.lat(), object.marker.latLng.lng());
    }
    
    aMap.setZoom(18);
    
    return true;
  }
  
  function getAllVisibleObjects() {
    var objects = [];
    for (var layer_id in Layers) {
      if (!Layers[layer_id].enabled) continue;
      
      objects.push.apply(objects, Layers[layer_id].objects);
    }
    return objects;
  }
  
  function getObjectByPointId(layer_id, point_id) {
    var layer_objects = getLayerObjects(layer_id);
    for (var i = 0; i < layer_objects.length; i++) {
      console.log(layer_objects[i].raw);
      if (layer_objects[i].raw['OBJECT_ID'] == point_id) {
        return layer_objects[i];
      }
    }
    console.warn('[ MapLayers ] getObjectByPointId', layer_id, point_id ,'not found');
  }
  
  function getAllVisibleMarkers() {
    var objects = [];
    for (var layer_id in Layers) {
      if (!Layers[layer_id].enabled) continue;
      
      var layer         = Layers[layer_id];
      var layer_objects = layer.objects;
      
      switch (layer.structure) {
        case MARKER :
          objects.push.apply(objects, layer_objects.map(function (obj) { return obj.marker}));
          break;
        case MARKER_CIRCLE :
          objects.push.apply(objects, layer_objects.map(function (obj) { return obj.marker}));
          break;
        case MARKERS_POLYLINE :
          $.each(layer_objects, function (i, object) {
            objects.push.apply(objects, object.markers);
          });
          break;
        case MULTIPLE :
          $.each(layer_objects, function (i, object) { // TODO: Simplify
            if (isDefined(object['point'])) {
              objects.push(object['point']);
            }
          });
          break;
      }
      
    }
    return objects;
  }
  
  function hasCustomSent(layer_id) {
    return Layers[layer_id] && typeof (Layers[layer_id]['add_func']) !== 'undefined';
  }
  
  Events.on('layer_has_new_points', function (layer_id) {
    setLayerVisible(layer_id, false);
    setLayerVisible(layer_id, true);
  });
  
  
  return {
    setClusteringEnabled: setClusteringEnabled,
  
    pushToLayer: pushToLayer,
    toggleLayer: toggleLayer,
  
    enableLayer : enableLayer,
    disableLayer: disableLayer,
    refreshLayer: refreshLayer,
  
    createLayer   : createLayer,
    hasLayer      : hasLayer,
    getLayer      : getLayer,
    getLayers     : getLayers,
    isLayerVisible: isLayerVisible,
  
    getAllVisibleObjects: getAllVisibleObjects,
    getAllVisibleMarkers: getAllVisibleMarkers,
    getLayerObjects     : getLayerObjects,
    getClusterer        : getClusterer,
  
    hasCustomSent: hasCustomSent,
    showObject   : showObject,
    getObject    : getObject,
  
    setLayerMarkerVisibility: setLayerMarkerVisibility,
    setLayerObjectVisibility: setLayerObjectVisibility,
  
    onLayerEnabled : onLayerEnabled,
    onLayerDisabled: onLayerDisabled,
  
    addDefaultListeners: addDefaultListeners,
    mapGeometry        : mapInnerObjects
  };
})();

var AMapLayersBtns = (function () {
  //cache DOM
  var self = this;
  
  var $controlBlock = null;
  var cachedDOM     = false;
  
  var id_position_array = [];
  var typeBtnRefs       = {};
  
  function cacheDOM() {
    $controlBlock = $('#showLayersControlBlock').next('.dropdown-menu');
    if (!$controlBlock.length) console.warn('[ MapLayersButtons ]', 'Caching DOM too early');
    
    $.each(id_position_array, function (i, layer_id) {
      typeBtnRefs[layer_id] = $controlBlock.find('#showLayersControlBlock_' + (layer_id - 1));
    });
    
    cachedDOM = true;
    Events.emit('controlblockcached');
  }
  
  function enableButton(layer_id) {
    MapLayers.onLayerEnabled(layer_id, function () {
      if (typeBtnRefs[layer_id]) typeBtnRefs[layer_id].addClass('list-group-item-success');
      else console.warn('[ MapLayerBtns ]', 'unknown layer id', layer_id);
    });
  }
  
  function disableButton(layer_id) {
    MapLayers.onLayerDisabled(layer_id, function () {
      if (typeBtnRefs[layer_id]) typeBtnRefs[layer_id].removeClass('list-group-item-success');
      else console.warn('[ MapLayerBtns ]', 'unknown layer id', layer_id);
    });
  }
  
  function isButtonEnabled(layer_id) {
    return typeBtnRefs[layer_id].hasClass('list-group-item-success');
  }
  
  function toggleButton(layer_id) {
    if (!typeBtnRefs[layer_id]) return;
    if (!isButtonEnabled(layer_id)) {
      enableButton(layer_id);
    }
    else {
      disableButton(layer_id);
    }
  }
  
  function initButtons(id_position_array_) {
    
    id_position_array = id_position_array_;
    
    Events.once('controlblockcached', function () {
      
      $.each(id_position_array, function (i, layer_id) {
        // Register listeners for first enable
        MapLayers.onLayerEnabled(layer_id, enableButton);
        MapLayers.onLayerDisabled(layer_id, disableButton);
        
        // Register listeners for user enable/disable
        Events.on(layer_id + '_ENABLED', enableButton);
        Events.on(layer_id + '_DISABLED', disableButton);
      });
    });
    
  }
  
  Events.on('controlblockshowed', cacheDOM);
  
  //interface
  return {
    enableButton : enableButton,
    disableButton: disableButton,
    toggleButton : toggleButton,
    initButtons  : initButtons
  }
})();

var ClustererControl = function (layer_id, id) {
  
  var self = this;
  
  var DISABLE_MARKERS    = 0;
  var SHOW_IN_CLUSTERS   = 1;
  var SHOW_NON_CLUSTERED = 2;
  
  this.state    = (CLUSTERING_ENABLED && MapLayers.isLayerVisible(layer_id)) ? SHOW_IN_CLUSTERS : SHOW_NON_CLUSTERED;
  this.layer_id = layer_id;
  this.btnId    = id;
  
  this.layerObjects = MapLayers.getLayerObjects(self.layer_id);
  this.layerMarkers = [];
  for (var i = 0; i < self.layerObjects.length; i++) {
    if (!self.layerObjects[i].marker) continue;
    self.layerMarkers.push(self.layerObjects[i].marker);
  }
  
  this.layerClusterer = MapLayers.getClusterer(self.layer_id);
  this.$btn           = $('#' + self.btnId).find('button');
  
  this.toggle = function () {
    self.state++;
    if (self.state > SHOW_NON_CLUSTERED) {
      self.state = DISABLE_MARKERS;
    }
    switch (self.state) {
      case DISABLE_MARKERS:
        self.removeMarkersFromCluster();
        self.removeMarkersFromMap();
        self.$btn.attr('class', 'btn btn-danger');
        break;
      case SHOW_IN_CLUSTERS:
        self.addMarkersToCluster();
        self.$btn.attr('class', 'btn btn-success');
        break;
      case SHOW_NON_CLUSTERED:
        self.enableNonClusteredMarkers();
        self.$btn.attr('class', 'btn btn-warning');
        break;
    }
  };
  
  
  this.addMarkersToCluster = function () {
    self.layerClusterer.addMarkers(self.layerMarkers);
  };
  
  this.addMarkersToMap = function () {
    $.each(self.layerMarkers, function (i, marker) {
      aMap.addObjectToMap(marker);
    });
  };
  
  this.removeMarkersFromCluster = function () {
    self.layerClusterer.clearMarkers();
    
  };
  
  this.removeMarkersFromMap = function () {
    $.each(self.layerMarkers, function (i, marker) {
      aMap.removeObjectFromMap(marker);
      marker.setMap(null);
    });
  };
  
  this.enableNonClusteredMarkers = function () {
    self.removeMarkersFromMap();
    self.removeMarkersFromCluster();
    self.addMarkersToMap();
  };
  
  Events.on('BUILD_LAYER_DISABLED', function () {
    // State will be incremented
    self.state = DISABLE_MARKERS - 1;
    self.toggle();
  })
  
};


function MapControls() {
  this._controlDivs = [];
  
  this.addBtn = function (icon, onclickString, title, id, class_) {
    var index = this._controlDivs.length;
    
    var $controlBtnDiv = createControlBtn(icon, onclickString, class_);
    
    if (!id || typeof (id) === 'undefined') {
      id = 'ctrlBtn_' + index;
    }
    
    $controlBtnDiv.attr('id', id);
    $controlBtnDiv.attr('title', title);
    
    this._controlDivs[index] = $controlBtnDiv;
    return this;
  };
  
  this.addDropdown = function (icon, arrOptions, title, id, class_) {
    var index = this._controlDivs.length;
    
    if (typeof (id) === 'undefined' || !id) {
      id = 'ctrlBtn_' + index;
    }
    
    this._controlDivs[index] = createBtnDropdown(
        '<span class="glyphicon glyphicon-' + icon + '"></span>',
        arrOptions,
        class_,
        id
    );
    
    return this;
  };
  
  this.hideBtn = function (id) {
    $('#' + id).hide();
  };
  
  this.init = function () {
    if (this._controlDivs.length > 0)
      $('#mapControls').append(this._controlDivs);
    Events.emit('controlsready', true);
  };
  
  function createBtnDropdown(caption, arrOptions, class_, id) {
    var btnClass = class_ || 'primary';
    
    function createSubMenu(array) {
      var options = [];
      $.each(array, function (i, entry) {
        if (typeof entry === 'undefined') {
          return '';
        }
        else if (entry['submenu']) {
          options[i] = '<li class="dropdown-submenu">'
              + '<a href="#">' + entry['name'] + '</a>'
              + '<ul class="dropdown-menu">'
              + createSubMenu(entry['submenu'])
              + '</ul></li>'
        }
        else {
          entry['extra'] = entry['extra'] || '';
          options[i]     = '<li><a role="button"'
              + ' onclick="' + entry['onclick']
              + '" id="' + id + '_' + i + '">'
              + entry['extra']
              + entry['name']
              + '</a></li>';
        }
      });
      
      return options;
    }
    
    var dropdown_options = createSubMenu(arrOptions);
    
    return '<div class="btn-group" role="group"><div class="dropdown">'
        + '<button id="' + id + '" role="button" data-toggle="dropdown" class="btn btn-' + btnClass + ' dropdown-toggle" data-target="#">'
        + caption + '&nbsp;<span class="caret"></span>'
        + '</button>'
        + '<ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu">'
        + dropdown_options.join('')
        + '</ul>'
        + '</div></div>';
  }
  
  function createControlBtn(icon, onclickString, newBtnClass) {
    return $('<button></button>')
        .attr('type', 'button')
        .attr('class', 'btn btn-' + (newBtnClass || 'primary'))
        .attr('onclick', onclickString)
        .html('<span class="glyphicon glyphicon-' + icon + '"></span>');
  }
}


Events.on('layersready', function () {
  
  var data_array = window['ObjectsArray'];
  
  // Call parse function
  var layers = BillingObjectParser.render(data_array);
  
  var enableDefinedLayers = function () {
    $.each(Object.keys(layers), function (i, layer_id) {
      if (!MapLayers.hasLayer(layer_id)) {
        MapLayers.createLayer({
          id       : layer_id,
          name     : '',
          lang_name: ''
        })
      }
      MapLayers.enableLayer(layer_id);
    });
  };
  
  if (FORM['SHOW_CONTROLS']) {
    Events.once('controlblockcached', enableDefinedLayers);
  }
  else {
    enableDefinedLayers();
  }
  
  
  Events.emit('billingdefinedlayersshowed');
  
  window['ObjectsArray'] = [];
  
  
});