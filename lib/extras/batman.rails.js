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
    var buildParams, date_re, numericKeys, param, r20, rbracket;
    rbracket = /\[\]$/;
    r20 = /%20/g;
    param = function(a) {
      var add, k, name, s, v, value;
      if (typeof a === 'string') {
        return a;
      }
      s = [];
      add = function(key, value) {
        if (typeof value === 'function') {
          value = value();
        }
        return s[s.length] = encodeURIComponent(key) + "=" + encodeURIComponent(value);
      };
      if (Batman.typeOf(a) === 'Array') {
        for (value in a) {
          name = a[value];
          add(name, value);
        }
      } else {
        for (k in a) {
          if (!__hasProp.call(a, k)) continue;
          v = a[k];
          buildParams(k, v, add);
        }
      }
      return s.join("&").replace(r20, "+");
    };
    buildParams = function(prefix, obj, add) {
      var i, name, v, _len, _results, _results2;
      if (Batman.typeOf(obj) === 'Array') {
        _results = [];
        for (i = 0, _len = obj.length; i < _len; i++) {
          v = obj[i];
          _results.push(rbracket.test(prefix) ? add(prefix, v) : buildParams(prefix + "[]", v, add));
        }
        return _results;
      } else if ((obj != null) && typeof obj === "object") {
        _results2 = [];
        for (name in obj) {
          _results2.push(buildParams(prefix + "[" + name + "]", obj[name], add));
        }
        return _results2;
      } else {
        return add(prefix, obj);
      }
    };
    numericKeys = [1, 2, 3, 4, 5, 6, 7, 10, 11];
    date_re = /^(\d{4}|[+\-]\d{6})(?:-(\d{2})(?:-(\d{2}))?)?(?:T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{3}))?)?(?:(Z)|([+\-])(\d{2})(?::(\d{2}))?)?)?$/;
    Batman.mixin(Batman.Encoders, {
      railsDate: {
        defaultTimezoneOffset: (new Date()).getTimezoneOffset(),
        encode: function(value) {
          return value;
        },
        decode: function(value) {
          var key, minutesOffset, obj, _i, _len;
          if (value != null) {
            if ((obj = date_re.exec(value))) {
              for (_i = 0, _len = numericKeys.length; _i < _len; _i++) {
                key = numericKeys[_i];
                obj[key] = +obj[key] || 0;
              }
              obj[2] = (+obj[2] || 1) - 1;
              obj[3] = +obj[3] || 1;
              if (obj[8] !== "Z" && obj[9] !== void 0) {
                minutesOffset = obj[10] * 60 + obj[11];
                if (obj[9] === "+") {
                  minutesOffset = 0 - minutesOffset;
                }
              } else {
                minutesOffset = Batman.Encoders.railsDate.defaultTimezoneOffset;
              }
              return new Date(Date.UTC(obj[1], obj[2], obj[3], obj[4], obj[5] + minutesOffset, obj[6], obj[7]));
            } else {
              Batman.developer.warn("Unrecognized rails date " + value + "!");
              return Date.parse(value);
            }
          }
        }
      }
    });
    return Batman.RailsStorage = (function() {
      __extends(RailsStorage, Batman.RestStorage);
      function RailsStorage() {
        RailsStorage.__super__.constructor.apply(this, arguments);
      }
      RailsStorage.prototype._serializeToFormData = function(data) {
        return param(data);
      };
      RailsStorage.prototype.urlForRecord = function() {
        return this._addJsonExtension(RailsStorage.__super__.urlForRecord.apply(this, arguments));
      };
      RailsStorage.prototype.urlForCollection = function() {
        return this._addJsonExtension(RailsStorage.__super__.urlForCollection.apply(this, arguments));
      };
      RailsStorage.prototype._addJsonExtension = function(url) {
        if (url.indexOf('?') !== -1 || url.substr(-5, 5) === '.json') {
          return url;
        }
        return url + '.json';
      };
      RailsStorage.prototype._errorsFrom422Response = function(response) {
        return JSON.parse(response);
      };
      RailsStorage.prototype.before('update', 'create', function(env, next) {
        if (this.serializeAsForm && !env.options.formData) {
          env.options.data = this._serializeToFormData(env.options.data);
        }
        return next();
      });
      RailsStorage.prototype.after('update', 'create', function(_arg, next) {
        var env, error, errorsArray, key, record, response, validationError, validationErrors, _i, _len, _ref;
        error = _arg.error, record = _arg.record, response = _arg.response;
        if (error) {
          if (((_ref = error.request) != null ? _ref.get('status') : void 0) === 422) {
            try {
              validationErrors = this._errorsFrom422Response(response);
            } catch (extractionError) {
              env.error = extractionError;
              return next();
            }
            for (key in validationErrors) {
              errorsArray = validationErrors[key];
              for (_i = 0, _len = errorsArray.length; _i < _len; _i++) {
                validationError = errorsArray[_i];
                record.get('errors').add(key, "" + key + " " + validationError);
              }
            }
            env = arguments[0];
            env.result = record;
            env.error = record.get('errors');
            return next();
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
