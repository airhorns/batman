applyExtra = (Batman) ->
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

    _addJsonExtension: (options) ->
      options.url += '.json'

    optionsForRecord: (args..., callback) ->
      super args..., (err, options) ->
        @_addJsonExtension(options) unless err
        callback.call @, err, options

    optionsForCollection: (args..., callback) ->
      super args..., (err, options) ->
        @_addJsonExtension(options) unless err
        callback.call @, err, options

    @::after 'update', 'create', ([err, record, response, recordOptions]) ->
      # Rails validation errors
      if err
        if err.request.get('status') is 422
          for key, validationErrors of JSON.parse(err.request.get('response'))
            record.get('errors').add(key, "#{key} #{validationError}") for validationError in validationErrors
          return [record.get('errors'), record, response, recordOptions]
      return arguments[0]

if (module? && require?)
  module.exports = applyExtra
else
  applyExtra(Batman)
