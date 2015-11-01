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

    createMarker: (latLng, options, callbacks) ->
        # convert latLng to real latLng if it isn't already
        if not (latLng.lat and latLng.lng)
            latLng = new google.maps.LatLng(latLng[0], latLng[1])

        opts = {
            'map': @.map,
            'position': latLng,
        }

        for key of @.markerOptions
            opts[key] = @.markerOptions[key]

        for key of options
            opts[key] = options[key]

        marker = new google.maps.Marker(opts)

        # bind event listeners
        if callbacks
            for ev of callbacks
                google.maps.event.addListener(marker, ev, (args...) =>
                    args.splice(0, 0, @)
                    args.splice(0, 0, marker)
                    callbacks[ev](args)
                )

        return marker

    removeMarker: (marker) ->
        if marker
            marker.setMap(null)
            google.maps.event.clearInstanceListeners(marker)


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

    editable: true;

    initializeMap: () ->
        # initialize map itself
        # TODO selector as a parameter
        @.map = new google.maps.Map($('.js-map-container')[0], @.initialMapOptions)

        @.bindMapEvents()

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

    centerMap: (points) ->
        # fail fast
        if not points
            return

        latLngs = []
        for coords in points
            if coords.lat and coords.lng
                latLng = coords
            else
                latLng = new google.maps.LatLng(coords[0], coords[1])

            latLngs.push(latLng)

        # this is a single point
        if latLngs.length == 1
            @.map.setCenter(latLngs[0])
        # this is some sort of collection of points
        else
            latlngbounds = new google.maps.LatLngBounds()
            for latLng in latLngs
                latlngbounds.extend(latLng)
            @.map.fitBounds(latlngbounds)

    bindMapEvents: () ->
        google.maps.event.addListener(@map, 'click', (point) =>
            if @.handler and @.editable
                @.handler.onClick(point)
        )

        google.maps.event.addListener(@map, 'rightclick', (point) =>
            if @.handler and @.editable
                @.handler.onRightClick(point)
        )

        mapUpdater = {'bounds_changed_timeout': null}
        google.maps.event.addListener(@map, 'bounds_changed', =>
            if @.handler
                clearTimeout(mapUpdater.boundsChangedTimeout)
                if @.eventDelayTime
                    mapUpdater.boundsChangedTimeout = setTimeout(
                        @.handler.onMapBoundsChanged, @.eventDelayTime)
                else
                    @.handler.onMapBoundsChanged()
        )

    clearMap: () ->
        for mode of @modes
            @modes[mode].clear()

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
