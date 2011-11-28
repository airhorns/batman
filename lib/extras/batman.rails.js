(function() {
  var applyExtra;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  applyExtra = function(Batman) {
    Batman.mixin(Batman.Encoders, {
      railsDate: {
        encode: function(value) {
          return value;
        },
        decode: function(value) {
          var a;
          a = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)Z$/.exec(value);
          if (a) {
            return new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4], +a[5], +a[6]));
          } else {
            Batman.developer.warn("Unrecognized rails date " + value + "!");
            return Date.parse(value);
          }
        }
      }
    });
    return Batman.RailsStorage = (function() {
      __extends(RailsStorage, Batman.RestStorage);
      function RailsStorage() {
        RailsStorage.__super__.constructor.apply(this, arguments);
      }
      RailsStorage.prototype._addJsonExtension = function(url) {
        return url + '.json';
      };
      RailsStorage.prototype.urlForRecord = function() {
        return this._addJsonExtension(RailsStorage.__super__.urlForRecord.apply(this, arguments));
      };
      RailsStorage.prototype.urlForCollection = function() {
        return this._addJsonExtension(RailsStorage.__super__.urlForCollection.apply(this, arguments));
      };
      RailsStorage.prototype._errorsFrom422Response = function(response) {
        return JSON.parse(response);
      };
      RailsStorage.prototype.after('update', 'create', function(_arg, next) {
        var error, errorsArray, key, record, response, validationError, validationErrors, _i, _len, _ref;
        error = _arg.error, record = _arg.record, response = _arg.response;
        if (error) {
          if (((_ref = error.request) != null ? _ref.get('status') : void 0) === 422) {
            try {
              validationErrors = this._errorsFrom422Response(response);
            } catch (extractionError) {
              return next(extractionError);
            }
            for (key in validationErrors) {
              errorsArray = validationErrors[key];
              for (_i = 0, _len = errorsArray.length; _i < _len; _i++) {
                validationError = errorsArray[_i];
                record.get('errors').add(key, "" + key + " " + validationError);
              }
            }
            arguments[0].result = record;
            return next(record.get('errors'));
          }
        }
        return next();
      });
      return RailsStorage;
    })();
  };
  if ((typeof module !== "undefined" && module !== null) && (typeof require !== "undefined" && require !== null)) {
    module.exports = applyExtra;
  } else {
    applyExtra(Batman);
  }
}).call(this);
