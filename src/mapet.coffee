# Base work mode object ------------------------------------------------------

class Mode
    markerOptions: {}

    initialize: (options) ->
        for opt of options
            @[opt] = options[opt]

    drawFromInitialData: (data) ->
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


class WrappersBaseMode extends Mode
    wrappers: []
    selected: null;
    editable: true;

    # data operations -----------------

    drawFromInitialData: (data) ->
        for polygonData in data
            wrapper = @.getNewWrapper({'selected': false})
            wrapper.drawFromInitialData(data)
            @.wrappers.push(wrapper)

    getValue: ->
        data = []
        for wrapper in @.wrappers
            data.push(wrapper.getValue())
        return data

    # events handling -----------------

    on_click: (ev) ->
        if @.selected
            # if any wrapper is selected, then pass a marker to it
            @.selected.crateMarker(ev.latLng)
            @.selected.redraw()
        else
            # otherwise create new wrapper
            wrapper = @.getNewWrapper()
            wrapper.crateMarker(ev.latLng)
            @.wrappers.push(wrapper)
            @.select(wrapper)

    on_rightclick: (ev) ->
        # deselect any selected polygons
        @.deselect()

    # rendering -----------------------

    start: ->
        # run when MapHandler enters this mode
        null;

    clear: ->
        for wrapper in @.wrappers
            wrapper.clear()
        @.wrappers = []
        @.selected = null;

    # wrappers manipulation -----------

    select: (wrapper) ->
        @.deselect()

        @.selected = wrapper
        @.selected.selected = true;
        @.selected.redraw()

    deselect: () ->
        if @.selected
            if @.selected.isValid()
                @.selected.selected = false;
                @.selected.redraw()
            else
                @.removeWrapper(@.selected)

        @.selected = null;

    setEditable: (editable) ->
        @.editable = editable
        if @.editable
            for wrapper in @.wrappers
                wrapper.setEditable(true)
        else
            @.deselect()
            for wrapper in @.wrappers
                wrapper.setEditable(false)

    getNewWrapper: (options) ->
        alert('getNewWrapper is not implemented')

    removeWrapper: (wrapper) ->
        wrapper.clear()
        if wrapper.selected
            @.selected = null;
        @.wrappers.splice(@.wrappers.indexOf(wrapper), 1)

# Task specific work modes ---------------------------------------------------

class MarkersMode extends Mode
    markers: []

    removableMarkers: true;

    on_click: (point) ->
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


class PolygonMode extends WrappersBaseMode

    getNewWrapper: (options={}) ->
        return new PolygonWrapper(@, options)


class PolylineMode extends WrappersBaseMode

    getNewWrapper: (options={}) ->
        return new PolylineWrapper(@, options)


class RouteMode extends WrappersBaseMode

    constructor: ->
        @.useGoogleDirections = false;
        @.tmpUseGoogleDirections = false;
        @.directionsService = new google.maps.DirectionsService()

    getNewWrapper: (options={}) ->
        return new RouteWrapper(@, options)

    # events handling -----------------

    on_click: (ev) ->
        # check pressed keys to see if reversed useGoogleDirections should
        # be used
        if 1#ev.altKey
            @.tmpUseGoogleDirections = ! @.useGoogleDirections

        super(ev)

        # set tmpUseGoogleDirections back to its value
        @.tmpUseGoogleDirections = @.useGoogleDirections


# Main map handler -----------------------------------------------------------

class MapHandler

    # work modes
    availableModes: {
        'BaseMode': Mode,
        'MarkersMode': MarkersMode,
        'PolygonMode': PolygonMode,
        'PolylineMode': PolylineMode,
        'RouteMode': RouteMode,
    }

    constructor: ->
        # map stuff
        @map = null;
        @mapContainerSelector = '#map-container'
        @.initialMapOptions = {
            center: new google.maps.LatLng(52.21885952070011, 20.983983278274536),
            zoom: 18,
            mapTypeId: google.maps.MapTypeId.ROADMAP
        }

        # modes stuff
        @.mode = 'none'
        @.modes = {}
        @.handler = null;

        # behaviour controllers
        @.editable = true;
        @.delayedEventsTimeout = 1000

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

    bindMapEvents: ->
        events = [
            'bounds_changed', 'center_changed', 'heading_changed', 'idle',
            'maptypeid_changed', 'projection_changed', 'tilt_changed',
            'zoom_changed',
            'click', 'dblclick', 'rightclick'
            'dragstart', 'dragend',
            'mouseover', 'mouseout',
            'tilesloaded',
        ]

        delayedEvents = [
            'drag', 'mousemove'
        ]

        # this is the only thing about js that really bothers me
        bindWrapper = (callbackName, eventType) =>
            google.maps.event.addListener(@.map, eventType, (arg) =>
                # don't do anything if handler has no callback for this event
                # don't do anything if handler is marked as not editable
                # console.log(callbackName)
                if @.handler and @.handler.editable and @.handler[callbackName]
                    @.handler[callbackName](arg)
            )

        for eventType in events
            callbackName = 'on_' + eventType
            bindWrapper(callbackName, eventType)

        bindDelayedWrapper = (callbackName, eventType) =>
            delayHelper = {'timeout': null}
            google.maps.event.addListener(@.map, eventType, (arg) =>
                if delayHelper.timeout
                    return null;

                delayHelper.timeout = setTimeout( =>
                    # don't do anything if handler has no callback for this event
                    # don't do anything if handler is marked as not editable
                    if @.handler and @.handler.editable and @.handler[callbackName]
                        @.handler[callbackName](arg)
                    delayHelper.timeout = null;

                , @.delayedEventsTimeout)
            )

        for eventType in delayedEvents
            callbackName = 'on_' + eventType
            bindDelayedWrapper(callbackName, eventType)


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

    setEditable: (editable) ->
        if @.handler
            @.handler.setEditable(editable)


window.MapHandler = MapHandler
