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

Batman.config =
  pathPrefix: '/'
  usePushState: no

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


_implementImmediates = ->
  canUsePostMessage = ->
    return false unless container.postMessage
    async = true
    oldMessage = container.onmessage
    container.onmessage = -> async = false
    container.postMessage("","*")
    container.onmessage = oldMessage
    async

  tasks = new Batman.SimpleHash
  count = 0
  getHandle = -> "go#{++count}"

  if container.setImmediate
    $setImmediate = container.setImmediate
    $clearImmediate = container.clearImmediate
  else if container.msSetImmediate
    $setImmediate = msSetImmediate
    $clearImmediate = msClearImmediate
  else if canUsePostMessage()
    prefix = 'com.batman.'
    functions = new Batman.SimpleHash
    handler = (e) ->
      return unless ~e.data.search(prefix)
      handle = e.data.substring(prefix.length)
      tasks.unset(handle)?()

    if container.addEventListener
      container.addEventListener('message', handler, false)
    else
      container.attachEvent('onmessage', handler)

    $setImmediate = (f) ->
      tasks.set(handle = getHandle(), f)
      container.postMessage(prefix+handle, "*")
      handle
    $clearImmediate = (handle) -> tasks.unset(handle)
  else if typeof document isnt 'undefined' && "onreadystatechange" in document.createElement("script")
    $setImmediate = (f) ->
      handle = getHandle()
      script = document.createElement("script")
      script.onreadystatechange = ->
        tasks.get(handle)?()
        script.onreadystatechange = null
        script.parentNode.removeChild(script)
        script = null
      document.documentElement.appendChild(script)
      handle
    $clearImmediate = (handle) -> tasks.unset(handle)
  else
    $setImmediate = (f) -> setTimeout(f, 0)
    $clearImmediate = (handle) -> clearTimeout(handle)

  Batman.setImmediate = $setImmediate
  Batman.clearImmediate = $clearImmediate

Batman.setImmediate = $setImmediate = ->
  _implementImmediates()
  Batman.setImmediate.apply(@, arguments)

Batman.clearImmediate = $clearImmediate = ->
  _implementImmediates()
  Batman.clearImmediate.apply(@, arguments)

# `translate` is hook for the i18n extra to override and implemnent. All strings which might
# be shown to the user pass through this method. `translate` is aliased to `t` internally.
Batman.translate = (x, values = {}) -> helpers.interpolate($get(Batman.translate.messages, x), values)
Batman.translate.messages = {}
t = -> Batman.translate(arguments...)

# Developer Tooling
# -----------------

developer =
  suppressed: false
  DevelopmentError: (->
    DevelopmentError = (@message) ->
      @name = "DevelopmentError"
    DevelopmentError:: = Error::
    DevelopmentError
  )()
  _ie_console: (f, args) ->
    console?[f] "...#{f} of #{args.length} items..." unless args.length == 1
    console?[f] arg for arg in args
  suppress: (f) ->
    developer.suppressed = true
    if f
      f()
      developer.suppressed = false
  unsuppress: ->
    developer.suppressed = false
  log: ->
    return if developer.suppressed or !(console?.log?)
    if console.log.apply then console.log(arguments...) else developer._ie_console "log", arguments
  warn: ->
    return if developer.suppressed or !(console?.warn?)
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

Batman.developer = developer

developer.assert (->).bind, "Error! Batman needs Function.bind to work! Please shim it using something like es5-shim or augmentjs!"
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

  interpolate: (stringOrObject, keys) ->
    if typeof stringOrObject is 'object'
      string = stringOrObject[keys.count]
      unless string
        string = stringOrObject['other']
    else
      string = stringOrObject

    for key, value of keys
      string = string.replace(new RegExp("%\\{#{key}\\}", "g"), value)
    string
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
        if ancestor.isEventEmitter and ancestor.hasEvent(key)
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
  allowAndFire: ->
    @allow()
    @fire(arguments...)

Batman.EventEmitter =
  isEventEmitter: true
  hasEvent: (key) ->
    @_batman?.get?('events')?.hasKey(key)
  event: (key) ->
    Batman.initializeObject @
    eventClass = @eventClass or Batman.Event
    events = @_batman.events ||= new Batman.SimpleHash
    if events.hasKey(key)
      existingEvent = events.get(key)
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
  prevent: (key) ->
    @event(key).prevent()
    @
  allow: (key) ->
    @event(key).allow()
    @
  isPrevented: (key) ->
    @event(key).isPrevented()
  fire: (key, args...) ->
    @event(key).fire(args...)
  allowAndFire: (key, args...) ->
    @event(key).allowAndFire(args...)

class Batman.PropertyEvent extends Batman.Event
  eachHandler: (iterator) -> @base.eachObserver(iterator)
  handlerContext: -> @base.base

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

  changeEvent: ->
    event = @event('change')
    @changeEvent = -> event
    event
  accessor: ->
    keyAccessors = @base._batman?.get('keyAccessors')
    accessor = if keyAccessors && (val = keyAccessors.get(@key))
      val
    else
      @base._batman?.getFirst('defaultAccessor') or Batman.Property.defaultAccessor
    @accessor = -> accessor
    accessor
  eachObserver: (iterator) ->
    key = @key
    @changeEvent().handlers.forEach(iterator)
    if @base.isObservable
      @base._batman.ancestors (ancestor) ->
        if ancestor.isObservable and ancestor.hasProperty(key)
          property = ancestor.property(key)
          handlers = property.event('change').handlers
          handlers.forEach(iterator)

  pushSourceTracker: -> Batman.Property._sourceTrackerStack.push(new Batman.SimpleSet)
  pushDummySourceTracker: -> Batman.Property._sourceTrackerStack.push(null)
  popSourceTracker: -> Batman.Property._sourceTrackerStack.pop()
  updateSourcesFromTracker: ->
    newSources = @popSourceTracker()
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
    if value isnt previousValue and not @isIsolated()
      @fire(value, previousValue)

  sourceChangeHandler: ->
    handler = => @_handleSourceChange()
    @sourceChangeHandler = -> handler
    handler

  _handleSourceChange: ->
    if @isIsolated()
      @_needsRefresh = yes
    else if @changeEvent().handlers.isEmpty()
      @cached = no
    else
      @refresh()

  valueFromAccessor: -> @accessor().get?.call(@base, @key)

  setValue: (val) ->
    @pushDummySourceTracker()
    @cached = no
    result = @accessor().set?.call(@base, @key, val)
    @refresh()
    @popSourceTracker()
    result
  unsetValue: ->
    @pushDummySourceTracker()
    result = @accessor().unset?.call(@base, @key)
    @refresh()
    @popSourceTracker()
    if (!@sources? || @sources.length == 0) && @changeEvent().handlers?.length == 0
      @base._batman?.properties?.unset(@key)
    result

  forget: (handler) ->
    if handler?
      @changeEvent().removeHandler(handler)
    else
      @changeEvent().handlers.clear()
  observeAndFire: (handler) ->
    @observe(handler)
    handler.call(@base, @value, @value)
  observe: (handler) ->
    @changeEvent().addHandler(handler)
    @getValue()
    this

  removeSourceHandlers: ->
    handler = @sourceChangeHandler()
    @_eachSourceChangeEvent (e) -> e.removeHandler(handler)
    @forget()

  fire: -> @changeEvent().fire(arguments...)

  isolate: ->
    if @_isolationCount is 0
      @_preIsolationValue = @getValue()
    @_isolationCount++
  expose: ->
    if @_isolationCount is 1
      @_isolationCount--
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
  hasProperty: (key) ->
    @_batman?.properties?.hasKey?(key)
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
      @_batman.properties?.forEach (key, property) -> property.forget()
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

$get = Batman.get = (base, key) ->
  if base.get? && typeof base.get is 'function'
    base.get(key)
  else
    Batman.Property.forBaseAndKey(base, key).getValue()

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

  toJSON: ->
    obj = {}
    for own key, value of @ when key not in ["_batman", "hashKey", "_objectID"]
      obj[key] = if value.toJSON then value.toJSON() else value
    obj


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

class Batman.TerminalAccessible extends Batman.Accessible
  propertyClass: Batman.Property

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
    hashKey = @hashKeyFor(key)
    if pairs = @_storage[hashKey]
      for [obj,value], index in pairs
        if @equality(obj, key)
          pair = pairs.splice(index,1)
          delete @_storage[hashKey] unless pairs.length
          @length--
          return pair[0][1]
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
    Batman.SimpleHash::forEach.call @, (key) -> result.push key
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
    set: @mutation (key, value) ->
      result = Batman.SimpleHash::set.call(@, key, value)
      @fire 'itemsWereAdded', key
      result
    unset: @mutation (key) ->
      result = Batman.SimpleHash::unset.call(@, key)
      @fire 'itemsWereRemoved', key if result?
      result

  clear: @mutation ->
    keys = @meta.get('keys')
    @forEach (k) => @unset(k)
    result = Batman.SimpleHash::clear.call(@)
    @fire 'itemsWereRemoved', keys...
    result
  equality: Batman.SimpleHash::equality
  hashKeyFor: Batman.SimpleHash::hashKeyFor

  toJSON: ->
    obj = {}
    @keys().forEach (key) =>
      value = @get key
      obj[key] = if value.toJSON then value.toJSON() else value
    obj

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
  sortedBy: (key, order="asc") ->
    order = if order.toLowerCase() is "desc" then "desc" else "asc"
    sortsForKey = @_sorts.get(key) or @_sorts.set(key, new Batman.Object)
    sortsForKey.get(order) or sortsForKey.set(order, new Batman.SetSort(@, key, order))

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

  @accessor 'indexedBy', -> new Batman.TerminalAccessible (key) => @indexedBy(key)
  @accessor 'sortedBy',  -> new Batman.TerminalAccessible (key) => @sortedBy(key)
  @accessor 'sortedByDescending', -> new Batman.TerminalAccessible (key) => @sortedBy(key, 'desc')
  @accessor 'isEmpty', -> @isEmpty()
  @accessor 'toArray', -> @toArray()
  @accessor 'length', ->
    @registerAsMutableSource()
    @length

class Batman.SetObserver extends Batman.Object
  constructor: (@base) ->
    @_itemObservers = new Batman.SimpleHash
    @_setObservers = new Batman.SimpleHash
    @_setObservers.set "itemsWereAdded", => @fire('itemsWereAdded', arguments...)
    @_setObservers.set "itemsWereRemoved", => @fire('itemsWereRemoved', arguments...)
    @on 'itemsWereAdded', @startObservingItems.bind(@)
    @on 'itemsWereRemoved', @stopObservingItems.bind(@)

  observedItemKeys: []
  observerForItemAndKey: (item, key) ->

  _getOrSetObserverForItemAndKey: (item, key) ->
    @_itemObservers.getOrSet item, =>
      observersByKey = new Batman.SimpleHash
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

class Batman.SetProxy extends Batman.Object
  constructor: () ->
    super()
    @length = 0

  $extendsEnumerable(@::)

  filter: (f) ->
    r = new Batman.Set()
    @reduce(((r, e) -> r.add(e) if f(e); r), r)

  for k in ['add', 'remove', 'clear']
    do (k) =>
      @::[k] = ->
        results = @base[k](arguments...)
        @length = @set('length', @base.get 'length')
        results

  for k in ['has', 'merge', 'toArray', 'isEmpty']
    do (k) =>
      @::[k] = -> @base[k](arguments...)

  for k in ['isEmpty', 'toArray']
    do (k) =>
      @accessor k, -> @base.get(k)

  @accessor 'length'
    get: ->
      @registerAsMutableSource()
      @length
    set: (k, v) ->
      @length = v

class Batman.SetSort extends Batman.SetProxy
  constructor: (@base, @key, order="asc") ->
    super()
    @descending = order.toLowerCase() is "desc"
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
      valueA = $get(a, @key)
      valueA = valueA.valueOf() if valueA?
      valueB = $get(b, @key)
      valueB = valueB.valueOf() if valueB?
      multiple = if @descending then -1 else 1
      @compare.call(@, valueA, valueB) * multiple
    @_setObserver?.startObservingItems(newOrder...)
    @set('_storage', newOrder)

class Batman.SetIndex extends Batman.Object
  constructor: (@base, @key) ->
    super()
    @_storage = new Batman.SimpleHash
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
    results = @_resultSetForKey(key)
    results.remove item
    @_storage.unset(key) if results.isEmpty()
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
    super
    if resultSet.isEmpty()
      @_uniqueIndex.unset(key)
    else
      @_uniqueIndex.set(key, resultSet.toArray()[0])

# State Machines
# --------------

class Batman.StateMachine extends Batman.Object
  @InvalidTransitionError: (@message) ->
  @InvalidTransitionError:: = Error::

  @transitions: (table) ->
    @::transitionTable = $mixin {}, @::transitionTable, table
    for k, transitions of @::transitionTable
      do (k) =>
        @::[k] ||= (suggestedNextState) -> @do(k, suggestedNextState)
    @

  constructor: (startState) ->
    @nextEvents = []
    @set('_state', startState)

  @accessor 'state', -> @get('_state')
  isTransitioning: false
  transitionTable: {}

  onTransition: (from, into, callback) -> @on("#{from}->#{into}", callback)
  onEnter: (into, callback) -> @on("enter:#{into}", callback)
  onExit: (from, callback) -> @on("exit:#{from}", callback)

  do: (event, suggestedNextState) ->
    if @isTransitioning
      @nextEvents.push event
      return

    previousState = @get('state')
    nextState = @nextStateOnEvent(event)

    if !nextState
      return false

    if nextState.unshift # quick test for an array
      developer.assert ~nextState.indexOf(suggestedNextState), "Warning, invalid transition for the multiple destination event #{event}!"
      nextState = suggestedNextState

    @isTransitioning = true

    @fire "exit:#{previousState}"
    @fire "#{previousState}->#{nextState}"
    @set('_state', nextState)
    @fire "enter:#{nextState}"
    @isTransitioning = false

    if @nextEvents.length > 0
      @do @nextEvents.shift()
    true

  canDo: (event, fromState = @get('state')) -> !!@nextStateOnEvent(event, fromState)
  nextStateOnEvent: (event, fromState = @get('state')) -> @transitionTable[event]?[fromState]
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
    @_autosendTimeout = $setImmediate => @send()

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
  developer.do =>
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
            if not @isPrevented 'run'
              @fire 'loaded'

            @run() if @wantsToRun
      @

    @controller = (names...) ->
      names = names.map (n) -> n + '_controller'
      @require 'controllers', names...

    @model = ->
      @require 'models', arguments...

    @view = ->
      @require 'views', arguments...

  # Layout is the base view that other views can be yielded into. The
  # default behavior is that when `app.run()` is called, a new view will
  # be created for the layout using the `document` node as its content.
  # Use `MyApp.layout = null` to turn off the default behavior.
  @layout: undefined

  # Call `MyApp.run()` to start up an app. Batman level initializers will
  # be run to bootstrap the application.
  @event('ready').oneShot = true
  @event('run').oneShot = true
  @run: ->
    if Batman.currentApp
      return if Batman.currentApp is @
      Batman.currentApp.stop()

    return false if @hasRun

    if @isPrevented 'run'
      @wantsToRun = true
      return false
    else
      delete @wantsToRun

    Batman.currentApp = @

    if typeof @dispatcher is 'undefined'
      @dispatcher ||= new Batman.Dispatcher @

    @observe 'layout', (layout) =>
      layout?.on 'ready', => @fire 'ready'

    if typeof @layout is 'undefined'
      @set 'layout', new Batman.View
        contexts: [@]
        node: document
    else if typeof @layout is 'string'
      @set 'layout', new @[helpers.camelize(@layout) + 'View']

    if typeof @navigator is 'undefined' and @dispatcher.routeMap
      @on 'run', =>
        @navigator = Batman.navigator = Batman.Navigator.forApp(this)
        @navigator.start()

    @hasRun = yes
    @fire('run')
    @

  @event('ready').oneShot = true

  @event('stop').oneShot = true
  @stop: ->
    @navigator?.stop()
    Batman.navigator = null
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
        if typeof action is 'function'
          matches = yes
        else
          {controller, action} = action
          if controller is params.controller and action is (params.action || 'index')
            matches = yes

      continue if not matches
      $mixin paramsCopy = {}, params
      $unmixin paramsCopy, {controller:null, action:null, resource:null, url:null, signature:null, target:null}

      for key, value of params
        regex = new RegExp('[:|\*]' + key)
        continue if not regex.test url

        url = url.replace regex, value
        paramsCopy[key] = null
        delete paramsCopy[key]

      queryString = ''
      for key, value of paramsCopy
        queryString += if not queryString then '?' else '&'
        queryString += key + '=' + value

      return url + queryString

  pathFromParams: (params) ->
    if $typeOf(params) is 'String'
      Batman.Navigator.normalizePath(params)
    else
      @findUrl(params)

  dispatch: (params) ->
    url = @pathFromParams(params)
    route = @findRoute(url)
    if route
      route.dispatch(url)
    else if url isnt '/404'
      $redirect('/404')

    @app.set 'currentURL', url
    @app.set 'currentRoute', route
    @app.set 'currentParams', params
    url

class Batman.Navigator
  @defaultClass: ->
    if Batman.config.usePushState and Batman.PushStateNavigator.isSupported()
      Batman.PushStateNavigator
    else
      Batman.HashbangNavigator
  @forApp: (app) -> new (@defaultClass())(app)
  constructor: (@app) ->
  start: ->
    return if typeof window is 'undefined'
    return if @started
    @started = yes
    @startWatching()
    Batman.currentApp.prevent 'ready'
    $setImmediate =>
      @handleCurrentLocation()
      Batman.currentApp.allowAndFire 'ready'
  stop: ->
    @stopWatching()
    @started = no
  handleLocation: (location) ->
    path = @pathFromLocation(location)
    return if path is @cachedPath
    @dispatch(path)
  handleCurrentLocation: => @handleLocation(window.location)
  dispatch: (params) ->
    @cachedPath = @app.dispatcher.dispatch(params)
  push: (params) ->
    path = @dispatch(params)
    @pushState(null, '', path)
    path
  replace: (params) ->
    path = @dispatch(params)
    @replaceState(null, '', path)
    path
  redirect: @::push
  normalizePath: (segments...) ->
    segments = for seg, i in segments
      "#{seg}".replace(/^(?!\/)/, '/').replace(/\/+$/,'')
    segments.join('') or '/'
  @normalizePath: @::normalizePath

class Batman.PushStateNavigator extends Batman.Navigator
  @isSupported: -> window?.history?.pushState?
  startWatching: ->
    $addEventListener window, 'popstate', @handleCurrentLocation
  stopWatching: ->
    $removeEventListener window, 'popstate', @handleCurrentLocation
  pushState: (stateObject, title, path) ->
    window.history.pushState(stateObject, title, @linkTo(path))
  replaceState: (stateObject, title, path) ->
    window.history.replaceState(stateObject, title, @linkTo(path))
  linkTo: (url) ->
    @normalizePath(Batman.config.pathPrefix, url)
  pathFromLocation: (location) ->
    fullPath = "#{location.pathname or ''}#{location.search or ''}"
    prefixPattern = new RegExp("^#{@normalizePath(Batman.config.pathPrefix)}")
    @normalizePath(fullPath.replace(prefixPattern, ''))
  handleLocation: (location) ->
    path = @pathFromLocation(location)
    if path is '/' and (hashbangPath = Batman.HashbangNavigator::pathFromLocation(location)) isnt '/'
      @replace(hashbangPath)
    else
      super

class Batman.HashbangNavigator extends Batman.Navigator
  HASH_PREFIX: '#!'
  if window? and 'onhashchange' of window
    @::startWatching = ->
      $addEventListener window, 'hashchange', @handleCurrentLocation
    @::stopWatching = ->
      $removeEventListener window, 'hashchange', @handleCurrentLocation
  else
    @::startWatching = ->
      @interval = setInterval @handleCurrentLocation, 100
    @::stopWatching = ->
      @interval = clearInterval @interval
  pushState: (stateObject, title, path) ->
    window.location.hash = @linkTo(path)
  replaceState: (stateObject, title, path) ->
    loc = window.location
    loc.replace("#{loc.pathname}#{loc.search}#{@linkTo(path)}")
  linkTo: (url) -> @HASH_PREFIX + url
  pathFromLocation: (location) ->
    hash = location.hash
    if hash?.substr(0,2) is @HASH_PREFIX
      @normalizePath(hash.substr(2))
    else
      '/'
  handleLocation: (location) ->
    return super unless Batman.config.usePushState
    realPath = Batman.PushStateNavigator::pathFromLocation(location)
    if realPath is '/'
      super
    else
      location.replace(@normalizePath("#{Batman.config.pathPrefix}#{@linkTo(realPath)}"))


Batman.redirect = $redirect = (url) ->
  Batman.navigator?.redirect url

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
    resource = "#{options.parentResource}/:#{helpers.singularize(options.parentResource)}Id/#{resource}" if options.parentResource

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
        resources: (childResource, options={}, callback) =>
          (callback = options; options = {}) if typeof options is 'function'
          options.parentResource = resource
          @resources childResource, options, callback

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

  @accessor 'action', # FIXME: does this even need to be private?
    get: -> @_currentAction
    set: (key, value) -> @_currentAction = value

  # You shouldn't call this method directly. It will be called by the dispatcher when a route is called.
  # If you need to call a route manually, use `$redirect()`.
  dispatch: (action, params = {}) ->
    params.controller ||= @get 'controllerName'
    params.action ||= action
    params.target ||= @

    oldRedirect = Batman.navigator?.redirect
    Batman.navigator?.redirect = @redirect

    @_actedDuringAction = no
    @set 'action', action
    @set 'params', params

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

    Batman.navigator?.redirect = oldRedirect

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
      controllerName = $functionName(@constructor).replace('Controller', '')

      options.contexts ||= []
      options.contexts.push @
      options.source ||= helpers.underscore(controllerName) + '/' + @_currentAction
      options.view = new (Batman.currentApp?[helpers.camelize("#{controllerName}_#{@_currentAction}_view")] || Batman.View)(options)

    if view = options.view
      Batman.currentApp?.prevent 'ready'
      view.on 'ready', =>
        Batman.DOM.replace (options.into || 'main'), view.get('node')
        Batman.currentApp?.allowAndFire 'ready'
        view.ready?(@params)
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

  class Model.LifecycleStateMachine extends Batman.StateMachine
    @transitions
      load: {empty: 'loading', loaded: 'loading', loading: 'loading'}
      loaded: {loading: 'loaded'}
      error: {loading: 'error'}

  @classAccessor 'lifecycle', ->
    @_batman.check(@)
    @_batman.lifecycle ||= new Model.LifecycleStateMachine('empty')

  # ### Query methods
  @classAccessor 'all',
    get: ->
      @load() if @::hasStorage() and @get('lifecycle.state') not in ['loaded', 'loading']
      @get('loaded')

    set: (k, v) -> @set('loaded', v)

  @classAccessor 'loaded',
    get: -> @_loaded ||= new Batman.Set
    set: (k, v) -> @_loaded = v

  @classAccessor 'first', -> @get('all').toArray()[0]
  @classAccessor 'last', -> x = @get('all').toArray(); x[x.length - 1]

  @find: (id, callback) ->
    developer.assert callback, "Must call find with a callback!"
    record = new @()
    record.set 'id', id
    newRecord = @_mapIdentity(record)
    newRecord.load callback
    return newRecord

  # `load` fetches records from all sources possible
  @load: (options, callback) ->
    if $typeOf(options) is 'Function'
      callback = options
      options = {}

    developer.assert @::_batman.getAll('storage').length, "Can't load model #{$functionName(@)} without any storage adapters!"

    lifecycle = @get('lifecycle')
    if lifecycle.load()
      @::_doStorageOperation 'readAll', options, (err, records) =>
        if err?
          lifecycle.error()
          callback?(err, [])
        else
          mappedRecords = (@_mapIdentity(record) for record in records)
          lifecycle.loaded()
          callback?(err, mappedRecords)
    else
      callback(new Batman.StateMachine.InvalidTransitionError("Can't load while in state #{lifecycle.get('state')}"))

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

  # ### Associations API

  @belongsTo: (label, scope) -> new Batman.Association.belongsTo(@, label, scope)
  @hasOne: (label, scope) -> new Batman.Association.hasOne(@, label, scope)
  @hasMany: (label, scope) -> new Batman.Association.hasMany(@, label, scope)

  # ### Record API

  # Add a universally accessible accessor for retrieving the primrary key, regardless of which key its stored under.
  @accessor 'id',
    get: ->
      pk = @constructor.primaryKey
      if pk == 'id'
        @id
      else
        @get(pk)
    set: (k, v) ->
      # naively coerce string ids into integers
      if typeof v is "string" and !isNaN(intId = parseInt(v, 10))
        v = intId

      pk = @constructor.primaryKey
      if pk == 'id'
        @_markDirtyAttribute(k, @id)
        @id = v
      else
        @set(pk, v)

  # Add normal accessors for the dirty keys and errors attributes of a record, so these accesses don't fall to the
  # default accessor.
  @accessor 'dirtyKeys', 'errors', Batman.Property.defaultAccessor

  @accessor 'batmanState', -> @lifecycle.get('state')

  # Add a default accessor to make models store their attributes under a namespace by default.
  @accessor Model.defaultAccessor =
    get: (k) -> (@_batman.attributes ||= {})[k] || @[k]
    set: (key, value) ->
      oldValue = @get(key)
      result = (@_batman.attributes ||= {})[key] = value
      @_markDirtyAttribute(key, oldValue)
      result

    unset: (key) ->
      oldValue = (@_batman.attributes ||={})[key]
      delete @_batman.attributes[key]
      @_markDirtyAttribute(key, oldValue)
      oldValue

  # Each model instance (each record) can be in one of many states throughout its lifetime. Since various
  # operations on the model are asynchronous, these states are used to indicate exactly what point the
  # record is at in it's lifetime, which can often be during a save or load operation.

  # Define the various states for the model to use.
  class Model.InstanceLifecycleStateMachine extends Batman.StateMachine
    @transitions
      # Event          from : 'into'  state pairs
      load:           {empty: 'loading', dirty: 'loading', loaded: 'loading', loading: 'loading'}
      loaded:         {loading: 'loaded'}
      keySet:         {empty: 'dirty', loaded: 'dirty', dirty: 'dirty', validated: 'dirty'}
      clean:          {dirty: 'loaded', loaded: 'loaded'}
      validate:       {dirty: 'validating', loaded: 'validating', empty: 'validating', validated: 'validating'}
      validated:      {validating: 'validated'}
      invalidate:     {validating: ['dirty', 'loaded', 'empty']}
      doneValidation: {validated: ['dirty', 'loaded', 'empty']}
      save:           {validated: 'saving', empty: 'saving', loaded: 'saving', dirty: 'saving'}
      saved:          {saving: 'saved'}
      create:         {validated: 'creating', empty: 'creating', loaded: 'creating', dirty: 'creating'}
      created:        {creating: 'created'}
      doneStore:      {created: 'loaded', saved: 'loaded'}
      destroy:        {loaded: 'destroying', dirty: 'destroying'}
      destroyed:      {destroying: 'destroyed'}
      error:          {loading: 'error', validating: 'error', destroying: 'error', saving: 'error', creating: 'error'}

  # New records can be constructed by passing either an ID or a hash of attributes (potentially
  # containing an ID) to the Model constructor. By not passing an ID, the model is marked as new.
  constructor: (idOrAttributes = {}) ->
    developer.assert  @ instanceof Batman.Object, "constructors must be called with new"

    # We have to do this ahead of super, because mixins will call set which calls things on dirtyKeys.
    @dirtyKeys = new Batman.Hash
    @errors = new Batman.ErrorsSet
    @lifecycle = new Batman.Model.InstanceLifecycleStateMachine('empty')

    # Find the ID from either the first argument or the attributes.
    if $typeOf(idOrAttributes) is 'Object'
      super(idOrAttributes)
    else
      super()
      @set('id', idOrAttributes)

  updateAttributes: (attrs) ->
    @mixin(attrs)
    @

  toString: ->
    "#{$functionName(@constructor)}: #{@get('id')}"

  # `toJSON` uses the various encoders for each key to grab a storable representation of the record.
  toJSON: ->
    obj = {}

    # Encode associations into properties
    Batman.Association.Collection.encodeModelIntoObject(@, obj)

    # Encode each key into a new object
    encoders = @_batman.get('encoders')
    unless !encoders or encoders.isEmpty()
      encoders.forEach (key, encoder) =>
        val = @get key
        if typeof val isnt 'undefined'
          encodedVal = encoder(val)
          if typeof encodedVal isnt 'undefined'
            obj[key] = encodedVal
    obj

  # `fromJSON` uses the various decoders for each key to generate a record instance from the JSON
  # stored in whichever storage mechanism.
  fromJSON: (data) ->
    obj = {}

    # Decode associations into attributes
    Batman.Association.Collection.decodeObjectIntoModel(@, obj, data)

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
    developer.do ->
      if (!decoders) || decoders.reduce(((sum, x) -> sum + x), 0) <= 1
        developer.warn "Warning: Model #{@get('storageKey')} has suspiciously few decoders!"

    # Mixin the buffer object to use optimized and event-preventing sets used by `mixin`.
    @mixin obj

  _doStorageOperation: (operation, options, callback) ->
    developer.assert @hasStorage(), "Can't #{operation} model #{$functionName(@constructor)} without any storage adapters!"
    mechanisms = @_batman.get('storage')
    for mechanism in mechanisms
      mechanism[operation] @, options, callback
    true

  hasStorage: -> (@_batman.get('storage') || []).length > 0

  # `load` fetches the record from all sources possible
  load: (callback) =>
    if @lifecycle.get('state') in ['destroying', 'destroyed']
      callback?(new Error("Can't load a destroyed record!"))
      return

    if @lifecycle.load()
      @_doStorageOperation 'read', {}, (err, record) =>
        unless err
          @lifecycle.loaded()
          record = @constructor._mapIdentity(record)
        else
          @lifecycle.error()
        callback?(err, record)
    else
      callback?(new Batman.StateMachine.InvalidTransitionError("Can't load while in state #{@lifecycle.get('state')}"))

  # `save` persists a record to all the storage mechanisms added using `@persist`. `save` will only save
  # a model if it is valid.
  save: (callback) =>
    if @lifecycle.get('state') in ['destroying', 'destroyed']
      callback?(new Error("Can't save a destroyed record!"))
      return

    @validate (error, errors) =>
      if error || errors.length
        callback?(error || errors)
        return
      creating = @isNew()

      if @lifecycle.do(if creating then 'create' else 'save')

        if associations = Batman.Association.Collection.getModelAssociations(@)
          {belongsTo, hasOne, hasMany} = associations
          # Save belongsTo models immediately since we don't need this model's id
          belongsTo?.forEach (association) => association.apply(@)

        @_doStorageOperation (if creating then 'create' else 'update'), {}, (err, record) =>
          unless err
            @lifecycle.do(if creating then 'created' else 'saved')
            @dirtyKeys.clear()
            hasOne?.forEach (association) -> association.apply(err, record)
            hasMany?.forEach (association) -> association.apply(err, record)
            record = @constructor._mapIdentity(record)
          else
            @lifecycle.error()
          @lifecycle.doneStore()
          callback?(err, record)
      else
        callback?(new Batman.StateMachine.InvalidTransitionError("Can't save while in state #{@lifecycle.get('state')}"))

  # `destroy` destroys a record in all the stores.
  destroy: (callback) =>
    if @lifecycle.destroy()
      @_doStorageOperation 'destroy', {}, (err, record) =>
        unless err
          @constructor.get('all').remove(@)
          @lifecycle.destroyed()
        else
          @lifecycle.error()
        callback?(err)
    else
      callback?(new Batman.StateMachine.InvalidTransitionError("Can't destroy while in state #{@lifecycle.get('state')}"))

  # `validate` performs the record level validations determining the record's validity. These may be asynchronous,
  # in which case `validate` has no useful return value. Results from asynchronous validations can be received by
  # listening to the `afterValidation` lifecycle callback.
  validate: (callback) ->
    oldState = @lifecycle.get 'state'

    @errors.clear()
    if @lifecycle.validate()

      finish = () =>
        if @errors.get('length') == 0
          @lifecycle.validated()
          @lifecycle.doneValidation(oldState)
          callback?(undefined, @errors)
        else
          @lifecycle.invalidate(oldState)
          callback?(undefined, @errors)

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
    else
      callback?(new Batman.StateMachine.InvalidTransitionError("Can't validate while in state #{@lifecycle.get('state')}"))
    return

  isNew: -> typeof @get('id') is 'undefined'

  _markDirtyAttribute: (key, oldValue) ->
    unless @lifecycle.get('state') in ['loading', 'creating', 'saving', 'saved']
      if @lifecycle.keySet()
        @dirtyKeys.set(key, oldValue)
      else
        throw new Batman.StateMachine.InvalidTransitionError("Can't set while in state #{@lifecycle.get('state')}")

class Batman.Association
  constructor: (@model, @label, @options = {}) ->
    Batman.Association.Collection.add @

    # curry association info into the getAccessor, which has the model applied as the context
    self = @
    getAccessor = -> return self.getAccessor.call(@, self, model, label)

    model.accessor label,
      get: getAccessor
      set: Batman.Model.defaultAccessor.set
      unset: Batman.Model.defaultAccessor.unset

  getRelatedModel: ->
    scope = @options['namespace'] or Batman.currentApp
    modelName = @options['name'] or helpers.camelize(helpers.singularize(@label))
    scope?[modelName]

  decodeObjectIntoModel: (model, obj, data) ->
    if json = data[@label]
      if relatedModel = @getRelatedModel()
        record = new relatedModel(json)
        obj[@label] = relatedModel._mapIdentity(record)

  getAccessor: -> developer.error "You must override getAccessor in Batman.Association subclasses."
  encodeModelIntoObject: -> developer.error "You must override encodeModelIntoObject in Batman.Associatio subclasses."

Batman.Association.Collection = (->
  class BatmanAssociationCollection
    constructor: ->
      # Contains (association, label) pairs mapped by base model and association type
      # ie. @storage = {<Model.constructor>: {<Association.constructor>: {<Association>: <label>}}}
      @storage = new Batman.SimpleHash

    add: (association) ->
      unless baseModelHash = @storage.get(association.model)
        baseModelHash = new Batman.SimpleHash
        @storage.set association.model, baseModelHash

      unless associationTypeHash = baseModelHash.get(association.constructor)
        associationTypeHash = new Batman.SimpleHash
        baseModelHash.set association.constructor, associationTypeHash

      associationTypeHash.set association, association.label

    getModelAssociations: (model) ->
      if hash = @storage.get(model.constructor)
        belongsTo: hash.get(Batman.Association.belongsTo)
        hasOne: hash.get(Batman.Association.hasOne)
        hasMany: hash.get(Batman.Association.hasMany)

    encodeModelIntoObject: (model, obj) ->
      unless @_encodingRelation
        # Only encode this level of associations
        @_encodingRelation = true
        @forEach model, (association) -> association.encodeModelIntoObject(model, obj)
        @_encodingRelation = false

    decodeObjectIntoModel: (model, obj, data) ->
      unless @_decodingRelation
        @_decodingRelation = true
        @forEach model, (association) ->
          association.decodeObjectIntoModel(model, obj, data)
        @_decodingRelation = false

    forEach: (model, callback) ->
      @storage.forEach (modelClass, associationClassHash) ->
        # Consider associations for any parent models
        return unless model instanceof modelClass
        associationClassHash.forEach (associationClass, associationHash) ->
          associationHash?.forEach (association) ->
            callback association

  return new BatmanAssociationCollection
)()

class Batman.Association.belongsTo extends Batman.Association
  constructor: ->
    super
    @model.encode "#{@label}_id"

  getAccessor: (self, model, label) ->
    if relatedRecord = @_batman.attributes?[label]
      return relatedRecord

    # Make sure there is a relation
    return unless relatedID = @get("#{label}_id")

    # Make sure the related model has been loaded
    return unless relatedModel = self.getRelatedModel()

    loadedRecord = relatedModel.get('loaded').indexedBy('id').get(relatedID)
    unless loadedRecord.isEmpty()
      return loadedRecord.toArray()[0]
    else
      return relatedModel.find relatedID, (error, loadedRecord) ->
        throw error if error

  apply: (base) ->
    if model = base.get(@label)
      base.set "#{@label}_id", model.get('id')

  encodeModelIntoObject: (model, obj) ->
    return unless @options["saveInline"] is true
    if relation = model.get(@label)
      obj[@label] = relation.toJSON()

class Batman.Association.hasOne extends Batman.Association
  constructor: ->
    super
    @propertyName = $functionName(@model).toLowerCase()
    @foreignKey = "#{helpers.underscore($functionName(@model))}_id"

  getAccessor: (self, model, label) ->
    return if @amSetting

    # Check whether the relatedModel has already been set on this model
    existingInstance = Batman.Model.defaultAccessor.get.call(@, label)
    return existingInstance if existingInstance?

    # Make sure relatedModel has been loaded
    return unless relatedModel = self.getRelatedModel()

    # Make sure we have an id to match on
    return unless id = @get('id')

    # Check whether the relatedModel has already loaded the instance we want
    relatedRecords = relatedModel.get('loaded').indexedBy(self.foreignKey).get(id)
    unless relatedRecords.isEmpty()
      return relatedRecords.toArray()[0]
    else
      # Create a relatedModel instance to return immediately and populate when it loads
      loadedRecord = new relatedModel
      # FIXME shouldn't need to short-circuit the get/set accessor loop
      @amSetting = true
      @set label, loadedRecord
      @amSetting = false

      loadOptions = {}
      loadOptions[self.foreignKey] = id
      relatedModel.load loadOptions, (error, loadedRecords) =>
        throw error if error
        return if !loadedRecords or loadedRecords.length <= 0
        loadedRecord.fromJSON loadedRecords[0].toJSON()
      return loadedRecord

  apply: (baseSaveError, base) ->
    if relation = base._batman.attributes?[@label]
      relation.set @foreignKey, base.get('id')

  encodeModelIntoObject: (model, obj) ->
    return if @options["saveInline"] is false
    if relation = model.get(@label)
      relationJSON = relation.toJSON()
      relationJSON[@foreignKey] = model.get('id')
      obj[@label] = relationJSON

class Batman.Association.hasMany extends Batman.Association
  constructor: ->
    super
    @propertyName = $functionName(@model).toLowerCase()
    @foreignKey = "#{helpers.underscore($functionName(@model))}_id"

  getAccessor: (self, model, label) ->
    return if @amSetting
    return unless relatedModel = self.getRelatedModel()

    if recordInAttributes = @_batman.attributes?[label]
      return recordInAttributes

    return unless id = @get('id')
    relatedRecords = relatedModel.get('loaded').indexedBy(self.foreignKey).get(id)
    if relatedRecords.isEmpty()
      @amSetting = true
      @set label, relatedRecords
      @amSetting = false

      loadOptions = {}
      loadOptions[self.foreignKey] = id
      relatedModel.load loadOptions, (error, records) -> throw error if error
    relatedRecords

  apply: (baseSaveError, base) ->
    if relations = base._batman.attributes?[@label]
      relations.forEach (model) =>
        model.set @foreignKey, base.get('id')

  encodeModelIntoObject: (model, obj) ->
    return if @options["saveInline"] is false
    if relationSet = model.get(@label)
      jsonArray = []
      relationSet.forEach (relation) =>
        relationJSON = relation.toJSON()
        relationJSON[@foreignKey] = model.get('id')
        jsonArray.push relationJSON
      obj[@label] = jsonArray

  decodeObjectIntoModel: (model, obj, data) ->
    if jsonArray = data[@label]
      relations = new Batman.Set
      if relatedModel = @getRelatedModel()
        for jsonObject in jsonArray
          record = new relatedModel(jsonObject)
          record = relatedModel._mapIdentity(record)
          relations.add record
      obj[@label] = relations

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
  format: (key, messageKey, interpolations) -> t('errors.format', {attribute: key, message: t("errors.messages.#{messageKey}", interpolations)})

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
        errors.add key, @format(key, 'too_short', {count: options.minLength})
      if options.maxLength and value.length > options.maxLength
        errors.add key, @format(key, 'too_long', {count: options.maxLength})
      if options.length and value.length isnt options.length
        errors.add key, @format(key, 'wrong_length', {count: options.length})
      callback()

  class Batman.PresenceValidator extends Batman.Validator
    @options 'presence'
    validateEach: (errors, record, key, callback) ->
      value = record.get(key)
      if @options.presence and !value?
        errors.add key, @format(key, 'blank')
      callback()
]

$mixin Batman.translate.messages,
  errors:
    format: "%{attribute} %{message}"
    messages:
      too_short: "must be at least %{count} characters"
      too_long: "must be less than %{count} characters"
      wrong_length: "must be %{count} characters"
      blank: "can't be blank"

class Batman.StorageAdapter extends Batman.Object
  constructor: (model) ->
    super(model: model)

  isStorageAdapter: true
  modelKey: (record) ->
    model = record?.constructor || @model
    model.get('storageKey') || helpers.pluralize(helpers.underscore($functionName(model)))

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
    return

  storageRegExp: (record) -> new RegExp("^#{@modelKey(record)}(\\d+)$")

  idForRecord: (record) ->
    re = @storageRegExp(record)
    nextId = 1
    @_forAllRecords (k, v) ->
      if matches = re.exec(k)
        nextId = Math.max(nextId, parseInt(matches[1], 10) + 1)
    nextId

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
        @storage.setItem(@modelKey(record) + id, recordToSave)
      else
        err = new Error("Couldn't get record primary key.")
    callback(@_filterData('after', 'update', err, record, options)...)

  create: (record, options, callback) ->
    [err, recordToSave] = @_filterData('before', 'create', undefined, record, options)
    if !err
      id = record.get('id') || record.set('id', @idForRecord(record))
      if id?
        key = @modelKey(record) + id
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
        attrs = @storage.getItem(@modelKey(record) + id)
        if !attrs
          err = new Error("Couldn't find record!")
      else
        err = new Error("Couldn't get record primary key.")

    callback(@_filterData('after', 'read', err, record, attrs, options)...)

  readAll: (proto, options, callback) ->
    records = []
    [err, options] = @_filterData('before', 'readAll', undefined, options)
    if !err
      re = @storageRegExp(proto)
      @_forAllRecords (storageKey, data) ->
        if keyMatches = re.exec(storageKey)
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
        key = @modelKey(record) + id
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
  serializeAsForm: true

  constructor: ->
    super
    @defaultOptions = $mixin {}, @defaultOptions

  recordJsonNamespace: (record) ->
    helpers.singularize(@modelKey(record))
  collectionJsonNamespace: (proto) ->
    helpers.pluralize(@modelKey(proto))

  @::before 'create', 'update', $passError ([record, options]) ->
    json = record.toJSON()
    record = if namespace = @recordJsonNamespace(record)
      x = {}
      x[namespace] = json
      x
    else
      json
    record = JSON.stringify(record) unless @serializeAsForm
    [record, options]

  @::after 'create', 'read', 'readAll', 'update', 'destroy', ([error, record, data, options]) ->
    if !error
      if typeof data is 'string'
        try
          data = JSON.parse(data)
        catch e
          error = e
    [error, record, data, options]

  @::after 'create', 'read', 'update', $passError ([record, data, options]) ->
    namespace = @recordJsonNamespace(record)
    data = data[namespace] if namespace && data[namespace]?
    [record, data, options]

  @::after 'create', 'read', 'update', $passError ([record, data, options]) ->
    record.fromJSON(data)
    [record, data, options]

  optionsForRecord: (record, recordOptions, callback) ->
    if record.url
      url = if typeof record.url is 'function' then record.url(recordOptions) else record.url
    else
      url = if record.constructor.url
        if typeof record.constructor.url is 'function'
          record.constructor.url(recordOptions)
        else
          record.constructor.url
      else
        "/#{@modelKey(record)}"

      if recordOptions.idRequired
        id = record.get('id')
        if !id?
          callback.call(@, new Error("Couldn't get record primary key!"))
          return
        url = url + "/" + id

    unless url
      callback.call @, new Error("Couldn't get model url!")
    else
      callback.call @, undefined, $mixin({}, @defaultOptions, {url})

  optionsForCollection: (model, recordsOptions, callback) ->
    if model.url
      url = if typeof model.url is 'function' then model.url(recordsOptions) else model.url
    else
      url = "/#{@modelKey(model::)}"

    unless url
      callback.call @, new Error("Couldn't get collection url!")
    else
      callback.call @, undefined, $mixin {}, @defaultOptions, {url, data: $mixin({}, @defaultOptions.data, recordsOptions)}

  create: (record, recordOptions, callback) ->
    @optionsForRecord record, {idRequired: false}, (err, options) ->
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
    @optionsForRecord record, {idRequired: true}, (err, options) ->
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
    @optionsForRecord record, {idRequired: true}, (err, options) ->
      [err, record, recordOptions] = @_filterData('before', 'read', err, record, recordOptions)
      if err
        callback(err)
        return

      new Batman.Request $mixin options,
        data: recordOptions
        method: 'GET'
        success: (data) => callback(@_filterData('after', 'read', undefined, record, data, recordOptions)...)
        error:  (error) => callback(@_filterData('after', 'read', error, record, error.request.get('response'), recordOptions)...)

  readAll: (proto, recordsOptions, callback) ->
    @optionsForCollection proto.constructor, recordsOptions, (err, options) ->
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
        success: (data) => callback(@_filterData('after', 'readAll', undefined, data, proto, recordsOptions)...)
        error:  (error) => callback(@_filterData('after', 'readAll', error, error.request.get('response'), proto, recordsOptions)...)

  @::after 'readAll', $passError ([data, proto, options]) ->
    namespace = @collectionJsonNamespace(proto)
    recordData = if namespace && data[namespace]? then data[namespace] else data
    [recordData, data, proto, options]

  @::after 'readAll', $passError ([recordData, serverData, proto, options]) ->
    [@getRecordFromData(attributes) for attributes in recordData, serverData, proto, options]

  destroy: (record, recordOptions, callback) ->
    @optionsForRecord record, {idRequired: true}, (err, options) ->
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

class Batman.ViewSourceCache extends Batman.Object
  constructor: ->
    super
    @sources = {}
    @requests = {}

  propertyClass: Batman.Property

  @accessor
    get: (path) ->
      path = Batman.Navigator.normalizePath(path)
      return @sources[path] if @sources[path]?
      unless @requests[path]?
        @requests = new Batman.Request
          url: path + '.html'
          type: 'html'
          success: (response) => @set(path, response)
          error: (response) -> throw new Error("Could not load view from #{path}")
      return undefined
    set: (k,v) -> @sources[k] = v

  prefetch: (path) ->
    @get(path)
    true

# A `Batman.View` can function two ways: a mechanism to load and/or parse html files
# or a root of a subclass hierarchy to create rich UI classes, like in Cocoa.
class Batman.View extends Batman.Object
  constructor: ->
    @contexts = []
    super

    # Support both `options.context` and `options.contexts`
    if context = @get('context')
      @contexts.push context
      @unset('context')

    # Start the rendering by asking for the node
    if node = @get('node')
      @render node
    else
      @observe 'node', (node) => @render(node)

  @sourceCache: new Batman.ViewSourceCache()

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

  @accessor 'html',
    get: ->
      return @html if @html && @html.length > 0
      source = @get 'source'
      return if not source
      path = Batman.Navigator.normalizePath(@prefix, source)
      @html = @constructor.sourceCache.get(path)
    set: (_, html) -> @html = html

  @accessor 'node'
    get: ->
      unless @node
        html = @get('html')
        return unless html && html.length > 0
        @node = document.createElement 'div'
        $setInnerHTML(@node, html)
      return @node
    set: (_, node) -> @node = node


  render: (node) ->
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
          $appendChild @contentFor, node
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
  deferEvery: 50

  constructor: (@node, callback, contexts = []) ->
    super()
    @on('parsed', callback) if callback?
    @context = if contexts instanceof Batman.RenderContext then contexts else Batman.RenderContext.start(contexts...)
    @timeout = $setImmediate @start

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

  bindingRegexp = /^data\-(.*)/
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
    if @deferEvery && (new Date - @startTime) > @deferEvery
      @resumeNode = node
      @timeout = $setImmediate @resume
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
        else if result instanceof Batman.RenderContext
          oldContext = @context
          @context = result
          $onParseExit(node, => @context = oldContext)

    if (nextNode = @nextNode(node, skipChildren)) then @parseNode(nextNode) else @finish()

  nextNode: (node, skipChildren) ->
    if not skipChildren
      children = node.childNodes
      return children[0] if children?.length

    sibling = node.nextSibling # Grab the reference before onParseExit may remove the node
    $onParseExit(node).forEach (callback) -> callback()
    return if @node == node
    return sibling if sibling

    nextParent = node
    while nextParent = nextParent.parentNode
      $onParseExit(nextParent).forEach (callback) -> callback()
      return if @node == nextParent

      parentSibling = nextParent.nextSibling
      return parentSibling if parentSibling

    return

# The RenderContext class manages the stack of contexts accessible to a view during rendering.
class Batman.RenderContext
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
      @binding = new Batman.DOM.AbstractBinding(undefined, @keyPath, @renderContext)

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
      bindingClass = false
      switch node.nodeName.toLowerCase()
        when 'input'
          switch node.getAttribute('type')
            when 'checkbox'
              Batman.DOM.attrReaders.bind(node, 'checked', key, context, renderer, only)
              return true
            when 'radio'
              bindingClass = Batman.DOM.RadioBinding
            when 'file'
              bindingClass = Batman.DOM.FileBinding
        when 'select'
          bindingClass = Batman.DOM.SelectBinding
      bindingClass ||= Batman.DOM.Binding
      new bindingClass(arguments...)
      true

    context: (node, key, context, renderer) -> return context.descendWithKey(key)

    mixin: (node, key, context, renderer) ->
      new Batman.DOM.MixinBinding(node, key, context.descend(Batman.mixins), renderer)
      true

    showif: (node, key, context, parentRenderer, invert) ->
      new Batman.DOM.ShowHideBinding(node, key, context, parentRenderer, false, invert)
      true

    hideif: -> Batman.DOM.readers.showif(arguments..., yes)

    route: (node, key, context) ->
      # you must specify the / in front to route directly to hash route
      if key.substr(0, 1) is '/'
        url = key
      else
        isHash = key.indexOf('#') > 1
        [key, action] = if isHash then key.split('#') else key.split('/')
        [dispatcher, app] = context.findKey 'dispatcher'
        [model, container] = context.findKey key if not isHash

        dispatcher ||= Batman.currentApp.dispatcher

        if isHash
          url = dispatcher.findUrl controller: key, action: action
        else if model instanceof Batman.Model
          action ||= 'show'
          name = helpers.underscore(helpers.pluralize($functionName(model.constructor)))
          url = dispatcher.findUrl({resource: name, id: model.get('id'), action: action})
        else if model?.prototype # TODO write test for else case
          action ||= 'index'
          name = helpers.underscore(helpers.pluralize($functionName(model)))
          url = dispatcher.findUrl({resource: name, action: action})

      return unless url

      if node.nodeName.toUpperCase() is 'A'
        node.href = Batman.Navigator.defaultClass()::linkTo(url)

      Batman.DOM.events.click node, -> $redirect url
      true

    partial: (node, path, context, renderer) ->
      renderer.prevent('rendered')

      view = new Batman.View
        source: path
        contentFor: node
        contexts: context.chain()

      view.on 'ready', ->
        renderer.allowAndFire 'rendered'

      true

    defineview: (node, name, context, renderer) ->
      $onParseExit(node, -> $removeNode(node))
      Batman.View.sourceCache.set(Batman.Navigator.normalizePath(Batman.View::prefix, name), node.innerHTML)
      false

    yield: (node, key) ->
      $setImmediate -> Batman.DOM.yield key, node
      true
    contentfor: (node, key) ->
      $setImmediate -> Batman.DOM.contentFor key, node
      true
    replace: (node, key) ->
      $setImmediate -> Batman.DOM.replace key, node
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
      bindingClass = switch attr
        when 'checked', 'disabled', 'selected'
          Batman.DOM.CheckedBinding
        when 'value', 'href', 'src', 'size'
          Batman.DOM.NodeAttributeBinding
        when 'class'
          Batman.DOM.ClassBinding
        when 'style'
          Batman.DOM.StyleBinding
        else
          Batman.DOM.AttributeBinding
      new bindingClass(arguments...)
      true

    context: (node, contextName, key, context) -> return context.descendWithKey(key, contextName)

    event: (node, eventName, key, context) ->
      new Batman.DOM.EventBinding(arguments...)
      true

    addclass: (node, className, key, context, parentRenderer, invert) ->
      new Batman.DOM.AddClassBinding(node, className, key, context, parentRenderer, false, invert)
      true

    removeclass: (node, className, key, context, parentRenderer) -> Batman.DOM.attrReaders.addclass node, className, key, context, parentRenderer, yes

    foreach: (node, iteratorName, key, context, parentRenderer) ->
      new Batman.DOM.IteratorBinding(arguments...)
      false # Return false so the Renderer doesn't descend into this node's children.

    formfor: (node, localName, key, context) ->
      Batman.DOM.events.submit node, (node, e) -> $preventDefault e
      context.descendWithKey(key, localName)
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

    other: (node, eventName, callback) -> $addEventListener node, eventName, (args...) -> callback node, args...
  }

  # `yield` and `contentFor` are used to declare partial views and then pull them in elsewhere.
  # `replace` is used to replace yielded content.
  # This can be used for abstraction as well as repetition.
  yield: (name, node, _replaceContent = !Batman.data(node, 'yielded')) ->
    Batman.DOM._yields[name] = node

    # render any content for this yield
    if contents = Batman.DOM._yieldContents[name]
      if _replaceContent
        $setInnerHTML node, '', true
      for content in contents when !Batman.data(content, 'yielded')
        content = content.cloneNode(true) if $isChildOf(node, content)
        $appendChild node, content, true
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

  # Adds a binding or binding-like object to the `bindings` set in a node's
  # data, so that upon node removal we can unset the binding and any other objects
  # it retains.
  trackBinding: $trackBinding = (binding, node) ->
    if bindings = Batman.data node, 'bindings'
      bindings.add binding
    else
      Batman.data node, 'bindings', new Batman.SimpleSet(binding)

  # Removes listeners and bindings tied to `node`, allowing it to be cleared
  # or removed without leaking memory
  unbindNode: $unbindNode = (node) ->
    # break down all bindings
    if bindings = Batman.data node, 'bindings'
      bindings.forEach (binding) -> binding.destroy()

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
  setInnerHTML: $setInnerHTML = (node, html, args...) ->
    hide.apply(child, args) for child in node.childNodes when hide = Batman.data(child, 'hide')
    $unbindTree node, false
    node?.innerHTML = html

  # Memory-safe removal of a node from the DOM
  removeNode: $removeNode = (node) ->
    node?.parentNode?.removeChild node
    Batman.DOM.didRemoveNode(node)

  appendChild: $appendChild = (parent, child, args...) ->
    Batman.data(child, 'show')?.apply(child, args)
    parent.appendChild(child)

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

  didRemoveNode: (node) -> $unbindTree node

  onParseExit: $onParseExit = (node, callback) ->
    set = Batman.data(node, 'onParseExit') || Batman.data(node, 'onParseExit', new Batman.SimpleSet)
    set.add callback if callback?
    set
}

# Bindings are shortlived objects which manage the observation of any keypaths a `data` attribute depends on.
# Bindings parse any keypaths which are filtered and use an accessor to apply the filters, and thus enjoy
# the automatic trigger and dependency system that Batman.Objects use. Every, and I really mean every method
# which uses filters has to be defined in terms of a new binding. This is so that the proper order of
# objects is traversed and any observers are properly attached.
class Batman.DOM.AbstractBinding extends Batman.Object
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
    (
      [a-zA-Z][\w\.]* # Now that true and false can't be matched, match a dot delimited list of keys.
      [\?\!]?         # Allow ? and ! at the end of a keypath to support Ruby's methods
    )
    \s*               # Be insensitive to whitespace before the next comma or end of the filter arguments list.
    (?=$|,)             # Match either the next comma or the end of the filter arguments list.
    ///g

  # A less beastly pair of regular expressions for pulling out the [] syntax `get`s in a binding string, and
  # dotted names that follow them.
  get_dot_rx = /(?:\]\.)(.+?)(?=[\[\.]|\s*\||$)/
  get_rx = /(?!^\s*)\[(.*?)\]/g

  deProxy = (object) -> if object instanceof Batman.RenderContext.ContextProxy then object.get('proxiedObject') else object
  # The `filteredValue` which calculates the final result by reducing the initial value through all the filters.
  @accessor 'filteredValue', ->
    unfilteredValue = @get('unfilteredValue')

    if @filterFunctions.length > 0
      developer.currentFilterStack = @renderContext

      result = @filterFunctions.reduce((value, fn, i) =>
        # Get any argument keypaths from the context stored at parse time.
        args = @filterArguments[i].map (argument) ->
          if argument._keypath
            $get(argument.context, argument._keypath)
          else
            argument

        # Apply the filter.
        args.unshift value
        args = args.map deProxy
        fn.apply(@renderContext, args)
      , unfilteredValue)
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

  bindImmediately: true

  constructor: (@node, @keyPath, @renderContext, @renderer, @only = false) ->
    Batman.DOM.trackBinding(@, @node) if @node?

    # Pull out the `@key` and filter from the `@keyPath`.
    @parseFilter()

    # Observe the node and the data.
    @bind() if @bindImmediately

  bind: ->
    shouldSet = yes
    # And attach them.
    if @node? && @only in [false, 'nodeChange'] and Batman.DOM.nodeIsEditable(@node)
      Batman.DOM.events.change @node, =>
        shouldSet = no
        @nodeChange?(@node, @get('keyContext') || @value)
        shouldSet = yes

    # Observe the value of this binding's `filteredValue` and fire it immediately to update the node.
    if @only in [false, 'dataChange']
      @observeAndFire 'filteredValue', (value) =>
        if shouldSet
          @dataChange?(value, @node)

  destroy: ->
    @forget()
    @_batman.properties?.forEach (key, property) -> property.removeSourceHandlers()

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
    JSON.parse( "[" + segment.replace(keypath_rx, "$1{\"_keypath\": \"$2\"}") + "]" )

class Batman.DOM.AbstractAttributeBinding extends Batman.DOM.AbstractBinding
  constructor: (node, @attributeName, args...) -> super(node, args...)

class Batman.DOM.AbstractCollectionBinding extends Batman.DOM.AbstractAttributeBinding

  bindCollection: (newCollection) ->
    unless newCollection == @collection
      @unbindCollection()
      @collection = newCollection
      if @collection
        if @collection.isObservable && @collection.toArray
          @collection.observe 'toArray', @handleArrayChanged
        else if @collection.isEventEmitter
          @collection.on 'itemsWereAdded', @handleItemsWereAdded
          @collection.on 'itemsWereRemoved', @handleItemsWereRemoved
        else
          return false
        return true
    return false

  unbindCollection: ->
    if @collection
      if @collection.isObservable && @collection.toArray
        @collection.forget('toArray', @handleArrayChanged)
      else if @collection.isEventEmitter
        @collection.event('itemsWereAdded').removeHandler(@handleItemsWereAdded)
        @collection.event('itemsWereRemoved').removeHandler(@handleItemsWereRemoved)

  handleItemsWereAdded: ->
  handleItemsWereRemoved: ->
  handleArrayChanged: ->

  destroy: ->
    @unbindCollection()
    super

class Batman.DOM.Binding extends Batman.DOM.AbstractBinding
  nodeChange: (node, context) ->
    if @key && @filterFunctions.length == 0
      @get('keyContext').set @key, @node.value

  dataChange: (value, node) ->
    Batman.DOM.valueForNode @node, value

class Batman.DOM.AttributeBinding extends Batman.DOM.AbstractAttributeBinding
  dataChange: (value) -> @node.setAttribute(@attributeName, value)
  nodeChange: (node) -> @get('keyContext').set(@key, Batman.DOM.attrReaders._parseAttribute(node.getAttribute(@attributeName)))

class Batman.DOM.NodeAttributeBinding extends Batman.DOM.AbstractAttributeBinding
  dataChange: (value) -> @node[@attributeName] = value
  nodeChange: (node) -> @get('keyContext').set(@key, Batman.DOM.attrReaders._parseAttribute(node[@attributeName]))

class Batman.DOM.ShowHideBinding extends Batman.DOM.AbstractBinding
  constructor: (node, className, key, context, parentRenderer, @invert = false) ->
    @originalDisplay = node.style.display || ''
    super

  dataChange: (value) ->
    if !!value is !@invert
      Batman.data(@node, 'show')?.call(@node)
      @node.style.display = @originalDisplay
    else
      hide = Batman.data @node, 'hide'
      if typeof hide == 'function'
        hide.call @node
      else
        @node.style.display = 'none'

class Batman.DOM.CheckedBinding extends Batman.DOM.NodeAttributeBinding
  dataChange: (value) ->
    @node[@attributeName] = !!value
    # Update the parent's binding if necessary
    Batman.data(@node.parentNode, 'updateBinding')?()

  constructor: ->
    super
    # Attach this binding to the node under the attribute name so that parent
    # bindings can query this binding and modify its state. This is useful
    # for <options> within a select or radio buttons.
    Batman.data @node, @attributeName, @

class Batman.DOM.ClassBinding extends Batman.DOM.AbstractCollectionBinding
  dataChange: (value) ->
    if value?
      @unbindCollection()
      if typeof value is 'string'
        @node.className = value
      else
        @bindCollection(value)
        @updateFromCollection()

  updateFromCollection: ->
    if @collection
      array = if @collection.map
        @collection.map((x) -> x)
      else
        (k for own k,v of @collection)
      array = array.toArray() if array.toArray?
      @node.className = array.join ' '

  handleArrayChanged: => @updateFromCollection()
  handleItemsWereRemoved: => @updateFromCollection()
  handleItemsWereAdded: => @updateFromCollection()

class Batman.DOM.AddClassBinding extends Batman.DOM.AbstractAttributeBinding
  constructor: (node, className, keyPath, renderContext, renderer, only, @invert = false) ->
    @className = className.replace(/\|/g, ' ')
    super
    delete @attributeName

  dataChange: (value) ->
    currentName = @node.className
    includesClassName = currentName.indexOf(@className) isnt -1
    if !!value is !@invert
      @node.className = "#{currentName} #{@className}" if !includesClassName
    else
      @node.className = currentName.replace(@className, '') if includesClassName

class Batman.DOM.EventBinding extends Batman.DOM.AbstractAttributeBinding
  bindImmediately: false
  constructor: ->
    super
    confirmText = @node.getAttribute('data-confirm')
    callback = =>
      return if confirmText and not confirm(confirmText)
      @get('filteredValue')?.apply @get('callbackContext'), arguments

    if attacher = Batman.DOM.events[@attributeName]
      attacher @node, callback
    else
      Batman.DOM.events.other @node, @attributeName, callback

  @accessor 'callbackContext', ->
    contextKeySegments = @key.split('.')
    contextKeySegments.pop()
    context = if contextKeySegments.length > 0
      @get('keyContext').get(contextKeySegments.join('.'))
    else
      @get('keyContext')

class Batman.DOM.RadioBinding extends Batman.DOM.AbstractBinding
  dataChange: (value) ->
    # don't overwrite `checked` attributes in the HTML unless a bound
    # value is defined in the context. if no bound value is found, bind
    # to the key if the node is checked.
    if (boundValue = @get('filteredValue'))?
      @node.checked = boundValue == @node.value
    else if @node.checked
      @get('keyContext').set @key, @node.value

  nodeChange: (node) ->
    @get('keyContext').set(@key, Batman.DOM.attrReaders._parseAttribute(node.value))

class Batman.DOM.FileBinding extends Batman.DOM.AbstractBinding
  nodeChange: (node, subContext) ->
    segments = @key.split('.')
    if segments.length > 1
      keyContext = subContext.get(segments.slice(0, -1).join('.'))
    else
      keyContext = subContext

    if keyContext instanceof Batman.RenderContext.ContextProxy
      actualObject = keyContext.get('proxiedObject')
    else
      actualObject = keyContext

    if actualObject.hasStorage && actualObject.hasStorage()
      for adapter in actualObject._batman.get('storage') when adapter instanceof Batman.RestStorage
        adapter.defaultOptions.formData = true

    if node.hasAttribute('multiple')
      subContext.set @key, Array::slice.call(node.files)
    else
      subContext.set @key, node.files[0]

class Batman.DOM.MixinBinding extends Batman.DOM.AbstractBinding
  dataChange: (value) -> $mixin @node, value if value?

class Batman.DOM.SelectBinding extends Batman.DOM.AbstractBinding
  bindImmediately: false
  constructor: ->
    super

    # wait for the select to render before binding to it
    @renderer.on 'rendered', =>
      if @node?
        Batman.data @node, 'updateBinding', @updateSelectBinding
        @bind()

  dataChange: (newValue) =>
    # For multi-select boxes, the `value` property only holds the first
    # selection, so go through the child options and update as necessary.
    if newValue instanceof Array
      # Use a hash to map values to their nodes to avoid O(n^2).
      valueToChild = {}
      for child in @node.children
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
    # For a regular select box, update the value.
    else
      Batman.DOM.valueForNode(@node, newValue)

    # Finally, update the options' `selected` bindings
    @updateOptionBindings()

  nodeChange: =>
    @updateSelectBinding()
    @updateOptionBindings()

  updateSelectBinding: =>
    # Gather the selected options and update the binding
    selections = if @node.multiple then (c.value for c in @node.children when c.selected) else @node.value
    selections = selections[0] if selections.length == 1
    @get('keyContext').set @key, selections
    true

  updateOptionBindings: =>
    # Go through the option nodes and update their bindings using the
    # context and key attached to the node via Batman.data
    for child in @node.children
      if selectedBinding = Batman.data(child, 'selected')
        selectedBinding.nodeChange(selectedBinding.node)
    true

class Batman.DOM.StyleBinding extends Batman.DOM.AbstractCollectionBinding

  class @SingleStyleBinding extends Batman.DOM.AbstractAttributeBinding
    constructor: (args..., @parent) ->
      super(args...)
    dataChange: (value) -> @parent.setStyle(@attributeName, value)

  constructor: ->
    @oldStyles = {}
    super

  dataChange: (value) ->
    unless value
      @reapplyOldStyles()
      return

    @unbindCollection()

    if typeof value is 'string'
      @reapplyOldStyles()
      for style in value.split(';')
        # handle a case when css value contains colons itself (absolute URI)
        [cssName, cssValue] = style.split(/:(.+)/)
        @setStyle cssName, cssValue
      return

    if value instanceof Batman.Hash
      if @bindCollection(value)
        value.forEach (key, value) => @setStyle key, value
    else if value instanceof Object
      @reapplyOldStyles()
      for own key, keyValue of value
        # Check whether the value is an existing keypath, and if so bind this attribute to it
        [keypathValue, keypathContext] = @renderContext.findKey(keyValue)
        if keypathValue
          @bindSingleAttribute key, keyValue
          @setStyle key, keypathValue
        else
          @setStyle key, keyValue

  handleItemsWereAdded: (newKey) => @setStyle newKey, @collection.get(newKey)
  handleItemsWereRemoved: (oldKey) => @setStyle oldKey, ''

  bindSingleAttribute: (attr, keyPath) -> new @constructor.SingleStyleBinding(@node, attr, keyPath, @renderContext, @renderer, @only, @)

  setStyle: (key, value) =>
    return unless key
    key = helpers.camelize(key.trim(), true)
    @oldStyles[key] = @node.style[key]
    @node.style[key] = if value then value.trim() else ""

  reapplyOldStyles: ->
    @setStyle(cssName, cssValue) for own cssName, cssValue of @oldStyles

class Batman.DOM.IteratorBinding extends Batman.DOM.AbstractCollectionBinding
  deferEvery: 50
  currentActionNumber: 0
  queuedActionNumber: 0
  bindImmediately: false

  constructor: (sourceNode, args...) ->
    @parentNode = sourceNode.parentNode
    @initialSiblingNode = sourceNode.nextSibling
    super(@parentNode, args...)

    @iteratorName = @attributeName
    @parentRenderer = @renderer

    @nodeMap = new Batman.SimpleHash
    @actionMap = new Batman.SimpleHash
    @rendererMap = new Batman.SimpleHash
    @actions = []

    @prototypeNode = sourceNode.cloneNode(true)
    @prototypeNode.removeAttribute "data-foreach-#{@iteratorName}"

    # Remove the original node once the parent has moved past it.
    @parentRenderer.on 'parsed', =>
      # Move any Batman.data from the sourceNode to the prototype; we need to
      # retain the bindings, and we want to dispose of the node.
      @prototypeNode[Batman.expando] = sourceNode[Batman.expando]
      delete sourceNode[Batman.expando] if Batman.canDeleteExpando
      $removeNode sourceNode

    # Don't let the parent emit its rendered event until all the children have.
    # This `prevent`'s matching allow is run once the queue is empty in `processActionQueue`.
    @parentRenderer.prevent 'rendered'
    @fragment = document.createDocumentFragment()

    # Attach observers.
    @bind()

  destroy: ->
    $unbindNode(@prototypeNode)
    super
    @destroyed = true

  unbindCollection: ->
    if @collection
      @nodeMap.forEach (item, node) -> $removeNode node
      @nodeMap.clear()
      @rendererMap.forEach (item, renderer) -> renderer.stop()
      @rendererMap.clear()
      super

  dataChange: (newCollection) ->
    @bindCollection(newCollection)
    if @collection
      if @collection.toArray
        @handleArrayChanged()
      else if @collection.forEach
        @collection.forEach (item) => @addItem(item)
      else
        @addItem(key) for own key, value of @collection

    else
      developer.warn "Warning! data-foreach-#{@iteratorName} called with an undefined binding. Key was: #{@key}."

    @processActionQueue()

  handleItemsWereAdded: (items...) => @addItem(item, {fragment: true}) for item in items
  handleItemsWereRemoved: (items...) => @removeItem(item) for item in items

  handleArrayChanged: =>
    newItemsInOrder = @collection.toArray()
    trackingNodeMap = new Batman.SimpleHash
    for item in newItemsInOrder
      existingNode = @nodeMap.get(item)
      trackingNodeMap.set(item, true)
      if existingNode
        @insertItem(item, existingNode, {fragment: false, actionNumber: @queuedActionNumber++, sync: true})
      else
        @addItem(item, {fragment: false})

    @nodeMap.forEach (item, node) =>
      @removeItem(item) unless trackingNodeMap.hasKey(item)

  addItem: (item, options = {fragment: true}) ->
    @parentRenderer.prevent 'rendered'

    self = @
    options.actionNumber = @queuedActionNumber++
    childRenderer = new Batman.Renderer @_nodeForItem(item),
                                        (-> self.insertItem(item, @node, options)),
                                        @renderContext.descend(item, @iteratorName)

    @rendererMap.set(item, childRenderer)

    finish = =>
      return if @destroyed
      @parentRenderer.allowAndFire 'rendered'

    childRenderer.on 'rendered', finish
    childRenderer.on 'stopped', =>
      return if @destroyed
      @actions[options.actionNumber] = ->
      finish()
      @processActionQueue()
    item

  removeItem: (item) ->
    return if @destroyed
    @_removeOldAction(item)
    oldNode = @nodeMap.unset(item)
    if oldNode
      if hideFunction = Batman.data oldNode, 'hide'
        hideFunction.call(oldNode)
      else
        $removeNode(oldNode)

  insertItem: (item, node, options = {}) ->
    return if @destroyed
    futureActionNumber = @actionMap.get(item)
    if futureActionNumber? && futureActionNumber > options.actionNumber
      # This same action is scheduled for the future, do it then to preserve ordering instead of now.
      @actions[options.actionNumber] = ->
    else
      @_removeOldAction(item)
      @actionMap.set item, options.actionNumber
      if @nodeMap.get(item) != node
        # The render has rendered a node which is now out of date, do nothing.
        @actions[options.actionNumber] ||= ->
      else
        @rendererMap.unset item
        @actions[options.actionNumber] ||= ->
          show = Batman.data node, 'show'
          if typeof show is 'function'
            show.call node, before: @nextSibling()
          else
            if options.fragment
              @fragment.appendChild node
            else
              @parentNode.insertBefore node, @nextSibling()
          @lastNode = node

    @actions[options.actionNumber].item = item
    @processActionQueue()

  processActionQueue: ->
    return if @destroyed
    unless @actionQueueTimeout
      # Prevent the parent which will then be allowed when the timeout actually runs
      @actionQueueTimeout = $setImmediate =>
        return if @destroyed
        delete @actionQueueTimeout
        startTime = new Date

        while !!(f = @actions[@currentActionNumber])
          @actions[@currentActionNumber] = true
          f.call(@)
          @currentActionNumber++

          if @deferEvery && (new Date - startTime) > @deferEvery
            return @processActionQueue()

        if @fragment && @rendererMap.length is 0 && @fragment.hasChildNodes()
          @parentNode.insertBefore @fragment, @nextSibling()
          @fragment = document.createDocumentFragment()

        if @currentActionNumber == @queuedActionNumber
          @parentRenderer.allowAndFire 'rendered'

  nextSibling: ->
    if @lastNode
      @lastNode.nextSibling
    else
      if @initialSiblingNode && @initialSiblingNode.parentNode
        @initialSiblingNode
      else
        undefined

  _nodeForItem: (item) ->
    newNode = @prototypeNode.cloneNode(true)
    @nodeMap.set(item, newNode)
    newNode

  _removeOldAction: (item) ->
    oldActionNumber = @actionMap.get(item)
    if oldActionNumber? && oldActionNumber > @currentActionNumber
      @actionMap.unset(item)
      @actions[oldActionNumber] = ->

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

  interpolate: (string, interpolationKeypaths) ->
    return undefined unless string?
    values = {}
    for k, v of interpolationKeypaths
      values[k] = @findKey(v)[0]
      if !values[k]?
        Batman.developer.warn "Warning! Undefined interpolation key #{k} for interpolation", string
        values[k] = ''

    Batman.helpers.interpolate(string, values)

for k in ['capitalize', 'singularize', 'underscore', 'camelize']
  filters[k] = buntUndefined helpers[k]

developer.addFilters()

# Data
# ----
$mixin Batman,
  cache: {}
  uuid: 0
  expando: "batman" + Math.random().toString().replace(/\D/g, '')
  # Test to see if it's possible to delete an expando from an element
  # Fails in Internet Explorer
  canDeleteExpando: try
      div = document.createElement 'div'
      delete div.test
    catch e
      Batman.canDeleteExpando = false
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


# Mixins
# ------
mixins = Batman.mixins = new Batman.Object()

# Encoders
# ------
Batman.Encoders = {}

class Batman.Paginator extends Batman.Object
  class @Cache
    constructor: (@offset, @limit, @items) ->
      @length = items.length
      @reach = offset + limit
    containsItemsForOffsetAndLimit: (offset, limit) ->
      offset >= @offset and (offset + limit) <= @reach
    itemsForOffsetAndLimit: (offset, limit) ->
      return unless @containsItemsForOffsetAndLimit(offset, limit)
      begin = offset-@offset
      end = begin + limit
      @items.slice(begin, end)

  offset: 0
  limit: 10
  totalCount: 0

  offsetFromPageAndLimit: (page, limit) -> Math.round((+page - 1) * limit)
  pageFromOffsetAndLimit: (offset, limit) -> offset / limit + 1

  toArray: ->
    cache = @get('cache')
    offset = @get('offset')
    limit = @get('limit')
    items = cache?.itemsForOffsetAndLimit(offset, limit)
    @loadItemsForOffsetAndLimit(offset, limit) unless items
    items or []
  page: ->
    @pageFromOffsetAndLimit(@get('offset'), @get('limit'))
  pageCount: ->
    Math.ceil(@get('totalCount') / @get('limit'))

  previousPage: -> @set('page', @get('page')-1)
  nextPage: -> @set('page', @get('page')+1)

  loadItemsForOffsetAndLimit: (offset, limit) -> # override on subclasses or instances
  updateCache: (offset, limit, items) ->
    @set('cache', new Batman.Paginator.Cache(offset, limit, items))
  @accessor 'toArray', @::toArray
  @accessor 'offset', 'limit', 'totalCount'
    get: Batman.Property.defaultAccessor.get
    set: (key, value) -> Batman.Property.defaultAccessor.set.call(this, key, +value)
  @accessor 'page',
    get: @::page
    set: (_,value) ->
      value = +value
      @set('offset', @offsetFromPageAndLimit(value, @get('limit')))
      value
  @accessor 'pageCount', @::pageCount

class Batman.ModelPaginator extends Batman.Paginator
  cachePadding: 0
  paddedOffset: (offset) ->
    offset -= @cachePadding
    if offset < 0 then 0 else offset
  paddedLimit: (limit) ->
    limit + @cachePadding * 2

  loadItemsForOffsetAndLimit: (offset, limit) ->
    params = @paramsForOffsetAndLimit(offset, limit)
    params[k] = v for k,v of @params
    @model.load params, (err, records) =>
      unless err?
        @updateCache(@offsetFromParams(params), @limitFromParams(params), records)

  # override these to fetch records however you like:
  paramsForOffsetAndLimit: (offset, limit) ->
    offset: @paddedOffset(offset), limit: @paddedLimit(limit)
  offsetFromParams: (params) -> params.offset
  limitFromParams: (params) -> params.limit

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
  for k in ['mixin', 'unmixin', 'route', 'redirect', 'typeOf', 'redirect', 'setImmediate']
    onto["$#{k}"] = Batman[k]
  onto

Batman.exportGlobals = () ->
  Batman.exportHelpers(container)
