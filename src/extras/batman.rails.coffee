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
