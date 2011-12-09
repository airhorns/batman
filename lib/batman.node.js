(function() {
  var Batman, querystring, url;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  url = require('url');
  querystring = require('querystring');
  Batman = require('./batman');
  (require('./extras/batman.rails'))(Batman);
  (require('./extras/batman.i18n'))(Batman);
  Batman.mixin(Batman.Request.prototype, {
    getModule: function(protocol) {
      var requestModule;
      return requestModule = (function() {
        switch (protocol) {
          case 'http:':
          case 'https:':
            return require(protocol.slice(0, -1));
          case void 0:
            return require('http');
          default:
            throw "Unrecognized request protocol " + protocol;
        }
      })();
    },
    send: function(data) {
      var auth, body, getParams, options, path, protocol, request, requestModule, requestURL, _ref, _ref2;
      this.fire('loading');
      requestURL = url.parse(this.get('url', true));
      protocol = requestURL.protocol;
      requestModule = this.getModule(protocol);
      path = requestURL.pathname;
      if (this.get('method') === 'GET') {
        getParams = this.get('data');
        path += typeof data === 'string' ? getParams : querystring.stringify(Batman.mixin({}, requestURL.query, getParams));
      }
      options = {
        path: path,
        method: this.get('method'),
        port: requestURL.port,
        host: requestURL.hostname,
        headers: {}
      };
      auth = this.get('username') ? "" + (this.get('username')) + ":" + (this.get('password')) : requestURL.auth ? requestURL.auth : void 0;
      if (auth) {
        options.headers["Authorization"] = "Basic " + (new Buffer(auth).toString('base64'));
      }
      if ((_ref = this.get('method')) === "PUT" || _ref === "POST") {
        options.headers["Content-type"] = this.get('contentType');
        body = this.get('data');
        options.headers["Content-length"] = Buffer.byteLength(body);
      }
      request = requestModule.request(options, __bind(function(response) {
        data = [];
        response.on('data', function(d) {
          return data.push(d);
        });
        return response.on('end', __bind(function() {
          var status;
          data = data.join('');
          this.set('response', data);
          status = this.set('status', response.statusCode);
          if ((status >= 200 && status < 300) || status === 304) {
            this.fire('success', data);
          } else {
            request.request = this;
            this.fire('error', request);
          }
          return this.fire('loaded');
        }, this));
      }, this));
      request.on('error', __bind(function(error) {
        this.set('response', error);
        this.fire('error', error);
        return this.fire('loaded');
      }, this));
      if ((_ref2 = this.get('method')) === 'POST' || _ref2 === 'PUT') {
        request.write(body);
      }
      request.end();
      return request;
    }
  });
  module.exports = Batman;
}).call(this);
