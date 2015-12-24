// Generated by CoffeeScript 1.9.3
(function() {
  var MapHandler, MarkersMode, Mode, PolygonMode,
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Mode = (function() {
    function Mode() {}

    Mode.prototype.markerOptions = {};

    Mode.prototype.initialize = function(options) {
      var opt, results;
      results = [];
      for (opt in options) {
        results.push(this[opt] = options[opt]);
      }
      return results;
    };

    Mode.prototype.drawFromInitialData = function(data) {
      return null;
    };

    Mode.prototype.start = function() {
      return null;
    };

    Mode.prototype.clear = function() {
      return null;
    };

    Mode.prototype.getValue = function() {
      return null;
    };

    Mode.prototype.createMarker = function(latLng, options, callbacks) {
      var ev, key, marker, opts;
      if (!(latLng.lat && latLng.lng)) {
        latLng = new google.maps.LatLng(latLng[0], latLng[1]);
      }
      opts = {
        'map': this.map,
        'position': latLng
      };
      for (key in this.markerOptions) {
        opts[key] = this.markerOptions[key];
      }
      for (key in options) {
        opts[key] = options[key];
      }
      marker = new google.maps.Marker(opts);
      if (callbacks) {
        for (ev in callbacks) {
          google.maps.event.addListener(marker, ev, (function(_this) {
            return function() {
              var args;
              args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
              args.splice(0, 0, _this);
              args.splice(0, 0, marker);
              return callbacks[ev](args);
            };
          })(this));
        }
      }
      return marker;
    };

    Mode.prototype.removeMarker = function(marker) {
      if (marker) {
        marker.setMap(null);
        return google.maps.event.clearInstanceListeners(marker);
      }
    };

    return Mode;

  })();

  MarkersMode = (function(superClass) {
    extend(MarkersMode, superClass);

    function MarkersMode() {
      return MarkersMode.__super__.constructor.apply(this, arguments);
    }

    MarkersMode.prototype.markers = [];

    MarkersMode.prototype.removableMarkers = true;

    MarkersMode.prototype.on_click = function(point) {
      var marker;
      marker = this.createMarker(point.latLng);
      if (this.removableMarkers) {
        google.maps.event.addListener(marker, 'rightclick', (function(_this) {
          return function() {
            return _this.removeMarker(marker);
          };
        })(this));
      }
      this.markers.push(marker);
      return marker;
    };

    MarkersMode.prototype.removeMarker = function(marker) {
      var idx;
      idx = this.markers.indexOf(marker);
      this.markers.splice(idx, 1);
      return MarkersMode.__super__.removeMarker.call(this, marker);
    };

    MarkersMode.prototype.clear = function() {
      var marker, results;
      results = [];
      while (this.markers.length) {
        marker = this.markers[this.markers.length - 1];
        results.push(this.removeMarker(marker));
      }
      return results;
    };

    MarkersMode.prototype.getValue = function() {
      var i, len, marker, markerPosition, positions, ref;
      positions = [];
      ref = this.markers;
      for (i = 0, len = ref.length; i < len; i++) {
        marker = ref[i];
        markerPosition = marker.getPosition();
        positions.push([markerPosition.lat(), markerPosition.lng()]);
      }
      return positions;
    };

    MarkersMode.prototype.drawFromInitialData = function(data) {

      /*
      Example data is:
      {
          'coords': [[51.51, 23.23, {attr: 'optional'}], [52.00, 23.00]],
          'options': {draggable:false}, v
          'callbacks': {'click': (arg) -> console.log('klik ' + arg)}
      }
      If data has no 'coords' attribute, then assume it is just a list of
      coordinates (like: [[51.51, 23.23, {attr: 'optional'}], [52.00, 23.00]])
       */
      var attr, coord, coords, i, len, marker, results;
      if (!data.coords) {
        coords = data;
      } else {
        coords = data.coords;
      }
      results = [];
      for (i = 0, len = coords.length; i < len; i++) {
        coord = coords[i];
        marker = this.createMarker(coord, data.options, data.callbacks);
        if (coord[2]) {
          for (attr in coord[2]) {
            marker[attr] = coord[2][attr];
          }
        }
        results.push(this.markers.push(marker));
      }
      return results;
    };

    return MarkersMode;

  })(Mode);

  PolygonMode = (function(superClass) {
    extend(PolygonMode, superClass);

    function PolygonMode() {
      return PolygonMode.__super__.constructor.apply(this, arguments);
    }

    PolygonMode.prototype.wrappers = [];

    PolygonMode.prototype.selected = null;

    PolygonMode.prototype.editable = true;

    PolygonMode.prototype.drawFromInitialData = function(data) {
      var i, len, polygonData, results, wrapper;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        polygonData = data[i];
        wrapper = new PolygonWrapper(this, {
          'selected': false
        });
        wrapper.drawFromInitialData(data);
        results.push(this.wrappers.push(wrapper));
      }
      return results;
    };

    PolygonMode.prototype.getValue = function() {
      var data, i, len, ref, wrapper;
      data = [];
      ref = this.wrappers;
      for (i = 0, len = ref.length; i < len; i++) {
        wrapper = ref[i];
        data.push(wrapper.getValue());
      }
      return data;
    };

    PolygonMode.prototype.on_click = function(ev) {
      var wrapper;
      if (this.selected) {
        this.selected.crateMarker(ev.latLng);
        return this.selected.redraw();
      } else {
        wrapper = new PolygonWrapper(this);
        wrapper.crateMarker(ev.latLng);
        this.wrappers.push(wrapper);
        return this.select(wrapper);
      }
    };

    PolygonMode.prototype.on_rightclick = function(ev) {
      return this.deselect();
    };

    PolygonMode.prototype.start = function() {
      return null;
    };

    PolygonMode.prototype.clear = function() {
      var i, len, ref, wrapper;
      ref = this.wrappers;
      for (i = 0, len = ref.length; i < len; i++) {
        wrapper = ref[i];
        wrapper.clear();
      }
      this.wrappers = [];
      return this.selected = null;
    };

    PolygonMode.prototype.select = function(wrapper) {
      this.deselect();
      this.selected = wrapper;
      this.selected.selected = true;
      return this.selected.redraw();
    };

    PolygonMode.prototype.deselect = function() {
      if (this.selected) {
        if (this.selected.isValid()) {
          this.selected.selected = false;
          this.selected.redraw();
        } else {
          this.removeWrapper(this.selected);
        }
      }
      return this.selected = null;
    };

    PolygonMode.prototype.setEditable = function(editable) {
      var i, j, len, len1, ref, ref1, results, results1, wrapper;
      this.editable = editable;
      if (this.editable) {
        ref = this.wrappers;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          wrapper = ref[i];
          results.push(wrapper.setEditable(true));
        }
        return results;
      } else {
        this.deselect();
        ref1 = this.wrappers;
        results1 = [];
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          wrapper = ref1[j];
          results1.push(wrapper.setEditable(false));
        }
        return results1;
      }
    };

    PolygonMode.prototype.removeWrapper = function(wrapper) {
      wrapper.clear();
      return this.wrappers.splice(this.wrappers.indexOf(wrapper), 1);
    };

    return PolygonMode;

  })(Mode);

  MapHandler = (function() {
    function MapHandler() {}

    MapHandler.prototype.map = null;

    MapHandler.prototype.mapContainerSelector = '#map-container';

    MapHandler.prototype.initialMapOptions = {
      center: new google.maps.LatLng(52.21885952070011, 20.983983278274536),
      zoom: 18,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };

    MapHandler.prototype.mode = 'none';

    MapHandler.prototype.availableModes = {
      'BaseMode': Mode,
      'MarkersMode': MarkersMode,
      'PolygonMode': PolygonMode
    };

    MapHandler.prototype.modes = {};

    MapHandler.prototype.handler = null;

    MapHandler.prototype.editable = true;

    MapHandler.prototype.delayedEventsTimeout = 1000;

    MapHandler.prototype.initializeMap = function(mapContainerSelector) {
      var className, id, mapContainer;
      mapContainerSelector = mapContainerSelector || this.mapContainerSelector;
      if (mapContainerSelector.charAt(0) === '.') {
        className = mapContainerSelector.slice(1);
        mapContainer = document.getElementsByClassName(className)[0];
      } else if (mapContainerSelector.charAt(0) === '#') {
        id = mapContainerSelector.slice(1);
        mapContainer = document.getElementById(id);
      }
      this.map = new google.maps.Map(mapContainer, this.initialMapOptions);
      return this.bindMapEvents();
    };

    MapHandler.prototype.initializeMode = function(modeName, modeCodename, modeOptions) {
      var optName;
      if (modeOptions == null) {
        modeOptions = {};
      }
      if (this.modes[modeName]) {
        return null;
      }
      if (!modeCodename) {
        modeCodename = modeName;
      }
      if (!this.availableModes[modeCodename]) {
        throw Error('Unknown work mode: ' + String(modeCodename));
      }
      this.modes[modeName] = new this.availableModes[modeCodename]();
      for (optName in modeOptions) {
        this.modes[modeName][optName] = modeOptions[optName];
      }
      this.modes[modeName].mapHandler = this;
      this.modes[modeName].map = this.map;
      return this.modes[modeName].initialize();
    };

    MapHandler.prototype.centerMap = function(points) {
      var coords, i, j, latLng, latLngs, latlngbounds, len, len1;
      if (!points) {
        return;
      }
      latLngs = [];
      for (i = 0, len = points.length; i < len; i++) {
        coords = points[i];
        if (coords.lat && coords.lng) {
          latLng = coords;
        } else {
          latLng = new google.maps.LatLng(coords[0], coords[1]);
        }
        latLngs.push(latLng);
      }
      if (latLngs.length === 1) {
        return this.map.setCenter(latLngs[0]);
      } else {
        latlngbounds = new google.maps.LatLngBounds();
        for (j = 0, len1 = latLngs.length; j < len1; j++) {
          latLng = latLngs[j];
          latlngbounds.extend(latLng);
        }
        return this.map.fitBounds(latlngbounds);
      }
    };

    MapHandler.prototype.bindMapEvents = function() {
      var bindDelayedWrapper, bindWrapper, callbackName, delayedEvents, eventType, events, i, j, len, len1, results;
      events = ['bounds_changed', 'center_changed', 'heading_changed', 'idle', 'maptypeid_changed', 'projection_changed', 'tilt_changed', 'zoom_changed', 'click', 'dblclick', 'rightclick', 'dragstart', 'dragend', 'mouseover', 'mouseout', 'tilesloaded'];
      delayedEvents = ['drag', 'mousemove'];
      bindWrapper = (function(_this) {
        return function(callbackName, eventType) {
          return google.maps.event.addListener(_this.map, eventType, function(arg) {
            if (_this.handler && _this.handler.editable && _this.handler[callbackName]) {
              return _this.handler[callbackName](arg);
            }
          });
        };
      })(this);
      for (i = 0, len = events.length; i < len; i++) {
        eventType = events[i];
        callbackName = 'on_' + eventType;
        bindWrapper(callbackName, eventType);
      }
      bindDelayedWrapper = (function(_this) {
        return function(callbackName, eventType) {
          var delayHelper;
          delayHelper = {
            'timeout': null
          };
          return google.maps.event.addListener(_this.map, eventType, function(arg) {
            if (delayHelper.timeout) {
              return null;
            }
            return delayHelper.timeout = setTimeout(function() {
              if (_this.handler && _this.handler.editable && _this.handler[callbackName]) {
                _this.handler[callbackName](arg);
              }
              return delayHelper.timeout = null;
            }, _this.delayedEventsTimeout);
          });
        };
      })(this);
      results = [];
      for (j = 0, len1 = delayedEvents.length; j < len1; j++) {
        eventType = delayedEvents[j];
        callbackName = 'on_' + eventType;
        results.push(bindDelayedWrapper(callbackName, eventType));
      }
      return results;
    };

    MapHandler.prototype.clearMap = function() {
      var mode, results;
      results = [];
      for (mode in this.modes) {
        results.push(this.modes[mode].clear());
      }
      return results;
    };

    MapHandler.prototype.changeMode = function(modeName, modeCodename) {
      if (modeName === 'none') {
        this.mode = modeName;
        this.handler = null;
      }
      if (!this.modes[modeName]) {
        this.initializeMode(modeName, modeCodename);
      }
      this.mode = modeName;
      this.handler = this.modes[modeName];
      return this.handler.start();
    };

    MapHandler.prototype.setEditable = function(editable) {
      if (this.handler) {
        return this.handler.setEditable(editable);
      }
    };

    return MapHandler;

  })();

  window.MapHandler = MapHandler;

}).call(this);
