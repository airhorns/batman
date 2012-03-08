
  Batman.Request.prototype.send = function(data) {
    var options, _ref;
    var _this = this;
    options = {
      url: this.get('url'),
      type: this.get('method'),
      dataType: this.get('type'),
      data: data || this.get('data'),
      username: this.get('username'),
      password: this.get('password'),
      headers: this.get('headers'),
      beforeSend: function() {
        return _this.fire('loading');
      },
      success: function(response, textStatus, xhr) {
        _this.set('status', xhr.status);
        _this.set('response', response);
        return _this.fire('success', response);
      },
      error: function(xhr, status, error) {
        _this.set('status', xhr.status);
        _this.set('response', xhr.responseText);
        xhr.request = _this;
        return _this.fire('error', xhr);
      },
      complete: function() {
        return _this.fire('loaded');
      }
    };
    if ((_ref = this.get('method')) === 'PUT' || _ref === 'POST') {
      if (!this.hasFileUploads()) {
        options.contentType = this.get('contentType');
      } else {
        options.contentType = false;
        options.processData = false;
        options.data = this.constructor.objectToFormData(options.data);
      }
    }
    return jQuery.ajax(options);
  };

  Batman.mixins.animation = {
    show: function(addToParent) {
      var jq, show, _ref, _ref2;
      jq = $(this);
      show = function() {
        return jq.show(600);
      };
      if (addToParent) {
        if ((_ref = addToParent.append) != null) _ref.appendChild(this);
        if ((_ref2 = addToParent.before) != null) {
          _ref2.parentNode.insertBefore(this, addToParent.before);
        }
        jq.hide();
        setTimeout(show, 0);
      } else {
        show();
      }
      return this;
    },
    hide: function(removeFromParent) {
      var _this = this;
      $(this).hide(600, function() {
        var _ref;
        if (removeFromParent) {
          if ((_ref = _this.parentNode) != null) _ref.removeChild(_this);
        }
        return Batman.DOM.didRemoveNode(_this);
      });
      return this;
    }
  };
