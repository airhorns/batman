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

    _addJsonExtension: ([err, url]) ->
      url += '.json' unless err
      [err, url]

    urlForRecord: -> @_addJsonExtension(super)
    urlForCollection: -> @_addJsonExtension(super)

    @::after 'update', 'create', ({error, record, response}, next) ->
      # Rails validation errors
      if error
        if error.request?.get('status') == 422
          for key, validationErrors of JSON.parse(response)
            record.get('errors').add(key, "#{key} #{validationError}") for validationError in validationErrors
          arguments[0].result = record
          return next(record.get('errors'))
      next()

if (module? && require?)
  module.exports = applyExtra
else
  applyExtra(Batman)
