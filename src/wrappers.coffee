# ============================================================================
# Base wrapper ---------------------------------------------------------------
# ============================================================================

class MapObjectWrapper
    parent: null;
    selected: false;
    editable: true;

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


# ============================================================================
# Base class for multiple markers wrappers -----------------------------------
# ============================================================================

class MultipleMarkersDrawnWrapper extends MapObjectWrapper

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

    objectOptions: {
        strokeColor: '#0000CC',
        strokeWeight: 1,
        editable: false,
        draggable: false,
        geodesic: false,
    }

    objectOptionsWhenSelected: {
        strokeColor: '#FF0000',
        strokeWeight: 2,
    }

    objectEventTypes: [
        'click', 'dblclick', 'rightclick'
        'drag', 'dragend', 'dragstart',
        'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup'
    ]

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
            @.clearObject()
            return null;

        pathPoints = @.drawMarkers(false)

        # create / update object
        if not @.object
            @.createObject(pathPoints)
        else
            @.updateObjectOptions({path: pathPoints})

    clear: ->
        while @.markers.length
            @.clearMarker(@.markers[0])

        @.mainMarkers = []
        @.markers = []

        @.clearObject()

    hide: ->
        @.clearHelperMarkers()
        for marker in @.markers
            marker.setVisible(false)

        @.object.setVisible(false)

    clearHelperMarkers: ->
        clearMarkers = []
        for marker in @.markers
            if not marker.mainMarker
                clearMarkers.push(marker)

        for marker in clearMarkers
            @.clearMarker(marker)

    drawMarkers: (closePath=false) ->
        i = 0
        pathPoints = []
        markers = []
        # other markers
        while i < @.mainMarkers.length
            prevMarker = @.mainMarkers[i - 1]
            thisMarker = @.mainMarkers[i]

            thisPosition = thisMarker.getPosition()

            if @.getDrawHelperMarker() and prevMarker
                prevPosition = prevMarker.getPosition()

                helperPosition = @.getHelperMarkerPosition(prevPosition, thisPosition)
                helperMarker = @.createHelperMarker(helperPosition)
                markers.push(helperMarker)

            pathPoints.push(thisPosition)
            markers.push(thisMarker)

            @.updateMarkerOptions(thisMarker)

            i += 1

        # create helper marker between last and first main marker
        # (only if closePath is true)
        if closePath and @.getDrawHelperMarker() and @.mainMarkers.length > 2
            prevPosition = @.mainMarkers[@.mainMarkers.length - 1].getPosition()
            thisPosition = @.mainMarkers[0].getPosition()

            helperPosition = @.getHelperMarkerPosition(prevPosition, thisPosition)
            helperMarker = @.createHelperMarker(helperPosition)
            markers.push(helperMarker)

        @.markers = markers

        return pathPoints

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

    clearMarker: (marker) ->
        google.maps.event.clearInstanceListeners(marker)
        marker.setMap(null)
        @.markers.splice(@.markers.indexOf(marker), 1)
        if marker.mainMarker
            @.mainMarkers.splice(@.mainMarkers.indexOf(marker), 1)

    clearObject: ->
        if not @.object
            return null;
        @.unbindObject()
        @.object.setMap(null)
        delete @.object
        @.object = null;

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

    updateMarkerOptions: (marker, options) ->
        opts = @.getMarkerOptions(options)
        marker.setOptions(opts)

    getDrawHelperMarker: ->
        return @.selected and @.editable

    getObjectOptions: (options={}) ->
        opts = {
            'map': @.parent.map
        }

        for optName of @.objectOptions
            opts[optName] = @.objectOptions[optName]

        if @.selected
            for optName of @.objectOptionsWhenSelected
                opts[optName] = @.objectOptionsWhenSelected[optName]

        for optName of options
            opts[optName] = options[optName]

        return opts

    updateObjectOptions: (options) ->
        opts = @.getObjectOptions(options)
        @.object.setOptions(opts)

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

    bindMarkers: ->
        for marker in @.markers
            @.bindMarker(marker)

    unbindMarkers: ->
        for marker in @.markers
            google.maps.event.clearInstanceListeners(marker)

    bindObject: ->
        # this is the only thing about js that really bothers me
        bindWrapper = (callbackName) =>
            google.maps.event.addListener(@.object, eventType, (arg) =>
                @[callbackName](@, @.object, arg)
            )

        for eventType in @.objectEventTypes
            # callbacks are defined on wrapper
            wrapperCallbackName = eventType + 'Object'
            @.ensureWrapperCallbackExists(wrapperCallbackName)
            bindWrapper(wrapperCallbackName)

    unbindObject: ->
        google.maps.event.clearInstanceListeners(@.object)

    # editable setting ----------------

    setEditable: (editable) ->
        @.editable = editable
        @.unbindMarkers()  # this is to prevent multiple binding
        @.unbindObject()
        if @.editable
            @.bindMarkers()
            @.bindObject()

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

    clickObject: (this_, object, ev) ->
        if not this_.selected
            this_.parent.select(this_)
        else
            # TODO - pass event to map
            null;

    rightclickObject: (this_, object, ev) ->
        # remove this object (and wrapper)
        this_.clear()
        this_.parent.removeWrapper(this_)

    # helper functions ----------------

    getHelperMarkerPosition: (positionA, positionB) ->
        # it is not possible to tell where the helper marker should be located
        # using only coordinates.
        # Example: A.lng = 170, B.lng = -170
        # There is no way to tell if users intention is to draw a line that
        # crosses meridian 180 or meridian 0.
        # Google maps seem to assume, that user always wants to draw a shorter
        # line.
        # TODO - this does not work for long geodesic lines

        lng = null;
        # check if these are on different halfs of the globe
        if (positionA.lng() * positionB.lng()) < 0
            # figure out if line between these points will be shorter, if
            # crossing meridian 180...
            deltaLng = Math.abs(positionA.lng()) + Math.abs(positionB.lng())
            deltaLng180 = 360 - Math.abs(positionA.lng()) - Math.abs(positionB.lng())
            # calculate lng if it will
            if deltaLng > deltaLng180
                lng = Math.max(positionA.lng(), positionB.lng()) + deltaLng180 / 2
                if lng > 180
                    lng -= 360

        # otherwise everything should be simple
        if not lng
            lng = (positionA.lng() + positionB.lng()) / 2

        lat = (positionA.lat() + positionB.lat()) / 2

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

# ============================================================================
# Task specific wrappers -----------------------------------------------------
# ============================================================================

class PolygonWrapper extends MultipleMarkersDrawnWrapper

    objectOptions: {
        strokeColor: '#0000CC',
        strokeOpacity: 0.2,
        strokeWeight: 1,
        fillColor: '#0000CC',
        fillOpacity: 0.2,
        editable: false,
        draggable: false,
        geodesic: false,
    }

    objectOptionsWhenSelected: {
        strokeColor: '#FF0000',
        strokeOpacity: 0.5,
        strokeWeight: 2,
        fillColor: '#FF0000',
        fillOpacity: 0.35,
    }

    objectEventTypes: [
        'click', 'dblclick', 'rightclick'
        'drag', 'dragend', 'dragstart',
        'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup'
    ]

    # rendering -----------------------

    drawMarkers: (_) ->
        return super(true)

    # map elements manipulation -------

    createObject: (path) ->
        options = @getObjectOptions({'path': path})
        @.object = new google.maps.Polygon(options)
        @bindObject()


# export
window.PolygonWrapper = PolygonWrapper
