applyExtra = (Batman) ->

  # `param` and `buildParams` stolen from jQuery
  #
  # jQuery JavaScript Library
  # http://jquery.com/
  #
  # Copyright 2011, John Resig
  # Dual licensed under the MIT or GPL Version 2 licenses.
  # http://jquery.org/license
  # Rails really doesn't like collection[0][rules], it wants collection[][rules],
  # so we will give it that.
  rbracket = /\[\]$/
  r20 = /%20/g
  param = (a) ->
    return a if typeof a is 'string'
    s = []
    add = (key, value) ->
      value = value() if typeof value is 'function'
      s[s.length] = encodeURIComponent(key) + "=" + encodeURIComponent(value)

    if Batman.typeOf(a) is 'Array'
      for value, name of a
        add name, value
    else
      for own k, v of a
        buildParams k, v, add
    s.join("&").replace r20, "+"

  buildParams = (prefix, obj, add) ->
    if Batman.typeOf(obj) is 'Array'
      for v, i in obj
        if rbracket.test(prefix)
          add prefix, v
        else
          buildParams prefix + "[]", v, add
    else if obj? and typeof obj == "object"
      for name of obj
        buildParams prefix + "[" + name + "]", obj[name], add
    else
      add prefix, obj

  Batman.mixin Batman.Encoders,
    railsDate:
      encode: (value) -> value
      decode: (value) ->
        a = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)Z$/.exec(value)
        if a
          return new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4], +a[5], +a[6]))
        else
          Batman.developer.warn "Unrecognized rails date #{value}!"
          return Date.parse(value)

  class Batman.RailsStorage extends Batman.RestStorage

    _addJsonExtension: (url) -> url + '.json'
    _serializeToFormData: (data) -> param(data)
    urlForRecord: -> @_addJsonExtension(super)
    urlForCollection: -> @_addJsonExtension(super)

    _errorsFrom422Response: (response) -> JSON.parse(response)

    @::before 'update', 'create', (env, next) ->
      env.options.data = @_serializeToFormData(env.options.data) if @serializeAsForm
      next()

    @::after 'update', 'create', ({error, record, response}, next) ->
      if error
        # Rails validation errors
        if error.request?.get('status') == 422
          try
            validationErrors = @_errorsFrom422Response(response)
          catch extractionError
            env.error = extractionError
            return next()

          for key, errorsArray of validationErrors
            for validationError in errorsArray
              record.get('errors').add(key, "#{key} #{validationError}")

          env = arguments[0]
          env.result = record
          env.error = record.get('errors')
          return next()
      next()

if (module? && require?)
  module.exports = applyExtra
else
  applyExtra(Batman)
