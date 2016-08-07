// Generated by CoffeeScript 1.9.3
(function() {
  var MapObjectWrapper, MultipleMarkersDrawnWrapper, PolygonWrapper, PolylineWrapper,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  MapObjectWrapper = (function() {
    MapObjectWrapper.prototype.parent = null;

    MapObjectWrapper.prototype.selected = false;

    MapObjectWrapper.prototype.editable = true;

    function MapObjectWrapper(parent, options) {
      var opt;
      this.parent = parent;
      this.selected = true;
      for (opt in options) {
        this[opt] = options[opt];
      }
    }

    MapObjectWrapper.prototype.redraw = function() {
      return null;
    };

    MapObjectWrapper.prototype.clear = function() {
      return null;
    };

    MapObjectWrapper.prototype.getValue = function() {
      return null;
    };

    MapObjectWrapper.prototype.drawFromInitialData = function(data) {
      return null;
    };

    MapObjectWrapper.prototype.isValid = function() {
      return true;
    };

    return MapObjectWrapper;

  })();

  MultipleMarkersDrawnWrapper = (function(superClass) {
    extend(MultipleMarkersDrawnWrapper, superClass);

    MultipleMarkersDrawnWrapper.prototype.markerOptions = {
      'icon': 'http://maps.google.com/mapfiles/ms/icons/blue-dot.png',
      'draggable': false,
      'clickable': false
    };

    MultipleMarkersDrawnWrapper.prototype.markerOptionsWhenSelected = {
      'icon': 'http://maps.google.com/mapfiles/ms/icons/red-dot.png',
      'draggable': true,
      'clickable': true
    };

    MultipleMarkersDrawnWrapper.prototype.helperMarkerOptions = {
      'icon': 'http://maps.google.com/mapfiles/ms/icons/pink-dot.png',
      'draggable': true
    };

    MultipleMarkersDrawnWrapper.prototype.objectOptions = {
      strokeColor: '#0000CC',
      strokeWeight: 1,
      editable: false,
      draggable: false,
      geodesic: false
    };

    MultipleMarkersDrawnWrapper.prototype.objectOptionsWhenSelected = {
      strokeColor: '#FF0000',
      strokeWeight: 2
    };

    MultipleMarkersDrawnWrapper.prototype.objectEventTypes = ['click', 'dblclick', 'rightclick', 'drag', 'dragend', 'dragstart', 'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup'];

    function MultipleMarkersDrawnWrapper(parent, options) {
      if (options == null) {
        options = {};
      }
      this.mainMarkers = [];
      this.markers = [];
      this.polygon = null;
      MultipleMarkersDrawnWrapper.__super__.constructor.call(this, parent, options);
    }

    MultipleMarkersDrawnWrapper.prototype.drawFromInitialData = function(data) {
      var j, len, point, position;
      for (j = 0, len = data.length; j < len; j++) {
        point = data[j];
        position = new google.maps.LatLng(point[0], point[1]);
        this.createMarker(position);
      }
      return this.redraw();
    };

    MultipleMarkersDrawnWrapper.prototype.getValue = function() {
      var j, len, marker, point, pointValues, ref;
      pointValues = [];
      ref = this.mainMarkers;
      for (j = 0, len = ref.length; j < len; j++) {
        marker = ref[j];
        point = marker.getPosition();
        pointValues.push([point.lat(), point.lng()]);
      }
      return pointValues;
    };

    MultipleMarkersDrawnWrapper.prototype.isValid = function() {
      if (this.mainMarkers.length > 2) {
        return true;
      }
      return false;
    };

    MultipleMarkersDrawnWrapper.prototype.redraw = function() {
      var pathPoints;
      this.clearHelperMarkers();
      if (this.mainMarkers.length < 2) {
        this.clearObject();
        return null;
      }
      pathPoints = this.drawMarkers(false);
      if (!this.object) {
        return this.createObject(pathPoints);
      } else {
        return this.updateObjectOptions({
          path: pathPoints
        });
      }
    };

    MultipleMarkersDrawnWrapper.prototype.clear = function() {
      while (this.markers.length) {
        this.clearMarker(this.markers[0]);
      }
      this.mainMarkers = [];
      this.markers = [];
      return this.clearObject();
    };

    MultipleMarkersDrawnWrapper.prototype.hide = function() {
      var j, len, marker, ref;
      this.clearHelperMarkers();
      ref = this.markers;
      for (j = 0, len = ref.length; j < len; j++) {
        marker = ref[j];
        marker.setVisible(false);
      }
      return this.object.setVisible(false);
    };

    MultipleMarkersDrawnWrapper.prototype.clearHelperMarkers = function() {
      var clearMarkers, j, k, len, len1, marker, ref, results;
      clearMarkers = [];
      ref = this.markers;
      for (j = 0, len = ref.length; j < len; j++) {
        marker = ref[j];
        if (!marker.mainMarker) {
          clearMarkers.push(marker);
        }
      }
      results = [];
      for (k = 0, len1 = clearMarkers.length; k < len1; k++) {
        marker = clearMarkers[k];
        results.push(this.clearMarker(marker));
      }
      return results;
    };

    MultipleMarkersDrawnWrapper.prototype.drawMarkers = function(closePath) {
      var helperMarker, helperPosition, i, markers, pathPoints, prevMarker, prevPosition, thisMarker, thisPosition;
      if (closePath == null) {
        closePath = false;
      }
      i = 0;
      pathPoints = [];
      markers = [];
      while (i < this.mainMarkers.length) {
        prevMarker = this.mainMarkers[i - 1];
        thisMarker = this.mainMarkers[i];
        thisPosition = thisMarker.getPosition();
        if (this.getDrawHelperMarker() && prevMarker) {
          prevPosition = prevMarker.getPosition();
          helperPosition = this.getHelperMarkerPosition(prevPosition, thisPosition);
          helperMarker = this.createHelperMarker(helperPosition);
          markers.push(helperMarker);
        }
        pathPoints.push(thisPosition);
        markers.push(thisMarker);
        this.updateMarkerOptions(thisMarker);
        i += 1;
      }
      if (closePath && this.getDrawHelperMarker() && this.mainMarkers.length > 2) {
        prevPosition = this.mainMarkers[this.mainMarkers.length - 1].getPosition();
        thisPosition = this.mainMarkers[0].getPosition();
        helperPosition = this.getHelperMarkerPosition(prevPosition, thisPosition);
        helperMarker = this.createHelperMarker(helperPosition);
        markers.push(helperMarker);
      }
      this.markers = markers;
      return pathPoints;
    };

    MultipleMarkersDrawnWrapper.prototype.crateMarker = function(position) {
      var marker, options;
      options = this.getMarkerOptions({
        'position': position
      });
      marker = new google.maps.Marker(options);
      marker.mainMarker = true;
      this.bindMarker(marker);
      this.markers.push(marker);
      return this.mainMarkers.push(marker);
    };

    MultipleMarkersDrawnWrapper.prototype.createHelperMarker = function(position) {
      var marker, options;
      options = this.getHelperMarkerOptions({
        'position': position
      });
      marker = new google.maps.Marker(options);
      marker.mainMarker = false;
      this.bindMarker(marker);
      this.markers.push(marker);
      return marker;
    };

    MultipleMarkersDrawnWrapper.prototype.clearMarker = function(marker) {
      google.maps.event.clearInstanceListeners(marker);
      marker.setMap(null);
      this.markers.splice(this.markers.indexOf(marker), 1);
      if (marker.mainMarker) {
        return this.mainMarkers.splice(this.mainMarkers.indexOf(marker), 1);
      }
    };

    MultipleMarkersDrawnWrapper.prototype.clearObject = function() {
      if (!this.object) {
        return null;
      }
      this.unbindObject();
      this.object.setMap(null);
      delete this.object;
      return this.object = null;
    };

    MultipleMarkersDrawnWrapper.prototype.getMarkerOptions = function(options) {
      var optName, opts;
      if (options == null) {
        options = {};
      }
      opts = {
        'map': this.parent.map
      };
      for (optName in this.markerOptions) {
        opts[optName] = this.markerOptions[optName];
      }
      if (this.selected) {
        for (optName in this.markerOptionsWhenSelected) {
          opts[optName] = this.markerOptionsWhenSelected[optName];
        }
      }
      for (optName in options) {
        opts[optName] = options[optName];
      }
      return opts;
    };

    MultipleMarkersDrawnWrapper.prototype.getHelperMarkerOptions = function(options) {
      var optName, opts;
      if (options == null) {
        options = {};
      }
      opts = {
        'map': this.parent.map
      };
      for (optName in this.helperMarkerOptions) {
        opts[optName] = this.helperMarkerOptions[optName];
      }
      for (optName in options) {
        opts[optName] = options[optName];
      }
      return opts;
    };

    MultipleMarkersDrawnWrapper.prototype.updateMarkerOptions = function(marker, options) {
      var opts;
      opts = this.getMarkerOptions(options);
      return marker.setOptions(opts);
    };

    MultipleMarkersDrawnWrapper.prototype.getDrawHelperMarker = function() {
      return this.selected && this.editable;
    };

    MultipleMarkersDrawnWrapper.prototype.getObjectOptions = function(options) {
      var optName, opts;
      if (options == null) {
        options = {};
      }
      opts = {
        'map': this.parent.map
      };
      for (optName in this.objectOptions) {
        opts[optName] = this.objectOptions[optName];
      }
      if (this.selected) {
        for (optName in this.objectOptionsWhenSelected) {
          opts[optName] = this.objectOptionsWhenSelected[optName];
        }
      }
      for (optName in options) {
        opts[optName] = options[optName];
      }
      return opts;
    };

    MultipleMarkersDrawnWrapper.prototype.updateObjectOptions = function(options) {
      var opts;
      opts = this.getObjectOptions(options);
      return this.object.setOptions(opts);
    };

    MultipleMarkersDrawnWrapper.prototype.bindMarker = function(marker) {
      var bindWrapper, eventType, eventTypes, j, len, results, wrapperCallbackName;
      eventTypes = ['click', 'dblclick', 'rightclick', 'drag', 'dragstart', 'dragend', 'mousedown', 'mouseup', 'mouseover', 'mouseout', 'position_changed', 'visible_changed'];
      bindWrapper = (function(_this) {
        return function(callbackName) {
          return google.maps.event.addListener(marker, eventType, function(arg) {
            return _this[callbackName](_this, marker, arg);
          });
        };
      })(this);
      results = [];
      for (j = 0, len = eventTypes.length; j < len; j++) {
        eventType = eventTypes[j];
        wrapperCallbackName = eventType + 'Marker';
        this.ensureWrapperCallbackExists(wrapperCallbackName);
        results.push(bindWrapper(wrapperCallbackName));
      }
      return results;
    };

    MultipleMarkersDrawnWrapper.prototype.bindMarkers = function() {
      var j, len, marker, ref, results;
      ref = this.markers;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        marker = ref[j];
        results.push(this.bindMarker(marker));
      }
      return results;
    };

    MultipleMarkersDrawnWrapper.prototype.unbindMarkers = function() {
      var j, len, marker, ref, results;
      ref = this.markers;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        marker = ref[j];
        results.push(google.maps.event.clearInstanceListeners(marker));
      }
      return results;
    };

    MultipleMarkersDrawnWrapper.prototype.bindObject = function() {
      var bindWrapper, eventType, j, len, ref, results, wrapperCallbackName;
      bindWrapper = (function(_this) {
        return function(callbackName) {
          return google.maps.event.addListener(_this.object, eventType, function(arg) {
            return _this[callbackName](_this, _this.object, arg);
          });
        };
      })(this);
      ref = this.objectEventTypes;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        eventType = ref[j];
        wrapperCallbackName = eventType + 'Object';
        this.ensureWrapperCallbackExists(wrapperCallbackName);
        results.push(bindWrapper(wrapperCallbackName));
      }
      return results;
    };

    MultipleMarkersDrawnWrapper.prototype.unbindObject = function() {
      return google.maps.event.clearInstanceListeners(this.object);
    };

    MultipleMarkersDrawnWrapper.prototype.setEditable = function(editable) {
      this.editable = editable;
      this.unbindMarkers();
      this.unbindObject();
      if (this.editable) {
        this.bindMarkers();
        return this.bindObject();
      }
    };

    MultipleMarkersDrawnWrapper.prototype.rightclickMarker = function(this_, marker, ev) {
      if (marker.mainMarker) {
        this_.clearMarker(marker);
        return this_.redraw();
      }
    };

    MultipleMarkersDrawnWrapper.prototype.dragendMarker = function(this_, marker, ev) {
      if (!marker.mainMarker) {
        marker.mainMarker = true;
        this.refillMainMarkers();
      }
      return this_.redraw();
    };

    MultipleMarkersDrawnWrapper.prototype.clickObject = function(this_, object, ev) {
      if (!this_.selected) {
        return this_.parent.select(this_);
      } else {
        return null;
      }
    };

    MultipleMarkersDrawnWrapper.prototype.rightclickObject = function(this_, object, ev) {
      return this_.parent.removeWrapper(this_);
    };

    MultipleMarkersDrawnWrapper.prototype.getHelperMarkerPosition = function(positionA, positionB) {
      var deltaLng, deltaLng180, lat, lng;
      lng = null;
      if ((positionA.lng() * positionB.lng()) < 0) {
        deltaLng = Math.abs(positionA.lng()) + Math.abs(positionB.lng());
        deltaLng180 = 360 - Math.abs(positionA.lng()) - Math.abs(positionB.lng());
        if (deltaLng > deltaLng180) {
          lng = Math.max(positionA.lng(), positionB.lng()) + deltaLng180 / 2;
          if (lng > 180) {
            lng -= 360;
          }
        }
      }
      if (!lng) {
        lng = (positionA.lng() + positionB.lng()) / 2;
      }
      lat = (positionA.lat() + positionB.lat()) / 2;
      return new google.maps.LatLng(lat, lng);
    };

    MultipleMarkersDrawnWrapper.prototype.refillMainMarkers = function() {
      var j, len, marker, ref, results;
      this.mainMarkers = [];
      ref = this.markers;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        marker = ref[j];
        if (marker.mainMarker) {
          results.push(this.mainMarkers.push(marker));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    MultipleMarkersDrawnWrapper.prototype.ensureWrapperCallbackExists = function(wrapperCallbackName) {
      if (!this[wrapperCallbackName]) {
        return this[wrapperCallbackName] = function(this_, object, arg) {
          return null;
        };
      }
    };

    return MultipleMarkersDrawnWrapper;

  })(MapObjectWrapper);

  PolygonWrapper = (function(superClass) {
    extend(PolygonWrapper, superClass);

    function PolygonWrapper() {
      return PolygonWrapper.__super__.constructor.apply(this, arguments);
    }

    PolygonWrapper.prototype.objectOptions = {
      strokeColor: '#0000CC',
      strokeOpacity: 0.2,
      strokeWeight: 1,
      fillColor: '#0000CC',
      fillOpacity: 0.2,
      editable: false,
      draggable: false,
      geodesic: false
    };

    PolygonWrapper.prototype.objectOptionsWhenSelected = {
      strokeColor: '#FF0000',
      strokeOpacity: 0.5,
      strokeWeight: 2,
      fillColor: '#FF0000',
      fillOpacity: 0.35
    };

    PolygonWrapper.prototype.objectEventTypes = ['click', 'dblclick', 'rightclick', 'drag', 'dragend', 'dragstart', 'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup'];

    PolygonWrapper.prototype.drawMarkers = function(_) {
      return PolygonWrapper.__super__.drawMarkers.call(this, true);
    };

    PolygonWrapper.prototype.createObject = function(path) {
      var options;
      options = this.getObjectOptions({
        'path': path
      });
      this.object = new google.maps.Polygon(options);
      return this.bindObject();
    };

    return PolygonWrapper;

  })(MultipleMarkersDrawnWrapper);

  PolylineWrapper = (function(superClass) {
    extend(PolylineWrapper, superClass);

    function PolylineWrapper() {
      return PolylineWrapper.__super__.constructor.apply(this, arguments);
    }

    PolylineWrapper.prototype.objectOptions = {
      strokeColor: '#0000CC',
      strokeWeight: 5,
      editable: false,
      draggable: false,
      geodesic: false
    };

    PolylineWrapper.prototype.objectOptionsWhenSelected = {
      strokeColor: '#FF0000',
      strokeWeight: 5
    };

    PolylineWrapper.prototype.createObject = function(path) {
      var options;
      options = this.getObjectOptions({
        'path': path
      });
      this.object = new google.maps.Polyline(options);
      return this.bindObject();
    };

    return PolylineWrapper;

  })(MultipleMarkersDrawnWrapper);

  window.PolygonWrapper = PolygonWrapper;

  window.PolylineWrapper = PolylineWrapper;

}).call(this);
