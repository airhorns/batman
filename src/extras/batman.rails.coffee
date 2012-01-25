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

  numericKeys = [1, 2, 3, 4, 5, 6, 7, 10, 11]
  date_re = ///
    ^
    (\d{4}|[+\-]\d{6})  # 1 YYYY
    (?:-(\d{2})         # 2 MM
    (?:-(\d{2}))?)?     # 3 DD
    (?:
      T(\d{2}):         # 4 HH
      (\d{2})           # 5 mm
      (?::(\d{2})       # 6 ss
      (?:\.(\d{3}))?)?  # 7 msec
      (?:(Z)|           # 8 Z
        ([+\-])         # 9 ±
        (\d{2})         # 10 tzHH
        (?::(\d{2}))?   # 11 tzmm
      )?
    )?
    $
  ///

  Batman.mixin Batman.Encoders,
    railsDate:
      defaultTimezoneOffset: (new Date()).getTimezoneOffset()
      encode: (value) -> value
      decode: (value) ->
        # Thanks to https://github.com/csnover/js-iso8601 for the majority of this algorithm.
        # MIT Licensed
        if value?
          if (obj = date_re.exec(value))
            # avoid NaN timestamps caused by “undefined” values being passed to Date.UTC
            for key in numericKeys
              obj[key] = +obj[key] or 0

            # allow undefined days and months
            obj[2] = (+obj[2] || 1) - 1;
            obj[3] = +obj[3] || 1;

            # process timezone by adjusting minutes
            if obj[8] != "Z" and obj[9] != undefined
              minutesOffset = obj[10] * 60 + obj[11]
              minutesOffset = 0 - minutesOffset  if obj[9] == "+"
            else
              minutesOffset = Batman.Encoders.railsDate.defaultTimezoneOffset
            return new Date(Date.UTC(obj[1], obj[2], obj[3], obj[4], obj[5] + minutesOffset, obj[6], obj[7]))
          else
            Batman.developer.warn "Unrecognized rails date #{value}!"
            return Date.parse(value)

  class Batman.RailsStorage extends Batman.RestStorage

    _serializeToFormData: (data) -> param(data)

    urlForRecord: -> @_addJsonExtension(super)
    urlForCollection: -> @_addJsonExtension(super)

    _addJsonExtension: (url) ->
      if url.indexOf('?') isnt -1 or url.substr(-5, 5) is '.json'
        return url
      url + '.json'

    _errorsFrom422Response: (response) -> JSON.parse(response)

    @::before 'update', 'create', (env, next) ->
      if @serializeAsForm && !env.options.formData
        env.options.data = @_serializeToFormData(env.options.data)
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
              record.get('errors').add(key, validationError)

          env = arguments[0]
          env.result = record
          env.error = record.get('errors')
          return next()
      next()

if (module? && require?)
  module.exports = applyExtra
else
  applyExtra(Batman)
