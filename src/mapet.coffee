# Base work mode object ------------------------------------------------------

class Mode
    markerOptions: {}

    initialize: (options) ->
        for opt of options
            @[opt] = options[opt]

    drawFromInitialData: (data) ->
        null;

    onClick: (point) ->
        null;

    onRightClick: (point) ->
        null;

    onMapBoundsChanged: ->
        null;

    start: ->
        # run when MapHandler enters this mode
        null;

    clear: ->
        null;

    getValue: ->
        null;


# Main map handler -----------------------------------------------------------

class MapHandler
    # map stuff
    map: null;
    initialMapOptions: {
        center: new google.maps.LatLng(52.21885952070011, 20.983983278274536),
        zoom: 18,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }

    # work modes
    mode: 'none'
    availableModes: {
        'BaseMode': Mode,
    }
    modes: {}
    handler: null;  # just for convenience

    initializeMap: () ->
        # initialize map itself
        # TODO selector as a parameter
        @.map = new google.maps.Map($('.js-map-container')[0], @.initialMapOptions)


    initializeMode: (modeName, modeCodename, modeOptions={}) ->
        # don't allow to override existing modes
        if @.modes[modeName]
            return null;

        if not modeCodename
            modeCodename = modeName

        # throw an error if codename is unavailable
        if not @.availableModes[modeCodename]
            throw Error('Unknown work mode: ' + String(modeCodename))

        @.modes[modeName] = new @.availableModes[modeCodename]()

        # apply options
        for optName of modeOptions
            @.modes[modeName][optName] = modeOptions[optName]

        @.modes[modeName].mapHandler = @
        @.modes[modeName].map = @map
        @.modes[modeName].initialize()

    changeMode: (modeName, modeCodename) ->
        # this should switch off the handler (note that it doesn't clear the map)
        if modeName == 'none'
            @.mode = modeName
            @.handler = null;

        # check if this mode already exists
        if not @.modes[modeName]
            @.initializeMode(modeName, modeCodename)

        @.mode = modeName
        @.handler = @.modes[modeName]
        @.handler.start()

window.MapHandler = MapHandler
