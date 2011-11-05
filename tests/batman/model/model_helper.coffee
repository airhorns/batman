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
      @storage[@modelKey(record) + id] = record.toJSON()
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  create: (record, options, callback) ->
    id = record.set('id', @counter++)
    if id
      @storage[@modelKey(record) + id] = record.toJSON()
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  read: (record, options, callback) ->
    id = record.get('id')
    if id
      attrs = @storage[@modelKey(record) + id]
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

    callback(undefined, @getRecordFromData(record) for record in records)

  destroy: (record, options, callback) ->
    id = record.get('id')
    if id
      key = @modelKey(record) + id
      if @storage[key]
        delete @storage[key]
        callback(undefined, record)
      else
        callback(new Error("Can't delete nonexistant record!"), record)
    else
      callback(new Error("Can't delete record without an primary key!"), record)

class AsyncTestStorageAdapter extends TestStorageAdapter
  for k in ['update', 'create', 'read', 'readAll', 'destroy']
    do (k) =>
      AsyncTestStorageAdapter[k] = ->
        setTimeout (=> TestStorageAdapter[k].apply(@, arguments)), 0

createStorageAdapter = (modelClass, adapterClass, data = {}) ->
  adapter = new adapterClass(modelClass)
  adapter.storage = data
  modelClass.persist adapter
  adapter

if typeof exports is 'undefined'
  window.TestStorageAdapter = TestStorageAdapter
  window.AsyncTestStorageAdapter = AsyncTestStorageAdapter
  window.createStorageAdapter = createStorageAdapter
else
  exports.TestStorageAdapter = TestStorageAdapter
  exports.AsyncTestStorageAdapter = AsyncTestStorageAdapter
  exports.createStorageAdapter = createStorageAdapter
