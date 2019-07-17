/**
 * Created by Anykey on 23.10.2015.
 * Parses, renders and shows Metro UI tiles with information
 */

var AInfoPanels = (function () {

    var INFO_PANEL_CONTENT_LEFT_CLASSES = "text-1 no-border";
    var INFO_PANEL_CONTENT_RIGHT_CLASSES = "text-2 no-border";

    //Intensity of Background color
    var BACKGROUND_OPACITY = 0.7;


    function getSize(size) {
        var xs, sm, md, lg;

        if (size == 1) {
            xs = 6;
            sm = 4;
            md = 4;
            lg = 3;
        } else if (size == 2) {
            xs = 12;
            sm = 8;
            md = 8;
            lg = 6;
        }
        return '' +
            ' col-xs-' + xs +
            ' col-sm-' + sm +
            ' col-md-' + md +
            ' col-lg-' + lg;
    }

    function getMaxRowSize() {
        var width = window.innerWidth;
        if (width < 768) { //xs
            return 2;
        } else if (width <= 992) { //sm
            return 2;
        } else if (width <= 1200) { //md
            return 3;
        } else { //lg
            return 4;
        }
    }

    //Colors
    var colors = new AColorPalette();

    //RAW JSON
    var InfoPanelsArray = [];
    //JSON WITH PARAMS WE CARE + DEFAULT PARAMS
    var parsedTiles = [];
    //OBJECTS THAT PRESENT TILE CONTENT AND META INFORMATION WE NEED FOR CALCULATING SIZE AND POSITION
    var renderedTiles = [];
    //HTML ROWS
    var rows = [];

    var clearPanel = {
        "NAME": null,
        "HEADER": null,
        "COLOR": null,
        "SIZE": null,
        "CONTENT": {},
        "FOOTER": null
    };

    //bindEvents
    Events.on('infoPanels_renewed', renew);


    function parse() {
        $.each(InfoPanelsArray, function (index, panel) {
            console.log(panel);
            var newPanel = Object.create(clearPanel);
            //meta information
            newPanel.id = 'InfoPanel_' + panel.NAME;
            newPanel.size = Number(panel.SIZE) || 1;  //small by default
            newPanel.color = panel.COLOR || colors.getNextColorRGBA(BACKGROUND_OPACITY);
            //content
            newPanel.HEADER = panel.HEADER || '';
            if (panel.CONTENT)
                newPanel.BODY = parseContent(panel.CONTENT, panel.PROPORTION);
            else if (panel.SLIDES)
                newPanel.BODY = parseSlides(panel.SLIDES, panel.PROPORTION, newPanel.id + '_SLIDER');
            newPanel.FOOTER = panel.FOOTER || '';
            //save result
            parsedTiles.push(newPanel);
        });

        function parseContent(contentObject, proportion) {
            var prop = 2;
            if (isFinite(proportion)) prop = proportion;
            var leftSize = (6 / Math.abs(prop)) * 2;
            var rightSize = (12 - leftSize);
            if (prop < 0) { //swap sizes
                rightSize = swap(leftSize, leftSize = rightSize);
                // http://stackoverflow.com/questions/16151682/swap-two-objects-in-javascript
                function swap(x) {
                    return x
                }
            }
            var contentRows = '';
            for (var key in contentObject) {
                contentRows += '<div class="row">';
                contentRows += '<div class="' + INFO_PANEL_CONTENT_LEFT_CLASSES + ' col-md-' + leftSize + '">' + key + '</div>';
                contentRows += '<div class="' + INFO_PANEL_CONTENT_RIGHT_CLASSES + ' col-md-' + rightSize + '">' + contentObject[key] + '</div>';
                contentRows += '</div>';
            }
            return contentRows;
        }

        function parseSlides(slidesArray, proportion, id) {
            var slideWrapper = '';
            //var slideIndicators = getSlideIndicators(id, slidesArray.length);
            if (slidesArray.length > 0) {
                var SLIDE_CONTROLS = '<a class="left carousel-control" href="#' + id + '" role="button" data-slide="prev">' +
                    '<span class="glyphicon glyphicon-chevron-left" aria-hidden="true"></span>' +
                    '<span class="sr-only">Previous</span>' +
                    '</a>' +
                    '<a class="right carousel-control" href="#' + id + '" role="button" data-slide="next">' +
                    '<span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>' +
                    '<span class="sr-only">Next</span>' +
                    '</a>';

                slideWrapper = '<div id="' + id + '" class="carousel slide" data-ride="carousel">';
                //slideWrapper = slideIndicators;
                slideWrapper += '<div class="carousel-inner">';
                $.each(slidesArray, function (i, slide) {

                    var item = '<div class="item">';
                    if (i == 0) item = '<div class="item active">';

                    item += parseContent(slide, proportion);
                    item += '</div>';

                    slideWrapper += item;
                });
                slideWrapper += '</div>';
                slideWrapper += SLIDE_CONTROLS;
                slideWrapper += '</div>';
            }
            return slideWrapper;


        }

        function getSlideIndicators(id, slideArrayLength) {
            var wrapper = '<ol class="carousel-indicators">';
            var count = 0;

            wrapper += '<li data-target="#' + id + '" data-slide-to="' + count + '" class="active"></li>';
            count++;
            while (count < slideArrayLength) {
                wrapper += '<li data-target="#' + id + '" data-slide-to="' + count + '"></li>';
                count++;
            }
            wrapper += '</ol>';

            return wrapper;
        }
    }

    //Creates HTML from parsed panels Array
    function render() {
        //clear
        renderedTiles = [];

        $.each(parsedTiles, function (index, rawTile) {
            var tile = renderTile(rawTile, index);

            renderedTiles.push(tile);

            function renderTile(panel, index) {
                var panelElement = '<div class="' + getSize(panel.size) + ' tileSize' + panel.size + '">';

                panelElement += '<div id="tile' + index + '" class="tile">';
                if (panel.HEADER)
                    panelElement += '<div class="row text-center InfoPanelHeader">' + panel.HEADER + '</div>';
                //append content
                panelElement += '<div class="row InfoPanelContent">' + panel.BODY + '</div>';
                if (panel.FOOTER)
                    panelElement += '<div class="row InfoPanelFooterWrapper"><div class="text-center InfoPanelFooter">' + panel.FOOTER + '</div></div>';
                //end of content
                panelElement += '</div>';
                panelElement += '</div>';

                //apply styles
                var $panel = $(panelElement);
                $panel.css({
                    "background-color": panel.color
                });

                return {
                    "CONTENT": $panel,
                    "META": {
                        "NUMBER": index,
                        "SIZE": panel.size
                    }
                };
            }
        });

        makeRows();

        show();

        function makeRows() {
            //clear
            rows = [];
            //prepare
            var copyOfRenderedTiles = {};
            var largerTiles = [];

            //saving from array to object with numeric values
            for (var i = 0; i < renderedTiles.length; i++) {
                copyOfRenderedTiles[i] = renderedTiles[i];
            }

            var maxSize = getMaxRowSize();

            var $row = createNewRow();

            var rowSize = 0;
            for (var j = 0; j < renderedTiles.length; j++) {
                //check largerTilesArray
                if (largerTiles.length > 0) {
                    tryPush(largerTiles.pop(), $row);
                }
                var tile = copyOfRenderedTiles[j];
                tryPush(tile, $row);
                //check size
                if (rowSize >= maxSize) {//if size is over create new row
                    $row = createNewRow($row);
                }
            }

            if (largerTiles.length > 0) {
                $.each(largerTiles, function (i, tile) {
                    $row.append(tile.CONTENT);
                });
            }
            rows.push($row);

            function tryPush(tile, $row) {
                //console.log("Tile size: " + tile.META.SIZE);
                //console.log("MaxSize: " + maxSize);
                //console.log("RowSize: " + rowSize);

                if (tile.META.SIZE <= maxSize - rowSize) {
                    $row.append(tile.CONTENT);
                    rowSize += tile.META.SIZE;
                } else {
                    largerTiles.push(tile);
                }
            }

            function createNewRow(row) {
                if (row) {
                    rows.push(row);
                }
                rowSize = 0;
                var $row = $('<div></div>');
                $row.addClass('row');
                return $row;
            }
        }

    }

    function show() {
        var $panelsDiv = $('#infoPanelsDiv');
        $panelsDiv.empty();
        //push rows to $panelsDiv
        //console.log(rows);
        $.each(rows, function (index, row) {
            //var newRow = '<div class="row">' + row.html() + '</div>';
            //console.log(newRow);
            $panelsDiv.append(row);
        });
        makeSquareTiles();
    }

    function renew() {
        parse();
        render();
    }

//MAKE TILES SQUARE FORM
    function makeSquareTiles() {
        //cacheDOM
        var $tile1 = $('.tileSize1');
        var $tile = $(".tile");
        var tile1Width = $tile1.width();
        $tile.parent().height(tile1Width);
    }

    return {
        renew: renew,
        render: render,
        makeSquareTiles: makeSquareTiles,
        InfoPanelsArray: InfoPanelsArray
    }
})();

$(document).ready(function () {
    AInfoPanels.makeSquareTiles();
    $(window).resize(function () {
        if (this.resizeTO) clearTimeout(this.resizeTO);
        this.resizeTO = setTimeout(function () {
            $(this).trigger('resizeEnd');
        }, 10);
    });
    $(window).bind('resizeEnd', AInfoPanels.render);
});