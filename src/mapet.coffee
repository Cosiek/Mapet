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

# Task specific work modes ---------------------------------------------------

class MarkersMode extends Mode
    markers: []

    removableMarkers: true;

    onClick: (point) ->
        # insert a marker at given position
        marker = @.createMarker(point.latLng)

        # bind marker events
        if @.removableMarkers
            google.maps.event.addListener(marker, 'rightclick', =>
                @.removeMarker(marker)
            )

        # add marker to list
        @.markers.push(marker)
        return marker

    removeMarker: (marker) ->
        # remove marker from markers list
        idx = @.markers.indexOf(marker)
        @.markers.splice(idx, 1)

        # remove marker from map
        super(marker)

    clear: ->
        while @.markers.length
            marker = @.markers[@.markers.length - 1]
            @.removeMarker(marker)

    getValue: ->
        positions = []
        for marker in @.markers
            markerPosition = marker.getPosition()
            positions.push([markerPosition.lat(), markerPosition.lng()])
        return positions

    drawFromInitialData: (data) ->
        ###
        Example data is:
        {
            'coords': [[51.51, 23.23, {attr: 'optional'}], [52.00, 23.00]],
            'options': {draggable:false}, v
            'callbacks': {'click': (arg) -> console.log('klik ' + arg)}
        }
        If data has no 'coords' attribute, then assume it is just a list of
        coordinates (like: [[51.51, 23.23, {attr: 'optional'}], [52.00, 23.00]])
        ###
        if not data.coords
            coords = data
        else
            coords = data.coords

        for coord in coords
            marker = @.createMarker(coord, data.options, data.callbacks)
            if coord[2]
                for attr of coord[2]
                    marker[attr] = coord[2][attr]
            @.markers.push(marker)

# Main map handler -----------------------------------------------------------

class MapHandler
    # map stuff
    map: null;
    mapContainerSelector: '#map-container'
    initialMapOptions: {
        center: new google.maps.LatLng(52.21885952070011, 20.983983278274536),
        zoom: 18,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }

    # work modes
    mode: 'none'
    availableModes: {
        'BaseMode': Mode,
        'MarkersMode': MarkersMode,
    }
    modes: {}
    handler: null;  # just for convenience

    editable: true;

    initializeMap: (mapContainerSelector) ->
        mapContainerSelector = mapContainerSelector or @.mapContainerSelector
        # initialize map itself
        if mapContainerSelector.charAt(0) == '.'
            className = mapContainerSelector.slice(1)
            mapContainer = document.getElementsByClassName(className)[0]
        else if mapContainerSelector.charAt(0) == '#'
            id = mapContainerSelector.slice(1)
            mapContainer = document.getElementById(id)

        @.map = new google.maps.Map(mapContainer, @.initialMapOptions)

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
