var Keyconfig, Shortcuts, events, getPlatformBindings, getPlatformCollisions, os,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Keyconfig = require('keyconfig');

events = require('events');

os = require('component-os');

require('mousetrap');

require('mousetrap-global-bind');

require('mousetrap-pause');

module.exports = Shortcuts = (function(superClass) {
  extend(Shortcuts, superClass);

  function Shortcuts(defaults) {
    var transform;
    if (defaults == null) {
      defaults = {};
    }
    this.config = new Keyconfig(defaults);
    this._numListeners = this.config.reduce(function(acc, x) {
      acc[x.name] = 0;
      return acc;
    }, {});
    this.config.on('change', (function(_this) {
      return function(collection, model) {
        if (_this._numListeners[collection.name] > 0) {
          _this._resetBinding(collection, model);
        }
        _this.emit('change', collection, model);
      };
    })(this));
    this._listeners = {};
    transform = (function(_this) {
      return function(event) {
        var collection, collectionName, eventName, ref;
        ref = event.split(':'), eventName = ref[0], collectionName = ref[1];
        if (eventName !== 'key' || !(collection = _this.get(collectionName))) {
          return void 0;
        }
        return collection;
      };
    })(this);
    this.on('newListener', (function(_this) {
      return function(event) {
        var collection;
        if (!(collection = transform(event))) {
          return void 0;
        }
        if (++_this._numListeners[collection.name] === 1) {
          return _this._bind(collection);
        }
      };
    })(this));
    this.on('removeListener', (function(_this) {
      return function(event) {
        var collection;
        if (!(collection = transform(event))) {
          return void 0;
        }
        if (--_this._numListeners[collection.name] === 0) {
          return _this._unbind(collection);
        }
      };
    })(this));
    Shortcuts.__super__.constructor.call(this);
  }

  Shortcuts.prototype.removeAllListeners = function(type) {
    if (!type) {
      throw new Error('missing type');
    }
    return Shortcuts.__super__.removeAllListeners.call(this, type);
  };

  Shortcuts.prototype._resetBinding = function(collection, model) {
    var index, listener, listeners;
    index = this._listeners[collection.name];
    listeners = index[model.name];
    while ((listener = listeners != null ? listeners.pop() : void 0) != null) {
      Mousetrap.unbind(listener.sequence);
    }
    listeners = this._bindKeys(collection, model);
    if (listeners.length) {
      return index[model.name] = listeners;
    } else {
      return delete index[model.name];
    }
  };

  Shortcuts.prototype._bind = function(collection) {
    var base, index, name;
    index = ((base = this._listeners)[name = collection.name] || (base[name] = {}));
    collection.each((function(_this) {
      return function(model) {
        var listeners;
        listeners = _this._bindKeys(collection, model);
        if (listeners.length) {
          return index[model.name] = listeners;
        }
      };
    })(this));
  };

  Shortcuts.prototype._bindKeys = function(collection, model) {
    var bindings, listeners;
    bindings = getPlatformBindings(model);
    listeners = [];
    if (bindings.length) {
      bindings.forEach((function(_this) {
        return function(sequence) {
          var cb, listener, ref, ref1;
          if (((ref = model.options) != null ? ref.enabled : void 0) === false) {
            return;
          }
          cb = function(e) {
            e.collection = collection;
            e.model = model;
            e.sequence = sequence;
            return _this.emit("key:" + collection.name, e);
          };
          listener = {
            sequence: sequence,
            cb: cb
          };
          listeners.push(listener);
          if (((ref1 = model.options) != null ? ref1.global : void 0) === true) {
            return Mousetrap.bindGlobal(listener.sequence, listener.cb);
          } else {
            return Mousetrap.bind(listener.sequence, listener.cb);
          }
        };
      })(this));
    }
    return listeners;
  };

  Shortcuts.prototype._unbind = function(collection) {
    var index, key, listener, listeners;
    index = this._listeners[collection.name];
    for (key in index) {
      listeners = index[key];
      while ((listener = listeners != null ? listeners.pop() : void 0) != null) {
        Mousetrap.unbind(listener.sequence);
      }
      delete index[key];
    }
    delete this._listeners[collection.name];
  };

  Shortcuts.prototype.getCollisions = function(collectionName) {
    var collection;
    collection = this.config.find({
      name: collectionName
    });
    if (collection) {
      return getPlatformCollisions(collection);
    }
  };

  Shortcuts.prototype.get = function(collectionName, modelName) {
    var collection, model;
    collection = this.config.find({
      name: collectionName
    });
    if (!modelName || (modelName && !collection)) {
      return collection;
    } else {
      model = collection.find({
        name: modelName
      });
      return model;
    }
  };

  Shortcuts.prototype.update = function(collectionName, modelName, value, silent) {
    var collection;
    if (silent == null) {
      silent = false;
    }
    if (!(collection = this.get(collectionName))) {
      throw collectionName + " not found";
    }
    return collection.update(modelName, value, silent).find({
      name: modelName
    });
  };

  Shortcuts.prototype.pause = function() {
    return Mousetrap.pause();
  };

  Shortcuts.prototype.unpause = function() {
    return Mousetrap.unpause();
  };

  return Shortcuts;

})(events.EventEmitter);

getPlatformBindings = function(model) {
  var bindings;
  bindings = os === 'mac' ? model.getMacKeys() : model.getWinKeys();
  return [].concat(bindings).filter(Boolean);
};

getPlatformCollisions = function(collection) {
  var collisions;
  collisions = os === 'mac' ? collection.getCollidingMac() : model.getCollidingWin();
  return collisions;
};
