###
# batman.coffee
# batman.js
# 
# Created by Nicholas Small
# Copyright 2011, JadedPixel Technologies, Inc.
###

# The global namespace, the Batman function will also create also create a new
# instance of Batman.Object and mixin all arguments to it.
Batman = (mixins...) ->
  new Batman.Object mixins...

# Batman.typeOf returns a string that contains the built-in class of an object
# like String, Array, or Object. Note that only Object will be returned for
# the entire prototype chain.
Batman.typeOf = $typeOf = (object) ->
  _objectToString.call(object).slice(8, -1)
# Cache this function to skip property lookups.
_objectToString = Object.prototype.toString

###
# Mixins
###

# Batman.mixin will apply every key from every argument after the first to the
# first argument. If a mixin has an `initialize` method, it will be called in
# the context of the `to` object and won't be applied.
Batman.mixin = $mixin = (to, mixins...) ->
  set = to.set
  hasSet = typeof set is 'function'
  
  for mixin in mixins
    continue if $typeOf(mixin) isnt 'Object'
    
    for key, value of mixin
      continue if key in ['initialize', 'uninitialize', 'prototype']
      if hasSet then set.call(to, key, value) else to[key] = value
  
  to

# Batman.unmixin will remove every key from every argument after the first
# from the first argument. If a mixin has a `deinitialize` method, it will be
# called in the context of the `from` object and won't be removed.
Batman.unmixin = $unmixin = (from, mixins...) ->
  for mixin in mixins
    for key of mixin
      continue if key in ['initialize', 'uninitialize']
      
      from[key] = null
      delete from[key]
    
    if typeof mixin.deinitialize is 'function'
      mixin.deinitialize.call from
  
  from

Batman._initializeObject = (object) ->
  if object.prototype and object._batman?.__initClass__ isnt @
    object._batman = {__initClass__: @}
  else unless object.hasOwnProperty '_batman'
    object._batman = {}

Batman._findName = (f, context) ->
  if not f.displayName
    for key, value of context
      if value is f
        f.displayName = key
        break
  
  f.displayName


class Batman.Hash
  constructor: ->
    @_storage = {}
  hasKey: (key) ->
    typeof @get(key) isnt 'undefined'
  get: (key) ->
    if matches = @_storage[key]
      for [obj,v] in matches
        return v if @equality(obj, key)
  set: (key, val) ->
    matches = @_storage[key] ||= []
    for match in matches
      pair = match if @equality(match[0], key)
    unless pair
      pair = [key]
      matches.push(pair)
    pair[1] = val
  remove: (key) ->
    if matches = @_storage[key]
      for [obj,v], index in matches
        if @equality(obj, key)
          matches.splice(index,1)
          return obj
  equality: (lhs, rhs) ->
    if typeof lhs.isEqual is 'function'
      lhs.isEqual rhs
    else if typeof rhs.isEqual is 'function'
      rhs.isEqual lhs
    else
      lhs is rhs
  each: (iterator) ->
    for key, values of @_storage
      iterator(obj, value) for [obj, value] in values
  keys: ->
    result = []
    @each (obj) -> result.push obj
    result
    
class Batman.Set
  constructor: ->
    @_storage = new Batman.Hash
  has: (item) ->
    @_storage.hasKey item
  add: (item) ->
    @_storage.set item, true
    item
  remove: (item) ->
    @_storage.remove item
  each: (iterator) ->
    @_storage.each (key, value) -> iterator(key)
  toArray: ->
    @_storage.keys()

class Batman.SortableSet extends Batman.Set
  constructor: (index) ->
    super
    @_indexes = {}
    @addIndex(index)
  add: (item) ->
    super
    @_reIndex()
    item
  remove: (item) ->
    super
    @_reIndex()
    item
  addIndex: (keypath) ->
    @_reIndex(keypath)
    @activeIndex = keypath
  removeIndex: (keypath) ->
    @_indexes[keypath] = null
    delete @_indexes[keypath]
    keypath
  each: (iterator) ->
    iterator(el) for el in toArray()
  toArray: ->
    ary = @_indexes[@activeIndex] ? ary : super
  _reIndex: (index) ->
    if index
      [keypath, ordering] = index.split ' '
      ary = Batman.Set.prototype.toArray.call @
      @_indexes[index] = ary.sort (a,b) ->
        valueA = (new Batman.Keypath(a, keypath)).resolve()?.valueOf()
        valueB = (new Batman.Keypath(b, keypath)).resolve()?.valueOf()
        [valueA, valueB] = [valueB, valueA] if ordering?.toLowerCase() is 'desc'
        if valueA < valueB then -1 else if valueA > valueB then 1 else 0
    else
      @_reIndex(index) for index of @_indexes


###
# Batman.Keypath
# A keypath has a base object and one or more key segments
# which represent a path to a target value.
###

class Batman.Keypath
  constructor: (@base, @segments) ->
    @segments = @segments.split('.') if $typeOf(@segments) is 'String'
  
  path: ->
    @segments.join '.'
    
  depth: ->
    @segments.length
  
  slice: (begin, end) ->
    base = @base
    for segment in @segments.slice(0, begin)
      return unless base = base?[segment]
    
    new Batman.Keypath base, @segments.slice(begin, end)
  
  finalPair: ->
    @slice(-1)
  
  eachPair: (callback) ->
    base = @base
    for segment, index in @segments
      return unless nextBase = base?[segment]
      callback(new Batman.Keypath(base, segment), index)
      base = nextBase
  
  resolve: ->
    switch @depth()
      when 0 then @base
      when 1 then @base[@segments[0]]
      else @finalPair()?.resolve()
  
  assign: (val) ->
    switch @depth()
      when 0 then return
      when 1 then @base[@segments[0]] = val
      else @finalPair().assign(val)
  
  remove: ->
    switch @depth()
      when 0 then return
      when 1
        @base[@segments[0]] = null
        delete @base[@segments[0]]
        return
      else @finalPair().remove()
  
  isEqual: (other) ->
    @base is other.base and @path() is other.path()
    

class Batman.Trigger
  @populateKeypath: (keypath, callback) ->
    keypath.eachPair (minimalKeypath, index) ->
      return unless minimalKeypath.base.observe
      Batman.Observable.initialize.call minimalKeypath.base
      new Batman.Trigger(minimalKeypath.base, minimalKeypath.segments[0], keypath, callback)
  
  constructor: (@base, @key, @targetKeypath, @callback) ->
    for base in [@base, @targetKeypath.base]
      return unless base.observe
      Batman.Observable.initialize.call base
    # FIXME - Batman.Trigger should not interact directly with Observables' TriggerSets
    (@base._batman.outboundTriggers[@key] ||= new Batman.TriggerSet()).add @
    (@targetKeypath.base._batman.inboundTriggers[@targetKeypath.path()] ||= new Batman.TriggerSet()).add @
  
  isEqual: (other) ->
    other instanceof Batman.Trigger and
    @base is other.base and
    @key is other.key and 
    @targetKeypath.isEqual(other.targetKeypath) and
    @callback is other.callback
  
  isInKeypath: ->
    targetBase = @targetKeypath.base
    for segment in @targetKeypath.segments
      return true if targetBase is @base and segment is @key
      targetBase = targetBase?[segment]
      return false unless targetBase
  
  hasActiveObserver: ->
    @targetKeypath.base.observesKeyWithObserver(@targetKeypath.path(), @callback)
    
  remove: ->
    # FIXME - Batman.Trigger should not interact directly with Observables' TriggerSets
    if outboundSet = @base._batman?.outboundTriggers[@key]
      outboundSet.remove @
    if inboundSet = @targetKeypath.base._batman?.inboundTriggers[@targetKeypath.path()]
      inboundSet.remove @


class Batman.TriggerSet
  constructor: ->
    @triggers = new Batman.Set
    @oldValues = new Batman.Hash
  
  add: (trigger) ->
    @triggers.add trigger
  
  remove: (trigger) ->
    @triggers.remove(trigger)
  
  keypaths: ->
    result = new Batman.Set
    @triggers.each (trigger) ->
      result.add trigger.targetKeypath
    result
  
  rememberOldValues: ->
    oldValues = @oldValues = new Batman.Hash
    @keypaths().each (keypath) ->
      oldValues.set keypath, keypath.resolve()
    
  fireAll: ->
    @oldValues.each (keypath, oldValue) ->
      keypath.base.fire keypath.path(), keypath.resolve(), oldValue
  
  refreshKeypathsWithTriggers: ->
    @triggers.each (trigger) ->
      Batman.Trigger.populateKeypath(trigger.targetKeypath, trigger.callback)
  
  removeTriggersNotInKeypath: ->
    for trigger in @triggers.toArray()
      trigger.remove() unless trigger.isInKeypath()
  
  removeTriggersWithInactiveObservers: ->
    for trigger in @triggers.toArray()
      trigger.remove() unless trigger.hasActiveObserver()
    
###
# Batman.Observable
# Batman.Observable is a generic mixin that can be applied to any object in
# order to make that object bindable. It is applied by default to every
# instance of Batman.Object and subclasses.
###

Batman.Observable = {
  initialize: ->
    Batman._initializeObject @
    @_batman.observers ||= {}
    @_batman.outboundTriggers ||= {}
    @_batman.inboundTriggers ||= {}
    @_batman.preventCounts ||= {}
  
  rememberingOutboundTriggerValues: (key, callback) ->
    Batman.Observable.initialize.call @
    if triggers = @_batman.outboundTriggers[key]
      triggers.rememberOldValues()
    callback()
  
  keypath: (string) ->
    new Batman.Keypath(@, string)
  
  get: (key) ->
    @keypath(key).resolve()
  
  set: (key, val) ->
    minimalKeypath = @keypath(key).finalPair()
    oldValue = minimalKeypath.resolve()
    minimalKeypath.base.rememberingOutboundTriggerValues minimalKeypath.segments[0], ->
      minimalKeypath.assign(val)
      minimalKeypath.base.fire(minimalKeypath.segments[0], val, oldValue)
    val
  
  unset: (key) ->
    minimalKeypath = @keypath(key).finalPair()
    oldValue = minimalKeypath.resolve()
    minimalKeypath.base.rememberingOutboundTriggerValues minimalKeypath.segments[0], ->
      minimalKeypath.remove()
      minimalKeypath.base.fire(minimalKeypath.segments[0], `void 0`, oldValue)
    return
  
  # Pass a key and a callback. Whenever the value for that key changes, your
  # callback will be called in the context of the original object.
  observe: (key, fireImmediately..., callback) ->
    Batman.Observable.initialize.call @
    fireImmediately = fireImmediately[0]?
    
    keypath = @keypath(key)
    currentVal = keypath.resolve()
    observers = @_batman.observers[key] ||= []
    observers.push callback
    
    Batman.Trigger.populateKeypath(keypath, callback) if keypath.depth() > 1
    
    callback.call(@, currentVal, currentVal) if fireImmediately
    @
  
  # You normally shouldn't call this directly. It will be invoked by `set`
  # to inform all observers for `key` that `value` has changed.
  fire: (key, value, oldValue) ->
    return unless @allowed(key)
    # We don't need to call Batman.Observable.initialize because @allowed calls it.
    
    args = [value]
    args.push oldValue if typeof oldValue isnt 'undefined'
    
    for observers in [@_batman.observers[key], @constructor::_batman?.observers?[key]]
      continue unless observers
      for callback in observers
        callback.apply @, args
    
    if outboundTriggers = @_batman.outboundTriggers[key]
      outboundTriggers.fireAll()
      outboundTriggers.refreshKeypathsWithTriggers()
        
    @_batman.inboundTriggers[key]?.removeTriggersNotInKeypath()
        
    @
  
  observesKeyWithObserver: (key, observer) ->
    return false unless @_batman?.observers?[key]
    for o in @_batman.observers[key]
      return true if o is observer
    return false
  
  # Forget removes an observer from an object. If the callback is passed in, 
  # its removed. If no callback but a key is passed in, all the observers on
  # that key are removed. If no key is passed in, all observers are removed.
  forget: (key, callback) ->
    Batman.Observable.initialize.call @
    
    if key
      if callback
        if keyObservers = @_batman.observers[key]
          callbackIndex = keyObservers.indexOf(callback)
          keyObservers.splice(callbackIndex, 1) if callbackIndex isnt -1
        if triggersForKey = @_batman.inboundTriggers[key]
          triggersForKey.removeTriggersWithInactiveObservers()
      else
        @forget key, o for o in @_batman.observers[key]
    else
      @forget k for k of @_batman.observers
    @
  
  # Prevent allows you to prevent a given binding from firing. You can
  # nest prevent counts, so three calls to prevent means you need to
  # make three calls to allow before you can fire observers again.
  prevent: (key) ->
    Batman.Observable.initialize.call @
    
    counts = @_batman.preventCounts
    counts[key] ||= 0
    counts[key]++
    @
  
  # Unblocks a property for firing observers. Every call to prevent
  # must have a matching call to allow.
  allow: (key) ->
    Batman.Observable.initialize.call @
    
    counts = @_batman.preventCounts
    counts[key]-- if counts[key] > 0
    @
  
  # Returns a boolean whether or not the property is currently allowed
  # to fire its observers.
  allowed: (key) ->
    Batman.Observable.initialize.call @
    !(@_batman.preventCounts?[key] > 0)
}

###
# Batman.Event
# Another generic mixin that simply allows an object to emit events. All events
# require an object that is observable. If you don't want to use an emitter,
# you can use the $event functions to create ephemeral objects internally.
###

Batman.EventEmitter = {
  # An event is a convenient observer wrapper. Wrap any function in an event.
  # Whenever you call that function, it will cause this object to fire all
  # the observers for that event. There is also some syntax sugar so you can
  # register an observer simply by calling the event with a function argument.
  event: (key, callback) ->
    if not callback and $typeOf(key) isnt 'String'
      callback = key
      key = null
    
    # The callback eater assists in creating events from two places: a class
    # definition where a bug in CoffeeScript requires you to wrap the key in
    # parenthesis and from outside a class definition, where you can pass in
    # the callback directly.
    callbackEater = (callback, context) ->
      f = (observer) ->
        if not @observe
          throw "EventEmitter object needs to be observable."
        
        key ||= Batman._findName(f, @)
        
        # Pass a function to the event to register it as an observer.
        if typeof observer is 'function'
          @observe key, observer
          observer.apply @, f._firedArgs if f.isOneShot and f.fired
        
        # Otherwise, calling the event will cause it to fire. Any
        # arguments you pass will be passed to your wrapped function.
        else if @allowed key
          return false if f.isOneShot and f.fired
          
          value = callback?.apply @, arguments
          
          # Observers will only fire if the result of the event is not false.
          if value isnt false
            value = arguments[0] if typeof value is 'undefined'
            value = null if typeof value is 'undefined'
            
            # Observers will be called with the result of the event function,
            # followed by the original arguments.
            f._firedArgs = [value].concat arguments...
            args = Array.prototype.slice.call f._firedArgs
            args.unshift key
            
            @fire.apply @, args
            f.fired = yes if f.isOneShot
          
          value
        else
          false
      
      f = f.bind(context) if context
      @[key] = f if $typeOf(key) is 'String'
      
      # This could be its own mixin but is kept here for brevity.
      $mixin f,
        isEvent: yes
        action: callback
        isOneShot: callbackEater.isOneShot
    
    if typeof callback is 'function' then callbackEater.call(@, callback) else callbackEater
  
  # Use a one shot event for something that only fires once. Any observers
  # added after it has already fired will simply be executed immediately.
  eventOneShot: (callback) ->
    $mixin Batman.EventEmitter.event.apply(@, arguments),
      isOneShot: yes
}

# $event lets you create an ephemeral event without needing an EventEmitter.
# If you already have an EventEmitter object, you should call .event() on it.
$event = (callback) ->
  context = new Batman.Object
  context.event('_event')(callback, context)

$eventOneShot = (callback) ->
  context = new Batman.Object
  context.eventOneShot('_event')(callback, context)

###
# Batman.Object
# The base class for all other Batman objects. It is not abstract. 
###

class Batman.Object
  # Setting `isGlobal` to true will cause the class name to be defined on the
  # global object. For example, Batman.Model will be aliased to window.Model.
  # You should use this sparingly; it's mostly useful for debugging.
  @global: (isGlobal) ->
    return if isGlobal is false
    global[@name] = @
  
  @property: (foo) ->
    {} #FIXME
  
  # Apply mixins to this subclass.
  @mixin: (mixins...) ->
    $mixin @, mixins...
  
  # Apply mixins to instances of this subclass.
  mixin: (mixins...) ->
    $mixin @, mixins...
  
  constructor: (mixins...) ->
    Batman._initializeObject @
    @mixin mixins...
  
  # Make every subclass and their instances observable.
  @mixin Batman.Observable, Batman.EventEmitter
  @::mixin Batman.Observable, Batman.EventEmitter

###
# Batman.Request
# A normalizer for XHR requests.
###

class Batman.Request extends Batman.Object
  url: ''
  data: ''
  method: 'get'
  
  response: null
  
  # After the URL gets set, we'll try to automatically send
  # your request after a short period. If this behavior is
  # not desired, use @cancel() after setting the URL.
  @::observe 'url', ->
    @_autosendTimeout = setTimeout (=> @send()), 0
  
  loading: @event ->
  loaded: @event ->
  
  success: @event ->
  error: @event ->
  
  send: (data) -> # Defined in your dependency file
  
  cancel: ->
    clearTimeout(@_autosendTimeout) if @_autosendTimeout

###
# Batman.App
###

class Batman.App extends Batman.Object
  # Require path tells the require methods which base directory to look in.
  @requirePath: ''
  
  # The require class methods (`controller`, `model`, `view`) simply tells
  # your app where to look for coffeescript source files. This
  # implementation may change in the future.
  @require: (path, names...) ->
    base = @requirePath + path
    for name in names
      @prevent 'run'
      
      path = base + '/' + name + '.coffee' # FIXME: don't hardcode this
      new Batman.Request
        url: path
        type: 'html'
        success: (response) =>
          CoffeeScript.eval response
          # FIXME: under no circumstances should we be compiling coffee in
          # the browser. This can be fixed via a real deployment solution
          # to compile coffeescripts, such as Sprockets.
          
          @allow 'run'
          @run() # FIXME: this should only happen if the client actually called run.
    @
  
  @controller: (names...) ->
    @require 'controllers', names...
  
  @model: (names...) ->
    @require 'models', names...
  
  @view: (names...) ->
    @require 'views', names...
  
  # Layout is your base view that other views can be yielded into. The
  # default behavior is that when you call `app.run()`, a new view will
  # be created for the layout using the `document` node as its content.
  # User `MyApp.layout = null` to turn off the default behavior.
  @layout: undefined
  
  # Call `MyApp.run()` to actually start up your app. Batman level
  # initializers will be run to bootstrap your application.
  @run: @eventOneShot ->
    return false if @hasRun
    Batman.currentApp = @
    
    if typeof @layout is 'undefined'
      @set 'layout', new Batman.View node: document
    
    #@startRouting()
    @hasRun = yes

###
# Routing
###

# route matching courtesy of Backbone
namedParam = /:([\w\d]+)/g
splatParam = /\*([\w\d]+)/g
namedOrSplat = /[:|\*]([\w\d]+)/g
escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

Batman.Route = {
  isRoute: yes
  
  toString: ->
    "route: #{@pattern} #{@action}"
}

$mixin Batman,
  HASH_PATTERN: '#!'
  _routes: []
  
  route: (pattern, callback) ->
    callbackEater = (callback) ->
      f = ->
        context = f.context || @
        if context and context.sharedInstance
          context = context.get 'sharedInstance'
        
        if context and context.dispatch
          context.dispatch f, @
        else
          f.action.apply context, arguments
      
      $mixin f, Batman.Route,
        pattern: pattern
        action: callback
        context: callbackEater.context
      
      Batman._routes.push f
      f
    
    callbackEater.context = @
    if typeof callback is 'function' then callbackEater(callback) else callbackEater
  
  redirect: (urlOrFunction) ->
    url = if urlOrFunction?.isRoute then urlOrFunction.pattern else urlOrFunction
    window.location.hash = "#{Batman.HASH_PATTERN}#{url}"

Batman.Object.route = $route = Batman.route
Batman.Object.redirect = $redirect = Batman.redirect

$mixin Batman.App,
  startRouting: ->
    return if typeof window is 'undefined'
    return if not Batman._routes.length
    
    parseUrl = =>
      hash = window.location.hash.replace(Batman.HASH_PATTERN, '')
      return if hash is @_cachedRoute
      
      @_cachedRoute = hash
      @dispatch hash
    
    window.location.hash = "#{Batman.HASH_PATTERN}/" if not window.location.hash
    setTimeout(parseUrl, 0)
    
    if 'onhashchange' of window
      @_routeHandler = parseUrl
      window.addEventListener 'hashchange', parseUrl
    else
      @_routeHandler = setInterval(parseUrl, 100)
  
  root: (callback) ->
    $route '/', callback

###
# Batman.Controller
###

class Batman.Controller extends Batman.Object
  # FIXME: should these be singletons?
  @sharedInstance: ->
    @_sharedInstance = new @ if not @_sharedInstance
    @_sharedInstance
  
  dispatch: (route, params...) ->
    @_actedDuringAction = no
    
    result = route.action.call @, params...
    key = Batman._findName route, @
    
    if not @_actedDuringAction
      new Batman.View source: ""
    
    delete @_actedDuringAction
  
  redirect: (url) ->
    @_actedDuringAction = yes
    $redirect url
  
  render: (options = {}) ->
    @_actedDuringAction = yes
    
    if not options.view
      options.source = 'views/' + helpers.underscore(@constructor.name.replace('Controller', '')) + '/' + @_currentAction + '.html'
      options.view = new Batman.View(options)
    
    if view = options.view
      view.context = global
      
      m = {}
      push = (key, value) ->
        ->
          Array.prototype.push.apply @, arguments
          view.context.fire(key, @)
      
      for own key, value of @
        continue if key.substr(0,1) is '_'
        m[key] = value
        if typeOf(value) is 'Array'
          value.push = push(key, value)
      
      $mixin global, m
      view.ready ->
        Batman.DOM.contentFor('main', view.get('node'))
        Batman.unmixin(global, m)

###
# Batman.DataStore
###

class Batman.DataStore extends Batman.Object
  constructor: (model) ->
    @model = model
    @_data = {}
  
  set: (id, json) ->
    if not id
      id = model.getNewId()
    
    @_data[''+id] = json
  
  get: (id) ->
    record = @_data[''+id]
    
    response = {}
    response[record.id] = record
    
    response
  
  all: ->
    Batman.mixin {}, @_data
  
  query: (params) ->
    results = {}
    
    for id, json of @_data
      match = yes
      
      for key, value of params
        if json[key] isnt value
          match = no
          break
      
      if match
        results[id] = json
      
    results

###
# Batman.Model
###

class Batman.Model extends Batman.Object
  @_makeRecords: (ids) ->
    for id, json of ids
      r = new @ {id: id}
      $mixin r, json

  @hasMany: (relation) ->
    model = helpers.camelize(helpers.singularize(relation))
    inverse = helpers.camelize(@name, yes)

    @::[relation] = Batman.Object.property ->
      query = model: model
      query[inverse + 'Id'] = ''+@id

      App.constructor[model]._makeRecords(App.dataStore.query(query))

  @hasOne: (relation) ->


  @belongsTo: (relation) ->
    model = helpers.camelize(helpers.singularize(relation))
    key = helpers.camelize(model, yes) + 'Id'

    @::[relation] = Batman.Object.property (value) ->
      if arguments.length
        @set key, if value and value.id then ''+value.id else ''+value

      App.constructor[model]._makeRecords(App.dataStore.query({model: model, id: @[key]}))[0]
  
  @persist: (mixin) ->
    return if mixin is false

    if not @dataStore
      @dataStore = new Batman.DataStore @

    if mixin is Batman
      # FIXME
    else
      Batman.mixin @, mixin
  
  @all: @property ->
    @_makeRecords @dataStore.all()
  
  @first: @property ->
    @_makeRecords(@dataStore.all())[0]
  
  @last: @property ->
    array = @_makeRecords(@dataStore.all())
    array[array.length - 1]
  
  @find: (id) ->
    console.log @dataStore.get(id)
    @_makeRecords(@dataStore.get(id))[0]
  
  @create: Batman.Object.property ->
    new @
  
  @destroyAll: ->
    all = @get 'all'
    for r in all
      r.destroy()
  
  constructor: ->
    @_data = {}
    super
  
  id: ''
  
  isEqual: (rhs) ->
    @id is rhs.id
  
  set: (key, value) ->
    @_data[key] = super
  
  save: ->
    model = @constructor
    model.dataStore.set(@id, @toJSON())
    # model.dataStore.needsSync()
    
    @
  
  destroy: =>
    return if typeof @id is 'undefined'
    App.dataStore.unset(@id)
    App.dataStore.needsSync()
    
    @constructor.fire('all', @constructor.get('all'))
    @
  
  toJSON: ->
    @_data
  
  fromJSON: (data) ->
    Batman.mixin @, data

###
# Batman.View
# A few can function two ways: a mechanism to load and/or parse html files
# or a root of a subclass hierarchy to create rich UI classes, like in Cocoa.
###

class Batman.View extends Batman.Object
  # Set the source attribute to an html file to have that file loaded.
  source: ''
  
  # Set the html to a string of html to have that html parsed.
  html: ''
  
  # Set an existing DOM node to parse immediately.
  node: null
  
  contentFor: null
  
  # Fires once a node is parsed.
  ready: @eventOneShot ->
  
  @::observe 'source', ->
    setTimeout @reloadSource, 0
  
  reloadSource: =>
    return if not @source
    
    new Batman.Request
      url: "views/#{@source}"
      type: 'html'
      success: (response) ->
        @set 'html', response
  
  @::observe 'html', (html) ->
    if @contentFor
      # FIXME: contentFor
    else
      node = @node || document.createElement 'div'
      node.innerHTML = html
      
      @set 'node', node if @node isnt node
  
  @::observe 'node', (node) ->
    @ready.fired = false
    
    if @_renderer
      @_renderer.forgetAll()
    
    if node
      @_renderer = new Batman.Renderer node, => @ready()

###
# DOM Helpers
###

# Batman.Renderer will take a node and parse all recognized data
# attributes out of it and its children. It is a continuation
# style parser, designed not to blog for longer than 50ms at a
# time if the document fragment is particularly long.
class Batman.Renderer extends Batman.Object
  constructor: (@node, @callback) ->
    super
    @contexts = [window, Batman.currentApp, @contextObject = new Batman.Object]
    
    setTimeout @start, 0
  
  start: =>
    @startTime = new Date
    @parseNode @node
  
  resume: =>
    @startTime = new Date
    @parseNode @resumeNode
  
  finish: ->
    @startTime = null
    @callback()
  
  forgetAll: ->
    
  regexp = /data\-(.*)/
  
  parseNode: (node) ->
    if new Date - @startTime > 50
      @resumeNode = node
      setTimeout @resume, 0
      return
    
    if node.getAttribute
      @contextObject.node = node
      contexts = @contexts
      
      for attr in node.attributes
        name = attr.nodeName.match(regexp)?[1]
        continue if not name
        
        if (index = name.indexOf('-')) is -1
          Batman.DOM.readers[name]?(node, attr.value, contexts)
        else
          Batman.DOM.attrReaders[name.substr(0, index)]?(node, name.substr(index + 1), attr.value, contexts)
        
    
    if (nextNode = @nextNode(node)) then @parseNode(nextNode) else @finish
  
  nextNode: (node) ->
    children = node.childNodes
    return children[0] if children?.length
    
    node.onParseExit?()
    
    sibling = node.nextSibling
    return sibling if sibling
    
    nextParent = node
    while nextParent = nextParent.parentNode
      nextParent.onParseExit?()
      parentSibling = nextParent.nextSibling
      return parentSibling if parentSibling
    
    return
    

matchContext = (contexts, key) ->
  base = key.split('.')[0]
  i = contexts.length
  while i--
    context = contexts[i]
    return context if typeof context[base] isnt 'undefined'

Batman.DOM = {
  readers: {
    bind: (node, key, contexts) ->
      context = matchContext contexts, key
      shouldSet = yes
      
      if Batman.DOM.nodeIsEditable(node)
        Batman.DOM.events.change node, ->
          shouldSet = no
          context.set key, node.value
          shouldSet = yes
      
      context?.observe key, yes, observer = (value) ->
        if shouldSet
          Batman.DOM.valueForNode node, value
    
    context: (node, key, contexts) ->
      context = matchContext(contexts, key).get(key)
      contexts.push context
      
      node.onParseExit = ->
        index = contexts.indexOf(context)
        contexts.splice(index, contexts.length - index)
    
    route: (node, key, contexts) ->
      if key.substr(0, 1) is '/'
        route = Batman.redirect.bind Batman, key
        routeName = key
      else
        route = matchContext contexts, key
        routeName = route.path
      
      switch node.nodeName.toUpperCase()
        when 'A' then node.href = Batman.HASH_PATTERN + routeName
      
      Batman.DOM.addEventListener node, 'click', (e) ->
        e.preventDefault()
        
        route()
        false
  }
  
  attrReaders: {
    bind: (node, attr, key, contexts) ->
      context = matchContext contexts, key
      context?.observe key, yes, (value) ->
        node[attr] = value
      
    foreach: (node, attr, key, contexts) ->
      context = matchContext contexts, key
      context
  }
  
  events: {
    change: (node, callback) ->
      eventName = switch node.nodeName.toUpperCase()
        when 'TEXTAREA' then 'keyup'
        when 'INPUT'
          if node.type.toUpperCase() is 'TEXT' then 'keyup' else 'change'
        else 'change'
      
      Batman.DOM.addEventListener node, eventName, callback
  }
  
  valueForNode: (node, value) ->
    isSetting = arguments.length > 1
    
    switch node.nodeName.toUpperCase()
      when 'INPUT' then (if isSetting then (node.value = value) else node.value)
      else (if isSetting then (node.innerHTML = value) else node.innerHTML)
  
  nodeIsEditable: (node) ->
    node.nodeName.toUpperCase() in ['INPUT', 'TEXTAREA']
  
  addEventListener: (node, eventName, callback) ->
    if node.addEventListener
      node.addEventListener eventName, callback, false
    else
      node.attachEvent "on#{eventName}", callback
}

###
# Helpers
# Just a few random Rails-style string helpers. You can add more
# to the Batman.helpers object.
###

camelize_rx = /(?:^|_)(.)/g
underscore_rx1 = /([A-Z]+)([A-Z][a-z])/g
underscore_rx2 = /([a-z\d])([A-Z])/g

helpers = Batman.helpers = {
  camelize: (string, firstLetterLower) ->
    string = string.replace camelize_rx, (str, p1) -> p1.toUpperCase()
    if firstLetterLower then string.substr(0,1).toLowerCase() + string.substr(1) else string

  underscore: (string) ->
    string.replace(underscore_rx1, '$1_$2')
          .replace(underscore_rx2, '$1_$2')
          .replace('-', '_').toLowerCase()

  singularize: (string) ->
    if string.substr(-1) is 's'
      string.substr(0, string.length - 1)
    else
      string

  pluralize: (count, string) ->
    if string
      return string if count is 1
    else
      string = count

    if string.substr(-1) is 'y'
      "#{string.substr(0,string.length-1)}ies"
    else
      "#{string}s"
}

###
# Filters
###

filters = Batman.filters = {
  
}

# Export a few globals.
global = exports ? this
global.Batman = Batman

$mixin global, Batman.Observable

# Optionally export global sugar. Not sure what to do with this.
Batman.exportGlobals = ->
  global.$typeOf = $typeOf
  global.$mixin = $mixin
  global.$unmixin = $unmixin
  global.$route = $route
  global.$redirect = $redirect
  global.$event = $event
  global.$eventOneShot = $eventOneShot
