(function() {
  var applyImplementation, querystring, url;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  url = require('url');
  querystring = require('querystring');
  applyImplementation = function(onto) {
    return onto.Request.prototype.send = function(data) {
      var options, path, protocol, request, requestModule, requestURL;
      requestURL = url.parse(this.get('url', true));
      protocol = requestURL.protocol;
      requestModule = (function() {
        switch (protocol) {
          case 'http:':
          case 'https:':
            return require(protocol.slice(0, -1));
          default:
            throw "Unrecognized request protocol " + protocol;
        }
      })();
      path = requestURL.pathname;
      if (this.get('method') === 'GET') {
        path += querystring.stringify(onto.extend({}, requestURL.query, this.get('data')));
      }
      options = {
        path: path,
        method: this.get('method'),
        port: requestURL.port,
        host: requestURL.hostname
      };
      request = requestModule.request(options, __bind(function(response) {
        data = [];
        response.on('data', function(d) {
          return data.push(d);
        });
        return response.on('end', __bind(function() {
          var status;
          data = data.join();
          this.set('response', data);
          status = response.statusCode;
          if ((status >= 200 && status < 300) || status === 304) {
            return this.success(data);
          } else {
            return this.error(data);
          }
        }, this));
      }, this));
      if (requestURL.auth) {
        request.setHeader("Authorization", new Buffer(requestURL.auth).toString('base64'));
      }
      if (this.get('method' === 'POST')) {
        request.write(JSON.stringify(this.get('data')));
      }
      request.end();
      request.on('error', function(e) {
        this.set('response', error);
        return this.error(error);
      });
      return request;
    };
  };
  if (typeof Batman !== "undefined" && Batman !== null) {
    applyImplementation(Batman);
  }
  if (global.Batman != null) {
    applyImplementation(global.Batman);
  }
  exports.apply = applyImplementation;
}).call(this);
