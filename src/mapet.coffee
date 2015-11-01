# Main map handler -----------------------------------------------------------

class MapHandler
    # map stuff
    map: null;
    initialMapOptions: {
        center: new google.maps.LatLng(52.21885952070011, 20.983983278274536),
        zoom: 18,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }

    initializeMap: () ->
        # initialize map itself
        # TODO selector as a parameter
        @.map = new google.maps.Map($('.js-map-container')[0], @.initialMapOptions)


window.MapHandler = MapHandler
