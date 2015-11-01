// Generated by CoffeeScript 1.9.3
(function() {
  var MapHandler, Mode;

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

    Mode.prototype.onClick = function(point) {
      return null;
    };

    Mode.prototype.onRightClick = function(point) {
      return null;
    };

    Mode.prototype.onMapBoundsChanged = function() {
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

    return Mode;

  })();

  MapHandler = (function() {
    function MapHandler() {}

    MapHandler.prototype.map = null;

    MapHandler.prototype.initialMapOptions = {
      center: new google.maps.LatLng(52.21885952070011, 20.983983278274536),
      zoom: 18,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };

    MapHandler.prototype.mode = 'none';

    MapHandler.prototype.availableModes = {
      'BaseMode': Mode,
    };

    MapHandler.prototype.modes = {};

    MapHandler.prototype.modeHandler = null;

    MapHandler.prototype.editable = true;

    MapHandler.prototype.initializeMap = function() {
      return this.map = new google.maps.Map($('.js-map-container')[0], this.initialMapOptions);

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

    return MapHandler;

  })();

  window.MapHandler = MapHandler;

}).call(this);
