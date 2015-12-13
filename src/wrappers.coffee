# Base wrapper ---------------------------------------------------------------

class MapObjectWrapper
    parent: null;
    selected: false;

    constructor: (parent, options) ->
        @.parent = parent
        @.selected = true;

        for opt of options
            @[opt] = options[opt]

    redraw: ->
        null;

    clear: ->
        null;

    getValue: ->
        null;

    drawFromInitialData: (data) ->
        null;

    isValid: ->
        return true;


# Task specific wrappers -----------------------------------------------------

class PolygonWrapper extends MapObjectWrapper

    markerOptions: {
        'icon': 'http://maps.google.com/mapfiles/ms/icons/blue-dot.png',
        'draggable': false;
        'clickable': false;
    }

    markerOptionsWhenSelected: {
        'icon': 'http://maps.google.com/mapfiles/ms/icons/red-dot.png'
        'draggable': true,
        'clickable': true;
    }

    helperMarkerOptions: {
        'icon': 'http://maps.google.com/mapfiles/ms/icons/pink-dot.png',
        'draggable': true,
    }

    polygonOptions: {
        strokeColor: '#0000CC',
        strokeOpacity: 0.2,
        strokeWeight: 1,
        fillColor: '#0000CC',
        fillOpacity: 0.2,
        editable: false,
        draggable: false,
        geodesic: true,
    }

    polygonOptionsWhenSelected: {
        strokeColor: '#FF0000',
        strokeOpacity: 0.5,
        strokeWeight: 2,
        fillColor: '#FF0000',
        fillOpacity: 0.35,
    }

    # init ----------------------------

    constructor: (parent, options={}) ->
        @.mainMarkers = []
        @.markers = []
        @.polygon = null;

        super(parent, options)

    # data operations -----------------

    drawFromInitialData: (data) ->
        for point in data
            position = new google.maps.LatLng(point[0], point[1])
            @.createMarker(position)

        @.redraw()

    getValue: ->
        pointValues = []
        for marker in @.mainMarkers
            point = marker.getPosition()
            pointValues.push([point.lat(), point.lng()])

        return pointValues

    isValid: ->
        if @.mainMarkers.length > 2
            return true;

        return false;

    # rendering -----------------------

    redraw: ->
        @.clearHelperMarkers()

        if @.mainMarkers.length < 2
            console.log('if @.mainMarkers.length <= 1')
            @.clearPolygon()
            return null;

        i = 0
        pathPoints = []
        markers = []
        # other markers
        while i < @.mainMarkers.length
            prevMarker = @.mainMarkers[i - 1]
            thisMarker = @.mainMarkers[i]

            markers.push(thisMarker)

            thisPosition = thisMarker.getPosition()

            if @.selected and prevMarker
                prevPosition = prevMarker.getPosition()

                helperPosition = @.getHelperMarkerPosition(prevPosition, thisPosition)
                helperMarker = @.createHelperMarker(helperPosition)
                markers.push(helperMarker)

            pathPoints.push(thisPosition)

            @.updateMarkerOptions(thisMarker)

            i += 1

        markers.push(thisMarker)

        # create helper marker between last and first main marker
        if @.selected and @.mainMarkers.length > 2
            prevPosition = @.mainMarkers[@.mainMarkers.length - 1].getPosition()
            thisPosition = @.mainMarkers[0].getPosition()

            helperPosition = @.getHelperMarkerPosition(prevPosition, thisPosition)
            helperMarker = @.createHelperMarker(helperPosition)
            markers.push(helperMarker)

        @.markers = markers

        # create / update polygon
        if not @.polygon
            @.createPolygon(pathPoints)
        else
            @.updatePolygonOptions({path: pathPoints})

    clear: ->
        while @.markers.length
            @.clearMarker(@.markers[0])

        @.mainMarkers = []
        @.markers = []

        @.clearPolygon()

    hide: ->
        @.clearHelperMarkers()
        for marker in @.markers
            marker.setVisible(false)

        @.polygon.setVisible(false)

    clearHelperMarkers: ->
        clearMarkers = []
        for marker in @.markers
            if marker.mainMarker
                #markers.push(marker)
                null;
            else
                clearMarkers.push(marker)

        for marker in clearMarkers
            @.clearMarker(marker)

    # map elements manipulation -------

    crateMarker: (position) ->
        options = @getMarkerOptions({'position': position})
        marker = new google.maps.Marker(options)
        marker.mainMarker = true;
        @.bindMarker(marker)
        @.markers.push(marker)
        @.mainMarkers.push(marker)

    createHelperMarker: (position) ->
        options = @.getHelperMarkerOptions({'position': position})
        marker = new google.maps.Marker(options)
        marker.mainMarker = false;
        @.bindMarker(marker)
        @.markers.push(marker)
        return marker

    createPolygon: (path) ->
        options = @getPolygonOptions({'path': path})
        @.polygon = new google.maps.Polygon(options)
        @bindPolygon()

    clearMarker: (marker) ->
        google.maps.event.clearInstanceListeners(marker)
        marker.setMap(null)
        @.markers.splice(@.markers.indexOf(marker), 1)
        if marker.mainMarker
            @.mainMarkers.splice(@.mainMarkers.indexOf(marker), 1)

    clearPolygon: ->
        if not @.polygon
            return null;
        google.maps.event.clearInstanceListeners(@.polygon)
        @.polygon.setMap(null)
        delete @.polygon
        @.polygon = null;

    # map elements display ------------

    getMarkerOptions: (options={}) ->
        opts = {
            'map': @.parent.map
        }

        for optName of @.markerOptions
            opts[optName] = @.markerOptions[optName]

        if @.selected
            for optName of @.markerOptionsWhenSelected
                opts[optName] = @.markerOptionsWhenSelected[optName]

        for optName of options
            opts[optName] = options[optName]

        return opts

    getHelperMarkerOptions: (options={}) ->
        opts = {
            'map': @.parent.map
        }

        for optName of @.helperMarkerOptions
            opts[optName] = @.helperMarkerOptions[optName]

        for optName of options
            opts[optName] = options[optName]

        return opts

    getPolygonOptions: (options={}) ->
        opts = {
            'map': @.parent.map
        }

        for optName of @.polygonOptions
            opts[optName] = @.polygonOptions[optName]

        if @.selected
            for optName of @.polygonOptionsWhenSelected
                opts[optName] = @.polygonOptionsWhenSelected[optName]

        for optName of options
            opts[optName] = options[optName]

        return opts

    updateMarkerOptions: (marker, options) ->
        opts = @.getMarkerOptions(options)
        marker.setOptions(opts)

    updatePolygonOptions: (options) ->
        opts = @.getPolygonOptions(options)
        @.polygon.setOptions(opts)

    # bindings ------------------------

    bindMarker: (marker) ->
        eventTypes = [
            'click', 'dblclick', 'rightclick',
            'drag', 'dragstart', 'dragend',
            'mousedown', 'mouseup', 'mouseover', 'mouseout',
            'position_changed', 'visible_changed',
        ]

        # this is the only thing about js that really bothers me
        bindWrapper = (callbackName) =>
            google.maps.event.addListener(marker, eventType, (arg) =>
                @[callbackName](@, marker, arg)
            )

        for eventType in eventTypes
            # callbacks are defined on wrapper
            wrapperCallbackName = eventType + 'Marker'
            @.ensureWrapperCallbackExists(wrapperCallbackName)
            bindWrapper(wrapperCallbackName)

    bindPolygon: ->
        eventTypes = [
            'click', 'dblclick', 'rightclick'
            'drag', 'dragend', 'dragstart',
            'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup'
        ]

        # this is the only thing about js that really bothers me
        bindWrapper = (callbackName) =>
            google.maps.event.addListener(@.polygon, eventType, (arg) =>
                @[callbackName](@, @.polygon, arg)
            )

        for eventType in eventTypes
            # callbacks are defined on wrapper
            wrapperCallbackName = eventType + 'Polygon'
            @.ensureWrapperCallbackExists(wrapperCallbackName)
            bindWrapper(wrapperCallbackName)

    # callbacks -----------------------

    rightclickMarker: (this_, marker, ev) ->
        # delete marker (only if main)
        if marker.mainMarker
            this_.clearMarker(marker)
            this_.redraw()

    dragendMarker: (this_, marker, ev) ->
        # mark this marker as main
        if not marker.mainMarker
            marker.mainMarker = true;
            @.refillMainMarkers()
        this_.redraw()

    clickPolygon: (this_, polygon, ev) ->
        if not this_.selected
            this_.parent.select(this_)
        else
            # TODO - pass event to map
            null;

    rightclickPolygon: (this_, polygon, ev) ->
        # remove this polygon (and wrapper)
        this_.clear()
        this_.parent.removeWrapper(this_)

    # helper functions ----------------

    getHelperMarkerPosition: (positionA, positionB) ->
        # TODO - this might not work near London and Kamchatka
        lat = (positionA.lat() + positionB.lat()) / 2
        lng = (positionA.lng() + positionB.lng()) / 2

        return new google.maps.LatLng(lat, lng)

    refillMainMarkers: ->
        @.mainMarkers = []
        for marker in @.markers
            if marker.mainMarker
                @.mainMarkers.push(marker)

    ensureWrapperCallbackExists: (wrapperCallbackName) ->
        # if no callback exists - create one to prevent 'no attr' errors
        if not @[wrapperCallbackName]
            @[wrapperCallbackName] = (this_, object, arg) ->
                # console.log(wrapperCallbackName)
                # TODO - add events publishing
                # TODO - pass event to map
                null;

# export
window.PolygonWrapper = PolygonWrapper
