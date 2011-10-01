#
# batman.js
#
# Created by Nick Small
# Copyright 2011, Shopify
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
  return "Undefined" if typeof object == 'undefined'
  _objectToString.call(object).slice(8, -1)

# Cache this function to skip property lookups.
_objectToString = Object.prototype.toString

# `$mixin` applies every key from every argument after the first to the
# first argument. If a mixin has an `initialize` method, it will be called in
# the context of the `to` object, and it's key/values won't be applied.
Batman.mixin = $mixin = (to, mixins...) ->
  hasSet = typeof to.set is 'function'

  for mixin in mixins
    continue if $typeOf(mixin) isnt 'Object'

    for own key, value of mixin
      continue if key in  ['initialize', 'uninitialize', 'prototype']
      if hasSet
        to.set(key, value)
      else if to.nodeName?
        Batman.data to, key, value
      else
        to[key] = value

    if typeof mixin.initialize is 'function'
      mixin.initialize.call to

  to

# `$unmixin` removes every key/value from every argument after the first
# from the first argument. If a mixin has a `deinitialize` method, it will be
# called in the context of the `from` object and won't be removed.
Batman.unmixin = $unmixin = (from, mixins...) ->
  for mixin in mixins
    for key of mixin
      continue if key in ['initialize', 'uninitialize']

      delete from[key]

    if typeof mixin.uninitialize is 'function'
      mixin.uninitialize.call from

  from

# `$block` takes in a function and returns a function which can either
#   A) take a callback as its last argument as it would normally, or
#   B) accept a callback as a second function application.
# This is useful so that multiline functions can be passed as callbacks
# without the need for wrapping brackets (which a CoffeeScript bug
# requires them to have). `$block` also takes an optional function airity
# argument as the first argument. If a `length` argument is given, and `length`
# or more arguments are passed, `$block` will call the second argument
# (the function) with the passed arguments, regardless of their type.
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
Batman._block = $block = (lengthOrFunction, fn) ->
  if fn?
    argsLength = lengthOrFunction
  else
    fn = lengthOrFunction

  callbackEater = (args...) ->
    ctx = @
    f = (callback) ->
      args.push callback
      fn.apply(ctx, args)

    # Call the function right now if we've been passed the callback already or if we've reached the argument count threshold
    if (typeof args[args.length-1] is 'function') || (argsLength && (args.length >= argsLength))
      f(args.pop())
    else
      f


# `findName` allows an anonymous function to find out what key it resides
# in within a context.
Batman._findName = $findName = (f, context) ->
  unless f.displayName
    for key, value of context
      if value is f
        f.displayName = key
        break

  f.displayName

# `$functionName` returns the name of a given function, if any
# Used to deal with functions not having the `name` property in IE
Batman._functionName = $functionName = (f) ->
  return f.__name__ if f.__name__
  return f.name if f.name
  f.toString().match(/\W*function\s+([\w\$]+)\(/)?[1]

# `$preventDefault` checks for preventDefault, since it's not
# always available across all browsers
Batman._preventDefault = $preventDefault = (e) ->
  if typeof e.preventDefault is "function" then e.preventDefault() else e.returnValue = false

Batman._isChildOf = $isChildOf = (parentNode, childNode) ->
  node = childNode.parentNode
  while node
    return true if node == parentNode
    node = node.parentNode
  false

# Developer Tooling
# -----------------

developer =
  DevelopmentError: (->
    DevelopmentError = (@message) ->
      @name = "DevelopmentError"
    DevelopmentError:: = Error::
    DevelopmentError
  )()
  _ie_console: (f, args) ->
    console?[f] "...#{f} of #{args.length} items..." unless args.length == 1
    console?[f] arg for arg in args
  log: ->
    return unless console?.log?
    if console.log.apply then console.log(arguments...) else developer._ie_console "log", arguments
  warn: ->
    return unless console?.warn?
    if console.warn.apply then console.warn(arguments...) else developer._ie_console "warn", arguments
  error: (message) -> throw new developer.DevelopmentError(message)
  assert: (result, message) -> developer.error(message) unless result
  do: (f) -> f()
  addFilters: ->
    $mixin Batman.Filters,
      log: (value, key) ->
        console?.log? arguments
        value

      logStack: (value) ->
        console?.log? developer.currentFilterStack
        value

      logContext: (value) ->
        console?.log? developer.currentFilterContext
        value

Batman.developer = developer

# Helpers
# -------

camelize_rx = /(?:^|_|\-)(.)/g
capitalize_rx = /(^|\s)([a-z])/g
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
    len = string.length
    if string.substr(len - 3) is 'ies'
      string.substr(0, len - 3) + 'y'
    else if string.substr(len - 1) is 's'
      string.substr(0, len - 1)
    else
      string

  pluralize: (count, string) ->
    if string
      return string if count is 1
    else
      string = count

    len = string.length
    lastLetter = string.substr(len - 1)
    if lastLetter is 'y'
      "#{string.substr(0, len - 1)}ies"
    else if lastLetter is 's'
      string
    else
      "#{string}s"

  capitalize: (string) -> string.replace capitalize_rx, (m,p1,p2) -> p1+p2.toUpperCase()

  trim: (string) -> if string then string.trim() else ""
}


class Batman.Event
  @forBaseAndKey: (base, key) ->
    if base.isEventEmitter
      base.event(key)
    else
      new Batman.Event(base, key)
  constructor: (@base, @key) ->
    @handlers = new Batman.SimpleSet
    @_preventCount = 0
  isEvent: true
  isEqual: (other) ->
    @constructor is other.constructor and @base is other.base and @key is other.key
  hashKey: ->
    @hashKey = -> key
    key = "<Batman.Event base: #{Batman.Hash::hashKeyFor(@base)}, key: \"#{Batman.Hash::hashKeyFor(@key)}\">"

  addHandler: (handler) ->
    @handlers.add(handler)
    @autofireHandler(handler) if @oneShot
    this
  removeHandler: (handler) ->
    @handlers.remove(handler)
    this

  eachHandler: (iterator) ->
    @handlers.forEach(iterator)
    if @base?.isEventEmitter
      key = @key
      @base._batman.ancestors (ancestor) ->
        if ancestor.isEventEmitter
          handlers = ancestor.event(key).handlers
          handlers.forEach(iterator)

  handlerContext: -> @base

  prevent: -> ++@_preventCount
  allow: ->
    --@_preventCount if @_preventCount
    @_preventCount
  isPrevented: -> @_preventCount > 0
  autofireHandler: (handler) ->
    if @_oneShotFired and @_oneShotArgs?
      handler.apply(@handlerContext(), @_oneShotArgs)
  resetOneShot: ->
    @_oneShotFired = false
    @_oneShotArgs = null
  fire: ->
    return false if @isPrevented() or @_oneShotFired
    context = @handlerContext()
    args = arguments
    if @oneShot
      @_oneShotFired = true
      @_oneShotArgs = arguments
    @eachHandler (handler) -> handler.apply(context, args)


class Batman.PropertyEvent extends Batman.Event
  eachHandler: (iterator) -> @base.eachObserver(iterator)
  handlerContext: -> @base.base

Batman.EventEmitter =
  isEventEmitter: true
  event: (key) ->
    Batman.initializeObject @
    eventClass = @eventClass or Batman.Event
    events = @_batman.events ||= new Batman.SimpleHash
    if existingEvent = events.get(key)
      existingEvent
    else
      existingEvents = @_batman.get('events')
      newEvent = events.set(key, new eventClass(this, key))
      newEvent.oneShot = existingEvents?.get(key)?.oneShot
      newEvent
  on: (key, handler) ->
    @event(key).addHandler(handler)
  registerAsMutableSource: ->
    Batman.Property.registerSource(@)
  mutation: (wrappedFunction) ->
    ->
      result = wrappedFunction.apply(this, arguments)
      @event('change').fire(this, this)
      result

for k in ['prevent', 'allow', 'fire', 'isPrevented']
  do (k) ->
    Batman.EventEmitter[k] = (key, args...) ->
      @event(key)[k](args...)
      @

class Batman.Property
  $mixin @prototype, Batman.EventEmitter

  @_sourceTrackerStack: []
  @sourceTracker: -> (stack = @_sourceTrackerStack)[stack.length - 1]
  @defaultAccessor:
    get: (key) -> @[key]
    set: (key, val) -> @[key] = val
    unset: (key) -> x = @[key]; delete @[key]; x
  @forBaseAndKey: (base, key) ->
    if base.isObservable
      base.property(key)
    else
      new Batman.Keypath(base, key)

  @registerSource: (obj) ->
    return unless obj.isEventEmitter
    @sourceTracker()?.add(obj)

  constructor: (@base, @key) ->

  _isolationCount: 0
  cached: no
  value: null
  sources: null
  isProperty: true
  eventClass: Batman.PropertyEvent

  isEqual: (other) ->
    @constructor is other.constructor and @base is other.base and @key is other.key
  hashKey: ->
    @hashKey = -> key
    key = "<Batman.Property base: #{Batman.Hash::hashKeyFor(@base)}, key: \"#{Batman.Hash::hashKeyFor(@key)}\">"

  accessor: ->
    accessors = @base._batman?.get('keyAccessors')
    if accessors && (val = accessors.get(@key))
      return val
    else
      @base._batman?.getFirst('defaultAccessor') or Batman.Property.defaultAccessor
  eachObserver: (iterator) ->
    key = @key
    @event('change').handlers.forEach(iterator)
    if @base.isObservable
      @base._batman.ancestors (ancestor) ->
        if ancestor.isObservable
          property = ancestor.property(key)
          handlers = property.event('change').handlers
          handlers.forEach(iterator)

  pushSourceTracker: -> Batman.Property._sourceTrackerStack.push(new Batman.SimpleSet)
  updateSourcesFromTracker: ->
    newSources = Batman.Property._sourceTrackerStack.pop()
    handler = @sourceChangeHandler()
    @_eachSourceChangeEvent (e) -> e.removeHandler(handler)
    @sources = newSources
    @_eachSourceChangeEvent (e) -> e.addHandler(handler)

  _eachSourceChangeEvent: (iterator) ->
    return unless @sources?
    @sources.forEach (source) -> iterator(source.event('change'))

  getValue: ->
    @registerAsMutableSource()
    unless @cached
      @pushSourceTracker()
      @value = @valueFromAccessor()
      @cached = yes
      @updateSourcesFromTracker()
    @value

  refresh: ->
    @cached = no
    previousValue = @value
    value = @getValue()
    unless value is previousValue or @isIsolated()
      @fire(value, previousValue)

  sourceChangeHandler: ->
    @sourceChangeHandler = -> handler
    handler = => @_handleSourceChange()

  _markNeedsRefresh: -> @_needsRefresh = true
  _handleSourceChange: @::refresh

  valueFromAccessor: -> @accessor()?.get?.call(@base, @key)

  setValue: (val) ->
    result = @accessor()?.set?.call(@base, @key, val)
    @refresh()
    result
  unsetValue: ->
    result = @accessor()?.unset?.call(@base, @key)
    @refresh()
    result

  forget: (handler) ->
    if handler?
      @event('change').removeHandler(handler)
    else
      @event('change').handlers.clear()
  observeAndFire: (handler) ->
    @observe(handler)
    handler.call(@base, @value, @value)
  observe: (handler) ->
    @event('change').addHandler(handler)
    @getValue()
    this

  fire: -> @event('change').fire(arguments...)

  isolate: ->
    if @_isolationCount is 0
      @_preIsolationValue = @getValue()
      @_handleSourceChange = @_markNeedsRefresh
    @_isolationCount++
  expose: ->
    if @_isolationCount is 1
      @_isolationCount--
      @_handleSourceChange = @refresh
      if @_needsRefresh
        @value = @_preIsolationValue
        @refresh()
      else if @value isnt @_preIsolationValue
        @fire(@value, @_preIsolationValue)
      @_preIsolationValue = null
    else if @_isolationCount > 0
      @_isolationCount--
  isIsolated: -> @_isolationCount > 0


# Keypaths
# --------

class Batman.Keypath extends Batman.Property
  constructor: (base, key) ->
    if $typeOf(key) is 'String'
      @segments = key.split('.')
      @depth = @segments.length
    else
      @segments = [key]
      @depth = 1
    super
  slice: (begin, end=@depth) ->
    base = @base
    for segment in @segments.slice(0, begin)
      return unless base? and base = Batman.Property.forBaseAndKey(base, segment).getValue()
    Batman.Property.forBaseAndKey base, @segments.slice(begin, end).join('.')
  terminalProperty: -> @slice -1
  valueFromAccessor: ->
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
    Batman.initializeObject @
    propertyClass = @propertyClass or Batman.Keypath
    properties = @_batman.properties ||= new Batman.SimpleHash
    properties.get(key) or properties.set(key, new propertyClass(this, key))
  get: (key) ->
    @property(key).getValue()
  set: (key, val) ->
    @property(key).setValue(val)
  unset: (key) ->
    @property(key).unsetValue()

  getOrSet: (key, valueFunction) ->
    currentValue = @get(key)
    unless currentValue
      currentValue = valueFunction()
      @set(key, currentValue)
    currentValue

  # `forget` removes an observer from an object. If the callback is passed in,
  # its removed. If no callback but a key is passed in, all the observers on
  # that key are removed. If no key is passed in, all observers are removed.
  forget: (key, observer) ->
    if key
      @property(key).forget(observer)
    else
      @_batman.properties.forEach (key, property) -> property.forget()
    @

# `fire` tells any observers attached to a key to fire, manually.
# `prevent` stops of a given binding from firing. `prevent` calls can be repeated such that
# the same number of calls to allow are needed before observers can be fired.
# `allow` unblocks a property for firing observers. Every call to prevent
# must have a matching call to allow later if observers are to be fired.
# `observe` takes a key and a callback. Whenever the value for that key changes, your
# callback will be called in the context of the original object.

  observe: (key, args...) ->
    @property(key).observe(args...)
    @

  observeAndFire: (key, args...) ->
    @property(key).observeAndFire(args...)
    @

$get = Batman.get = (object, key) ->
  if object.get
    object.get(key)
  else
    Batman.Observable.get.call(object, key)

# Objects
# -------

# `Batman.initializeObject` is called by all the methods in Batman.Object to ensure that the
# object's `_batman` property is initialized and it's own. Classes extending Batman.Object inherit
# methods like `get`, `set`, and `observe` by default on the class and prototype levels, such that
# both instances and the class respond to them and can be bound to. However, CoffeeScript's static
# class inheritance copies over all class level properties indiscriminately, so a parent class'
# `_batman` object will get copied to its subclasses, transferring all the information stored there and
# allowing subclasses to mutate parent state. This method prevents this undesirable behaviour by tracking
# which object the `_batman_` object was initialized upon, and reinitializing if that has changed since
# initialization.
Batman.initializeObject = (object) ->
  if object._batman?
    object._batman.check(object)
  else
    object._batman = new _Batman(object)

# _Batman provides a convienient, parent class and prototype aware place to store hidden
# object state. Things like observers, accessors, and states belong in the `_batman` object
# attached to every Batman.Object subclass and subclass instance.
Batman._Batman = class _Batman
  constructor: (@object, mixins...) ->
    $mixin(@, mixins...) if mixins.length > 0

  # Used by `Batman.initializeObject` to ensure that this `_batman` was created referencing
  # the object it is pointing to.
  check: (object) ->
    if object != @object
      object._batman = new _Batman(object)
      return false
    return true

  # `get` is a prototype and class aware property access method. `get` will traverse the prototype chain, asking
  # for the passed key at each step, and then attempting to merge the results into one object.
  # It can only do this if at each level an `Array`, `Hash`, or `Set` is found, so try to use
  # those if you need `_batman` inhertiance.
  get: (key) ->
    # Get all the keys from the ancestor chain
    results = @getAll(key)
    switch results.length
      when 0
        undefined
      when 1
        results[0]
      else
        # And then try to merge them if there is more than one. Use `concat` on arrays, and `merge` on
        # sets and hashes.
        if results[0].concat?
          results = results.reduceRight (a, b) -> a.concat(b)
        else if results[0].merge?
          results = results.reduceRight (a, b) -> a.merge(b)
        results

  # `getFirst` is a prototype and class aware property access method. `getFirst` traverses the prototype chain,
  # and returns the value of the first `_batman` object which defines the passed key. Useful for
  # times when the merged value doesn't make sense or the value is a primitive.
  getFirst: (key) ->
    results = @getAll(key)
    results[0]

  # `getAll` is a prototype and class chain iterator. When passed a key or function, it applies it to each
  # parent class or parent prototype, and returns the undefined values, closest ancestor first.
  getAll: (keyOrGetter) ->
    # Get a function which pulls out the key from the ancestor's `_batman` or use the passed function.
    if typeof keyOrGetter is 'function'
      getter = keyOrGetter
    else
      getter = (ancestor) -> ancestor._batman?[keyOrGetter]

    # Apply it to all the ancestors, and then this `_batman`'s object.
    results = @ancestors(getter)
    if val = getter(@object)
      results.unshift val
    results

  # `ancestors` traverses the prototype or class chain and returns the application of a function to each
  # object in the chain. `ancestors` does this _only_ to the `@object`'s ancestors, and not the `@object`
  # itsself.
  ancestors: (getter = (x) -> x) ->
    results = []
    # Decide if the object is a class or not, and pull out the first ancestor
    isClass = !!@object.prototype
    parent = if isClass
      @object.__super__?.constructor
    else
      if (proto = Object.getPrototypeOf(@object)) == @object
        @object.constructor.__super__
      else
        proto

    if parent?
      # Apply the function and store the result if it isn't undefined.
      val = getter(parent)
      results.push(val) if val?

      # Use a recursive call to `_batman.ancestors` on the ancestor, which will take the next step up the chain.
      results = results.concat(parent._batman.ancestors(getter)) if parent._batman?
    results

  set: (key, value) ->
    @[key] = value

# `Batman.Object` is the base class for all other Batman objects. It is not abstract.
class BatmanObject
  Batman.initializeObject(this)
  Batman.initializeObject(@prototype)
  # Setting `isGlobal` to true will cause the class name to be defined on the
  # global object. For example, Batman.Model will be aliased to window.Model.
  # This should be used sparingly; it's mostly useful for debugging.
  @global: (isGlobal) ->
    return if isGlobal is false
    container[$functionName(@)] = @

  # Apply mixins to this class.
  @classMixin: -> $mixin @, arguments...

  # Apply mixins to instances of this class.
  @mixin: -> @classMixin.apply @prototype, arguments
  mixin: @classMixin

  counter = 0
  _objectID: ->
    @_objectID = -> c
    c = counter++

  hashKey: ->
    return if typeof @isEqual is 'function'
    @hashKey = -> key
    key = "<Batman.Object #{@_objectID()}>"


  # Accessor implementation. Accessors are used to create properties on a class or prototype which can be fetched
  # with get, but are computed instead of just stored. This is a batman and old browser friendly version of
  # `defineProperty` without as much goodness.
  #
  # Accessors track which other properties they rely on for computation, and when those other properties change,
  # an accessor will recalculate its value and notifiy its observers. This way, when a source value is changed,
  # any dependent accessors will automatically update any bindings to them with a new value. Accessors accomplish
  # this feat by tracking `get` calls, do be sure to use `get` to retrieve properties inside accessors.
  #
  # `@accessor` or `@classAccessor` can be called with zero, one, or many keys to attach the accessor to. This
  # has the following effects:
  #
  #   * zero: create a `defaultAccessor`, which will be called when no other properties or accessors on an object
  #   match a keypath. This is similar to `method_missing` in Ruby or `#doesNotUnderstand` in Smalltalk.
  #   * one: create a `keyAccessor` at the given key, which will only be called when that key is `get`ed.
  #   * many: create `keyAccessors` for each given key, which will then be called whenever each key is `get`ed.
  #
  # Note: This function gets called in all sorts of different contexts by various
  # other pointers to it, but it acts the same way on `this` in all cases.
  getAccessorObject = (accessor) ->
    accessor = {get: accessor} if !accessor.get && !accessor.set && !accessor.unset
    accessor

  @classAccessor: (keys..., accessor) ->
    Batman.initializeObject @
    # Create a default accessor if no keys have been given.
    if keys.length is 0
      # The `accessor` argument is wrapped in `getAccessorObject` which allows functions to be passed in
      # as a shortcut to {get: function}
      @_batman.defaultAccessor = getAccessorObject(accessor)
    else
      # Otherwise, add key accessors for each key given.
      @_batman.keyAccessors ||= new Batman.SimpleHash
      @_batman.keyAccessors.set(key, getAccessorObject(accessor)) for key in keys

  # Support adding accessors to the prototype from within class defintions or after the class has been created
  # with `KlassExtendingBatmanObject.accessor(keys..., accessorObject)`
  @accessor: -> @classAccessor.apply @prototype, arguments
  # Support adding accessors to instances after creation
  accessor: @classAccessor

  constructor: (mixins...) ->
    @_batman = new _Batman(@)
    @mixin mixins...


  # Make every subclass and their instances observable.
  @classMixin Batman.EventEmitter, Batman.Observable
  @mixin Batman.EventEmitter, Batman.Observable

  # Observe this property on every instance of this class.
  @observeAll: -> @::observe.apply @prototype, arguments

  @singleton: (singletonMethodName="sharedInstance") ->
    @classAccessor singletonMethodName,
      get: -> @["_#{singletonMethodName}"] ||= new @

Batman.Object = BatmanObject

class Batman.Accessible extends Batman.Object
  constructor: -> @accessor.apply(@, arguments)


# Collections

Batman.Enumerable =
  isEnumerable: true
  map:   (f, ctx = container) -> r = []; @forEach(-> r.push f.apply(ctx, arguments)); r
  every: (f, ctx = container) -> r = true; @forEach(-> r = r && f.apply(ctx, arguments)); r
  some:  (f, ctx = container) -> r = false; @forEach(-> r = r || f.apply(ctx, arguments)); r
  reduce: (f, r) ->
    count = 0
    self = @
    @forEach -> if r? then r = f(r, arguments..., count, self) else r = arguments[0]
    r
  filter: (f) ->
    r = new @constructor
    if r.add
      wrap = (r, e) -> r.add(e) if f(e); r
    else if r.set
      wrap = (r, k, v) -> r.set(k, v) if f(k, v); r
    else
      r = [] unless r.push
      wrap = (r, e) -> r.push(e) if f(e); r
    @reduce wrap, r

# Provide this simple mixin ability so that during bootstrapping we don't have to use `$mixin`. `$mixin`
# will correctly attempt to use `set` on the mixinee, which ends up requiring the definition of
# `SimpleSet` to be complete during its definition.
$extendsEnumerable = (onto) -> onto[k] = v for k,v of Batman.Enumerable

class Batman.SimpleHash
  constructor: ->
    @_storage = {}
    @length = 0
  $extendsEnumerable(@::)
  propertyClass: Batman.Property
  hasKey: (key) ->
    if pairs = @_storage[@hashKeyFor(key)]
      for pair in pairs
        return true if @equality(pair[0], key)
    return false
  get: (key) ->
    if pairs = @_storage[@hashKeyFor(key)]
      for pair in pairs
        return pair[1] if @equality(pair[0], key)
  set: (key, val) ->
    pairs = @_storage[@hashKeyFor(key)] ||= []
    for pair in pairs
      if @equality(pair[0], key)
        return pair[1] = val
    @length++
    pairs.push([key, val])
    val
  unset: (key) ->
    if pairs = @_storage[@hashKeyFor(key)]
      for [obj,value], index in pairs
        if @equality(obj, key)
          pairs.splice(index,1)
          @length--
          return
  getOrSet: Batman.Observable.getOrSet
  hashKeyFor: (obj) -> obj?.hashKey?() or obj
  equality: (lhs, rhs) ->
    return true if lhs is rhs
    return true if lhs isnt lhs and rhs isnt rhs # when both are NaN
    return true if lhs?.isEqual?(rhs) and rhs?.isEqual?(lhs)
    return false
  forEach: (iterator) ->
    for key, values of @_storage
      iterator(obj, value) for [obj, value] in values.slice()
  keys: ->
    result = []
    # Explicitly reference this foreach so that if it's overriden in subclasses the new implementation isn't used.
    Batman.SimpleHash::forEach.call @, (obj) -> result.push obj
    result
  clear: ->
    @_storage = {}
    @length = 0
  isEmpty: ->
    @length is 0
  merge: (others...) ->
    merged = new @constructor
    others.unshift(@)
    for hash in others
      hash.forEach (obj, value) ->
        merged.set obj, value
    merged

class Batman.Hash extends Batman.Object
  constructor: ->
    Batman.SimpleHash.apply(@, arguments)
    # Add a meta object to all hashes which we can then use in the `meta` filter to allow binding
    # to hash meta-properties without reserving keys.
    @meta = new Batman.Object
    self = this
    @meta.accessor 'length', ->
      self.registerAsMutableSource()
      self.length
    @meta.accessor 'isEmpty', -> self.isEmpty()
    @meta.accessor 'keys', -> self.keys()
    super

  $extendsEnumerable(@::)
  propertyClass: Batman.Property

  @accessor
    get: Batman.SimpleHash::get
    set: @mutation(Batman.SimpleHash::set)
    unset: @mutation(Batman.SimpleHash::unset)

  clear: @mutation(Batman.SimpleHash::clear)
  equality: Batman.SimpleHash::equality
  hashKeyFor: Batman.SimpleHash::hashKeyFor

  for k in ['hasKey', 'forEach', 'isEmpty', 'keys', 'merge']
    proto = @prototype
    do (k) ->
      proto[k] = ->
        @registerAsMutableSource()
        Batman.SimpleHash::[k].apply(@, arguments)

class Batman.SimpleSet
  constructor: ->
    @_storage = new Batman.SimpleHash
    @_indexes = new Batman.SimpleHash
    @_sorts = new Batman.SimpleHash
    @length = 0
    @add.apply @, arguments if arguments.length > 0

  $extendsEnumerable(@::)

  has: (item) ->
    @_storage.hasKey item

  add: (items...) ->
    addedItems = []
    for item in items when !@_storage.hasKey(item)
      @_storage.set item, true
      addedItems.push item
      @length++
    if @fire and addedItems.length isnt 0
      @fire('change', this, this)
      @fire('itemsWereAdded', addedItems...)
    addedItems
  remove: (items...) ->
    removedItems = []
    for item in items when @_storage.hasKey(item)
      @_storage.unset item
      removedItems.push item
      @length--
    if @fire and removedItems.length isnt 0
      @fire('change', this, this)
      @fire('itemsWereRemoved', removedItems...)
    removedItems
  forEach: (iterator) ->
    @_storage.forEach (key, value) -> iterator(key)
  isEmpty: -> @length is 0
  clear: ->
    items = @toArray()
    @_storage = new Batman.SimpleHash
    @length = 0
    if @fire and items.length isnt 0
      @fire('change', this, this)
      @fire('itemsWereRemoved', items...)
    items
  toArray: ->
    @_storage.keys()
  merge: (others...) ->
    merged = new @constructor
    others.unshift(@)
    for set in others
      set.forEach (v) -> merged.add v
    merged
  indexedBy: (key) ->
    @_indexes.get(key) or @_indexes.set(key, new Batman.SetIndex(@, key))
  sortedBy: (key) ->
    @_sorts.get(key) or @_sorts.set(key, new Batman.SetSort(@, key))

class Batman.Set extends Batman.Object
  constructor: ->
    Batman.SimpleSet.apply @, arguments

  $extendsEnumerable(@::)

  for k in ['add', 'remove', 'clear', 'indexedBy', 'sortedBy']
    @::[k] = Batman.SimpleSet::[k]

  for k in ['merge', 'forEach', 'toArray', 'isEmpty', 'has']
    proto = @prototype
    do (k) ->
      proto[k] = ->
        @registerAsMutableSource()
        Batman.SimpleSet::[k].apply(@, arguments)

  toJSON: @::toArray

  @accessor 'indexedBy', -> new Batman.Accessible (key) => @indexedBy(key)
  @accessor 'sortedBy', -> new Batman.Accessible (key) => @sortedBy(key)
  @accessor 'isEmpty', -> @isEmpty()
  @accessor 'length', ->
    @registerAsMutableSource()
    @length

class Batman.SetObserver extends Batman.Object
  constructor: (@base) ->
    @_itemObservers = new Batman.Hash
    @_setObservers = new Batman.Hash
    @_setObservers.set "itemsWereAdded", => @fire('itemsWereAdded', arguments...)
    @_setObservers.set "itemsWereRemoved", => @fire('itemsWereRemoved', arguments...)
    @on 'itemsWereAdded', @startObservingItems.bind(@)
    @on 'itemsWereRemoved', @stopObservingItems.bind(@)

  observedItemKeys: []
  observerForItemAndKey: (item, key) ->

  _getOrSetObserverForItemAndKey: (item, key) ->
    @_itemObservers.getOrSet item, =>
      observersByKey = new Batman.Hash
      observersByKey.getOrSet key, =>
        @observerForItemAndKey(item, key)
  startObserving: ->
    @_manageItemObservers("observe")
    @_manageSetObservers("addHandler")
  stopObserving: ->
    @_manageItemObservers("forget")
    @_manageSetObservers("removeHandler")
  startObservingItems: (items...) ->
    @_manageObserversForItem(item, "observe") for item in items
  stopObservingItems: (items...) ->
    @_manageObserversForItem(item, "forget") for item in items
  _manageObserversForItem: (item, method) ->
    return unless item.isObservable
    for key in @observedItemKeys
      item[method] key, @_getOrSetObserverForItemAndKey(item, key)
    @_itemObservers.unset(item) if method is "forget"
  _manageItemObservers: (method) ->
    @base.forEach (item) => @_manageObserversForItem(item, method)
  _manageSetObservers: (method) ->
    return unless @base.isObservable
    @_setObservers.forEach (key, observer) =>
      @base.event(key)[method](observer)

class Batman.SetSort extends Batman.Object
  constructor: (@base, @key) ->
    if @base.isObservable
      @_setObserver = new Batman.SetObserver(@base)
      @_setObserver.observedItemKeys = [@key]
      boundReIndex = @_reIndex.bind(@)
      @_setObserver.observerForItemAndKey = -> boundReIndex
      @_setObserver.on 'itemsWereAdded', boundReIndex
      @_setObserver.on 'itemsWereRemoved', boundReIndex
      @startObserving()
    @_reIndex()
  startObserving: -> @_setObserver?.startObserving()
  stopObserving: -> @_setObserver?.stopObserving()
  toArray: -> @get('_storage')
  @accessor 'toArray', @::toArray
  forEach: (iterator) -> iterator(e,i) for e,i in @get('_storage')
  compare: (a,b) ->
    return 0 if a is b
    return 1 if a is undefined
    return -1 if b is undefined
    return 1 if a is null
    return -1 if b is null
    return 0 if a.isEqual?(b) and b.isEqual?(a)
    typeComparison = Batman.SetSort::compare($typeOf(a), $typeOf(b))
    return typeComparison if typeComparison isnt 0
    return 1 if a isnt a # means a is NaN
    return -1 if b isnt b # means b is NaN
    return 1 if a > b
    return -1 if a < b
    return 0
  _reIndex: ->
    newOrder = @base.toArray().sort (a,b) =>
      valueA = Batman.Observable.property.call(a, @key).getValue()
      valueA = valueA.valueOf() if valueA?
      valueB = Batman.Observable.property.call(b, @key).getValue()
      valueB = valueB.valueOf() if valueB?
      @compare.call(@, valueA, valueB)
    @_setObserver?.startObservingItems(newOrder...)
    @set('_storage', newOrder)

class Batman.SetIndex extends Batman.Object
  constructor: (@base, @key) ->
    @_storage = new Batman.Hash
    if @base.isEventEmitter
      @_setObserver = new Batman.SetObserver(@base)
      @_setObserver.observedItemKeys = [@key]
      @_setObserver.observerForItemAndKey = @observerForItemAndKey.bind(@)
      @_setObserver.on 'itemsWereAdded', (items...) =>
        @_addItem(item) for item in items
      @_setObserver.on 'itemsWereRemoved', (items...) =>
        @_removeItem(item) for item in items
    @base.forEach @_addItem.bind(@)
    @startObserving()
  @accessor (key) -> @_resultSetForKey(key)
  startObserving: ->@_setObserver?.startObserving()
  stopObserving: -> @_setObserver?.stopObserving()
  observerForItemAndKey: (item, key) ->
    (newValue, oldValue) =>
      @_removeItemFromKey(item, oldValue)
      @_addItemToKey(item, newValue)
  _addItem: (item) -> @_addItemToKey(item, @_keyForItem(item))
  _addItemToKey: (item, key) ->
    @_resultSetForKey(key).add item
  _removeItem: (item) -> @_removeItemFromKey(item, @_keyForItem(item))
  _removeItemFromKey: (item, key) ->
    @_resultSetForKey(key).remove item
  _resultSetForKey: (key) ->
    @_storage.getOrSet(key, -> new Batman.Set)
  _keyForItem: (item) ->
    Batman.Keypath.forBaseAndKey(item, @key).getValue()

class Batman.UniqueSetIndex extends Batman.SetIndex
  constructor: ->
    @_uniqueIndex = new Batman.Hash
    super
  @accessor (key) -> @_uniqueIndex.get(key)
  _addItemToKey: (item, key) ->
    @_resultSetForKey(key).add item
    unless @_uniqueIndex.hasKey(key)
      @_uniqueIndex.set(key, item)
  _removeItemFromKey: (item, key) ->
    resultSet = @_resultSetForKey(key)
    resultSet.remove item
    if resultSet.length is 0
      @_uniqueIndex.unset(key)
    else
      @_uniqueIndex.set(key, resultSet.toArray()[0])

class Batman.SortableSet extends Batman.Set
  constructor: ->
    super
    @_sortIndexes = {}
    @observe 'activeIndex', =>
      @setWasSorted()
  setWasSorted: -> @fire('setWasSorted') unless @length is 0

  for k in ['add', 'remove', 'clear']
    do (k) =>
      @::[k] = ->
        results = Batman.Set::[k].apply(@, arguments)
        @_reIndex()
        results

  isSortableSet: yes

  addIndex: (index) ->
    @_reIndex(index)
  removeIndex: (index) ->
    @_sortIndexes[index] = null
    delete @_sortIndexes[index]
    @unset('activeIndex') if @activeIndex is index
    index
  forEach: (iterator) ->
    iterator(el) for el in @toArray()
  sortBy: (index) ->
    @addIndex(index) unless @_sortIndexes[index]
    @set('activeIndex', index) unless @activeIndex is index
    @
  isSorted: ->
    @_sortIndexes[@get('activeIndex')]?
  toArray: ->
    @_sortIndexes[@get('activeIndex')] || super

  _reIndex: (index) ->
    if index
      [keypath, ordering] = index.split ' '
      ary = Batman.Set.prototype.toArray.call @
      @_sortIndexes[index] = ary.sort (a,b) ->
        valueA = (Batman.Observable.property.call(a, keypath)).getValue()?.valueOf()
        valueB = (Batman.Observable.property.call(b, keypath)).getValue()?.valueOf()
        [valueA, valueB] = [valueB, valueA] if ordering?.toLowerCase() is 'desc'
        if valueA < valueB then -1 else if valueA > valueB then 1 else 0
      @setWasSorted() if @activeIndex is index
    else
      @_reIndex(index) for index of @_sortIndexes
      @setWasSorted()
    @

# State Machines
# --------------

Batman.StateMachine = {
  initialize: ->
    Batman.initializeObject @
    if not @_batman.states
      @_batman.states = new Batman.SimpleHash

  state: (name, callback) ->
    Batman.StateMachine.initialize.call @

    return @_batman.getFirst 'state' unless name
    developer.assert @isEventEmitter, "StateMachine requires EventEmitter"

    @[name] ||= (callback) -> _stateMachine_setState.call(@, name)
    @on(name, callback) if typeof callback is 'function'

  transition: (from, to, callback) ->
    Batman.StateMachine.initialize.call @
    @state from
    @state to
    @on("#{from}->#{to}", callback) if callback
}

# A special method to alias state machine methods to class methods
Batman.Object.actsAsStateMachine = (includeInstanceMethods=true) ->
    Batman.StateMachine.initialize.call @
    Batman.StateMachine.initialize.call @prototype

    @classState = -> Batman.StateMachine.state.apply @, arguments
    @state = -> @classState.apply @prototype, arguments
    @::state = @classState if includeInstanceMethods

    @classTransition = -> Batman.StateMachine.transition.apply @, arguments
    @transition = -> @classTransition.apply @prototype, arguments
    @::transition = @classTransition if includeInstanceMethods

# This is cached here so it doesn't need to be recompiled for every setter
_stateMachine_setState = (newState) ->
  Batman.StateMachine.initialize.call @

  if @_batman.isTransitioning
    (@_batman.nextState ||= []).push(newState)
    return false

  @_batman.isTransitioning = yes

  oldState = @state()
  @_batman.state = newState

  if newState and oldState
    @fire("#{oldState}->#{newState}", newState, oldState)

  if newState
    @fire(newState, newState, oldState)

  @_batman.isTransitioning = no
  @[@_batman.nextState.shift()]() if @_batman.nextState?.length

  newState

# App, Requests, and Routing
# --------------------------

# `Batman.Request` is a normalizer for XHR requests in the Batman world.
class Batman.Request extends Batman.Object
  @objectToFormData: (data) ->
    pairForList = (key, object, first = false) ->
      list = switch Batman.typeOf(object)
        when 'Object'
          list = for k, v of object
            pairForList((if first then k else "#{key}[#{k}]"), v)
          list.reduce((acc, list) ->
            acc.concat list
          , [])
        when 'Array'
          object.reduce((acc, element) ->
            acc.concat pairForList("#{key}[]", element)
          , [])
        else
          [[key, object]]

    formData = new FormData()
    for [key, val] in pairForList("", data, true)
      formData.append(key, val)
    formData

  url: ''
  data: ''
  method: 'get'
  formData: false
  response: null
  status: null

  # Set the content type explicitly for PUT and POST requests.
  contentType: 'application/x-www-form-urlencoded'

  constructor: (options) ->
    handlers = {}
    for k, handler of options when k in ['success', 'error', 'loading', 'loaded']
      handlers[k] = handler
      delete options[k]

    super(options)
    @on k, handler for k, handler of handlers

  # After the URL gets set, we'll try to automatically send
  # your request after a short period. If this behavior is
  # not desired, use @cancel() after setting the URL.
  @observeAll 'url', ->
    @_autosendTimeout = setTimeout (=> @send()), 0

  # `send` is implmented in the platform layer files. One of those must be required for
  # `Batman.Request` to be useful.
  send: () -> developer.error "Please source a dependency file for a request implementation"

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
  developer.do ->
    App.require = (path, names...) ->
      base = @requirePath + path
      for name in names
        @prevent 'run'

        path = base + '/' + name + '.coffee'
        new Batman.Request
          url: path
          type: 'html'
          success: (response) =>
            CoffeeScript.eval response
            @allow 'run'
            @fire 'run' if @hasRun
      @

  @controller: (names...) ->
    names = names.map (n) -> n + '_controller'
    @require 'controllers', names...

  @model: ->
    @require 'models', arguments...

  @view: ->
    @require 'views', arguments...

  # Layout is the base view that other views can be yielded into. The
  # default behavior is that when `app.run()` is called, a new view will
  # be created for the layout using the `document` node as its content.
  # Use `MyApp.layout = null` to turn off the default behavior.
  @layout: undefined

  # Call `MyApp.run()` to start up an app. Batman level initializers will
  # be run to bootstrap the application.

  @event('run').oneShot = true
  @run: ->
    if Batman.currentApp
      return if Batman.currentApp is @
      Batman.currentApp.stop()

    return false if @hasRun
    Batman.currentApp = @

    if typeof @dispatcher is 'undefined'
      @dispatcher ||= new Batman.Dispatcher @

    if typeof @layout is 'undefined'
      @set 'layout', new Batman.View
        contexts: [@]
        node: document

      @get('layout').on 'ready', => @fire 'ready'

    if typeof @historyManager is 'undefined' and @dispatcher.routeMap
      @on 'run', =>
        @historyManager = Batman.historyManager = new Batman.HashHistory @
        @historyManager.start()

    @hasRun = yes
    @fire('run')
    @

  @event('ready').oneShot = true

  @event('stop').oneShot = true
  @stop: ->
    @historyManager?.stop()
    Batman.historyManager = null
    @hasRun = no
    @fire('stop')
    @

# Dispatcher
# ----------

class Batman.Route extends Batman.Object
  # Route regexes courtesy of Backbone
  namedParam = /:([\w\d]+)/g
  splatParam = /\*([\w\d]+)/g
  queryParam = '(?:\\?.+)?'
  namedOrSplat = /[:|\*]([\w\d]+)/g
  escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

  constructor: ->
    super

    @pattern = @url.replace(escapeRegExp, '\\$&')
    @regexp = new RegExp('^' + @pattern.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + queryParam + '$')

    @namedArguments = []
    while (array = namedOrSplat.exec(@pattern))?
      @namedArguments.push(array[1]) if array[1]

  @accessor 'action',
    get: ->
      return @action if @action

      if @options
        result = $mixin {}, @options

        if signature = result.signature
          components = signature.split('#')
          result.controller = components[0]
          result.action = components[1] || 'index'

        result.target = @dispatcher.get result.controller
        @set 'action', result
    set: (key, action) ->
      @action = action

  parameterize: (url) ->
    [url, query] = url.split '?'
    array = @regexp.exec(url)?.slice(1)
    params = url: url

    action = @get 'action'
    if typeof action is 'function'
      params.action = action
    else
      $mixin params, action

    if array
      for param, index in array
        params[@namedArguments[index]] = param

    if query
      for s in query.split '&'
        [key, value] = s.split '='
        params[key] = value

    params

  dispatch: (url) ->
    if $typeOf(url) is 'String'
      params = @parameterize url

    $redirect('/404') if not (action = params.action) and url isnt '/404'
    return action(params) if typeof action is 'function'
    return params.target.dispatch(action, params) if params.target?.dispatch
    return params.target?[action](params)

class Batman.Dispatcher extends Batman.Object
  constructor: (@app) ->
    @app.route @

    @app.controllers = new Batman.Object
    for key, controller of @app
      continue unless controller?.prototype instanceof Batman.Controller
      @prepareController controller

  prepareController: (controller) ->
    name = helpers.underscore($functionName(controller).replace('Controller', ''))
    return unless name

    getter = -> @[name] = controller.get 'sharedController'
    @accessor name, getter
    @app.controllers.accessor name, getter

  register: (url, options) ->
    url = "/#{url}" if url.indexOf('/') isnt 0
    route = if $typeOf(options) is 'Function'
      new Batman.Route url: url, action: options, dispatcher: @
    else
      new Batman.Route url: url, options: options, dispatcher: @

    @routeMap ||= {}
    @routeMap[url] = route

  findRoute: (url) ->
    url = "/#{url}" if url.indexOf('/') isnt 0
    return route if (route = @routeMap[url])
    for routeUrl, route of @routeMap
      return route if route.regexp.test(url)

  findUrl: (params) ->
    for url, route of @routeMap
      matches = no
      options = route.options
      if params.resource
        matches = options.resource is params.resource and
          options.action is params.action
      else
        action = route.get 'action'
        continue if typeof action is 'function'

        {controller, action} = action
        if controller is params.controller and action is (params.action || 'index')
          matches = yes

      continue if not matches
      for key, value of params
        url = url.replace new RegExp('[:|\*]' + key), value

      return url

  dispatch: (url) ->
    route = @findRoute(url)
    if route
      route.dispatch(url)
    else if url isnt '/404'
      $redirect('/404')

    @app.set 'currentURL', url

# History Manager
# ---------------
class Batman.HistoryManager
  constructor: (@app) ->
  dispatch: (url) ->
    url = "/#{url}" if url.indexOf('/') isnt 0
    @app.dispatcher.dispatch url

    url
  redirect: (url) ->
    if $typeOf(url) isnt 'String'
      url = @app.dispatcher.findUrl(url)
    @dispatch url

class Batman.HashHistory extends Batman.HistoryManager
  HASH_PREFIX: '#!'
  start: =>
    return if typeof window is 'undefined'
    return if @started
    @started = yes

    if 'onhashchange' of window
      $addEventListener window, 'hashchange', @parseHash
    else
      @interval = setInterval @parseHash, 100

    @first = true
    Batman.currentApp.prevent 'ready'
    setTimeout @parseHash, 0

  stop: =>
    if @interval
      @interval = clearInterval @interval
    else
      $removeEventListener window, 'hashchange', @parseHash

    @started = no

  urlFor: (url) ->
    @HASH_PREFIX + url

  parseHash: =>
    hash = window.location.hash.replace @HASH_PREFIX, ''
    return if hash is @cachedHash

    result = @dispatch (@cachedHash = hash)
    if @first
      Batman.currentApp.allow 'ready'
      Batman.currentApp.fire 'ready'
      @first = false
    result

  redirect: (params) ->
    url = super
    @cachedHash = url

    window.location.hash = @HASH_PREFIX + url

Batman.redirect = $redirect = (url) ->
  Batman.historyManager?.redirect url

# Route Declarators
# -----------------

Batman.App.classMixin
  route: (url, signature, options={}) ->
    return if not url
    if url instanceof Batman.Dispatcher
      dispatcher = url
      for key, value of @_dispatcherCache
        dispatcher.register key, value

      @_dispatcherCache = null
      return dispatcher

    if $typeOf(signature) is 'String'
      options.signature = signature
    else if $typeOf(signature) is 'Function'
      options = signature
    else if signature
      $mixin options, signature

    @_dispatcherCache ||= {}
    @_dispatcherCache[url] = options

  root: (signature, options) ->
    @route '/', signature, options

  resources: (resource, options={}, callback) ->
    (callback = options; options = {}) if typeof options is 'function'
    resource = helpers.pluralize(resource)
    controller = options.controller || resource

    @route(resource, "#{controller}#index", resource: controller, action: 'index') unless options.index is false
    @route("#{resource}/new", "#{controller}#new", resource: controller, action: 'new') unless options.new is false
    @route("#{resource}/:id", "#{controller}#show", resource: controller, action: 'show') unless options.show is false
    @route("#{resource}/:id/edit", "#{controller}#edit", resource: controller, action: 'edit') unless options.edit is false

    if callback
      app = @
      ops =
        collection: (collectionCallback) ->
          collectionCallback?.call route: (url, methodName) -> app.route "#{resource}/#{url}", "#{controller}##{methodName || url}"
        member: (memberCallback) ->
          memberCallback?.call route: (url, methodName) -> app.route "#{resource}/:id/#{url}", "#{controller}##{methodName || url}"

      callback.call ops

  redirect: $redirect

# Controllers
# -----------

class Batman.Controller extends Batman.Object
  @singleton 'sharedController'

  @beforeFilter: (nameOrFunction) ->
    Batman.initializeObject @
    filters = @_batman.beforeFilters ||= []
    filters.push(nameOrFunction) if filters.indexOf(nameOrFunction) is -1

  @accessor 'controllerName',
    get: -> @_controllerName ||= helpers.underscore($functionName(@constructor).replace('Controller', ''))
  @afterFilter: (nameOrFunction) ->
    Batman.initializeObject @
    filters = @_batman.afterFilters ||= []
    filters.push(nameOrFunction) if filters.indexOf(nameOrFunction) is -1

  @accessor 'action',
    get: -> @_currentAction
    set: (key, value) -> @_currentAction = value

  # You shouldn't call this method directly. It will be called by the dispatcher when a route is called.
  # If you need to call a route manually, use `$redirect()`.
  dispatch: (action, params = {}) ->
    params.controller ||= @get 'controllerName'
    params.action ||= action
    params.target ||= @

    oldRedirect = Batman.historyManager?.redirect
    Batman.historyManager?.redirect = @redirect

    @_actedDuringAction = no
    @set 'action', action

    if filters = @constructor._batman?.get('beforeFilters')
      for filter in filters
        if typeof filter is 'function' then filter.call(@, params) else @[filter](params)

    developer.assert @[action], "Error! Controller action #{@get 'controllerName'}.#{action} couldn't be found!"
    @[action](params)

    if not @_actedDuringAction
      @render()

    if filters = @constructor._batman?.get('afterFilters')
      for filter in filters
        if typeof filter is 'function' then filter.call(@, params) else @[filter](params)

    delete @_actedDuringAction
    @set 'action', null

    Batman.historyManager?.redirect = oldRedirect

    redirectTo = @_afterFilterRedirect
    delete @_afterFilterRedirect

    $redirect(redirectTo) if redirectTo

  redirect: (url) =>
    throw 'DoubleRedirectError' if @_actedDuringAction
    if @get 'action'
      @_actedDuringAction = yes
      @_afterFilterRedirect = url
    else
      if $typeOf(url) is 'Object'
        url.controller = @ if not url.controller

      $redirect url

  render: (options = {}) ->
    throw 'DoubleRenderError' if @_actedDuringAction
    @_actedDuringAction = yes
    return if options is false

    if not options.view
      options.source ||= helpers.underscore($functionName(@constructor).replace('Controller', '')) + '/' + @_currentAction + '.html'
      options.view = new Batman.View(options)

    if view = options.view
      Batman.currentApp?.prevent 'ready'
      view.contexts.push @
      view.on 'ready', ->
        Batman.DOM.replace 'main', view.get('node')
        Batman.currentApp?.allow 'ready'
        Batman.currentApp?.fire 'ready'
    view

# Models
# ------

class Batman.Model extends Batman.Object
  # ## Model API
  # Override this property if your model is indexed by a key other than `id`
  @primaryKey: 'id'

  # Override this property to define the key which storage adapters will use to store instances of this model under.
  #  - For RestStorage, this ends up being part of the url built to store this model
  #  - For LocalStorage, this ends up being the namespace in localStorage in which JSON is stored
  @storageKey: null

  # Pick one or many mechanisms with which this model should be persisted. The mechanisms
  # can be already instantiated or just the class defining them.
  @persist: (mechanisms...) ->
    Batman.initializeObject @prototype
    storage = @::_batman.storage ||= []
    results = for mechanism in mechanisms
      mechanism = if mechanism.isStorageAdapter then mechanism else new mechanism(@)
      storage.push mechanism
      mechanism
    if results.length > 1
      results
    else
      results[0]

  # Encoders are the tiny bits of logic which manage marshalling Batman models to and from their
  # storage representations. Encoders do things like stringifying dates and parsing them back out again,
  # pulling out nested model collections and instantiating them (and JSON.stringifying them back again),
  # and marshalling otherwise un-storable object.
  @encode: (keys..., encoderOrLastKey) ->
    Batman.initializeObject @prototype
    @::_batman.encoders ||= new Batman.SimpleHash
    @::_batman.decoders ||= new Batman.SimpleHash
    switch $typeOf(encoderOrLastKey)
      when 'String'
        keys.push encoderOrLastKey
      when 'Function'
        encoder = encoderOrLastKey
      else
        encoder = encoderOrLastKey.encode
        decoder = encoderOrLastKey.decode

    encoder = @defaultEncoder.encode if typeof encoder is 'undefined'
    decoder = @defaultEncoder.decode if typeof decoder is 'undefined'

    for key in keys
      @::_batman.encoders.set(key, encoder) if encoder
      @::_batman.decoders.set(key, decoder) if decoder

  # Set up the unit functions as the default for both
  @defaultEncoder:
    encode: (x) -> x
    decode: (x) -> x

  # Attach encoders and decoders for the primary key, and update them if the primary key changes.
  @observeAndFire 'primaryKey', (newPrimaryKey) -> @encode newPrimaryKey, {encode: false, decode: @defaultEncoder.decode}

  # Validations allow a model to be marked as 'valid' or 'invalid' based on a set of programmatic rules.
  # By validating our data before it gets to the server we can provide immediate feedback to the user about
  # what they have entered and forgo waiting on a round trip to the server.
  # `validate` allows the attachment of validations to the model on particular keys, where the validation is
  # either a built in one (by use of options to pass to them) or a custom one (by use of a custom function as
  # the second argument). Custom validators should have the signature `(errors, record, key, callback)`. They
  # should add strings to the `errors` set based on the record (maybe depending on the `key` they were attached
  # to) and then always call the callback. Again: the callback must always be called.
  @validate: (keys..., optionsOrFunction) ->
    Batman.initializeObject @prototype
    validators = @::_batman.validators ||= []

    if typeof optionsOrFunction is 'function'
      # Given a function, use that as the actual validator, expecting it to conform to the API
      # the built in validators do.
      validators.push
        keys: keys
        callback: optionsOrFunction
    else
      # Given options, find the validations which match the given options, and add them to the validators
      # array.
      options = optionsOrFunction
      for validator in Validators
        if (matches = validator.matches(options))
          delete options[match] for match in matches
          validators.push
            keys: keys
            validator: new validator(matches)

  # ### Query methods
  @classAccessor 'all',
    get: ->
      @load() if @::hasStorage() and @classState() not in ['loaded', 'loading']
      @get('loaded')

    set: (k, v) -> @set('loaded', v)

  @classAccessor 'loaded',
    get: ->
      unless @all
        @all = new Batman.SortableSet
        @all.sortBy "id asc"

      @all

    set: (k, v) -> @all = v

  @classAccessor 'first', -> @get('all').toArray()[0]
  @classAccessor 'last', -> x = @get('all').toArray(); x[x.length - 1]

  @find: (id, callback) ->
    developer.assert callback, "Must call find with a callback!"
    record = new @(id)
    newRecord = @_mapIdentity(record)
    newRecord.load callback
    return newRecord

  # `load` fetches records from all sources possible
  @load: (options, callback) ->
    if $typeOf(options) is 'Function'
      callback = options
      options = {}

    developer.assert @::_batman.getAll('storage').length, "Can't load model #{$functionName(@)} without any storage adapters!"

    @loading()
    @::_doStorageOperation 'readAll', options, (err, records) =>
      if err?
        callback?(err, [])
      else
        mappedRecords = (@_mapIdentity(record) for record in records)
        @loaded()
        callback?(err, mappedRecords)

  # `create` takes an attributes hash, creates a record from it, and saves it given the callback.
  @create: (attrs, callback) ->
    if !callback
      [attrs, callback] = [{}, attrs]
    obj = new this(attrs)
    obj.save(callback)
    obj

  # `findOrCreate` takes an attributes hash, optionally containing a primary key, and returns to you a saved record
  # representing those attributes, either from the server or from the identity map.
  @findOrCreate: (attrs, callback) ->
    record = new this(attrs)
    if record.isNew()
      record.save(callback)
    else
      foundRecord = @_mapIdentity(record)
      foundRecord.updateAttributes(attrs)
      callback(undefined, foundRecord)

  @_mapIdentity: (record) ->
    if typeof (id = record.get('id')) == 'undefined' || id == ''
      return record
    else
      existing = @get("loaded.indexedBy.id").get(id)?.toArray()[0]
      if existing
        existing.updateAttributes(record._batman.attributes || {})
        return existing
      else
        @get('loaded').add(record)
        return record

  # ### Record API

  # Add a universally accessible accessor for retrieving the primrary key, regardless of which key its stored under.
  @accessor 'id',
    get: ->
      pk = @constructor.get('primaryKey')
      if pk == 'id'
        @id
      else
        @get(pk)
    set: (k, v) ->
      # naively coerce string ids into integers
      if typeof v is "string" and !isNaN(intId = parseInt(v, 10))
        v = intId

      pk = @constructor.get('primaryKey')
      if pk == 'id'
        @id = v
      else
        @set(pk, v)

  # Add normal accessors for the dirty keys and errors attributes of a record, so these accesses don't fall to the
  # default accessor.
  @accessor 'dirtyKeys', 'errors', Batman.Property.defaultAccessor

  # Add an accessor for the internal batman state under `batmanState`, so that the `state` key can be a valid
  # attribute.
  @accessor 'batmanState'
    get: -> @state()
    set: (k, v) -> @state(v)

  # Add a default accessor to make models store their attributes under a namespace by default.
  @accessor Model.defaultAccessor =
    get: (k) -> (@_batman.attributes ||= {})[k] || @[k]
    set: (k, v) -> (@_batman.attributes ||= {})[k] = v
    unset: (k) ->
      x = (@_batman.attributes ||={})[k]
      delete @_batman.attributes[k]
      x

  # New records can be constructed by passing either an ID or a hash of attributes (potentially
  # containing an ID) to the Model constructor. By not passing an ID, the model is marked as new.
  constructor: (idOrAttributes = {}) ->
    developer.assert  @ instanceof Batman.Object, "constructors must be called with new"

    # We have to do this ahead of super, because mixins will call set which calls things on dirtyKeys.
    @dirtyKeys = new Batman.Hash
    @errors = new Batman.ErrorsSet

    # Find the ID from either the first argument or the attributes.
    if $typeOf(idOrAttributes) is 'Object'
      super(idOrAttributes)
    else
      super()
      @set('id', idOrAttributes)

    @empty() if not @state()

  # Override the `Batman.Observable` implementation of `set` to implement dirty tracking.
  set: (key, value) ->
    # Optimize setting where the value is the same as what's already been set.
    oldValue = @get(key)
    return if oldValue is value

    # Actually set the value and note what the old value was in the tracking array.
    result = super
    @dirtyKeys.set(key, oldValue)

    # Mark the model as dirty if isn't already.
    @dirty() unless @state() in ['dirty', 'loading', 'creating']
    result

  updateAttributes: (attrs) ->
    @mixin(attrs)
    @

  toString: ->
    "#{$functionName(@constructor)}: #{@get('id')}"

  # `toJSON` uses the various encoders for each key to grab a storable representation of the record.
  toJSON: ->
    obj = {}
    # Encode each key into a new object
    encoders = @_batman.get('encoders')
    unless !encoders or encoders.isEmpty()
      encoders.forEach (key, encoder) =>
        val = @get key
        if typeof val isnt 'undefined'
          encodedVal = encoder(@get key)
          if typeof encodedVal isnt 'undefined'
            obj[key] = encodedVal

    obj

  # `fromJSON` uses the various decoders for each key to generate a record instance from the JSON
  # stored in whichever storage mechanism.
  fromJSON: (data) ->
    obj = {}
    decoders = @_batman.get('decoders')
    # If no decoders were specified, do the best we can to interpret the given JSON by camelizing
    # each key and just setting the values.
    if !decoders or decoders.isEmpty()
      for key, value of data
        obj[key] = value
    else
      # If we do have decoders, use them to get the data.
      decoders.forEach (key, decoder) ->
        obj[key] = decoder(data[key]) if data[key]

    # Mixin the buffer object to use optimized and event-preventing sets used by `mixin`.
    @mixin obj

  # Each model instance (each record) can be in one of many states throughout its lifetime. Since various
  # operations on the model are asynchronous, these states are used to indicate exactly what point the
  # record is at in it's lifetime, which can often be during a save or load operation.
  @actsAsStateMachine yes

  # Add the various states to the model.
  for k in ['empty', 'dirty', 'loading', 'loaded', 'saving', 'saved', 'creating', 'created', 'validating', 'validated', 'destroying', 'destroyed']
    @state k

  for k in ['loading', 'loaded']
    @classState k

  _doStorageOperation: (operation, options, callback) ->
    developer.assert @hasStorage(), "Can't #{operation} model #{$functionName(@constructor)} without any storage adapters!"
    mechanisms = @_batman.get('storage')
    for mechanism in mechanisms
      mechanism[operation] @, options, callback
    true

  hasStorage: -> (@_batman.get('storage') || []).length > 0

  # `load` fetches the record from all sources possible
  load: (callback) =>
    if @state() in ['destroying', 'destroyed']
      callback?(new Error("Can't load a destroyed record!"))
      return

    @loading()
    @_doStorageOperation 'read', {}, (err, record) =>
      unless err
        @loaded()
        record = @constructor._mapIdentity(record)
      callback?(err, record)

  # `save` persists a record to all the storage mechanisms added using `@persist`. `save` will only save
  # a model if it is valid.
  save: (callback) =>
    if @state() in ['destroying', 'destroyed']
      callback?(new Error("Can't save a destroyed record!"))
      return

    @validate (isValid, errors) =>
      if !isValid
        callback?(errors)
        return
      creating = @isNew()

      do @saving
      do @creating if creating
      @_doStorageOperation (if creating then 'create' else 'update'), {}, (err, record) =>
        unless err
          if creating
            do @created
          do @saved
          @dirtyKeys.clear()
          record = @constructor._mapIdentity(record)
        callback?(err, record)

  # `destroy` destroys a record in all the stores.
  destroy: (callback) =>
    do @destroying
    @_doStorageOperation 'destroy', {}, (err, record) =>
      unless err
        @constructor.get('all').remove(@)
        do @destroyed
      callback?(err)

  # `validate` performs the record level validations determining the record's validity. These may be asynchronous,
  # in which case `validate` has no useful return value. Results from asynchronous validations can be received by
  # listening to the `afterValidation` lifecycle callback.
  validate: (callback) ->
    oldState = @state()
    @errors.clear()
    do @validating

    finish = () =>
      do @validated
      @[oldState]()
      callback?(@errors.length == 0, @errors)

    validators = @_batman.get('validators') || []
    unless validators.length > 0
      finish()
    else
      count = validators.length
      validationCallback = =>
        if --count == 0
          finish()
      for validator in validators
        v = validator.validator

        # Run the validator `v` or the custom callback on each key it validates by instantiating a new promise
        # and passing it to the appropriate function along with the key and the value to be validated.
        for key in validator.keys
          if v
            v.validateEach @errors, @, key, validationCallback
          else
            validator.callback @errors, @, key, validationCallback
    return

  isNew: -> typeof @get('id') is 'undefined'

class Batman.ValidationError extends Batman.Object
  constructor: (attribute, message) -> super({attribute, message})

# `ErrorSet` is a simple subclass of `Set` which makes it a bit easier to
# manage the errors on a model.
class Batman.ErrorsSet extends Batman.Set
  # Define a default accessor to get the set of errors on a key
  @accessor (key) -> @indexedBy('attribute').get(key)

  # Define a shorthand method for adding errors to a key.
  add: (key, error) -> super(new Batman.ValidationError(key, error))

class Batman.Validator extends Batman.Object
  constructor: (@options, mixins...) ->
    super mixins...

  validate: (record) -> developer.error "You must override validate in Batman.Validator subclasses."

  @options: (options...) ->
    Batman.initializeObject @
    if @_batman.options then @_batman.options.concat(options) else @_batman.options = options

  @matches: (options) ->
    results = {}
    shouldReturn = no
    for key, value of options
      if ~@_batman?.options?.indexOf(key)
        results[key] = value
        shouldReturn = yes
    return results if shouldReturn

Validators = Batman.Validators = [
  class Batman.LengthValidator extends Batman.Validator
    @options 'minLength', 'maxLength', 'length', 'lengthWithin', 'lengthIn'
    constructor: (options) ->
      if range = (options.lengthIn or options.lengthWithin)
        options.minLength = range[0]
        options.maxLength = range[1] || -1
        delete options.lengthWithin
        delete options.lengthIn

      super

    validateEach: (errors, record, key, callback) ->
      options = @options
      value = record.get(key)
      if options.minLength and value.length < options.minLength
        errors.add key, "#{key} must be at least #{options.minLength} characters"
      if options.maxLength and value.length > options.maxLength
        errors.add key, "#{key} must be less than #{options.maxLength} characters"
      if options.length and value.length isnt options.length
        errors.add key, "#{key} must be #{options.length} characters"
      callback()

  class Batman.PresenceValidator extends Batman.Validator
    @options 'presence'
    validateEach: (errors, record, key, callback) ->
      value = record.get(key)
      if @options.presence and !value?
        errors.add key, "#{key} must be present"
      callback()
]

class Batman.StorageAdapter extends Batman.Object
  constructor: (model) ->
    super(model: model, modelKey: model.get('storageKey') || helpers.pluralize(helpers.underscore($functionName(model))))
  isStorageAdapter: true

  @::_batman.check(@::)

  for k in ['all', 'create', 'read', 'readAll', 'update', 'destroy']
    for time in ['before', 'after']
      do (k, time) =>
        key = "#{time}#{helpers.capitalize(k)}"
        @::[key] = (filter) ->
          @_batman.check(@)
          (@_batman["#{key}Filters"] ||= []).push filter

  before: (keys..., callback) ->
    @["before#{helpers.capitalize(k)}"](callback) for k in keys

  after: (keys..., callback) ->
    @["after#{helpers.capitalize(k)}"](callback) for k in keys

  _filterData: (prefix, action, data...) ->
    # Filter the data first with the beforeRead and then the beforeAll filters
    (@_batman.get("#{prefix}#{helpers.capitalize(action)}Filters") || [])
      .concat(@_batman.get("#{prefix}AllFilters") || [])
      .reduce( (filteredData, filter) =>
        filter.call(@, filteredData)
      , data)

  getRecordFromData: (data) ->
    record = new @model()
    record.fromJSON(data)
    record

$passError = (f) ->
  return (filterables) ->
    if filterables[0]
      filterables
    else
      err = filterables.shift()
      filterables = f.call(@, filterables)
      filterables.unshift(err)
      filterables

class Batman.LocalStorage extends Batman.StorageAdapter
  constructor: ->
    if typeof window.localStorage is 'undefined'
      return null
    super
    @storage = localStorage
    @key_re = new RegExp("^#{@modelKey}(\\d+)$")
    @nextId = 1
    @_forAllRecords (k, v) ->
      if matches = @key_re.exec(k)
        @nextId = Math.max(@nextId, parseInt(matches[1], 10) + 1)
    return

  @::before 'create', 'update', $passError ([record, options]) ->
    [JSON.stringify(record), options]

  @::after 'read', $passError ([record, attributes, options]) ->
    [record.fromJSON(JSON.parse(attributes)), attributes, options]

  _forAllRecords: (f) ->
    for i in [0...@storage.length]
      k = @storage.key(i)
      f.call(@, k, @storage.getItem(k))

  getRecordFromData: (data) ->
    record = super
    @nextId = Math.max(@nextId, parseInt(record.get('id'), 10) + 1)
    record

  update: (record, options, callback) ->
    [err, recordToSave] = @_filterData('before', 'update', undefined, record, options)
    if !err
      id = record.get('id')
      if id?
        @storage.setItem(@modelKey + id, recordToSave)
      else
        err = new Error("Couldn't get record primary key.")
    callback(@_filterData('after', 'update', err, record, options)...)

  create: (record, options, callback) ->
    [err, recordToSave] = @_filterData('before', 'create', undefined, record, options)
    if !err
      id = record.get('id') || record.set('id', @nextId++)
      if id?
        key = @modelKey + id
        if @storage.getItem(key)
          err = new Error("Can't create because the record already exists!")
        else
          @storage.setItem(key, recordToSave)
      else
        err = new Error("Couldn't set record primary key on create!")
    callback(@_filterData('after', 'create', err, record, options)...)

  read: (record, options, callback) ->
    [err, record] = @_filterData('before', 'read', undefined, record, options)
    id = record.get('id')
    if !err
      if id?
        attrs = @storage.getItem(@modelKey + id)
        if !attrs
          err = new Error("Couldn't find record!")
      else
        err = new Error("Couldn't get record primary key.")

    callback(@_filterData('after', 'read', err, record, attrs, options)...)

  readAll: (_, options, callback) ->
    records = []
    [err, options] = @_filterData('before', 'readAll', undefined, options)
    if !err
      @_forAllRecords (storageKey, data) ->
        if keyMatches = @key_re.exec(storageKey)
          records.push {data, id: keyMatches[1]}

    callback(@_filterData('after', 'readAll', err, records, options)...)

  @::after 'readAll', $passError ([allAttributes, options]) ->
    allAttributes = for attributes in allAttributes
      data = JSON.parse(attributes.data)
      data[@model.primaryKey] ||= parseInt(attributes.id, 10)
      data

    [allAttributes, options]

  @::after 'readAll', $passError ([allAttributes, options]) ->
    matches = []
    for data in allAttributes
      match = true
      for k, v of options
        if data[k] != v
          match = false
          break
      if match
        matches.push data
    [matches, options]

  @::after 'readAll', $passError ([filteredAttributes, options]) ->
    [@getRecordFromData(data) for data in filteredAttributes, filteredAttributes, options]

  destroy: (record, options, callback) ->
    [err, record] = @_filterData 'before', 'destroy', undefined, record, options
    if !err
      id = record.get('id')
      if id?
        key = @modelKey + id
        if @storage.getItem key
          @storage.removeItem key
        else
          err = new Error("Can't delete nonexistant record!")
      else
        err = new Error("Can't delete record without an primary key!")

    callback(@_filterData('after', 'destroy', err, record, options)...)

class Batman.RestStorage extends Batman.StorageAdapter
  defaultOptions:
    type: 'json'

  recordJsonNamespace: false
  collectionJsonNamespace: false

  constructor: ->
    super
    @recordJsonNamespace = helpers.singularize(@modelKey)
    @collectionJsonNamespace = helpers.pluralize(@modelKey)

  @::before 'create', 'update', $passError ([record, options]) ->
    json = record.toJSON()
    record = if @recordJsonNamespace
      x = {}
      x[@recordJsonNamespace] = json
      x
    else
      json
    [record, options]

  @::after 'create', 'read', 'update', $passError ([record, data, options]) ->
    data = data[@recordJsonNamespace] if data[@recordJsonNamespace]
    [record, data, options]

  @::after 'create', 'read', 'update', $passError ([record, data, options]) ->
    record.fromJSON(data)
    [record, data, options]

  optionsForRecord: (record, idRequired, callback) ->
    if record.url
      url = if typeof record.url is 'function' then record.url() else record.url
    else
      url = "/#{@modelKey}"
      if idRequired || !record.isNew()
        id = record.get('id')
        if !id?
          callback.call(@, new Error("Couldn't get record primary key!"))
          return
        url = url + "/" + id

    unless url
      callback.call @, new Error("Couldn't get model url!")
    else
      callback.call @, undefined, $mixin({}, @defaultOptions, {url})

  optionsForCollection: (recordsOptions, callback) ->
    url = @model.url?() || @model.url || "/#{@modelKey}"
    unless url
      callback.call @, new Error("Couldn't get collection url!")
    else
      callback.call @, undefined, $mixin {}, @defaultOptions, {url, data: $mixin({}, @defaultOptions.data, recordsOptions)}

  create: (record, recordOptions, callback) ->
    @optionsForRecord record, false, (err, options) ->
      [err, data] = @_filterData('before', 'create', err, record, recordOptions)
      if err
        callback(err)
        return

      new Batman.Request $mixin options,
        data: data
        method: 'POST'
        success: (data) => callback(@_filterData('after', 'create', undefined, record, data, recordOptions)...)
        error:  (error) => callback(@_filterData('after', 'create', error, record, error.request.get('response'), recordOptions)...)

  update: (record, recordOptions, callback) ->
    @optionsForRecord record, true, (err, options) ->
      [err, data] = @_filterData('before', 'update', err, record, recordOptions)
      if err
        callback(err)
        return

      new Batman.Request $mixin options,
        data: data
        method: 'PUT'
        success: (data) => callback(@_filterData('after', 'update', undefined, record, data, recordOptions)...)
        error:  (error) => callback(@_filterData('after', 'update', error, record, error.request.get('response'), recordOptions)...)

  read: (record, recordOptions, callback) ->
    @optionsForRecord record, true, (err, options) ->
      [err, record, recordOptions] = @_filterData('before', 'read', err, record, recordOptions)
      if err
        callback(err)
        return

      new Batman.Request $mixin options,
        data: recordOptions
        method: 'GET'
        success: (data) => callback(@_filterData('after', 'read', undefined, record, data, recordOptions)...)
        error:  (error) => callback(@_filterData('after', 'read', error, record, error.request.get('response'), recordOptions)...)

  readAll: (_, recordsOptions, callback) ->
    @optionsForCollection recordsOptions, (err, options) ->
      [err, recordsOptions] = @_filterData('before', 'readAll', err, recordsOptions)
      if err
        callback(err)
        return
      if recordsOptions && recordsOptions.url
        options.url = recordsOptions.url
        delete recordsOptions.url

      new Batman.Request $mixin options,
        data: recordsOptions
        method: 'GET'
        success: (data) => callback(@_filterData('after', 'readAll', undefined, data, recordsOptions)...)
        error:  (error) => callback(@_filterData('after', 'readAll', error, error.request.get('response'), recordsOptions)...)

  @::after 'readAll', $passError ([data, options]) ->
    recordData = if data[@collectionJsonNamespace] then data[@collectionJsonNamespace] else data
    [recordData, data, options]

  @::after 'readAll', $passError ([recordData, serverData, options]) ->
    [@getRecordFromData(attributes) for attributes in recordData, serverData, options]

  destroy: (record, recordOptions, callback) ->
    @optionsForRecord record, true, (err, options) ->
      [err, record, recordOptions] = @_filterData('before', 'destroy', err, record, recordOptions)
      if err
        callback(err)
        return

      new Batman.Request $mixin options,
        method: 'DELETE'
        success: (data) => callback(@_filterData('after', 'destroy', undefined, record, data, recordOptions)...)
        error:  (error) => callback(@_filterData('after', 'destroy', error, record, error.request.get('response'), recordOptions)...)

# Views
# -----------

# A `Batman.View` can function two ways: a mechanism to load and/or parse html files
# or a root of a subclass hierarchy to create rich UI classes, like in Cocoa.
class Batman.View extends Batman.Object
  constructor: (options) ->
    @contexts = []
    super(options)

    # Support both `options.context` and `options.contexts`
    if context = @get('context')
      @contexts.push context
      @unset('context')

  @viewSources: {}

  # Set the source attribute to an html file to have that file loaded.
  source: ''

  # Set the html to a string of html to have that html parsed.
  html: ''

  # Set an existing DOM node to parse immediately.
  node: null

  contentFor: null

  # Fires once a node is parsed.
  @::event('ready').oneShot = true

  # Where to look for views on the server
  prefix: 'views'

  # Whenever the source changes we load it up asynchronously
  @observeAll 'source', ->
    setTimeout (=> @reloadSource()), 0

  reloadSource: ->
    source = @get 'source'
    return if not source

    if Batman.View.viewSources[source]
      @set('html', Batman.View.viewSources[source])
    else
      new Batman.Request
        url: url = "#{@prefix}/#{@source}"
        type: 'html'
        success: (response) =>
          Batman.View.viewSources[source] = response
          @set('html', response)
        error: (response) ->
          throw new Error("Could not load view from #{url}")

  @observeAll 'html', (html) ->
    node = @node || document.createElement 'div'
    $setInnerHTML(node, html)

    @set('node', node) if @node isnt node

  @observeAll 'node', (node) ->
    return unless node
    @event('ready').resetOneShot()

    if @_renderer
      @_renderer.forgetAll()

    # We use a renderer with the continuation style rendering engine to not
    # block user interaction for too long during the render.
    if node
      @_renderer = new Batman.Renderer(node, =>
        yieldTo = @contentFor
        if typeof yieldTo is 'string'
          @contentFor = Batman.DOM._yields[yieldTo]

        if @contentFor and node
          $setInnerHTML @contentFor, ''
          @contentFor.appendChild(node)
        else if yieldTo
          if contents = Batman.DOM._yieldContents[yieldTo]
            contents.push node
          else
            Batman.DOM._yieldContents[yieldTo] = [node]
      , @contexts)

      @_renderer.on 'rendered', => @fire('ready', node)

# DOM Helpers
# -----------

# `Batman.Renderer` will take a node and parse all recognized data attributes out of it and its children.
# It is a continuation style parser, designed not to block for longer than 50ms at a time if the document
# fragment is particularly long.
class Batman.Renderer extends Batman.Object

  constructor: (@node, callback, contexts = []) ->
    super()
    @on('parsed', callback) if callback?
    @context = if contexts instanceof RenderContext then contexts else RenderContext.start(contexts...)
    @timeout = setTimeout @start, 0

  start: =>
    @startTime = new Date
    @parseNode @node

  resume: =>
    @startTime = new Date
    @parseNode @resumeNode

  finish: ->
    @startTime = null
    @fire 'parsed'
    @fire 'rendered'

  stop: ->
    clearTimeout(@timeout)
    @fire 'stopped'

  forgetAll: ->

  for k in ['parsed', 'rendered', 'stopped']
    @::event(k).oneShot = true

  bindingRegexp = /data\-(.*)/
  sortBindings = (a, b) ->
    if a[0] == 'foreach'
      -1
    else if b[0] == 'foreach'
      1
    else if a[0] == 'formfor'
      -1
    else if b[0] == 'formfor'
      1
    else if a[0] == 'bind'
      -1
    else if b[0] == 'bind'
      1
    else
      0

  parseNode: (node) ->
    if new Date - @startTime > 50
      @resumeNode = node
      @timeout = setTimeout @resume, 0
      return

    if node.getAttribute and node.attributes
      bindings = for attr in node.attributes
        name = attr.nodeName.match(bindingRegexp)?[1]
        continue if not name
        if ~(varIndex = name.indexOf('-'))
          [name.substr(0, varIndex), name.substr(varIndex + 1), attr.value]
        else
          [name, attr.value]

      for readerArgs in bindings.sort(sortBindings)
        key = readerArgs[1]
        result = if readerArgs.length == 2
          Batman.DOM.readers[readerArgs[0]]?(node, key, @context, @)
        else
          Batman.DOM.attrReaders[readerArgs[0]]?(node, key, readerArgs[2], @context, @)

        if result is false
          skipChildren = true
          break
        else if result instanceof RenderContext
          @context = result

    if (nextNode = @nextNode(node, skipChildren)) then @parseNode(nextNode) else @finish()

  nextNode: (node, skipChildren) ->
    if not skipChildren
      children = node.childNodes
      return children[0] if children?.length

    Batman.data(node, 'onParseExit')?()
    return if @node == node

    sibling = node.nextSibling
    return sibling if sibling

    nextParent = node
    while nextParent = nextParent.parentNode
      nextParent.onParseExit?()
      return if @node == nextParent

      parentSibling = nextParent.nextSibling
      return parentSibling if parentSibling

    return

# Bindings are shortlived objects which manage the observation of any keypaths a `data` attribute depends on.
# Bindings parse any keypaths which are filtered and use an accessor to apply the filters, and thus enjoy
# the automatic trigger and dependency system that Batman.Objects use.
class Binding extends Batman.Object
  # A beastly regular expression for pulling keypaths out of the JSON arguments to a filter.
  # It makes the following matches:
  #
  # + `foo` and `baz.qux` in `foo, "bar", baz.qux`
  # + `foo.bar.baz` in `true, false, "true", "false", foo.bar.baz`
  # + `true.bar` in `2, true.bar`
  # + `truesay` in truesay
  # + no matches in `"bar", 2, {"x":"y", "Z": foo.bar.baz}, "baz"`
  keypath_rx = ///
    (^|,)             # Match either the start of an arguments list or the start of a space inbetween commas.
    \s*               # Be insensitive to whitespace between the comma and the actual arguments.
    (?!               # Use a lookahead to ensure we aren't matching true or false:
      (?:true|false)  # Match either true or false ...
      \s*             # and make sure that there's nothing else that comes after the true or false ...
      (?:$|,)         # before the end of this argument in the list.
    )
    ([a-zA-Z][\w\.]*) # Now that true and false can't be matched, match a dot delimited list of keys.
    \s*               # Be insensitive to whitespace before the next comma or end of the filter arguments list.
    ($|,)             # Match either the next comma or the end of the filter arguments list.
    ///g

  # A less beastly pair of regular expressions for pulling out the [] syntax `get`s in a binding string, and
  # dotted names that follow them.
  get_dot_rx = /(?:\]\.)(.+?)(?=[\[\.]|\s*\||$)/
  get_rx = /(?!^\s*)\[(.*?)\]/g

  deProxy = (object) -> if object instanceof RenderContext.ContextProxy then object.get('proxiedObject') else object
  # The `filteredValue` which calculates the final result by reducing the initial value through all the filters.
  @accessor 'filteredValue', ->
    unfilteredValue = @get('unfilteredValue')
    ctx = @get('keyContext') if @get('key')

    if @filterFunctions.length > 0
      developer.currentFilterContext = ctx
      developer.currentFilterStack = @renderContext

      result = @filterFunctions.reduce((value, fn, i) =>
        # Get any argument keypaths from the context stored at parse time.
        args = @filterArguments[i].map (argument) ->
          if argument._keypath
            argument.context.get(argument._keypath)
          else
            argument

        # Apply the filter.
        args.unshift value
        args = args.map deProxy
        fn.apply(ctx, args)
      , unfilteredValue)
      developer.currentFilterContext = null
      developer.currentFilterStack = null
      result
    else
      deProxy(unfilteredValue)

  # The `unfilteredValue` is whats evaluated each time any dependents change.
  @accessor 'unfilteredValue', ->
    # If we're working with an `@key` and not an `@value`, find the context the key belongs to so we can
    # hold a reference to it for passing to the `dataChange` and `nodeChange` observers.
    if k = @get('key')
      @get("keyContext.#{k}")
    else
      @get('value')

  # The `keyContext` accessor is
  @accessor 'keyContext', -> @renderContext.findKey(@key)[1]

  constructor: ->
    super

    # Pull out the key and filter from the `@keyPath`.
    @parseFilter()

    if @node
      # Tie this binding to its node using Batman.data
      if bindings = Batman.data @node, 'bindings'
        bindings.add @
      else
        Batman.data @node, 'bindings', new Batman.Set @

    # Define the default observers.
    @nodeChange ||= (node, context) =>
      if @key && @filterFunctions.length == 0
        @get('keyContext').set @key, @node.value
    @dataChange ||= (value, node) ->
      Batman.DOM.valueForNode @node, value

    shouldSet = yes

    # And attach them.
    if @only in [false, 'nodeChange'] and Batman.DOM.nodeIsEditable(@node)
      Batman.DOM.events.change @node, =>
        shouldSet = no
        @nodeChange(@node, @get('keyContext') || @value, @)
        shouldSet = yes

    # Observe the value of this binding's `filteredValue` and fire it immediately to update the node.
    if @only in [false, 'dataChange']
      @observeAndFire 'filteredValue', (value) =>
        if shouldSet
          @dataChange(value, @node, @)
    @

  parseFilter: ->
    # Store the function which does the filtering and the arguments (all except the actual value to apply the
    # filter to) in these arrays.
    @filterFunctions = []
    @filterArguments = []

    # Rewrite [] style gets, replace quotes to be JSON friendly, and split the string by pipes to see if there are any filters.
    keyPath = @keyPath
    keyPath = keyPath.replace(get_dot_rx, "]['$1']") while get_dot_rx.test(keyPath)  # Stupid lack of lookbehind assertions...
    filters = keyPath.replace(get_rx, " | get $1 ").replace(/'/g, '"').split(/(?!")\s+\|\s+(?!")/)

    # The key will is always the first token before the pipe.
    try
      key = @parseSegment(orig = filters.shift())[0]
    catch e
      developer.warn e
      developer.error "Error! Couldn't parse keypath in \"#{orig}\". Parsing error above."
    if key and key._keypath
      @key = key._keypath
    else
      @value = key

    if filters.length
      while filterString = filters.shift()
        # For each filter, get the name and the arguments by splitting on the first space.
        split = filterString.indexOf(' ')
        if ~split
          filterName = filterString.substr(0, split)
          args = filterString.substr(split)
        else
          filterName = filterString

        # If the filter exists, grab it.
        if filter = Batman.Filters[filterName]
          @filterFunctions.push filter

          # Get the arguments for the filter by parsing the args as JSON, or
          # just pushing an placeholder array
          if args
            try
              @filterArguments.push @parseSegment(args)
            catch e
              developer.error "Bad filter arguments \"#{args}\"!"
          else
            @filterArguments.push []
        else
          developer.error "Unrecognized filter '#{filterName}' in key \"#{@keyPath}\"!"

      # Map over each array of arguments to grab the context for any keypaths.
      @filterArguments = @filterArguments.map (argumentList) =>
        argumentList.map (argument) =>
          if argument._keypath
            # Discard the value (for the time being) and store the context for the keypath in `context`.
            [_, argument.context] = @renderContext.findKey argument._keypath
          argument

  # Turn a piece of a `data` keypath into a usable javascript object.
  #  + replacing keypaths using the above regular expression
  #  + wrapping the `,` delimited list in square brackets
  #  + and `JSON.parse`ing them as an array.
  parseSegment: (segment) ->
    JSON.parse( "[" + segment.replace(keypath_rx, "$1{\"_keypath\": \"$2\"}$3") + "]" )

# The RenderContext class manages the stack of contexts accessible to a view during rendering.
# Every, and I really mean every method which uses filters has to be defined in terms of a new
# binding, or by using the RenderContext.bind method. This is so that the proper order of objects
# is traversed and any observers are properly attached.
class RenderContext
  @start: (contexts...) ->
    node = new @(window)
    contexts.push Batman.currentApp if Batman.currentApp
    while context = contexts.pop()
      node = node.descend(context)
    node

  constructor: (@object, @parent) ->

  findKey: (key) ->
    base = key.split('.')[0].split('|')[0].trim()
    currentNode = @
    while currentNode
      if currentNode.object.get?
        val = currentNode.object.get(base)
      else
        val = currentNode.object[base]

      if typeof val isnt 'undefined'
        # we need to pass the check if the basekey exists, even if the intermediary keys do not.
        return [$get(currentNode.object, key), currentNode.object]
      currentNode = currentNode.parent

    return [container.get(key), container]

  # Below are the three primitives that all the `Batman.DOM` helpers are composed of.
  # `descend` takes an `object`, and optionally a `scopedKey`. It creates a new `RenderContext` leaf node
  # in the tree with either the object available on the stack or the object available at the `scopedKey`
  # on the stack.
  descend: (object, scopedKey) ->
    if scopedKey
      oldObject = object
      object = new Batman.Object()
      object[scopedKey] = oldObject
    return new @constructor(object, @)

  # `descendWithKey` takes a `key` and optionally a `scopedKey`. It creates a new `RenderContext` leaf node
  # with the runtime value of the `key` available on the stack or under the `scopedKey` if given. This
  # differs from a normal `descend` in that it looks up the `key` at runtime (in the parent `RenderContext`)
  # and will correctly reflect changes if the value at the `key` changes. A normal `descend` takes a concrete
  # reference to an object which never changes.
  descendWithKey: (key, scopedKey) ->
   proxy = new ContextProxy(@, key)
   return @descend(proxy, scopedKey)

  # `bind` takes a `node`, a `key`, and observers for when the `dataChange`s and the `nodeChange`s. It
  # creates a `Binding` to the key (supporting filters and the context stack), which fires the observers
  # when appropriate. Note that `Binding` has default observers for `dataChange` and `nodeChange` that
  # will set node/object values if these observers aren't passed in here.
  # The optional `only` parameter can be used to create data-to-node-only or node-to-data-only bindings. If left unset,
  # both data-to-node (source) and node-to-data (target) events are observed.
  bind: (node, key, dataChange, nodeChange, only = false) ->
    return new Binding
      renderContext: @
      keyPath: key
      node: node
      dataChange: dataChange
      nodeChange: nodeChange
      only: only

  # `chain` flattens a `RenderContext`'s path to the root.
  chain: ->
    x = []
    parent = this
    while parent
      x.push parent.object
      parent = parent.parent
    x

  # `ContextProxy` is a simple class which assists in pushing dynamic contexts onto the `RenderContext` tree.
  # This happens when a `data-context` is descended into, for each iteration in a `data-foreach`,
  # and in other specific HTML bindings like `data-formfor`. `ContextProxy`s use accessors so that if the
  # value of the object they proxy changes, the changes will be propagated to any thing observing the `ContextProxy`.
  # This is good because it allows `data-context` to take keys which will change, filtered keys, and even filters
  # which take keypath arguments. It will calculate the context to descend into when any of those keys change
  # because it preserves the property of a binding, and importantly it exposes a friendly `Batman.Object`
  # interface for the rest of the `Binding` code to work with.
  @ContextProxy = class ContextProxy extends Batman.Object
    isContextProxy: true

    # Reveal the binding's final value.
    @accessor 'proxiedObject', -> @binding.get('filteredValue')
    # Proxy all gets to the proxied object.
    @accessor
      get: (key) -> @get("proxiedObject.#{key}")
      set: (key, value) -> @set("proxiedObject.#{key}", value)
      unset: (key) -> @unset("proxiedObject.#{key}")

    constructor: (@renderContext, @keyPath, @localKey) ->
      @binding = new Binding
        renderContext: @renderContext
        keyPath: @keyPath
        only: 'neither'

Batman.DOM = {
  # `Batman.DOM.readers` contains the functions used for binding a node's value or innerHTML, showing/hiding nodes,
  # and any other `data-#{name}=""` style DOM directives.
  readers: {
    target: (node, key, context, renderer) ->
      Batman.DOM.readers.bind(node, key, context, renderer, 'nodeChange')
      true

    source: (node, key, context, renderer) ->
      Batman.DOM.readers.bind(node, key, context, renderer, 'dataChange')
      true

    bind: (node, key, context, renderer, only) ->
      switch node.nodeName.toLowerCase()
        when 'input'
          switch node.getAttribute('type')
            when 'checkbox'
              return Batman.DOM.attrReaders.bind(node, 'checked', key, context, renderer, only)
            when 'radio'
              return Batman.DOM.binders.radio(arguments...)
            when 'file'
              return Batman.DOM.binders.file(arguments...)
        when 'select'
          return Batman.DOM.binders.select(arguments...)

      # Fallback on the default nodeChange and dataChange observers in Binding
      context.bind(node, key, undefined, undefined, only)
      true

    context: (node, key, context, renderer) -> return context.descendWithKey(key)

    mixin: (node, key, context) ->
      context.descend(Batman.mixins).bind(node, key, (mixin) ->
        $mixin node, mixin
      , ->)
      true

    showif: (node, key, context, renderer, invert) ->
      originalDisplay = node.style.display || ''

      context.bind(node, key, (value) ->
        if !!value is !invert
          Batman.data(node, 'show')?.call(node)
          node.style.display = originalDisplay
        else
          hide = Batman.data node, 'hide'
          if typeof hide == 'function'
            hide.call node
          else
            node.style.display = 'none'
      , -> )
      true

    hideif: (args...) ->
      Batman.DOM.readers.showif args..., yes
      true

    route: (node, key, context) ->
      # you must specify the / in front to route directly to hash route
      if key.substr(0, 1) is '/'
        url = key
      else
        [key, action] = key.split '/'
        [dispatcher, app] = context.findKey 'dispatcher'
        [model, container] = context.findKey key

        dispatcher ||= Batman.currentApp.dispatcher

        if dispatcher and model instanceof Batman.Model
          action ||= 'show'
          name = helpers.underscore(helpers.pluralize($functionName(model.constructor)))
          url = dispatcher.findUrl({resource: name, id: model.get('id'), action: action})
        else if model?.prototype # TODO write test for else case
          action ||= 'index'
          name = helpers.underscore(helpers.pluralize($functionName(model)))
          url = dispatcher.findUrl({resource: name, action: action})

      return unless url

      if node.nodeName.toUpperCase() is 'A'
        node.href = Batman.HashHistory::urlFor url

      Batman.DOM.events.click node, (-> $redirect url)
      true

    partial: (node, path, context, renderer) ->
      renderer.prevent('rendered')

      view = new Batman.View
        source: path + '.html'
        contentFor: node
        contexts: context.chain()

      view.on 'ready', ->
        renderer.allow 'rendered'
        renderer.fire 'rendered'

      true

    yield: (node, key) ->
      setTimeout (-> Batman.DOM.yield key, node), 0
      true
    contentfor: (node, key) ->
      setTimeout (-> Batman.DOM.contentFor key, node), 0
      true
    replace: (node, key) ->
      setTimeout (-> Batman.DOM.replace key, node), 0
      true
  }
  _yieldContents: {}  # name/content pairs of content to be yielded
  _yields: {}         # name/container pairs of yielding nodes

  # `Batman.DOM.attrReaders` contains all the DOM directives which take an argument in their name, in the
  # `data-dosomething-argument="keypath"` style. This means things like foreach, binding attributes like
  # disabled or anything arbitrary, descending into a context, binding specific classes, or binding to events.
  attrReaders: {
    _parseAttribute: (value) ->
      if value is 'false' then value = false
      if value is 'true' then value = true
      value

    source: (node, attr, key, context, renderer) ->
      Batman.DOM.attrReaders.bind node, attr, key, context, renderer, 'dataChange'

    bind: (node, attr, key, context, renderer, only) ->
      switch attr
        when 'checked', 'disabled', 'selected'
          dataChange = (value) ->
            node[attr] = !!value
            # Update the parent's binding if necessary
            Batman.data(node.parentNode, 'updateBinding')?()

          nodeChange = (node, subContext) ->
            subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node[attr]))

          # Make the context and key available to the parent select
          Batman.data node, attr,
            context: context
            key: key

        when 'value', 'style', 'href', 'src', 'size'
          dataChange = (value) -> node[attr] = value
          nodeChange = (node, subContext) -> subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node[attr]))
        when 'class'
          dataChange = (value) -> node.className = value
          nodeChange = (node, subContext) -> subContext.set key, node.className
        else
          dataChange = (value) -> node.setAttribute(attr, value)
          nodeChange = (node, subContext) -> subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.getAttribute(attr)))

      context.bind(node, key, dataChange, nodeChange, only)
      true

    context: (node, contextName, key, context) -> return context.descendWithKey(key, contextName)

    event: (node, eventName, key, context) ->
      props =
        callback:  null
        subContext: null

      context.bind node, key, (value, node, binding) ->
        props.callback = value
        if binding.get('key')
          ks = binding.get('key').split('.')
          ks.pop()
          if ks.length > 0
            props.subContext = binding.get('keyContext').get(ks.join('.'))
          else
            props.subContext = binding.get('keyContext')
      , ->

      confirmText = node.getAttribute('data-confirm')
      Batman.DOM.events[eventName] node, ->
        if confirmText and not confirm(confirmText)
          return
        props.callback?.apply props.subContext, arguments
      true

    addclass: (node, className, key, context, parentRenderer, invert) ->
      className = className.replace(/\|/g, ' ') #this will let you add or remove multiple class names in one binding
      context.bind node, key, (value) ->
        currentName = node.className
        includesClassName = currentName.indexOf(className) isnt -1
        if !!value is !invert
          node.className = "#{currentName} #{className}" if !includesClassName
        else
          node.className = currentName.replace(className, '') if includesClassName
      , ->
      true

    removeclass: (args...) -> Batman.DOM.attrReaders.addclass args..., yes

    foreach: (node, iteratorName, key, context, parentRenderer) ->
      prototype = node.cloneNode true
      prototype.removeAttribute "data-foreach-#{iteratorName}"

      parent = node.parentNode
      sibling = node.nextSibling

      # Remove the original node once the parent has moved past it.
      parentRenderer.on 'parsed', -> $removeNode node

      # Get a hash keyed by collection item with the nodes representing that item as values
      nodeMap = new Batman.SimpleHash


      old = {collection: false, renderers: new Batman.SimpleHash, observers: {}}

      context.bind(node, key, (collection) ->
        # Track the old collection so that if it changes, we can remove the observers we attached,
        # and only observe the new collection.
        if old.collection
          return if collection == old.collection
          nodeMap.forEach (item, node) -> $removeNode node
          nodeMap.clear()
          old.renderers.forEach (renderer) -> renderer.stop()
          old.renderers.clear()
          if old.collection.isEventEmitter
            old.collection.event('itemsWereAdded').removeHandler(old.observers.add)
            old.collection.event('itemsWereRemoved').removeHandler(old.observers.remove)
            old.collection.event('setWasSorted').removeHandler(old.observers.reorder)

        old.collection = collection
        observers = (old.observers = {})
        fragment = document.createDocumentFragment()
        numPendingChildren = 0
        observers.add = (items...) ->
          numPendingChildren += items.length
          for item in items
            parentRenderer.prevent 'rendered'

            newNode = prototype.cloneNode true
            nodeMap.set item, newNode

            childRenderer = new Batman.Renderer newNode, do (newNode, item) ->
              ->
                # Handle the case where the item has already been deleted before rendering completed
                unless nodeMap.get(item) == newNode
                  old.renderers.unset(childRenderer)
                  return
                show = Batman.data newNode, 'show'
                if typeof show is 'function'
                  show.call newNode, before: sibling
                else
                  fragment.appendChild newNode
                if --numPendingChildren == 0
                  parent.insertBefore fragment, sibling
                  if collection.isSorted?()
                    observers.reorder()
                  fragment = document.createDocumentFragment()
            , context.descend(item, iteratorName)

            old.renderers.set(childRenderer)

            childRenderer.on 'rendered', ->
              parentRenderer.allow 'rendered'
              parentRenderer.fire 'rendered'

            childRenderer.on 'stopped', ->
              numPendingChildren--
              parentRenderer.allow 'rendered'
              parentRenderer.fire 'rendered'

        observers.remove = (items...) ->
          for item in items
            oldNode = nodeMap.get item
            nodeMap.unset item
            if oldNode? && typeof oldNode.hide is 'function'
              oldNode.hide yes
            else
              $removeNode oldNode
          true

        observers.reorder = ->
          items = collection.toArray()
          for item in items
            thisNode = nodeMap.get(item)
            show = Batman.data thisNode, 'show'
            if typeof show is 'function'
              show.call thisNode, before: sibling
            else
              parent.insertBefore(thisNode, sibling)

        observers.arrayChange = (array) ->
          observers.remove(array...)
          observers.add(array...)

        # Observe the collection for events in the future
        if collection
          if collection.isEventEmitter
            collection.on 'itemsWereAdded', observers.add
            collection.on 'itemsWereRemoved', observers.remove
            if collection.isSortableSet
              collection.on 'setWasSorted', observers.reorder
            else if collection.isObservable
              collection.observe 'toArray', observers.arrayChange

          # Add all the already existing items. For hash-likes, add the key.
          if collection.forEach
            collection.forEach (item) -> observers.add(item)
          else if collection.toArray is 'function' and array = collection.toArray()
            observers.add(array...)
          else
            observers.add(k) for own k, v of collection
        else
          developer.warn "Warning! data-foreach-#{iteratorName} called with an undefined binding. Key was: #{key}."
      , -> )

      false # Return false so the Renderer doesn't descend into this node's children.

    formfor: (node, localName, key, context) ->
      Batman.DOM.events.submit node, (node, e) -> $preventDefault e
      context.descendWithKey(key, localName)
  }

  # `Batman.DOM.binders` contains functions used to create element bindings
  # These are called via `Batman.DOM.readers` or `Batman.DOM.attrReaders`
  binders: {
    select: (node, key, context, renderer, only) ->
      [boundValue, container] = context.findKey key

      updateSelectBinding = =>
        # Gather the selected options and update the binding
        selections = if node.multiple then (c.value for c in node.children when c.selected) else node.value
        selections = selections[0] if selections.length == 1
        container.set key, selections

      updateOptionBindings = =>
        # Go through the option nodes and update their bindings using the
        # context and key attached to the node via Batman.data
        for child in node.children
          if data = Batman.data(child, 'selected')
            if (subContext = data.context) and (subKey = data.key)
              [subBoundValue, subContainer] = subContext.findKey subKey
              unless child.selected == subBoundValue
                subContainer.set subKey, child.selected

      # wait for the select to render before binding to it
      renderer.on 'rendered', ->
        # Update the select box with the binding's new value.
        dataChange = (newValue) ->
          # For multi-select boxes, the `value` property only holds the first
          # selection, so we need to go through the child options and update
          # as necessary.
          if newValue instanceof Array
            # Use a hash to map values to their nodes to avoid O(n^2).
            valueToChild = {}
            for child in node.children
              # Clear all options.
              child.selected = false
              # Avoid collisions among options with same values.
              matches = valueToChild[child.value]
              if matches then matches.push child else matches = [child]
              valueToChild[child.value] = matches
            # Select options corresponding to the new values
            for value in newValue
              for match in valueToChild[value]
                match.selected = yes
          # For a regular select box, we just update the value.
          else
            node.value = newValue

          # Finally, we need to update the options' `selected` bindings
          updateOptionBindings()

        # Update the bindings with the node's new value
        nodeChange = ->
          updateSelectBinding()
          updateOptionBindings()

        # Expose the updateSelectBinding helper for the child options
        Batman.data node, 'updateBinding', updateSelectBinding

        # Create the binding
        context.bind node, key, dataChange, nodeChange, only
      true

    radio: (node, key, context, renderer, only) ->
      dataChange = (value) ->
        # don't overwrite `checked` attributes in the HTML unless a bound
        # value is defined in the context. if no bound value is found, bind
        # to the key if the node is checked.
        [boundValue, container] = context.findKey key
        if boundValue
          node.checked = boundValue == node.value
        else if node.checked
          container.set key, node.value
      nodeChange = (newNode, subContext) ->
        subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.value))
      context.bind node, key, dataChange, nodeChange, only
      true

    file: (node, key, context, renderer, only) ->
      context.bind(node, key, ->
        developer.warn "Can't write to file inputs! Tried to on key #{key}."
      , (node, subContext) ->
        if subContext instanceof RenderContext.ContextProxy
          actualObject = subContext.get('proxiedObject')
        else
          actualObject = subContext
        if actualObject.hasStorage && actualObject.hasStorage()
          for adapter in actualObject._batman.get('storage') when adapter instanceof Batman.RestStorage
            adapter.defaultOptions.formData = true

        if node.hasAttribute('multiple')
          subContext.set key, Array::slice.call(node.files)
        else
          subContext.set key, node.files[0]
      , only)
      true
  }

  # `Batman.DOM.events` contains the helpers used for binding to events. These aren't called by
  # DOM directives, but are used to handle specific events by the `data-event-#{name}` helper.
  events: {
    click: (node, callback, eventName = 'click') ->
      $addEventListener node, eventName, (args...) ->
        callback node, args...
        $preventDefault args[0]

      if node.nodeName.toUpperCase() is 'A' and not node.href
        node.href = '#'

      node

    doubleclick: (node, callback) ->
      # The actual DOM event is called `dblclick`
      Batman.DOM.events.click node, callback, 'dblclick'

    change: (node, callback) ->
      eventNames = switch node.nodeName.toUpperCase()
        when 'TEXTAREA' then ['keyup', 'change']
        when 'INPUT'
          if node.type.toUpperCase() is 'TEXT'
            oldCallback = callback
            callback = (e) ->
              return if e.type == 'keyup' && 13 <= e.keyCode <= 14
              oldCallback(arguments...)
            ['keyup', 'change']
          else
            ['change']
        else ['change']

      for eventName in eventNames
        $addEventListener node, eventName, (args...) ->
          callback node, args...

    submit: (node, callback) ->
      if Batman.DOM.nodeIsEditable(node)
        $addEventListener node, 'keyup', (args...) ->
          if args[0].keyCode is 13 || args[0].which is 13 || args[0].keyIdentifier is 'Enter' || args[0].key is 'Enter'
            $preventDefault args[0]
            callback node, args...
      else
        $addEventListener node, 'submit', (args...) ->
          $preventDefault args[0]
          callback node, args...

      node
  }

  # `yield` and `contentFor` are used to declare partial views and then pull them in elsewhere.
  # `replace` is used to replace yielded content.
  # This can be used for abstraction as well as repetition.
  yield: (name, node, _replaceContent = !Batman.data(node, 'yielded')) ->
    Batman.DOM._yields[name] = node

    # render any content for this yield
    if contents = Batman.DOM._yieldContents[name]
      if _replaceContent
        $setInnerHTML node, ''
      for content in contents when !Batman.data(content, 'yielded')
        content = if $isChildOf(node, content) then content.cloneNode(true) else content
        node.appendChild(content)
        Batman.data(content, 'yielded', true)
      # delete references to the rendered content nodes and mark the node as yielded
      delete Batman.DOM._yieldContents[name]
      Batman.data(node, 'yielded', true)

  contentFor: (name, node, _replaceContent) ->
    contents = Batman.DOM._yieldContents[name]
    if contents then contents.push(node) else Batman.DOM._yieldContents[name] = [node]

    if yieldingNode = Batman.DOM._yields[name]
      Batman.DOM.yield name, yieldingNode, _replaceContent

  replace: (name, node) ->
    Batman.DOM.contentFor name, node, true

  # Removes listeners and bindings tied to `node`, allowing it to be cleared
  # or removed without leaking memory
  unbindNode: $unbindNode = (node) ->
    # remove all event listeners
    if listeners = Batman.data node, 'listeners'
      for eventName, eventListeners of listeners
        eventListeners.forEach (listener) ->
          $removeEventListener node, eventName, listener

    # remove all bindings and other data associated with this node
    Batman.removeData node

  # Unbinds the tree rooted at `node`.
  # When set to `false`, `unbindRoot` skips the `node` before unbinding all of its children.
  unbindTree: $unbindTree = (node, unbindRoot = true) ->
    return unless node?.nodeType is 1
    $unbindNode node if unbindRoot
    $unbindTree(child) for child in node.childNodes

  # Memory-safe setting of a node's innerHTML property
  setInnerHTML: $setInnerHTML = (node, html) ->
    $unbindTree node, false
    node?.innerHTML = html

  # Memory-safe removal of a node from the DOM
  removeNode: $removeNode = (node) ->
    $unbindTree node
    node?.parentNode?.removeChild node

  valueForNode: (node, value = '') ->
    isSetting = arguments.length > 1
    switch node.nodeName.toUpperCase()
      when 'INPUT'
        if isSetting then (node.value = value) else node.value
      when 'TEXTAREA'
        if isSetting
          node.innerHTML = node.value = value
        else
          node.innerHTML
      when 'SELECT'
        node.value = value
      else
        if isSetting
          $setInnerHTML node, value
        else node.innerHTML

  nodeIsEditable: (node) ->
    node.nodeName.toUpperCase() in ['INPUT', 'TEXTAREA', 'SELECT']

  # `$addEventListener uses attachEvent when necessary
  addEventListener: $addEventListener = (node, eventName, callback) ->
    # store the listener in Batman.data
    unless listeners = Batman.data node, 'listeners'
      listeners = Batman.data node, 'listeners', {}
    unless listeners[eventName]
      listeners[eventName] = new Batman.Set
    listeners[eventName].add callback

    if $hasAddEventListener
      node.addEventListener eventName, callback, false
    else
      node.attachEvent "on#{eventName}", callback

  # `$removeEventListener` uses detachEvent when necessary
  removeEventListener: $removeEventListener = (node, eventName, callback) ->
    # remove the listener from Batman.data
    if listeners = Batman.data node, 'listeners'
      if eventListeners = listeners[eventName]
        eventListeners.remove callback

    if $hasAddEventListener
      node.removeEventListener eventName, callback, false
    else
      node.detachEvent 'on'+eventName, callback

  hasAddEventListener: $hasAddEventListener = !!window?.addEventListener
}

# Filters
# -------
#
# `Batman.Filters` contains the simple, determininistic tranforms used in view bindings to
# make life a little easier.
buntUndefined = (f) ->
  (value) ->
    if typeof value is 'undefined'
      undefined
    else
      f.apply(@, arguments)

filters = Batman.Filters =
  get: buntUndefined (value, key) ->
    if value.get?
      value.get(key)
    else
      value[key]

  equals: buntUndefined (lhs, rhs) ->
    lhs is rhs

  not: (value) ->
    ! !!value

  truncate: buntUndefined (value, length, end = "...") ->
    if value.length > length
      value = value.substr(0, length-end.length) + end
    value

  default: (value, string) ->
    value || string

  prepend: (value, string) ->
    string + value

  append: (value, string) ->
    value + string

  downcase: buntUndefined (value) ->
    value.toLowerCase()

  upcase: buntUndefined (value) ->
    value.toUpperCase()

  pluralize: buntUndefined (string, count) -> helpers.pluralize(count, string)

  join: buntUndefined (value, byWhat = '') ->
    value.join(byWhat)

  sort: buntUndefined (value) ->
    value.sort()

  map: buntUndefined (value, key) ->
    value.map((x) -> x[key])

  first: buntUndefined (value) ->
    value[0]

  meta: buntUndefined (value, keypath) ->
    developer.assert value.meta, "Error, value doesn't have a meta to filter on!"
    value.meta.get(keypath)

for k in ['capitalize', 'singularize', 'underscore', 'camelize']
  filters[k] = buntUndefined helpers[k]

developer.addFilters()

# Data
# ----
$mixin Batman,
  cache: {}
  uuid: 0
  expando: "batman" + Math.random().toString().replace(/\D/g, '')
  canDeleteExpando: true
  noData: # these throw exceptions if you attempt to add expandos to them
    "embed": true,
    # Ban all objects except for Flash (which handle expandos)
    "object": "clsid:D27CDB6E-AE6D-11cf-96B8-444553540000",
    "applet": true

  hasData: (elem) ->
    elem = (if elem.nodeType then Batman.cache[elem[Batman.expando]] else elem[Batman.expando])
    !!elem and !isEmptyDataObject(elem)

  data: (elem, name, data, pvt) -> # pvt is for internal use only
    return  unless Batman.acceptData(elem)
    internalKey = Batman.expando
    getByName = typeof name == "string"
    # DOM nodes and JS objects have to be handled differently because IE6-7 can't
    # GC object references properly across the DOM-JS boundary
    isNode = elem.nodeType
    # Only DOM nodes need the global cache; JS object data is attached directly so GC
    # can occur automatically
    cache = if isNode then Batman.cache else elem
    # Only defining an ID for JS objects if its cache already exists allows
    # the code to shortcut on the same path as a DOM node with no cache
    id = if isNode then elem[Batman.expando] else elem[Batman.expando] && Batman.expando

    # Avoid doing any more work than we need to when trying to get data on an
    # object that has no data at all
    if (not id or (pvt and id and (cache[id] and not cache[id][internalKey]))) and getByName and data == undefined
      return

    unless id
      # Only DOM nodes need a new unique ID for each element since their data
      # ends up in the global cache
      if isNode
        elem[Batman.expando] = id = ++Batman.uuid
      else
        id = Batman.expando

    cache[id] = {} unless cache[id]

    # An object can be passed to Batman.data instead of a key/value pair; this gets
    # shallow copied over onto the existing cache
    if typeof name == "object" or typeof name == "function"
      if pvt
        cache[id][internalKey] = $mixin(cache[id][internalKey], name)
      else
        cache[id] = $mixin(cache[id], name)

    thisCache = cache[id]

    # Internal Batman data is stored in a separate object inside the object's data
    # cache in order to avoid key collisions between internal data and user-defined
    # data
    if pvt
      thisCache[internalKey] = {} unless thisCache[internalKey]
      thisCache = thisCache[internalKey]

    unless data is undefined
      thisCache[helpers.camelize(name, true)] = data

    # Check for both converted-to-camel and non-converted data property names
    # If a data property was specified
    if getByName
      # First try to find as-is property data
      ret = thisCache[name]
      # Test for null|undefined property data and try to find camel-cased property
      ret = thisCache[helpers.camelize(name, true)]  unless ret?
    else
      ret = thisCache

    return ret

  removeData: (elem, name, pvt) -> # pvt is for internal use only
    return unless Batman.acceptData(elem)
    internalKey = Batman.expando
    isNode = elem.nodeType
    # non DOM-nodes have their data attached directly
    cache = if isNode then Batman.cache else elem
    id = if isNode then elem[Batman.expando] else Batman.expando

    # If there is already no cache entry for this object, there is no
    # purpose in continuing
    return unless cache[id]

    if name
      thisCache = if pvt then cache[id][internalKey] else cache[id]
      if thisCache
        # Support interoperable removal of hyphenated or camelcased keys
        name = helpers.camelize(name, true) unless thisCache[name]
        delete thisCache[name]
        # If there is no data left in the cache, we want to continue
        # and let the cache object itself get destroyed
        return unless isEmptyDataObject(thisCache)

    if pvt
      delete cache[id][internalKey]
      # Don't destroy the parent cache unless the internal data object
      # had been the only thing left in it
      return unless isEmptyDataObject(cache[id])

    internalCache = cache[id][internalKey]

    # Browsers that fail expando deletion also refuse to delete expandos on
    # the window, but it will allow it on all other JS objects; other browsers
    # don't care
    # Ensure that `cache` is not a window object
    if Batman.canDeleteExpando or !cache.setInterval
      delete cache[id]
    else
      cache[id] = null

    # We destroyed the entire user cache at once because it's faster than
    # iterating through each key, but we need to continue to persist internal
    # data if it existed
    if internalCache
      cache[id] = {}
      cache[id][internalKey] = internalCache
    # Otherwise, we need to eliminate the expando on the node to avoid
    # false lookups in the cache for entries that no longer exist
    else if isNode
      if Batman.canDeleteExpando
        delete elem[Batman.expando]
      else if elem.removeAttribute
        elem.removeAttribute Batman.expando
      else
        elem[Batman.expando] = null

  # For internal use only
  _data: (elem, name, data) ->
    Batman.data elem, name, data, true

  # A method for determining if a DOM node can handle the data expando
  acceptData: (elem) ->
    if elem.nodeName
      match = Batman.noData[elem.nodeName.toLowerCase()]
      if match
        return !(match == true or elem.getAttribute("classid") != match)
    return true

isEmptyDataObject = (obj) ->
  for name of obj
    return false
  return true

# Test to see if it's possible to delete an expando from an element
# Fails in Internet Explorer
try
  div = document.createElement 'div'
  delete div.test
catch e
  Batman.canDeleteExpando = false

# Mixins
# ------
mixins = Batman.mixins = new Batman.Object()

# Encoders
# ------
Batman.Encoders =
  railsDate:
    encode: (value) -> value
    decode: (value) ->
      a = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)Z$/.exec(value)
      if a
        return new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4], +a[5], +a[6]))
      else
        developer.error "Unrecognized rails date #{value}!"


# Export a few globals, and grab a reference to an object accessible from all contexts for use elsewhere.
# In node, the container is the `global` object, and in the browser, the container is the window object.
container = if exports?
  module.exports = Batman
  global
else
  window.Batman = Batman
  window

$mixin container, Batman.Observable

# Optionally export global sugar. Not sure what to do with this.
Batman.exportHelpers = (onto) ->
  for k in ['mixin', 'unmixin', 'route', 'redirect', 'typeOf', 'redirect']
    onto["$#{k}"] = Batman[k]
  onto

Batman.exportGlobals = () ->
  Batman.exportHelpers(container)
