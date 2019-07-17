/**
 * Created by Anykey on 08.12.2016.
 *
 */

'use strict';
var CABLE_LAYER_ID = 10;
var WELL_LAYER_ID  = 11;

/**
 * Emulate drawing well on last opened infowindow position
 *
 * @param cable_id
 */
function insert_well_on_cable(cable_id) {
  var layer_obj = MapLayers.getLayer(WELL_LAYER_ID);
  
  // Get position from last_opened infowindow
  var last_infowindow = openedInfoWindows[openedInfoWindows.length - 1];
  var click_position  = last_infowindow.position;
  
  //Initialize controllers
  aDrawController = new DrawController();
  aDrawController
      .setLayerId(WELL_LAYER_ID)
      .setCallback(overlayCompleteCallback)
      .init(map)
      .setDrawingMode('MARKER');
  
  var mapObject = MapObjectTypesRefs.getMapObject(WELL_LAYER_ID);
  if (isDefined(mapObject.init)) {
    mapObject.init(MapLayers.getLayer(WELL_LAYER_ID));
  }
  
  mapObject.setCustomParams({
    add_func       : layer_obj['add_func'],
    module         : layer_obj['module'],
    INSERT_ON_CABLE: cable_id
  });
  mapObject.addCustomParams(layer_obj.custom_params);
  
  // Set COORDX and COORDY
  mapObject.emit({
    position: click_position
  });
  
  
  closeInfoWindows();
  aDrawController.clearDrawingMode();
  
  mapObject.send();
}

function split_cable(cable_id){
  // Get position from last_opened infowindow
  var last_infowindow = openedInfoWindows[openedInfoWindows.length - 1];
  var click_position  = GeoJsonExporter.encodePoint(last_infowindow);
  delete click_position.raw;
  
  var params = {
    get_index  : 'cablecat_maps_ajax',
    json       : 1,
    header     : 2,
    CABLE_ID   : cable_id,
    SPLIT_CABLE: 1,
    // REVERSE COORDS
    COORDX     : click_position['COORDX'],
    COORDY     : click_position['COORDY']
  };
  
  $.post('?', params, function (data) {
    
    console.log(data);
    
    MapLayers.refreshLayer(CABLE_LAYER_ID);
  })
}