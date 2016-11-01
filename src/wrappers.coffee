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


class PolylineWrapper extends MultipleMarkersDrawnWrapper

    objectOptions: {
        strokeColor: '#0000CC',
        strokeWeight: 5,
        editable: false,
        draggable: false,
        geodesic: false,
    }

    objectOptionsWhenSelected: {
        strokeColor: '#FF0000',
        strokeWeight: 5,
    }

    # map elements manipulation -------

    createObject: (path) ->
        options = @getObjectOptions({'path': path})
        @.object = new google.maps.Polyline(options)
        @bindObject()


class RouteWrapper extends PolylineWrapper

    travelMode: google.maps.TravelMode.DRIVING

    # init ----------------------------

    constructor: (parent, options={}) ->
        # this is just for easy usage
        @.directionsService = parent.directionsService

        # and this has some deeper meaning
        @.directionsCache = {}

        super(parent, options)

        @.messages = {}
        @.setMessages()

    setMessages: ->
        @.messages[google.maps.DirectionsStatus.ZERO_RESULTS] = "Nie znaleziono trasy - rysuję linię prostą"

    # data operations -----------------

    drawFromInitialData: (data) ->
        for point in data
            position = new google.maps.LatLng(point[0], point[1])
            @.createMarker(position)

        @.redraw()

    isValid: ->
        # TODO - check if all google directions are already loaded
        if @.mainMarkers.length > 2
            return true;

        return false;

    # rendering -----------------------

    drawMarkers: ->
        pathPoints = []
        markers = []
        # add first marker
        if @.mainMarkers.length > 1
            markers.push(@.mainMarkers[0])
            #pathPoints.push(@.mainMarkers[0].getPosition())
        else
            return []

        # iterate main markers
        i = 1
        while i < @.mainMarkers.length
            prevMarker = @.mainMarkers[i - 1]
            thisMarker = @.mainMarkers[i]
            nextMarker = @.mainMarkers[i + 1]

            # if marker is google directions
            if thisMarker.useGoogleDirections
                pathPart = @.getGooglePath(prevMarker, thisMarker, nextMarker)
                if pathPart
                    for point in pathPart
                        pathPoints.push(point)
                else
                    # this means that we need to wait for directions to be
                    # loaded from google.
                    return [];
            # add handle marker
            #handleMarker = @.addHandleMarker(pathPart)
            #if handleMarker
            #    markers.push(handleMarker)

            #pathPoints.push(thisMarker.getPosition())
            markers.push(thisMarker)
            i += 1

        @.markers = markers
        return pathPoints


    # map elements manipulation -------

    crateMarker: (position) ->
        super(position)

        marker = @.mainMarkers[@mainMarkers.length-1]
        marker.useGoogleDirections = @.parent.tmpUseGoogleDirections

    # directions helpers --------------

    getGooglePath: (mark1, mark2, mark3) ->
        pos1 = mark1.getPosition()
        pos2 = mark2.getPosition()
        pos3 = if mark3 then mark3.getPosition() else null;

        # check the cache
        [cacheKey, cacheKey2] = @.getDirectionsCacheKey(pos1, pos2, pos3)
        path = @.directionsCache[cacheKey]

        # return path if there is one
        if path
            return path

        # otherwise, get path from google
        # prepare request
        request = {
            origin: pos1,
            destination: pos2,
            travelMode: google.maps.TravelMode[@.travelMode]
            optimizeWaypoints: false,
            provideRouteAlternatives: false,
            region: 'pl',
        }

        # modify request if mark3 is given, and no path is found between
        # mark2 and mark3 - use route with waypoint instead of two
        # requests to google
        if pos3
            request.destination = pos3
            request.waypoints = [{location:pos2, stopover:false},]

        # finally ask google
        _this = @
        @.directionsService.route(request, (response, status) ->
            if status == google.maps.DirectionsStatus.OK
                # write result to local cache
                [path, path2] = _this.googleResponceToPath(response)
                _this.directionsCache[cacheKey] = path

                if path2.length
                    _this.directionsCache[cacheKey2] = path2

                # handle additional response information
                # (google requirement)
                _this.displayResponseExtras(response)

                _this.redraw()
            else
                # if no path was found, (or something else went wrong)
                # set marker 2 to use straight lines instead of google
                # directions...
                mark2.useGoogleDirections = false;
                # ...and tell the user that nothing was found
                _this.displayDirectionsWarning(status)
        )

    displayDirectionsWarning: (status) ->
        msg = @.messages[status]
        return null; # TODO

    displayResponseExtras: (response) ->
        return null; # TODO

    googleResponceToPath: (response) ->
        path = []
        path2 = []

        # just to shorten some code lines
        route = response.routes[0]

        if route.legs[0].via_waypoint.length
            waypointStepIdx = route.legs[0].via_waypoint[0].step_index

            idx = 0
            for step in route.legs[0].steps
                if idx <= waypointStepIdx
                    for point in step.path
                        path.push(point)
                else
                    for point in step.path
                        path2.push(point)
                idx += 1
        else
            for point in route.overview_path
                path.push(point)

        return [path, path2]

    getDirectionsCacheKey: (pos1, pos2, pos3) ->
        cacheKey = "#{pos1}:#{pos1}-#{pos2}:#{pos2}"
        if pos3
            cacheKey2 = "#{pos2}:#{pos2}-#{pos3}:#{pos3}"
            return [cacheKey, cacheKey2]
        else
            return [cacheKey, null]

    # handle markers ------------------

    addHandleMarker: (pathPart) ->
        return
        if not @.getDrawHelperMarker()
            return null;

        if pathPart.length == 2
            position = @.getHelperMarkerPosition(pathPart[0], pathPart[1])
        else
            # get total distance of path part
            totalDistance = 0
            distances = [0]
            i = 1
            # iterate
            while i < pathPart.length
                distance = 1 #@.getDistance(pos1, pos2)
                totalDistance += distance
                distances.push(totalDistance)
                i += 1

            markerDistance = totalDistance / 2
            i = 1
            while i < distances.length
                if distances[i] > markerDistance
                    pos1 = pathPart[i-1]
                    pos2 = pathPart[i]
                    dist = markerDistance - distances[i-1]
                    position = @.getHandleMarkerPositionWithDistance(pos1, pos2, dist)
                    break
                i += 1

        handleMarker = @.createHelperMarker(position)
        return handleMarker

    getHandleMarkerPositionWithDistance: (pos1, pos2, dist) ->
        null;

    getPointOnSection = (section, pt1ToFullKmDistance, ithKilometer) ->
        deltaLon = Number(section.endPoint['lon']) - Number(section.startPoint['lon'])
        deltaLat = Number(section.endPoint['lat']) - Number(section.startPoint['lat'])

        sectionDistance = get2PointsDistance(section.startPoint, section.endPoint)
        pt1ToIthKmDistance = pt1ToFullKmDistance + ithKilometer

        lon = Math.abs(deltaLon) * pt1ToIthKmDistance / sectionDistance
        lat = Math.abs(deltaLat) * pt1ToIthKmDistance / sectionDistance

        if deltaLon < 0
            lon = lon * -1

        if deltaLat < 0
            lat = lat * -1

        return [Number(section.startPoint['lat']) + lat, Number(section.startPoint['lon']) + lon]


# export
window.PolygonWrapper = PolygonWrapper
window.PolylineWrapper = PolylineWrapper
window.RouteWrapper = RouteWrapper
