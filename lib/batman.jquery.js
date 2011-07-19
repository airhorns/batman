(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Batman.Request.prototype.send = function(data) {
    return jQuery.ajax(this.get('url'), {
      type: this.get('method'),
      dataType: this.get('type'),
      data: data || this.get('data'),
      username: this.get('username'),
      password: this.get('password'),
      beforeSend: __bind(function() {
        return this.loading(true);
      }, this),
      success: __bind(function(response) {
        this.set('response', response);
        return this.success(response);
      }, this),
      error: __bind(function(xhr, status, error) {
        this.set('response', error);
        return this.error(error);
      }, this),
      complete: __bind(function() {
        this.loading(false);
        return this.loaded(true);
      }, this)
    });
  };
}).call(this);
