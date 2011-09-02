class TestStorageAdapter extends Batman.StorageAdapter
  constructor: ->
    super
    @counter = 10
    @storage = {}
    @lastQuery = false
    @create(new @model, {}, ->)

  update: (record, options, callback) ->
    id = record.get('id')
    if id
      @storage[@modelKey + id] = record.toJSON()
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  create: (record, options, callback) ->
    id = record.set('id', @counter++)
    if id
      @storage[@modelKey + id] = record.toJSON()
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  read: (record, options, callback) ->
    id = record.get('id')
    if id
      attrs = @storage[@modelKey + id]
      if attrs
        record.fromJSON(attrs)
        callback(undefined, record)
      else
        callback(new Error("Couldn't find record!"))
    else
      callback(new Error("Couldn't get record primary key."))

  readAll: (_, options, callback) ->
    records = []
    for storageKey, data of @storage
      match = true
      for k, v of options
        if data[k] != v
          match = false
          break
      records.push data if match

    callback(undefined, @getRecordsFromData(records))

  destroy: (record, options, callback) ->
    id = record.get('id')
    if id
      key = @modelKey + id
      if @storage[key]
        delete @storage[key]
        callback(undefined, record)
      else
        callback(new Error("Can't delete nonexistant record!"), record)
    else
      callback(new Error("Can't delete record without an primary key!"), record)

if typeof exports is 'undefined'
  window.TestStorageAdapter = TestStorageAdapter
else
  exports.TestStorageAdapter = TestStorageAdapter
