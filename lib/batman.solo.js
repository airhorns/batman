(function() {

  
/*!
  * Reqwest! A general purpose XHR connection manager
  * (c) Dustin Diaz 2011
  * https://github.com/ded/reqwest
  * license MIT
  */
!function (name, definition) {
  if (typeof module != 'undefined') module.exports = definition()
  else if (typeof define == 'function' && define.amd) define(name, definition)
  else this[name] = definition()
}('reqwest', function () {

  var context = this
    , win = window
    , doc = document
    , old = context.reqwest
    , twoHundo = /^20\d$/
    , byTag = 'getElementsByTagName'
    , readyState = 'readyState'
    , contentType = 'Content-Type'
    , requestedWith = 'X-Requested-With'
    , head = doc[byTag]('head')[0]
    , uniqid = 0
    , lastValue // data stored by the most recent JSONP callback
    , xmlHttpRequest = 'XMLHttpRequest'
    , isArray = typeof Array.isArray == 'function' ? Array.isArray : function (a) {
        return a instanceof Array
      }
    , defaultHeaders = {
          contentType: 'application/x-www-form-urlencoded'
        , accept: {
              '*':  'text/javascript, text/html, application/xml, text/xml, */*'
            , xml:  'application/xml, text/xml'
            , html: 'text/html'
            , text: 'text/plain'
            , json: 'application/json, text/javascript'
            , js:   'application/javascript, text/javascript'
          }
        , requestedWith: xmlHttpRequest
      }
    , xhr = win[xmlHttpRequest] ?
        function () {
          return new XMLHttpRequest()
        } :
        function () {
          return new ActiveXObject('Microsoft.XMLHTTP')
        }

  function handleReadyState(o, success, error) {
    return function () {
      if (o && o[readyState] == 4) {
        if (twoHundo.test(o.status)) {
          success(o)
        } else {
          error(o)
        }
      }
    }
  }

  function setHeaders(http, o) {
    var headers = o.headers || {}, h
    headers.Accept = headers.Accept || defaultHeaders.accept[o.type] || defaultHeaders.accept['*']
    // breaks cross-origin requests with legacy browsers
    if (!o.crossOrigin && !headers[requestedWith]) headers[requestedWith] = defaultHeaders.requestedWith
    if (!headers[contentType]) headers[contentType] = o.contentType || defaultHeaders.contentType
    for (h in headers) {
      headers.hasOwnProperty(h) && http.setRequestHeader(h, headers[h])
    }
  }

  function generalCallback(data) {
    lastValue = data
  }

  function urlappend(url, s) {
    return url + (/\?/.test(url) ? '&' : '?') + s
  }

  function handleJsonp(o, fn, err, url) {
    var reqId = uniqid++
      , cbkey = o.jsonpCallback || 'callback' // the 'callback' key
      , cbval = o.jsonpCallbackName || ('reqwest_' + reqId) // the 'callback' value
      , cbreg = new RegExp('((^|\\?|&)' + cbkey + ')=([^&]+)')
      , match = url.match(cbreg)
      , script = doc.createElement('script')
      , loaded = 0

    if (match) {
      if (match[3] === '?') {
        url = url.replace(cbreg, '$1=' + cbval) // wildcard callback func name
      } else {
        cbval = match[3] // provided callback func name
      }
    } else {
      url = urlappend(url, cbkey + '=' + cbval) // no callback details, add 'em
    }

    win[cbval] = generalCallback

    script.type = 'text/javascript'
    script.src = url
    script.async = true
    if (typeof script.onreadystatechange !== 'undefined') {
        // need this for IE due to out-of-order onreadystatechange(), binding script
        // execution to an event listener gives us control over when the script
        // is executed. See http://jaubourg.net/2010/07/loading-script-as-onclick-handler-of.html
        script.event = 'onclick'
        script.htmlFor = script.id = '_reqwest_' + reqId
    }

    script.onload = script.onreadystatechange = function () {
      if ((script[readyState] && script[readyState] !== 'complete' && script[readyState] !== 'loaded') || loaded) {
        return false
      }
      script.onload = script.onreadystatechange = null
      script.onclick && script.onclick()
      // Call the user callback with the last value stored and clean up values and scripts.
      o.success && o.success(lastValue)
      lastValue = undefined
      head.removeChild(script)
      loaded = 1
    }

    // Add the script to the DOM head
    head.appendChild(script)
  }

  function getRequest(o, fn, err) {
    var method = (o.method || 'GET').toUpperCase()
      , url = typeof o === 'string' ? o : o.url
      // convert non-string objects to query-string form unless o.processData is false
      , data = (o.processData !== false && o.data && typeof o.data !== 'string')
        ? reqwest.toQueryString(o.data)
        : (o.data || null)
      , http

    // if we're working on a GET request and we have data then we should append
    // query string to end of URL and not post data
    if ((o.type == 'jsonp' || method == 'GET') && data) {
      url = urlappend(url, data)
      data = null
    }

    if (o.type == 'jsonp') return handleJsonp(o, fn, err, url)

    http = xhr()
    http.open(method, url, true)
    setHeaders(http, o)
    http.onreadystatechange = handleReadyState(http, fn, err)
    o.before && o.before(http)
    http.send(data)
    return http
  }

  function Reqwest(o, fn) {
    this.o = o
    this.fn = fn
    init.apply(this, arguments)
  }

  function setType(url) {
    var m = url.match(/\.(json|jsonp|html|xml)(\?|$)/)
    return m ? m[1] : 'js'
  }

  function init(o, fn) {
    this.url = typeof o == 'string' ? o : o.url
    this.timeout = null
    var type = o.type || setType(this.url)
      , self = this
    fn = fn || function () {}

    if (o.timeout) {
      this.timeout = setTimeout(function () {
        self.abort()
      }, o.timeout)
    }

    function complete(resp) {
      o.timeout && clearTimeout(self.timeout)
      self.timeout = null
      o.complete && o.complete(resp)
    }

    function success(resp) {
      var r = resp.responseText
      if (r) {
        switch (type) {
        case 'json':
          try {
            resp = win.JSON ? win.JSON.parse(r) : eval('(' + r + ')')
          } catch (err) {
            return error(resp, 'Could not parse JSON in response', err)
          }
          break;
        case 'js':
          resp = eval(r)
          break;
        case 'html':
          resp = r
          break;
        }
      }

      fn(resp)
      o.success && o.success(resp)

      complete(resp)
    }

    function error(resp, msg, t) {
      o.error && o.error(resp, msg, t)
      complete(resp)
    }

    this.request = getRequest(o, success, error)
  }

  Reqwest.prototype = {
    abort: function () {
      this.request.abort()
    }

  , retry: function () {
      init.call(this, this.o, this.fn)
    }
  }

  function reqwest(o, fn) {
    return new Reqwest(o, fn)
  }

  // normalize newline variants according to spec -> CRLF
  function normalize(s) {
    return s ? s.replace(/\r?\n/g, '\r\n') : ''
  }

  function serial(el, cb) {
    var n = el.name
      , t = el.tagName.toLowerCase()
      , optCb = function(o) {
          // IE gives value="" even where there is no value attribute
          // 'specified' ref: http://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-862529273
          if (o && !o.disabled)
            cb(n, normalize(o.attributes.value && o.attributes.value.specified ? o.value : o.text))
        }

    // don't serialize elements that are disabled or without a name
    if (el.disabled || !n) return;

    switch (t) {
    case 'input':
      if (!/reset|button|image|file/i.test(el.type)) {
        var ch = /checkbox/i.test(el.type)
          , ra = /radio/i.test(el.type)
          , val = el.value;
        // WebKit gives us "" instead of "on" if a checkbox has no value, so correct it here
        (!(ch || ra) || el.checked) && cb(n, normalize(ch && val === '' ? 'on' : val))
      }
      break;
    case 'textarea':
      cb(n, normalize(el.value))
      break;
    case 'select':
      if (el.type.toLowerCase() === 'select-one') {
        optCb(el.selectedIndex >= 0 ? el.options[el.selectedIndex] : null)
      } else {
        for (var i = 0; el.length && i < el.length; i++) {
          el.options[i].selected && optCb(el.options[i])
        }
      }
      break;
    }
  }

  // collect up all form elements found from the passed argument elements all
  // the way down to child elements; pass a '<form>' or form fields.
  // called with 'this'=callback to use for serial() on each element
  function eachFormElement() {
    var cb = this
      , e, i, j
      , serializeSubtags = function(e, tags) {
        for (var i = 0; i < tags.length; i++) {
          var fa = e[byTag](tags[i])
          for (j = 0; j < fa.length; j++) serial(fa[j], cb)
        }
      }

    for (i = 0; i < arguments.length; i++) {
      e = arguments[i]
      if (/input|select|textarea/i.test(e.tagName)) serial(e, cb)
      serializeSubtags(e, [ 'input', 'select', 'textarea' ])
    }
  }

  // standard query string style serialization
  function serializeQueryString() {
    return reqwest.toQueryString(reqwest.serializeArray.apply(null, arguments))
  }

  // { 'name': 'value', ... } style serialization
  function serializeHash() {
    var hash = {}
    eachFormElement.apply(function (name, value) {
      if (name in hash) {
        hash[name] && !isArray(hash[name]) && (hash[name] = [hash[name]])
        hash[name].push(value)
      } else hash[name] = value
    }, arguments)
    return hash
  }

  // [ { name: 'name', value: 'value' }, ... ] style serialization
  reqwest.serializeArray = function () {
    var arr = []
    eachFormElement.apply(function(name, value) {
      arr.push({name: name, value: value})
    }, arguments)
    return arr
  }

  reqwest.serialize = function () {
    if (arguments.length === 0) return ''
    var opt, fn
      , args = Array.prototype.slice.call(arguments, 0)

    opt = args.pop()
    opt && opt.nodeType && args.push(opt) && (opt = null)
    opt && (opt = opt.type)

    if (opt == 'map') fn = serializeHash
    else if (opt == 'array') fn = reqwest.serializeArray
    else fn = serializeQueryString

    return fn.apply(null, args)
  }

  reqwest.toQueryString = function (o) {
    var qs = '', i
      , enc = encodeURIComponent
      , push = function (k, v) {
          qs += enc(k) + '=' + enc(v) + '&'
        }

    if (isArray(o)) {
      for (i = 0; o && i < o.length; i++) push(o[i].name, o[i].value)
    } else {
      for (var k in o) {
        if (!Object.hasOwnProperty.call(o, k)) continue;
        var v = o[k]
        if (isArray(v)) {
          for (i = 0; i < v.length; i++) push(k, v[i])
        } else push(k, o[k])
      }
    }

    // spaces should be + according to spec
    return qs.replace(/&$/, '').replace(/%20/g,'+')
  }

  // jQuery and Zepto compatibility, differences can be remapped here so you can call
  // .ajax.compat(options, callback)
  reqwest.compat = function (o, fn) {
    if (o) {
      o.type && (o.method = o.type) && delete o.type
      o.dataType && (o.type = o.dataType)
      o.jsonpCallback && (o.jsonpCallbackName = o.jsonpCallback) && delete o.jsonpCallback
      o.jsonp && (o.jsonpCallback = o.jsonp)
    }
    return new Reqwest(o, fn)
  }

  return reqwest
})

;

  var buildParams, param, prefixes, r20, rbracket;
  var __hasProp = Object.prototype.hasOwnProperty;

  (typeof exports !== "undefined" && exports !== null ? exports : this).reqwest = typeof window !== "undefined" && window !== null ? window.reqwest : reqwest;

  rbracket = /\[\]$/;

  r20 = /%20/g;

  param = function(a) {
    var add, k, name, s, v, value;
    if (typeof a === 'string') return a;
    s = [];
    add = function(key, value) {
      if (typeof value === 'function') value = value();
      if (value == null) value = '';
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
        if (rbracket.test(prefix)) {
          _results.push(add(prefix, v));
        } else {
          _results.push(buildParams(prefix + "[" + (typeof v === "object" || Batman.typeOf(v) === 'Array' ? i : "") + "]", v, add));
        }
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

  Batman.Request.prototype.send = function(data) {
    var options, xhr, _ref;
    var _this = this;
    if (data == null) data = this.get('data');
    this.fire('loading');
    options = {
      url: this.get('url'),
      method: this.get('method'),
      type: this.get('type'),
      headers: this.get('headers'),
      success: function(response) {
        _this.set('response', response);
        _this.set('status', (typeof xhr !== "undefined" && xhr !== null ? xhr.status : void 0) || 200);
        return _this.fire('success', response);
      },
      error: function(xhr) {
        _this.set('response', xhr.responseText || xhr.content);
        _this.set('status', xhr.status);
        xhr.request = _this;
        return _this.fire('error', xhr);
      },
      complete: function() {
        return _this.fire('loaded');
      }
    };
    if ((_ref = options.method) === 'PUT' || _ref === 'POST') {
      if (this.hasFileUploads()) {
        options.data = this.constructor.objectToFormData(data);
      } else {
        options.contentType = this.get('contentType');
        options.data = param(data);
      }
    } else {
      options.data = data;
    }
    return xhr = (reqwest(options)).request;
  };

  prefixes = ['Webkit', 'Moz', 'O', 'ms', ''];

  Batman.mixins.animation = {
    initialize: function() {
      var prefix, _i, _len;
      for (_i = 0, _len = prefixes.length; _i < _len; _i++) {
        prefix = prefixes[_i];
        this.style["" + prefix + "Transform"] = 'scale(0, 0)';
        this.style.opacity = 0;
        this.style["" + prefix + "TransitionProperty"] = "" + (prefix ? '-' + prefix.toLowerCase() + '-' : '') + "transform, opacity";
        this.style["" + prefix + "TransitionDuration"] = "0.8s, 0.55s";
        this.style["" + prefix + "TransformOrigin"] = "left top";
      }
      return this;
    },
    show: function(addToParent) {
      var show, _ref, _ref2;
      var _this = this;
      show = function() {
        var prefix, _i, _len;
        _this.style.opacity = 1;
        for (_i = 0, _len = prefixes.length; _i < _len; _i++) {
          prefix = prefixes[_i];
          _this.style["" + prefix + "Transform"] = 'scale(1, 1)';
        }
        return _this;
      };
      if (addToParent) {
        if ((_ref = addToParent.append) != null) _ref.appendChild(this);
        if ((_ref2 = addToParent.before) != null) {
          _ref2.parentNode.insertBefore(this, addToParent.before);
        }
        setTimeout(show, 0);
      } else {
        show();
      }
      return this;
    },
    hide: function(shouldRemove) {
      var prefix, _i, _len;
      var _this = this;
      this.style.opacity = 0;
      for (_i = 0, _len = prefixes.length; _i < _len; _i++) {
        prefix = prefixes[_i];
        this.style["" + prefix + "Transform"] = 'scale(0, 0)';
      }
      if (shouldRemove) {
        setTimeout((function() {
          var _ref;
          return (_ref = _this.parentNode) != null ? _ref.removeChild(_this) : void 0;
        }), 600);
      }
      return this;
    }
  };

}).call(this);
