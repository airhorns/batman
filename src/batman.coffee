#
# Batman.js
#
# Created by Nicholas Small
#
# Copyright 2011, JadedPixel Technologies, Inc.
#

# The global namespace, the `Batman` function will also create also create a new
# instance of Batman.Object and mixin all arguments to it.
Batman = (mixins...) ->
  new Batman.Object mixins...

# Global Helpers
# -------

# `$typeOf` returns a string that contains the built-in class of an object
# like `String`, `Array`, or `Object`. Note that only `Object` will be returned for
# the entire prototype chain.
Batman.typeOf = $typeOf = (object) ->
  _objectToString.call(object).slice(8, -1)

# Cache this function to skip property lookups.
_objectToString = Object.prototype.toString


# `$mixin` applies every key from every argument after the first to the
# first argument. If a mixin has an `initialize` method, it will be called in
# the context of the `to` object, and it's key/values won't be applied.
Batman.mixin = $mixin = (to, mixins...) ->
  set = to.set
  hasSet = typeof set is 'function'
  
  for mixin in mixins
    continue if $typeOf(mixin) isnt 'Object'
    
    for key, value of mixin
      continue if key in ['initialize', 'uninitialize', 'prototype']
      if hasSet then set.call(to, key, value) else to[key] = value
  
  to

# `$unmixin` removes every key/value from every argument after the first
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

# `$block` takes in a function and returns a function which can either
#   A) take a callback as its last argument as it would normally, or 
#   B) accept a callback as a second function application.
# This is useful so that multiline functions can be passed as callbacks 
# without the need for wrapping brackets (which a CoffeeScript bug 
# requires them to have).
#
# Example:
#  With a function that accepts a callback as its last argument
#
#     f = (a, b, callback) -> callback(a + b)
#     ex = $block f
#
#  We can use $block to make it accept the callback in both ways:   
#
#     ex(2, 3, (x) -> alert(x))  # alerts 5
#
#  or
#
#     ex(2, 3) (x) -> alert(x)
#
Batman._block = $block = (fn) ->
  callbackEater = (args...) ->
    ctx = @
    f = (callback) ->
      args.push callback
      fn.apply(ctx, args)
    
    if typeof args[args.length-1] is 'function'
      f(args.pop())
    else
      f


# `findName` allows an anonymous function to find out what key it resides
# in within a context.
Batman._findName = $findName = (f, context) ->
  if not f.displayName
    for key, value of context
      if value is f
        f.displayName = key
        break
  
  f.displayName


# Properties
# ----------

class Batman.Property
  @defaultAccessor:
    get: (key) -> @[key]
    set: (key, val) -> @[key] = val
    unset: (key) ->
      @[key] = null
      delete @[key]
      return
  @triggerTracker: null
  @for: (base, key) ->
    if base._batman
      Batman._initializeObject base
      properties = base._batman.properties ||= new Batman.SimpleHash
      properties.get(key) or properties.set(key, new @(base, key))
    else
      new @(base, key)
  constructor: (base, key) ->
    @base = base
    @key = key
  isProperty: true
  accessor: ->
    key = @key
    for result in Batman._lookupAllBatmanKeys(@base, 'keyAccessors')
      return val if (val = result.get(key))
    
    Batman._lookupBatmanKey(@base, 'defaultAccessor') or
    Batman.Property.defaultAccessor
  registerAsTrigger: ->
    tracker.add @ if tracker = Batman.Property.triggerTracker
  getValue: ->
    @registerAsTrigger()
    @accessor()?.get.call @base, @key
  setValue: (val) ->
    @accessor()?.set.call @base, @key, val
  unsetValue: -> @accessor()?.unset.call @base, @key
  isEqual: (other) ->
    @constructor is other.constructor and @base is other.base and @key is other.key
    

class Batman.ObservableProperty extends Batman.Property
  constructor: (base, key) ->
    super
    @observers = new Batman.SimpleSet
    @refreshTriggers() if @hasObserversToFire()
    @_preventCount = 0
  setValue: (val) ->
    @cacheDependentValues()
    super
    @fireDependents()
    val
  unsetValue: ->
    @cacheDependentValues()
    super
    @fireDependents()
    return
  cacheDependentValues: ->
    if @dependents
      @dependents.each (prop) -> prop.cachedValue = prop.getValue()
  fireDependents: ->
    if @dependents
      @dependents.each (prop) ->
        prop.fire(prop.getValue(), prop.cachedValue) if prop.hasObserversToFire?()
  observe: (fireImmediately..., callback) ->
    fireImmediately = fireImmediately[0] is true
    currentValue = @getValue()
    @observers.add callback
    @refreshTriggers()
    callback.call(@base, currentValue, currentValue) if fireImmediately
    @
  hasObserversToFire: ->
    return true if @observers.length > 0
    return false if @base is @base.constructor::
    @base.constructor::property?(@key).observers.length > 0
  preventFire: -> @_preventCount++
  allowFire: -> @_preventCount-- if @_preventCount > 0
  isAllowedToFire: -> @_preventCount <= 0
  fire: (args...) ->
    return unless @hasObserversToFire()
    key = @key
    base = @base
    properties = Batman._lookupAllBatmanKeys(@base)
    propertyObservers = [@observers].concat(properties.map((property) -> property?.property?(key).observers))
    for observers in propertyObservers
      observers?.each (callback) ->
        callback?.apply base, args
    @refreshTriggers()
  forget: (observer) ->
    if observer
      @observers.remove(observer)
    else
      @observers = new Batman.SimpleSet
    @clearTriggers() unless @hasObserversToFire()
  refreshTriggers: ->
    Batman.Property.triggerTracker = new Batman.SimpleSet
    @getValue()
    if @triggers
      @triggers.each (property) =>
        unless Batman.Property.triggerTracker.has(property)
          property.dependents?.remove @
    @triggers = Batman.Property.triggerTracker
    @triggers.each (property) =>
      property.dependents ||= new Batman.SimpleSet
      property.dependents.add @
    Batman.Property.triggerTracker = null
  clearTriggers: ->
    @triggers.each (property) =>
      property.dependents.remove @
    @triggers = new Batman.SimpleSet

# Keypaths
# --------

class Batman.Keypath extends Batman.ObservableProperty
  constructor: (base, key) ->
    if $typeOf(key) is 'String'
      @segments = key.split('.')
      @depth = @segments.length
    else
      @segments = [key]
      @depth = 1
    super
  slice: (begin, end) ->
    base = @base
    for segment in @segments.slice(0, begin)
      return unless base? and base = Batman.Keypath.for(base, segment).getValue()
    Batman.Keypath.for base, @segments.slice(begin, end).join('.')
  terminalProperty: -> @slice -1
  getValue: ->
    @registerAsTrigger()
    if @depth is 1 then super else @terminalProperty()?.getValue()
  setValue: (val) -> if @depth is 1 then super else @terminalProperty()?.setValue(val)
  unsetValue: -> if @depth is 1 then super else @terminalProperty()?.unsetValue()
 

# Observable
# ----------

# Batman.Observable is a generic mixin that can be applied to any object to allow it to be bound to.
# It is applied by default to every instance of `Batman.Object` and subclasses.
Batman.Observable =
  isObservable: true
  property: (key) ->
    Batman._initializeObject @
    Batman.Keypath.for(@, key)
  get: (key) -> @property(key).getValue()
  set: (key, val) -> @property(key).setValue(val)
  unset: (key) -> @property(key).unsetValue()

  # Pass a key and a callback. Whenever the value for that key changes, your
  # callback will be called in the context of the original object.
  observe: (key, args...) ->
    @property(key).observe(args...)
    @
  
  # Tell any observers attached to a key to fire, manually. 
  fire: (key, args...) ->
    @property(key).fire(args...)

  # Forget removes an observer from an object. If the callback is passed in, 
  # its removed. If no callback but a key is passed in, all the observers on
  # that key are removed. If no key is passed in, all observers are removed.
  forget: (key, observer) ->
    if key
      @property(key).forget(observer)
    else
      @_batman.properties.each (key, property) -> property.forget()
    @

  # Prevent allows the prevention of a given binding from firing. Prevent counts can be nested,
  # so three calls to prevent means three calls to allow must be made before observers will
  # be fired.
  prevent: (key) ->
    @property(key).preventFire()
    @

  # Allow unblocks a property for firing observers. Every call to prevent
  # must have a matching call to allow later if observers are to be fired.
  allow: (key) ->
    @property(key).allowFire()
    @

  # allowed returns a boolean describing whether or not the key is 
  # currently allowed to fire its observers.
  allowed: (key) ->
    @property(key).isAllowedToFire()

# Events
# ------

# `Batman.EventEmitter` is another generic mixin that simply allows an object to 
# emit events. Batman events use observers to manage the callbacks, so they require that
# the object emitting the events be observable. If events need to be attached to an object
# which isn't a `Batman.Object` or doesn't have the `Batman.Observable` and `Batman.EventEmitter`
# mixins applied, the $event function can be used to create ephemeral event objects which
# use those mixins internally.

Batman.EventEmitter =
  # An event is a convenient observer wrapper. Any function can be wrapped in an event, and
  # when called, it will cause it's object to fire all the observers for that event. There is 
  # also some syntactical sugar so observers can be registered simply by calling the event with a 
  # function argument. Notice that the `$block` helper is used here so events can be declared in
  # class definitions using the second function application syntax and no wrapping brackets.
  event: $block (key, context, callback) ->
    if not callback and typeof context isnt 'undefined'
      callback = context
      context = null
    if not callback and $typeOf(key) isnt 'String'
      callback = key
      key = null
    
    # Return a function which either takes another observer
    # to register or a value to fire the event with.
    f = (observer) ->
      if not @observe
        throw "EventEmitter requires Observable"
      
      Batman._initializeObject @
      
      key ||= $findName(f, @)
      fired = @_batman._oneShotFired?[key]
      
      # Pass a function to the event to register it as an observer.
      if typeof observer is 'function'
        @observe key, observer
        observer.apply(@, f._firedArgs) if f.isOneShot and fired
      
      # Otherwise, calling the event will cause it to fire. Any
      # arguments you pass will be passed to your wrapped function.
      else if @allowed key
        return false if f.isOneShot and fired
        value = callback?.apply @, arguments
        
        # Observers will only fire if the result of the event is not false.
        if value isnt false
          # Get and cache the arguments for the event listeners. Add the value if 
          # its not undefined, and then concat any more arguments passed to this 
          # event when fired.
          f._firedArgs = if typeof value isnt 'undefined'
              [value].concat arguments...
            else
              if arguments.length == 0
                []
              else
                Array.prototype.slice.call arguments

          # Copy the array and add in the key for `fire`
          args = Array.prototype.slice.call f._firedArgs
          args.unshift key
          @fire(args...)
          
          if f.isOneShot
            firings = @_batman._oneShotFired ||= {}
            firings[key] = yes
        
        value
      else
        false
    
    # This could be its own mixin but is kept here for brevity.
    f = f.bind(context) if context
    @[key] = f if key?
    $mixin f,
      isEvent: yes
      action: callback
      isOneShot: @isOneShot
  
  # One shot events can be used for something that only fires once. Any observers
  # added after it has already fired will simply be executed immediately. This is useful
  # for things like `ready` events on requests or renders, because once ready they always
  # remain ready. If an AJAX request had a vanilla `ready` event, observers attached after
  # the ready event fired the first time would never fire, as they would be waiting for
  # the next time `ready` would fire as is standard with vanilla events. With a one shot
  # event, any observers attached after the first fire will fire immediately, meaning no logic
  eventOneShot: (callback) ->
    $mixin Batman.EventEmitter.event.apply(@, arguments),
      isOneShot: yes


# `$event` lets you create an ephemeral event without needing an EventEmitter.
# If you already have an EventEmitter object, you should call .event() on it.
$event = (callback) ->
  context = new Batman.Object
  context.event('_event', context, callback)

# `$eventOneShot` lets you create an ephemeral one-shot event without needing an EventEmitter.
# If you already have an EventEmitter object, you should call .eventOneShot() on it.
$eventOneShot = (callback) ->
  context = new Batman.Object
  context.eventOneShot('_event', context, callback)

###
# Batman.StateMachine
###

Batman.StateMachine = {
  initialize: ->
    Batman._initializeObject @
    if not @_batman.states
      @_batman.states = {}
      @accessor 'state',
        get: -> @state()
        set: (key, value) -> _stateMachine_setState.call(@, value)
  
  state: (name, callback) ->
    Batman.StateMachine.initialize.call @
    
    if not name
      return Batman._lookupBatmanKey(@, 'state')
    
    if not @event
      throw "StateMachine requires EventEmitter"
    
    event = @[name] || @event name, -> _stateMachine_setState.call(@, name); false
    event.call(@, callback) if typeof callback is 'function'
    event
  
  transition: (from, to, callback) ->
    Batman.StateMachine.initialize.call @
    
    @state from
    @state to
    
    name = "#{from}->#{to}"
    transitions = @_batman.states
    
    event = transitions[name] ||= $event ->
    event(callback) if callback
    event
}

# this is cached here so it doesn't need to be recompiled for every setter
_stateMachine_setState = (newState) ->
  Batman.StateMachine.initialize.call @
  
  if @_batman.isTransitioning
    (@_batman.nextState ||= []).push(newState)
    return false
  
  @_batman.isTransitioning = yes
  
  oldState = @state()
  @_batman.state = newState
  
  if newState and oldState
    name = "#{oldState}->#{newState}"
    for event in Batman._lookupAllBatmanKeys(@, 'states', name)
      if event
        event newState, oldState
  
  if newState
    @fire newState, newState, oldState
  
  @_batman.isTransitioning = no
  @[@_batman.nextState.shift()]() if @_batman.nextState?.length
  
  newState

# Objects
# -------

# `Batman._initializeObject` is called by all the methods in Batman.Object to ensure that the
# objects `_batman` property is initialized and it's own. Classes extending Batman.Object inherit
# methods like `get`, `set`, and `observe` by default on the class and prototype levels, such that
# both instances and the class respond to them and can be bound to. However, CoffeeScript's static
# class inheritance copies over all class level properties indiscriminately, so a parent class' 
# `_batman` object will get copied to its subclasses, transferring all the information stored there and 
# allowing subclasses to mutate parent state. This method prevents this undesirable behaviour by tracking
# which object the `_batman_` object was initialized upon, and reinitializing if that has changed since
# initialization.
Batman._initializeObject = (object) ->
  if object.prototype and object._batman?.__initClass__ isnt object
    object._batman = {__initClass__: object}
  else unless object.hasOwnProperty '_batman'
    object._batman = {}

Batman._lookupBatmanKey = (object, key) ->
  return val if (val = object._batman?[key])
  
  nextClass = object.constructor
  while nextClass
    return val if (val = nextClass.prototype?._batman?[key])
    nextClass = nextClass.__super__?.constructor
  
  return

Batman._lookupAllBatmanKeys = (object, key, subkey) ->
  results = []
  results.push(val) if (val = object._batman?[key])
  
  isClass = !!object.prototype
  nextClass = if isClass then object.__super__?.constructor else object.constructor
  while nextClass
    if not key
      results.push nextClass.prototype
    else if isClass and (val = nextClass._batman?[key])
      results.push(val)
    else if !isClass and (val = nextClass.prototype?._batman?[key])
      results.push(val)
      
    nextClass = nextClass.__super__?.constructor
  
  if subkey then results.map((result) -> result[subkey]) else results

# `Batman.Object` is the base class for all other Batman objects. It is not abstract. 
class Batman.Object
  # Setting `isGlobal` to true will cause the class name to be defined on the
  # global object. For example, Batman.Model will be aliased to window.Model.
  # This should be used sparingly; it's mostly useful for debugging.
  @global: (isGlobal) ->
    return if isGlobal is false
    container[@name] = @
  
  # Apply mixins to this subclass.
  @mixin: (mixins...) -> $mixin @, mixins...
  
  # Apply mixins to instances of this subclass.
  mixin: @mixin
  
  @accessor: (keys..., accessor) ->
    Batman._initializeObject @
    if keys.length is 0
      if accessor.get or accessor.set
        @_batman.defaultAccessor = accessor
      else
        @_batman.keyAccessors ||= new Batman.SimpleHash
        for key, value of accessor
          @_batman.keyAccessors.set(key, {get: value, set: value})
          @[key] = value
    else
      @_batman.keyAccessors ||= new Batman.SimpleHash
      @_batman.keyAccessors.set(key, accessor) for key in keys
  accessor: @accessor
    
  constructor: (mixins...) ->
    Batman._initializeObject @
    @mixin mixins...
  
  # Make every subclass and their instances observable.
  @mixin Batman.Observable, Batman.EventEmitter
  @::mixin Batman.Observable, Batman.EventEmitter
  

class Batman.SimpleHash
  constructor: ->
    @_storage = {}
    @length = 0
  hasKey: (key) ->
    typeof @get(key) isnt 'undefined'
  get: (key) ->
    return @length if key is 'length' # FIXME: tries to call getValue
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
      # @length++
    pair[1] = val
  unset: (key) ->
    if matches = @_storage[key]
      for [obj,v], index in matches
        if @equality(obj, key)
          matches.splice(index,1)
          # @length--
          return
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
  clear: ->
    @each (obj) -> @unset obj
  isEmpty: ->
    @keys().length is 0
    

class Batman.Hash extends Batman.Object
  constructor: Batman.SimpleHash

  @::accessor
    get: Batman.SimpleHash::get
    set: Batman.SimpleHash::set
    unset: Batman.SimpleHash::unset

  @::accessor 'isEmpty', get: -> @isEmpty()
  for k in ['hasKey', 'equality', 'each', 'keys']
    @::[k] = Batman.SimpleHash::[k]

class Batman.SimpleSet
  constructor: ->
    @_storage = new Batman.SimpleHash
    @length = 0
    @add.apply @, arguments if arguments.length > 0
  has: (item) ->
    @_storage.hasKey item

  for k in ['get', 'set', 'unset']
   @::[k] = Batman.Property.defaultAccessor[k]

  add: (items...) ->
    for item in items
      unless @_storage.hasKey(item)
        @_storage.set item, true
        @set 'length', @length + 1
        @set 'isEmpty', true
    items
  remove: (items...) ->
    results = []
    for item in items
      if @_storage.hasKey(item)
        @_storage.unset item
        results.push item
        @set 'length', @length - 1
        @set 'isEmpty', true
    results
  each: (iterator) ->
    @_storage.each (key, value) -> iterator(key)
  isEmpty: -> @get('length') is 0
  clear: -> @remove @toArray()
  toArray: ->
    @_storage.keys()
    
class Batman.Set extends Batman.Object
  constructor: Batman.SimpleSet

  for k in ['add', 'remove']
    @::[k] = @event Batman.SimpleSet::[k]

  for k in ['has', 'each', 'isEmpty', 'toArray', 'clear']
    @::[k] = Batman.SimpleSet::[k]

  @::accessor 'isEmpty', {get: (-> @isEmpty()), set: ->}

class Batman.SortableSet extends Batman.Set
  constructor: (index) ->
    super
    @_indexes = {}
    @addIndex(index)
  add: @event ->
    results = Batman.SimpleSet::add.apply @, arguments
    @_reIndex()
    results
  remove: @event ->
    results = Batman.SimpleSet::remove.apply @, arguments
    @_reIndex()
    results
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
        valueA = (Batman.Observable.property.call(a, keypath)).getValue()?.valueOf()
        valueB = (Batman.Observable.property.call(b, keypath)).getValue()?.valueOf()
        [valueA, valueB] = [valueB, valueA] if ordering?.toLowerCase() is 'desc'
        if valueA < valueB then -1 else if valueA > valueB then 1 else 0
    else
      @_reIndex(index) for index of @_indexes

# App, Requests, and Routing
# --------------------------

# `Batman.Request` is a normalizer for XHR requests in the Batman world.
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
  
  send: () -> throw "Please source a dependency file for a request implementation" 
  
  cancel: ->
    clearTimeout(@_autosendTimeout) if @_autosendTimeout

# `Batman.App` manages requiring files and acts as a namespace for all code subclassing
# Batman objects.
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
  
  # Layout is the base view that other views can be yielded into. The
  # default behavior is that when `app.run()` is called, a new view will
  # be created for the layout using the `document` node as its content.
  # Use `MyApp.layout = null` to turn off the default behavior.
  @layout: undefined
  
  # Call `MyApp.run()` to start up an app. Batman level initializers will 
  # be run to bootstrap the application.
  @run: @eventOneShot ->
    return false if @hasRun
    Batman.currentApp = @
    
    if typeof @layout is 'undefined'
      @set 'layout', new Batman.View node: document
    
    @startRouting()
    @hasRun = yes

# route matching courtesy of Backbone
namedParam = /:([\w\d]+)/g
splatParam = /\*([\w\d]+)/g
queryParam = '(?:\\?.+)?'
namedOrSplat = /[:|\*]([\w\d]+)/g
escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g


# `Batman.Route` is a simple object representing a route
# which a user might visit in the application.
Batman.Route = {
  isRoute: yes
  
  pattern: null
  regexp: null
  namedArguments: null
  action: null
  context: null
  
  # call the action without going through the dispatch mechanism
  fire: (args, context) ->
    action = @action
    if $typeOf(action) is 'String'
      if (index = action.indexOf('#')) isnt -1
        controllerName = helpers.camelize(action.substr(0, index) + 'Controller')
        controller = Batman.currentApp[controllerName]
        
        context = controller
        if context?.sharedInstance
          context = context.sharedInstance()
        
        action = context[action.substr(index + 1)]
    
    action.apply(context || @context, args) if action
  
  toString: ->
    "route: #{@pattern}"
}

# The `route` and `redirect` methods are mixed in to the top level `Batman` object,
# so at any point new routes can be added and redirected to.
$mixin Batman,
  HASH_PATTERN: '#!'
  _routes: []
  
  # `route` adds a new route to the global routing table. It accepts a pattern of the
  # Rails/Backbone variety with `:foo` denoting named arguments and `*bar` denoting 
  # repeated segements. It also accepts a callback to fire when the route is visited.
  # Note that route uses the `$block` helper, so it can be used in class definitions 
  # without wrapping brackets 
  route: $block (pattern, callback) ->
    f = (params) ->
      context = f.context || @
      if context and context.sharedInstance
        context = context.sharedInstance()
      
      pattern = f.pattern
      if params and not params.url
        for key, value of params
          pattern = pattern.replace(new RegExp('[:|\*]' + key), value)
      
      if (params and not params.url) or not params
        Batman.currentApp._cachedRoute = pattern
        window.location.hash = Batman.HASH_PATTERN + pattern
        
      if context and context.dispatch
        context.dispatch f, params
      else
        f.fire arguments, context
      
    match = pattern.replace(escapeRegExp, '\\$&')
    regexp = new RegExp('^' + match.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + queryParam + '$')
    
    namedArguments = []
    while (array = namedOrSplat.exec(match))?
      namedArguments.push(array[1]) if array[1]
      
    $mixin f, Batman.Route,
      pattern: match
      regexp: regexp
      namedArguments: namedArguments
      action: callback
      context: @
    
    Batman._routes.push f
    f
   
  # `redirect` sets the `window.location.hash` to passed string or pattern of the passed route. This will
  # then trigger any route who's pattern matches the route and thus it's callback.
  redirect: (urlOrFunction) ->
    url = if urlOrFunction?.isRoute then urlOrFunction.pattern else urlOrFunction
    window.location.hash = "#{Batman.HASH_PATTERN}#{url}"

# Add the route and redirect helpers to the class level of all `Batman.Object` subclasses so they can be 
# used declaratively within class definitions.
Batman.Object.route = Batman.App.route = $route = Batman.route
Batman.Object.redirect = Batman.App.redirect = $redirect = Batman.redirect

$mixin Batman.App,
  # `startRouting` starts listening for changes to the window hash and dispatches routes when they change.
  startRouting: ->
    return if typeof window is 'undefined'
    parseUrl = =>
      hash = window.location.hash.replace(Batman.HASH_PATTERN, '')
      return if hash is @_cachedRoute
      @_cachedRoute = hash
      @_dispatch hash
    
    window.location.hash = "#{Batman.HASH_PATTERN}/" if not window.location.hash
    setTimeout(parseUrl, 0)
    
    if 'onhashchange' of window
      @_routeHandler = parseUrl
      window.addEventListener 'hashchange', parseUrl
    else
      old = window.location.hash
      @_routeHandler = setInterval parseUrl, 100
  
  # `stopRouting` stops any hash change listeners from dispatching routes.
  stopRouting: ->
    return unless @_routeHandler?
    if 'onhashchange' of window
      window.removeEventListener 'hashchange', @_routeHandler
      @_routeHandler = null
    else
      @_routeHandler = clearInterval @_routeHandler
  
  _dispatch: (url) ->
    route = @_matchRoute url
    if not route
      if url is '/404' then Batman.currentApp['404']() else $redirect '/404'
      return
    
    params = @_extractParams url, route
    route(params)
  
  _matchRoute: (url) ->
    for route in Batman._routes
      return route if route.regexp.test(url)
    
    null
  
  _extractParams: (url, route) ->
    [url, query] = url.split('?')
    array = route.regexp.exec(url).slice(1)
    params = url: url
    
    for param, index in array
      params[route.namedArguments[index]] = param
    
    if query?
      for s in query.split('&')
        [k, v] = s.split('=')
        params[k] = v

    params
  
  # `root` is a shortcut for setting the root route.
  root: (callback) ->
    $route '/', callback
  
  '404': ->
    view = new Batman.View
      html: '<h1>Page could not be found</h1>'
      contentFor: 'main'



# Controllers
# -----------


class Batman.Controller extends Batman.Object
  # FIXME: should these be singletons?
  @sharedInstance: ->
    @_sharedInstance = new @ if not @_sharedInstance
    @_sharedInstance
  
  @beforeFilter: (nameOrFunction) ->
    filters = @_beforeFilters ||= []
    filters.push nameOrFunction
  
  @resources: (base) ->
    # FIXME: MUST find a non-deferred way to do this
    f = =>
      @::index = @route("/#{base}", @::index) if @::index
      @::create = @route("/#{base}/new", @::create) if @::create
      @::show = @route("/#{base}/:id", @::show) if @::show
      @::edit = @route("/#{base}/:id/edit", @::edit) if @::edit
    setTimeout f, 0
    
    #name = helpers.underscore(@name.replace('Controller', ''))
    
    #$route "/#{base}", "#{name}#index"
    #$route "/#{base}/:id", "#{name}#show"
    #$route "/#{base}/:id/edit", "#{name}#edit"
  
  dispatch: (route, params...) ->
    key = $findName route, @
    
    @_actedDuringAction = no
    @_currentAction = key
    
    filters = @constructor._beforeFilters
    if filters
      for filter in filters
        filter.call @
    
    result = route.fire params, @
    
    if not @_actedDuringAction
      @render()
    
    delete @_actedDuringAction
    delete @_currentAction
  
  redirect: (url) ->
    @_actedDuringAction = yes
    $redirect url
  
  render: (options = {}) ->
    @_actedDuringAction = yes
    
    if not options.view
      options.source = helpers.underscore(@constructor.name.replace('Controller', '')) + '/' + @_currentAction + '.html'
      options.view = new Batman.View(options)
    
    if view = options.view
      view.context ||= @ 
      view.ready ->
        Batman.DOM.contentFor('main', view.get('node'))

# Models
# ------

class Batman.Model extends Batman.Object
  @persist: (mechanisms...) ->
    Batman._initializeObject @prototype
    storage = @::_batman.storage ||= []
    for m in mechanisms
      storage.push new m(@)
    @
  
  @accessor 'all', {get: -> @all ||= new Batman.Set}
  @accessor 'first', {get: -> @first = @get('all')[0]}
  @accessor 'last', {get: -> @last = @get('all')[@all.length - 1]}
  
  @::mixin Batman.StateMachine
  
  for k in ['empty', 'dirty', 'loading', 'loaded', 'saving']
    @::state k
  @::state 'saved', -> @dirtyKeys.clear()
  
  constructor: (id) ->
    # We have to do this ahead of super, because mixins will call set which calls things on dirtyKeys.
    @dirtyKeys = new Batman.Hash
    @errors = new Batman.Set
    
    super
    @empty() if not @state()
    
    if $typeOf(id) is 'String'
      @id = id
      @constructor.get('all').add(@)
  
  @find: (id) ->
    return record if (record = @get('all').get(id))
    record = new @(''+id)
    setTimeout (-> record.load()), 0
    record
  
  set: (key, value) ->
    oldValue = @[key]
    return if oldValue is value
    
    super
    @dirtyKeys.set(key, oldValue)
    
    @dirty() if @state() isnt 'dirty'
  
  @::accessor 'dirtyKeys',
    get: -> @dirtyKeys
  
  toJSON: ->
    obj = {}
    for encoders in Batman._lookupAllBatmanKeys(@, 'encoders')
      for key, encoder of encoders
        obj[key] = encoder(@[key])
    
    obj
  
  fromJSON: (data) ->
    obj = {}
    allDecoders = Batman._lookupAllBatmanKeys(@, 'decoders')
    if not allDecoders.length
      for key, value of data
        obj[helpers.camelize(key, yes)] = value
    else
      for decoders in allDecoders
        for key, decoder of decoders
          obj[key] = decoder(data[key])
    
    @mixin obj
  
  @encode: (keys...) ->
    Batman._initializeObject @prototype
    @::_batman.encoders ||= {}
    @::_batman.decoders ||= {}
    
    for key in keys
      @::_batman.encoders[key] = (value) ->
        ''+value
      
      @::_batman.decoders[key] = (value) ->
        value
  
  @beforeLoad: @event -> @get('all').clear()
  @afterLoad: @event ->
  @load: (callback) ->
    do @beforeLoad
    
    afterLoad = =>
      callback?.call @
      do @afterLoad
    
    allMechanisms = Batman._lookupAllBatmanKeys @prototype, 'storage'
    fireImmediately = !allMechanisms.length
    allMechanisms.shift() if not fireImmediately
    for mechanisms in allMechanisms
      fireImmediately = fireImmediately || !mechanisms.length
      for m in mechanisms
        m.readAllFromStorage @, afterLoad
    
    do afterLoad if fireImmediately
    
  beforeLoad: @event -> @loading(); true
  afterLoad: @event -> @loaded(); true
  load: (callback) ->
    do @beforeLoad
    
    afterLoad = =>
      callback?.call @
      do @afterLoad
    
    allMechanisms = Batman._lookupAllBatmanKeys @, 'storage'
    fireImmediately = !allMechanisms.length
    for mechanisms in allMechanisms
      fireImmediately = fireImmediately || !mechanisms.length
      for m in mechanisms
        m.readFromStorage @, afterLoad
    
    do afterLoad if fireImmediately
  
  beforeCreate: @event ->
  afterCreate: @event ->
  beforeSave: @event -> @saving(); true
  afterSave: @event -> @saved(); true
  save: (callback) ->
    return if not @isValid()
    do @beforeSave
    
    creating = !@id
    do @beforeCreate if creating
    
    afterSave = =>
      callback?.call @
      do @afterCreate if creating
      do @afterSave
    
    allMechanisms = Batman._lookupAllBatmanKeys @, 'storage'
    fireImmediately = !allMechanisms.length
    for mechanisms in allMechanisms
      fireImmediately = fireImmediately || !mechanisms.length
      for m in mechanisms
        m.writeToStorage @, afterSave
    
    do afterSave if fireImmediately
  
  beforeValidation: @event ->
  afterValidation: @event ->
  validate: ->
    do @beforeValidation
    async = no
    for allValidators in Batman._lookupAllBatmanKeys(@, 'validators')
      for validator in allValidators
        v = validator.validator
        for key in validator.keys
          promise = new Batman.ValidatorPromise @
          if v then v.validateEach promise, @, key, @get key else validator.callback promise, @, key, @get key
          
          if promise.paused
            @prevent 'afterValidation'
            promise.resume => @allow('afterValidation'); @afterValidation()
            async = yes
          else
            promise.success() if promise.canSucceed
    
    if async then return no else do @afterValidation
  
  @::accessor
    isValid: ->
      @errors.clear()
      return no if @validate() is no
      @errors.isEmpty()
  
  @validate: (keys..., options) ->
    Batman._initializeObject @prototype
    myValidators = @::_batman.validators ||= []
    
    if typeof options is 'function'
      myValidators.push({keys: keys, callback: options})
    else
      for validator in validators
        if (matches = validator.matches(options))
          delete options[match] for match of matches
          myValidators.push({keys: keys, validator: new validator(matches)})

class Batman.ValidatorPromise extends Batman.Object
  constructor: (@record) ->
    @canSucceed = yes
  
  error: (err) ->
    @record.errors.add err
    @canSucceed = no
  
  wait: ->
    @paused = yes
    @canSucceed = no
  
  resume: @event ->
    @paused = no
    true
  
  success: ->
    @canSucceed = no

class Batman.Validator extends Batman.Object
  constructor: (@options, mixins...) ->
    super mixins...
  
  validate: (record) ->
    throw "You must override -validate in Batman.Validator subclasses."
  
  @kind: -> helpers.underscore(@name).replace('_validator', '')
  kind: -> @constructor.kind()
  
  @options: (options...) ->
    Batman._initializeObject @
    if @_batman.options then @_batman.options.concat(options) else @_batman.options = options
  
  @matches: (options) ->
    results = {}
    shouldReturn = no
    for key, value of options
      if ~@_batman?.options?.indexOf(key)
        results[key] = value
        shouldReturn = yes
    return results if shouldReturn

validators = Batman.validators = [
  class Batman.LengthValidator extends Batman.Validator
    @options 'minLength', 'maxLength', 'length', 'lengthWithin', 'lengthIn'
    constructor: (options) ->
      if range = (options.lengthIn or options.lengthWithin)
        options.minLength = range[0]
        options.maxLength = range[1] || -1
        delete options.lengthWithin
        delete options.lengthIn
      
      super
      
    validateEach: (validator, record, key, value) ->
      options = @options
      if options.minLength and value.length < options.minLength
        validator.error "#{key} must be at least #{options.minLength} characters"
      if options.maxLength and value.length > options.maxLength
        validator.error "#{key} must be less than #{options.maxLength} characters"
      if options.length and value.length isnt options.length
        validator.error "#{key} must be #{options.length} characters"
  
  class Batman.PresenceValidator extends Batman.Validator
    @options 'presence'
    validateEach: (validator, record, key, value) ->
      options = @options
      if options.presence and !value?
        validator.error "#{key} must be present"
]

class Batman.StorageMechanism
  constructor: (@model) ->
    @modelKey = helpers.pluralize(helpers.underscore(@model.name))

class Batman.LocalStorage extends Batman.StorageMechanism
  constructor: ->
    return null if not 'localStorage' in window
    @id = 0
    super
  
  writeToStorage: (record, callback) ->
    key = @modelKey
    id = record.id ||= ++@id
    localStorage[key + id] = JSON.stringify(record) if key and id
    callback()
  
  readFromStorage: (record, callback) ->
    key = @modelKey
    id = record.id
    json = localStorage[key + id] if key and id
    record.fromJSON JSON.parse json
    callback()
    
class Batman.RestStorage extends Batman.StorageMechanism
  writeToStorage: (record, callback) ->
    key = @modelKey
    id = record.id
    new Batman.Request
      url: "/#{key}/#{id}"
      method: if id then 'put' else 'post'
      data: JSON.stringify record
      success: ->
        callback()
      error: (error) ->
        callback(error)
  
  readFromStorage: (record, callback) ->
    id = record.id
    return if not id
    new Batman.Request
      url: (@model.url || "/#{@modelKey}") + "/#{id}"
      type: 'json'
      success: (data) ->
        data = JSON.parse(data) if typeof data is 'string'
        for key of data
          data = data[key]
          break
        
        record.fromJSON data
        callback()
        
  readAllFromStorage: (model, callback) ->
    key = @modelKey
    r = new Batman.Request
      url: model.url || "/#{key}"
      type: 'json'
      success: (data) ->
        data = JSON.parse(data) if typeof data is 'string'
        if !Array.isArray(data)
          for key of data
            data = data[key]
            break
        
        for obj in data
          record = new model ''+obj.id
          record.fromJSON obj
        
        callback()
        return
    
# Views
# -----------

# A `Batman.View` can function two ways: a mechanism to load and/or parse html files
# or a root of a subclass hierarchy to create rich UI classes, like in Cocoa.
class Batman.View extends Batman.Object
  viewSources = {}
  
  # Set the source attribute to an html file to have that file loaded.
  source: ''
  
  # Set the html to a string of html to have that html parsed.
  html: ''
  
  # Set an existing DOM node to parse immediately.
  node: null
  
  context: null
  contexts: null
  contentFor: null
  
  # Fires once a node is parsed.
  ready: @eventOneShot ->
  
  # Where to look for views on the server
  prefix: 'views'

  # Whenever the source changes we load it up asynchronously
  @::observe 'source', ->
    setTimeout (=> @reloadSource()), 0
  
  reloadSource: ->
    source = @get 'source'
    return if not source
    
    if viewSources[source]
      @set('html', viewSources[source])
    else
      new Batman.Request
        url: "views/#{@source}"
        type: 'html'
        success: (response) =>
          viewSources[source] = response
          @set('html', response)
        error: (response) ->
          throw "Could not load view from #{url}"
  
  @::observe 'html', (html) ->
    node = @node || document.createElement 'div'
    node.innerHTML = html
    
    @set('node', node) if @node isnt node
  
  @::observe 'node', (node) ->
    return unless node
    @ready.fired = false
    
    if @_renderer
      @_renderer.forgetAll()
    
    # We use a renderer with the continuation style rendering engine to not
    # block user interaction for too long during the render.
    if node
      @_renderer = new Batman.Renderer( node, =>
        content = @contentFor
        if typeof content is 'string'
          @contentFor = Batman.DOM._yields?[content]
        
        if @contentFor and node
          @contentFor.innerHTML = ''
          @contentFor.appendChild(node)
        
        @ready node
      , @contexts)
      
      # Ensure any context object explicitly given for use in rendering the view (in `@context`) gets passed to the renderer
      @_renderer.contexts.push(@context) if @context
      @_renderer.contextObject.view = @

# DOM Helpers
# -----------

# `Batman.Renderer` will take a node and parse all recognized data attributes out of it and its children. 
# It is a continuation style parser, designed not to block for longer than 50ms at a time if the document 
# fragment is particularly long.
class Batman.Renderer extends Batman.Object
  constructor: (@node, @callback, contexts) ->
    super
    @contexts = contexts || [Batman.currentApp, new Batman.Object]
    @contextObject = @contexts[1]
    
    setTimeout @start, 0
  
  start: =>
    @startTime = new Date
    @parseNode @node
  
  resume: =>
    @startTime = new Date
    @parseNode @resumeNode
  
  finish: ->
    @startTime = null
    @callback?()
  
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
                
        result = if (index = name.indexOf('-')) is -1
          Batman.DOM.readers[name]?(node, attr.value, contexts, @)
        else
          Batman.DOM.attrReaders[name.substr(0, index)]?(node, name.substr(index + 1), attr.value, contexts, @)
        
        if result is false
          skipChildren = true
          break
    
    if (nextNode = @nextNode(node, skipChildren)) then @parseNode(nextNode) else @finish()
  
  nextNode: (node, skipChildren) ->
    if not skipChildren
      children = node.childNodes
      return children[0] if children?.length
    
    node.onParseExit?()
    
    sibling = node.nextSibling
    return sibling if sibling
    
    nextParent = node
    while nextParent = nextParent.parentNode
      nextParent.onParseExit?()
      #return if nextParent is @node
      # FIXME: we need a way to break if you exit the original node context of the renderer.
      
      parentSibling = nextParent.nextSibling
      return parentSibling if parentSibling
    
    return
    

# `matchContext` is used to find which context in a stack of objects which responds to a sought key.
# A matching context is returned if found, and if it isn't, the global object is returned.
matchContext = (contexts, key) ->
  base = key.split('.')[0]
  i = contexts.length
  while i--
    context = contexts[i]
    if (context.get? && context.get(base)?) || (context[base])?
      return context

  return container

Batman.DOM = {
  
  # `Batman.DOM.readers` contains the functions used for binding a node's value or innerHTML, showing/hiding nodes,
  # and any other `data-#{name}=""` style DOM directives.
  readers: {
    bind: (node, key, contexts) ->
      context = matchContext contexts, key
      shouldSet = yes
      
      if Batman.DOM.nodeIsEditable(node)
        Batman.DOM.events.change node, ->
          shouldSet = no
          context.set key, node.value
          shouldSet = yes
      
      context.observe key, yes, (value) ->
        if shouldSet
          Batman.DOM.valueForNode node, value
    
    context: (node, key, contexts) ->
      context = matchContext(contexts, key).get(key)
      contexts.push context
      
      node.onParseExit = ->
        index = contexts.indexOf(context)
        contexts.splice(index, contexts.length - index)
    
    mixin: (node, key, contexts) ->
      contexts.push(Batman.mixins)
      context = matchContext contexts, key
      mixin = context.get key
      contexts.pop()

      $mixin node, mixin
    
    showif: (node, key, contexts, renderer, invert) ->
      originalDisplay = node.style.display
      originalDisplay = 'block' if !originalDisplay or originalDisplay is 'none'
      
      context = matchContext contexts, key
      
      context.observe key, yes, (value) ->
        if !!value is !invert
          if typeof node.show is 'function' then node.show() else node.style.display = originalDisplay
        else
          if typeof node.hide is 'function' then node.hide() else node.style.display = 'none'
    
    hideif: (args...) ->
      Batman.DOM.readers.showif args..., yes
    
    route: (node, key, contexts) ->
      if key.substr(0, 1) is '/'
        route = Batman.redirect.bind Batman, key
        routeName = key
      else if (index = key.indexOf('#')) isnt -1
        controllerName = helpers.camelize(key.substr(0, index)) + 'Controller'
        context = matchContext contexts, controllerName
        controller = context[controllerName]
        
        route = controller?.sharedInstance()[key.substr(index + 1)]
        routeName = route?.pattern
      else
        context = matchContext contexts, key
        route = context.get key
        
        if route instanceof Batman.Model
          controllerName = helpers.camelize(helpers.pluralize(key)) + 'Controller'
          context = matchContext contexts, controllerName
          controller = context[controllerName].sharedInstance()
          
          id = route.id
          route = controller.show?.bind(controller, {id: id})
          routeName = '/' + helpers.pluralize(key) + '/' + id
        else
          routeName = route?.pattern
      
      if node.nodeName.toUpperCase() is 'A'
        node.href = Batman.HASH_PATTERN + (routeName || '')
      
      Batman.DOM.events.click node, (-> do route)
    
    partial: (node, path, contexts) ->
      view = new Batman.View
        source: path + '.html'
        contentFor: node
        contexts: Array.prototype.slice.call(contexts)
    
    yield: (node, key) ->
      setTimeout (-> Batman.DOM.yield key, node), 0
    
    contentfor: (node, key) ->
      setTimeout (-> Batman.DOM.contentFor key, node), 0
  }
  
  # `Batman.DOM.attrReaders` contains all the DOM directives which take an argument in their name, in the `data-dosomething-argument="keypath"` style.
  # This means things like foreach, binding attributes like disabled or anything arbitrary, descending into a context, binding specific classes, 
  # or binding to events.
  attrReaders: {
    bind: (node, attr, key, contexts) ->
      filters = key.split(/\s*\|\s*/)
      key = filters.shift()
      if filters.length
        while filterName = filters.shift()
          args = filterName.split(' ')
          filterName = args.shift()
          
          filter = Batman.filters[filterName] || Batman.helpers[filterName]
          continue if not filter
          
          if key.substr(0,1) is '@'
            key = key.substr(1)
            context = matchContext contexts, key
            key = context.get(key)
          
          value = filter(key, args..., node)
          node.setAttribute attr, value
      else
        context = matchContext contexts, key
        context.observe key, yes, (value) ->
          if attr is 'value'
            node.value = value
          else
            node.setAttribute attr, value
      
        if attr is 'value'
          Batman.DOM.events.change node, ->
            value = node.value
            if value is 'false' then value = false
            if value is 'true' then value = true
            context.set key, value
    
    context: (node, contextName, key, contexts) ->
      context = matchContext(contexts, key).get(key)
      object = new Batman.Object
      object[contextName] = context
      
      contexts.push object
      
      node.onParseExit = ->
        index = contexts.indexOf(context)
        contexts.splice(index, contexts.length - index)
    
    event: (node, eventName, key, contexts) ->
      if key.substr(0, 1) is '@'
        callback = new Function key.substr(1)
      else
        context = matchContext contexts, key
        callback = context.get key
      
      Batman.DOM.events[eventName] node, ->
        confirmText = node.getAttribute('data-confirm')
        if confirmText and not confirm(confirmText)
          return
        
        callback?.apply context, arguments
    
    addclass: (node, className, key, contexts, parentRenderer, invert) ->
      className = className.replace(/\|/g, ' ') #this will let you add or remove multiple class names in one binding
      
      context = matchContext contexts, key
      context.observe key, yes, (value) ->
        currentName = node.className
        includesClassName = currentName.indexOf(className) isnt -1
        
        if !!value is !invert
          node.className = "#{currentName} #{className}" if !includesClassName
        else
          node.className = currentName.replace(className, '') if includesClassName
          
    removeclass: (args...) ->
      Batman.DOM.attrReaders.addclass args..., yes
    
    foreach: (node, iteratorName, key, contexts, parentRenderer) ->
      prototype = node.cloneNode true
      prototype.removeAttribute "data-foreach-#{iteratorName}"
      
      parent = node.parentNode
      parent.removeChild node
      
      nodeMap = new Batman.Hash
      
      contextsClone = Array.prototype.slice.call(contexts)
      context = matchContext contexts, key
      collection = context.get key
      
      if collection?.observe
        collection.observe 'add', add = (item) ->
          newNode = prototype.cloneNode true
          nodeMap.set item, newNode
          
          renderer = new Batman.Renderer newNode, ->
            parent.appendChild newNode
            parentRenderer.allow 'ready'
          
          renderer.contexts = localClone = Array.prototype.slice.call(contextsClone)
          renderer.contextObject = Batman localClone[1]
          
          iteratorContext = new Batman.Object
          iteratorContext[iteratorName] = item
          localClone.push iteratorContext
          localClone.push item
        
        collection.observe 'remove', remove = (item) ->
          oldNode = nodeMap.get item
          oldNode?.parentNode?.removeChild oldNode
        
        collection.observe 'sort', ->
          collection.each remove
          setTimeout (-> collection.each add), 0
        
        collection.each (item) ->
          parentRenderer.prevent 'ready'
          add(item)
      
      false
  }

  
  # `Batman.DOM.events` contains the helpers used for binding to events. These aren't called by
  # DOM directives, but are used to handle specific events by the `data-event-#{name}` helper.
  events: {
    click: (node, callback) ->
      Batman.DOM.addEventListener node, 'click', (e) ->
        callback?.apply @, arguments
        e.preventDefault()
      
      if node.nodeName.toUpperCase() is 'A' and not node.href
        node.href = '#'
    
    change: (node, callback) ->
      eventName = switch node.nodeName.toUpperCase()
        when 'TEXTAREA' then 'keyup'
        when 'INPUT'
          if node.type.toUpperCase() is 'TEXT' then 'keyup' else 'change'
        else 'change'
      
      Batman.DOM.addEventListener node, eventName, callback
    
    submit: (node, callback) ->
      if Batman.DOM.nodeIsEditable(node)
        Batman.DOM.addEventListener node, 'keyup', (e) ->
          if e.keyCode is 13
            callback.apply @, arguments
            e.preventDefault()
      else
        Batman.DOM.addEventListener node, 'submit', (e) ->
          callback.apply @, arguments
          e.preventDefault()
  }
  
  # `yield` and `contentFor` are used to declare partial views and then pull them in elsewhere.
  # This can be used for abstraction as well as repetition.
  yield: (name, node) ->
    yields = Batman.DOM._yields ||= {}
    yields[name] = node
    
    if (content = Batman.DOM._yieldContents?[name])
      node.innerHTML = ''
      node.appendChild(content) if content
  
  contentFor: (name, node) ->
    contents = Batman.DOM._yieldContents ||= {}
    contents[name] = node
    
    if (yield = Batman.DOM._yields?[name])
      yield.innerHTML = ''
      yield.appendChild(node) if node
  
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

# Helpers
# -------

camelize_rx = /(?:^|_)(.)/g
underscore_rx1 = /([A-Z]+)([A-Z][a-z])/g
underscore_rx2 = /([a-z\d])([A-Z])/g

# Just a few random Rails-style string helpers. You can add more
# to the Batman.helpers object.
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

# Filters
# -------
filters = Batman.filters = {}

# Mixins
# ------
mixins = Batman.mixins = new Batman.Object

# Export a few globals, and grab a reference to an object accessible from all contexts for use elsewhere.
# In node, the container is the `global` object, and in the browser, the container is the window object.
container = if exports?
  exports.Batman = Batman
  global
else
  window.Batman = Batman
  window

$mixin container, Batman.Observable

# Optionally export global sugar. Not sure what to do with this.
Batman.exportHelpers = (onto) ->
  onto.$typeOf = $typeOf
  onto.$mixin = $mixin
  onto.$unmixin = $unmixin
  onto.$route = $route
  onto.$redirect = $redirect
  onto.$event = $event
  onto.$eventOneShot = $eventOneShot

Batman.exportGlobals = () ->
  Batman.exportHelpers(container)
