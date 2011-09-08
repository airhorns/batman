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

# Properties
# ----------
class Batman.Property
  @defaultAccessor:
    get: (key) -> @[key]
    set: (key, val) -> @[key] = val
    unset: (key) -> x = @[key]; delete @[key]; x
  @triggerTracker: null
  @forBaseAndKey: (base, key) ->
    if base._batman
      Batman.initializeObject base
      properties = base._batman.properties ||= new Batman.SimpleHash
      properties.get(key) or properties.set(key, new @(base, key))
    else
      new @(base, key)
  constructor: (@base, @key) ->
  isProperty: true
  accessor: ->
    accessors = @base._batman?.get('keyAccessors')
    if accessors && (val = accessors.get(@key))
      return val
    else
      @base._batman?.getFirst('defaultAccessor') or Batman.Property.defaultAccessor

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
      @dependents.forEach (prop) -> prop.cachedValue = prop.getValue()
  fireDependents: ->
    if @dependents
      @dependents.forEach (prop) ->
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
    if @base._batman
      @base._batman.ancestors().some((ancestor) => ancestor.property?(@key)?.observers?.length > 0)
    else
      false
  prevent: -> @_preventCount++
  allow: -> @_preventCount-- if @_preventCount > 0
  isAllowedToFire: -> @_preventCount <= 0
  fire: (args...) ->
    return unless @isAllowedToFire() and @hasObserversToFire()
    key = @key
    base = @base
    observerSets = [@observers]
    @observers.forEach (callback) ->
      callback?.apply base, args
    if @base._batman
      @base._batman.ancestors (ancestor) ->
        ancestor.property?(key).observers.forEach (callback) ->
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
      @triggers.forEach (property) =>
        unless Batman.Property.triggerTracker.has(property)
          property.dependents?.remove @
    @triggers = Batman.Property.triggerTracker
    @triggers.forEach (property) =>
      property.dependents ||= new Batman.SimpleSet
      property.dependents.add @
    delete Batman.Property.triggerTracker
  clearTriggers: ->
    @triggers.forEach (property) =>
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
  slice: (begin, end = @depth) ->
    base = @base
    for segment in @segments.slice(0, begin)
      return unless base? and base = Batman.Keypath.forBaseAndKey(base, segment).getValue()
    Batman.Keypath.forBaseAndKey base, @segments.slice(begin, end).join('.')
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
    Batman.initializeObject @
    Batman.Keypath.forBaseAndKey(@, key)
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

  # `allowed` returns a boolean describing whether or not the key is
  # currently allowed to fire its observers.
  allowed: (key) ->
    @property(key).isAllowedToFire()

# `fire` tells any observers attached to a key to fire, manually.
# `prevent` stops of a given binding from firing. `prevent` calls can be repeated such that
# the same number of calls to allow are needed before observers can be fired.
# `allow` unblocks a property for firing observers. Every call to prevent
# must have a matching call to allow later if observers are to be fired.
# `observe` takes a key and a callback. Whenever the value for that key changes, your
# callback will be called in the context of the original object.
for k in ['observe', 'prevent', 'allow', 'fire']
  do (k) ->
    Batman.Observable[k] = (key, args...) ->
      @property(key)[k](args...)
      @

$get = Batman.get = (object, key) ->
  if object.get
    object.get(key)
  else
    Batman.Observable.get.call(object, key)

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

      Batman.initializeObject @

      key ||= $findName(f, @)
      fired = @_batman.oneShotFired?[key]

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
          f._firedArgs = unless typeof value is 'undefined'
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
            firings = @_batman.oneShotFired ||= {}
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
      oneShotFired: @oneShotFired.bind @

  oneShotFired: (key) ->
    Batman.initializeObject @
    firings = @_batman.oneShotFired ||= {}
    !!firings[key]

# `$event` lets you create an ephemeral event without needing an EventEmitter.
# If you already have an EventEmitter object, you should call .event() on it.
Batman.event = $event = (callback) ->
  context = new Batman.Object
  context.event('_event', context, callback)

# `$eventOneShot` lets you create an ephemeral one-shot event without needing an EventEmitter.
# If you already have an EventEmitter object, you should call .eventOneShot() on it.
Batman.eventOneShot = $eventOneShot = (callback) ->
  context = new Batman.Object
  oneShot = context.eventOneShot('_event', context, callback)
  oneShot.oneShotFired = ->
    context.oneShotFired('_event')
  oneShot

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
  # Setting `isGlobal` to true will cause the class name to be defined on the
  # global object. For example, Batman.Model will be aliased to window.Model.
  # This should be used sparingly; it's mostly useful for debugging.
  @global: (isGlobal) ->
    return if isGlobal is false
    container[@name] = @

  # Apply mixins to this class.
  @classMixin: -> $mixin @, arguments...

  # Apply mixins to instances of this class.
  @mixin: -> @classMixin.apply @prototype, arguments
  mixin: @classMixin

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
  @classMixin Batman.Observable, Batman.EventEmitter
  @mixin Batman.Observable, Batman.EventEmitter

  # Observe this property on every instance of this class.
  @observeAll: -> @::observe.apply @prototype, arguments

  @singleton: (singletonMethodName="sharedInstance") ->
    @classAccessor singletonMethodName,
      get: -> @["_#{singletonMethodName}"] ||= new @

Batman.Object = BatmanObject

class Batman.Accessible extends Batman.Object
  constructor: -> @accessor.apply(@, arguments)

class Batman.SimpleHash
  constructor: ->
    @_storage = {}
    @length = 0
  hasKey: (key) ->
    matches = @_storage[key] ||= []
    for match in matches
      if @equality(match[0], key)
        pair = match
        return true
    return false
  get: (key) ->
    if matches = @_storage[key]
      for [obj,v] in matches
        return v if @equality(obj, key)
  set: (key, val) ->
    matches = @_storage[key] ||= []
    for match in matches
      if @equality(match[0], key)
        pair = match
        break
    unless pair
      pair = [key]
      matches.push(pair)
      @length++
    pair[1] = val
  unset: (key) ->
    if matches = @_storage[key]
      for [obj,v], index in matches
        if @equality(obj, key)
          matches.splice(index,1)
          @length--
          return
  getOrSet: Batman.Observable.getOrSet
  equality: (lhs, rhs) ->
    return true if lhs is rhs
    return true if lhs isnt lhs and rhs isnt rhs # when both are NaN
    return true if lhs?.isEqual?(rhs) and rhs?.isEqual?(lhs)
    return false
  forEach: (iterator) ->
    for key, values of @_storage
      iterator(obj, value) for [obj, value] in values
  keys: ->
    result = []
    @forEach (obj) -> result.push obj
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
    super

  @accessor
    get: Batman.SimpleHash::get
    set: Batman.SimpleHash::set
    unset: Batman.SimpleHash::unset

  @accessor 'isEmpty', -> @isEmpty()

  for k in ['hasKey', 'equality', 'forEach', 'keys', 'isEmpty', 'merge', 'clear']
    @::[k] = Batman.SimpleHash::[k]

class Batman.SimpleSet
  constructor: ->
    @_storage = new Batman.SimpleHash
    @_indexes = new Batman.SimpleHash
    @_sorts = new Batman.SimpleHash
    @length = 0
    @add.apply @, arguments if arguments.length > 0
  has: (item) ->
    @_storage.hasKey item
  add: (items...) ->
    addedItems = []
    for item in items
      unless @_storage.hasKey(item)
        @_storage.set item, true
        addedItems.push item
        @length++
    @itemsWereAdded(addedItems...) unless addedItems.length is 0
    addedItems
  remove: (items...) ->
    removedItems = []
    for item in items
      if @_storage.hasKey(item)
        @_storage.unset item
        removedItems.push item
        @length--
    @itemsWereRemoved(removedItems...) unless removedItems.length is 0
    removedItems
  forEach: (iterator) ->
    @_storage.forEach (key, value) -> iterator(key)
  isEmpty: -> @length is 0
  clear: ->
    items = @toArray()
    @_storage = new Batman.SimpleHash
    @length = 0
    @itemsWereRemoved(items...)
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
  itemsWereAdded: ->
  itemsWereRemoved: ->

class Batman.Set extends Batman.Object
  constructor: ->
    Batman.SimpleSet.apply @, arguments
  itemsWereAdded: @event ->
  itemsWereRemoved: @event ->

  for k in ['has', 'forEach', 'isEmpty', 'toArray', 'indexedBy', 'sortedBy']
    @::[k] = Batman.SimpleSet::[k]

  for k in ['add', 'remove', 'clear', 'merge']
    do (k) =>
      @::[k] = ->
        oldLength = @length
        results = Batman.SimpleSet::[k].apply(@, arguments)
        @property('length').fireDependents()
        results

  @accessor 'indexedBy', -> new Batman.Accessible (key) => @indexedBy(key)
  @accessor 'sortedBy', -> new Batman.Accessible (key) => @sortedBy(key)
  @accessor 'isEmpty', -> @isEmpty()
  @accessor 'length', -> @length

class Batman.SetObserver extends Batman.Object
  constructor: (@base) ->
    @_itemObservers = new Batman.Hash
    @_setObservers = new Batman.Hash
    @_setObservers.set("itemsWereAdded", @itemsWereAdded.bind(@))
    @_setObservers.set("itemsWereRemoved", @itemsWereRemoved.bind(@))
    @observe 'itemsWereAdded', @startObservingItems.bind(@)
    @observe 'itemsWereRemoved', @stopObservingItems.bind(@)

  itemsWereAdded: @event ->
  itemsWereRemoved: @event ->

  observedItemKeys: []
  observerForItemAndKey: (item, key) ->

  _getOrSetObserverForItemAndKey: (item, key) ->
    @_itemObservers.getOrSet item, =>
      observersByKey = new Batman.Hash
      observersByKey.getOrSet key, =>
        @observerForItemAndKey(item, key)
  startObserving: ->
    @_manageItemObservers("observe")
    @_manageSetObservers("observe")
  stopObserving: ->
    @_manageItemObservers("forget")
    @_manageSetObservers("forget")
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
      @base[method](key, observer)

class Batman.SetSort extends Batman.Object
  constructor: (@base, @key) ->
    if @base.isObservable
      @_setObserver = new Batman.SetObserver(@base)
      @_setObserver.observedItemKeys = [@key]
      boundReIndex = @_reIndex.bind(@)
      @_setObserver.observerForItemAndKey = -> boundReIndex
      @_setObserver.observe 'itemsWereAdded', boundReIndex
      @_setObserver.observe 'itemsWereRemoved', boundReIndex
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
    if @base.isObservable
      @_setObserver = new Batman.SetObserver(@base)
      @_setObserver.observedItemKeys = [@key]
      @_setObserver.observerForItemAndKey = @observerForItemAndKey.bind(@)
      @_setObserver.observe 'itemsWereAdded', (items...) =>
        @_addItem(item) for item in items
      @_setObserver.observe 'itemsWereRemoved', (items...) =>
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
      @setWasSorted(@)
  setWasSorted: @event ->
    return false if @length is 0
  add: ->
    results = super
    @_reIndex()
    results
  remove: ->
    results = super
    @_reIndex()
    results
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
      @setWasSorted(@) if @activeIndex is index
    else
      @_reIndex(index) for index of @_sortIndexes
      @setWasSorted(@)
    @

# State Machines
# --------------

Batman.StateMachine = {
  initialize: ->
    Batman.initializeObject @
    if not @_batman.states
      @_batman.states = new Batman.SimpleHash
      @accessor 'state',
        get: -> @state()
        set: (key, value) -> _stateMachine_setState.call(@, value)

  state: (name, callback) ->
    Batman.StateMachine.initialize.call @

    if not name
      return @_batman.getFirst 'state'

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

    event = transitions.get(name) || transitions.set(name, $event ->)
    event(callback) if callback
    event
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
    name = "#{oldState}->#{newState}"
    for event in @_batman.getAll((ancestor) -> ancestor._batman?.get('states')?.get(name))
      if event
        event newState, oldState

  if newState
    @fire newState, newState, oldState

  @_batman.isTransitioning = no
  @[@_batman.nextState.shift()]() if @_batman.nextState?.length

  newState

# App, Requests, and Routing
# --------------------------

# `Batman.Request` is a normalizer for XHR requests in the Batman world.
class Batman.Request extends Batman.Object
  url: ''
  data: ''
  method: 'get'
  response: null
  contentType: 'application/json'

  # After the URL gets set, we'll try to automatically send
  # your request after a short period. If this behavior is
  # not desired, use @cancel() after setting the URL.
  @observeAll 'url', ->
    @_autosendTimeout = setTimeout (=> @send()), 0

  loading: @event ->
  loaded: @event ->

  success: @event ->
  error: @event ->

  # `send` is implmented in the platform layer files. One of those must be required for
  # `Batman.Request` to be useful.
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
  @run: @eventOneShot ->
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

    if typeof @historyManager is 'undefined' and @dispatcher.routeMap
      @historyManager = Batman.historyManager = new Batman.HashHistory @
      @historyManager.start()

    @hasRun = yes
    @

  @stop: @eventOneShot ->
    @historyManager?.stop()
    Batman.historyManager = null
    @hasRun = no
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
    name = helpers.underscore(controller.name.replace('Controller', ''))
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
      window.addEventListener 'hashchange', @parseHash, false
    else
      @interval = setInterval @parseHash, 100

    setTimeout @parseHash, 0

  stop: =>
    if @interval
      @interval = clearInterval @interval
    else
      window.removeEventListener 'hashchange', @parseHash, false

    @started = no

  urlFor: (url) ->
    @HASH_PREFIX + url

  parseHash: =>
    hash = window.location.hash.replace @HASH_PREFIX, ''
    return if hash is @cachedHash

    @dispatch (@cachedHash = hash)

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

  resources: (resource, options, callback) ->
    (callback = options; options = null) if typeof options is 'function'
    resource = helpers.pluralize(resource)
    controller = options?.controller || resource

    @route(resource, "#{controller}#index", resource:controller, action:'index')
    @route("#{resource}/:id", "#{controller}#show", resource:controller, action:'show')
    @route("#{resource}/:id/edit", "#{controller}#edit", resource:controller, action:'edit')
    @route("#{resource}/:id/destroy", "#{controller}#destroy", resource:controller, action:'destroy')

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
    get: -> @_controllerName ||= helpers.underscore(@constructor.name.replace('Controller', ''))

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
      options.source ||= helpers.underscore(@constructor.name.replace('Controller', '')) + '/' + @_currentAction + '.html'
      options.view = new Batman.View(options)

    if view = options.view
      view.contexts.push @
      view.ready ->
        Batman.DOM.contentFor('main', view.get('node'))

# Models
# ------

class Batman.Model extends Batman.Object
  @create: (callback) ->
    obj = new @ arguments...
    obj.save(callback)
    obj

  # ## Model API
  # Override this property if your model is indexed by a key other than `id`
  @primaryKey: 'id'

  # Pick one or many mechanisms with which this model should be persisted. The mechanisms
  # can be already instantiated or just the class defining them.
  @persist: (mechanisms...) ->
    Batman.initializeObject @prototype
    storage = @::_batman.storage ||= []
    for mechanism in mechanisms
      storage.push if mechanism.isStorageAdapter then mechanism else new mechanism(@)
    @

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

    for key in keys
      @::_batman.encoders.set key, (encoder || @defaultEncoder.encode)
      @::_batman.decoders.set key, (decoder || @defaultEncoder.decode)

  # Set up the unit functions as the default for both
  @defaultEncoder:
    encode: (x) -> x
    decode: (x) -> x

  # Attach encoders and decoders for the primary key, and update them if the primary key changes.
  @observe 'primaryKey', yes, (newPrimaryKey) -> @encode newPrimaryKey, @defaultEncoder

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
      unless @all
        @all = new Batman.SortableSet
        @all.sortBy "id asc"

      if @all.isEmpty()
        @load() unless @::_batman.getAll('storage').length

      @all

    set: (k,v)-> @all = v

  @classAccessor 'first', -> @get('all').toArray()[0]
  @classAccessor 'last', -> x = @get('all').toArray(); x[x.length - 1]

  @find: (id, callback) ->
    throw "missing callback" unless callback
    record = new @(id)
    newRecord = @_mapIdentities([record])[0]
    newRecord.load callback
    return

  # `load` fetches records from all sources possible
  @load: (options, callback) ->
    if $typeOf(options) is 'Function'
      callback = options
      options = {}

    throw new Error("Can't load model #{@name} without any storage adapters!") unless @::_batman.getAll('storage').length

    do @loading
    @::_doStorageOperation 'readAll', options, (err, records) =>
      if err?
        callback?(err, [])
      else
        records = @_mapIdentities(records)
        do @loaded
        callback?(err, records)

  @_mapIdentities: (records) ->
    all = @get('all').toArray()
    newRecords = []
    returnRecords = []
    for record in records
      continue if typeof record is 'undefined'
      if typeof (id = record.get('id')) == 'undefined' || id == ''
        returnRecords.push record
      else
        existingRecord = false
        for potential in all
          if record.get('id') == potential.get('id')
            existingRecord = potential
            break
        if existingRecord
          returnRecords.push existingRecord
        else
          newRecords.push record
          returnRecords.push record
    @get('all').add(newRecords...) if newRecords.length > 0
    returnRecords

  # ### Record API

  @accessor 'id',
    get: ->
      pk = @constructor.get('primaryKey')
      if pk == 'id'
        @id
      else
        @get(pk)
    set: (k, v) ->
      pk = @constructor.get('primaryKey')
      if pk == 'id'
        @id = v
      else
        @set(pk, v)

  # New records can be constructed by passing either an ID or a hash of attributes (potentially
  # containing an ID) to the Model constructor. By not passing an ID, the model is marked as new.
  constructor: (idOrAttributes = {}) ->
    throw "constructors must be called with new" unless @ instanceof Batman.Object
    # We have to do this ahead of super, because mixins will call set which calls things on dirtyKeys.
    @dirtyKeys = new Batman.Hash
    @errors = new Batman.ErrorsHash

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

  toString: ->
    "#{@constructor.name}: #{@get('id')}"

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
        obj[key] = decoder(data[key])

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
    mechanisms = @_batman.get('storage') || []
    throw new Error("Can't #{operation} model #{@constructor.name} without any storage adapters!") unless mechanisms.length > 0
    for mechanism in mechanisms
      mechanism[operation] @, options, callback
    true

  _hasStorage: -> @_batman.getAll('storage').length > 0

  # `load` fetches the record from all sources possible
  load: (callback) =>
    if @get('state') in ['destroying', 'destroyed']
      callback?(new Error("Can't load a destroyed record!"))
      return

    do @loading
    @_doStorageOperation 'read', {}, (err, record) =>
      do @loaded unless err
      record = @constructor._mapIdentities([record])[0]
      callback?(err, record)

  # `save` persists a record to all the storage mechanisms added using `@persist`. `save` will only save
  # a model if it is valid.
  save: (callback) =>
    if @get('state') in ['destroying', 'destroyed']
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
        record = @constructor._mapIdentities([record])[0]
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

# `ErrorHash` is a simple subclass of `Hash` which makes it a bit easier to
# manage the errors on a model.
class Batman.ErrorsHash extends Batman.Hash
  constructor: -> super(_sets: {})

  # Define a default accessor to instantiate a set for any requested key.
  @accessor
    get: (key) ->
      unless @_sets[key]
        @_sets[key] = new Batman.Set
        @length++
      @_sets[key]
    set: Batman.Property.defaultAccessor.set

  # Define a shorthand method for adding errors to a key.
  add: (key, error) -> @get(key).add(error)
  clear: ->
    @_sets = {}
    super

class Batman.Validator extends Batman.Object
  constructor: (@options, mixins...) ->
    super mixins...

  validate: (record) ->
    throw "You must override validate in Batman.Validator subclasses."

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

class Batman.StorageAdapter
  constructor: (@model) ->
    @modelKey = helpers.pluralize(helpers.underscore(@model.name))
  isStorageAdapter: true
  getRecordsFromData: (datas) ->
    datas = @transformOutgoingCollectionData(datas) if @transformOutgoingCollectionData?
    for data in datas
       @getRecordFromData(data)
  getRecordFromData: (data) ->
    data = @transformIncomingRecordData(data) if @transformIncomingRecordData?
    record = new @model()
    record.fromJSON(data)
    record

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

  _forAllRecords: (f) ->
    for i in [0...@storage.length]
      k = @storage.key(i)
      f.call(@, k, @storage.getItem(k))

  getRecordFromData: (data) ->
    record = super
    @nextId = Math.max(@nextId, parseInt(record.get('id'), 10) + 1)
    record

  update: (record, options, callback) ->
    id = record.get('id')
    if id?
      @storage.setItem(@modelKey + id, JSON.stringify(record))
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  create: (record, options, callback) ->
    id = record.get('id') || record.set('id', @nextId++)
    if id?
      key = @modelKey + id
      if @storage.getItem(key)
        callback(new Error("Can't create because the record already exists!"))
      else
        @storage.setItem(key, JSON.stringify(record))
        callback(undefined, record)
    else
      callback(new Error("Couldn't set record primary key on create!"))

  read: (record, options, callback) ->
    id = record.get('id')
    if id?
      attrs = JSON.parse(@storage.getItem(@modelKey + id))
      if attrs
        record.fromJSON(attrs)
        callback(undefined, record)
      else
        callback(new Error("Couldn't find record!"))
    else
      callback(new Error("Couldn't get record primary key."))

  readAll: (_, options, callback) ->
    records = []
    @_forAllRecords (storageKey, data) ->
      if keyMatches = @key_re.exec(storageKey)
        match = true
        data = JSON.parse(data)
        data[@model.primaryKey] ||= parseInt(keyMatches[1], 10)
        for k, v of options
          if data[k] != v
            match = false
            break
        records.push data if match

    callback(undefined, @getRecordsFromData(records))

  destroy: (record, options, callback) ->
    id = record.get('id')
    if id?
      key = @modelKey + id
      if @storage.getItem key
        @storage.removeItem key
        callback(undefined, record)
      else
        callback(new Error("Can't delete nonexistant record!"), record)
    else
      callback(new Error("Can't delete record without an primary key!"), record)

class Batman.RestStorage extends Batman.StorageAdapter
  defaultOptions:
    type: 'json'
  recordJsonNamespace: false
  collectionJsonNamespace: false
  constructor: ->
    super
    @recordJsonNamespace = helpers.singularize(@modelKey)
    @collectionJsonNamespace = helpers.pluralize(@modelKey)
    @model.encode('id')
  transformIncomingRecordData: (data) ->
    return data[@recordJsonNamespace] if data[@recordJsonNamespace]
    data
  transformOutgoingRecordData: (record) ->
    if @recordJsonNamespace
      x = {}
      x[@recordJsonNamespace] = record.toJSON()
      return x
    else
      record.toJSON()
  transformOutgoingCollectionData: (data) ->
    return data[@collectionJsonNamespace] if data[@collectionJsonNamespace]
    data
  optionsForRecord: (record, idRequired, callback) ->
    if record.url
      url = if typeof record.url is 'function' then record.url() else record.url
    else
      url = "/#{@modelKey}"
      if idRequired || !record.isNew()
        id = record.get('id')
        if !id?
          callback(new Error("Couldn't get record primary key!"))
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
      if err
        callback(err)
        return
      new Batman.Request $mixin options,
        data: @transformOutgoingRecordData(record)
        method: 'POST'
        success: (data) =>
          record.fromJSON(@transformIncomingRecordData(data))
          callback(undefined, record)
        error: (err) -> callback(err)

  update: (record, recordOptions, callback) ->
    @optionsForRecord record, true, (err, options) ->
      if err
        callback(err)
        return

      new Batman.Request $mixin options,
        data: @transformOutgoingRecordData(record)
        method: 'PUT'
        success: (data) =>
          record.fromJSON(@transformIncomingRecordData(data))
          callback(undefined, record)
        error: (err) -> callback(err)

  read: (record, recordOptions, callback) ->
    @optionsForRecord record, true, (err, options) ->
      if err
        callback(err)
        return

      new Batman.Request $mixin options,
        method: 'GET'
        success: (data) =>
          record.fromJSON(@transformIncomingRecordData(data))
          callback(undefined, record)
        error: (err) -> callback(err)

  readAll: (_, recordsOptions, callback) ->
    @optionsForCollection recordsOptions, (err, options) ->
      if err
        callback(err)
        return
      new Batman.Request $mixin options,
        method: 'GET'
        success: (data) => callback(undefined, @getRecordsFromData(data))
        error: (err) -> callback(err)

  destroy: (record, recordOptions, callback) ->
    @optionsForRecord record, true, (err, options) ->
      if err
        callback(err)
        return
      new Batman.Request $mixin options,
        method: 'DELETE'
        success: -> callback(undefined, record)
        error: (err) -> callback(err)

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

  viewSources = {}

  # Set the source attribute to an html file to have that file loaded.
  source: ''

  # Set the html to a string of html to have that html parsed.
  html: ''

  # Set an existing DOM node to parse immediately.
  node: null

  contentFor: null

  # Fires once a node is parsed.
  ready: @eventOneShot ->

  # Where to look for views on the server
  prefix: 'views'

  # Whenever the source changes we load it up asynchronously
  @observeAll 'source', ->
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

  @observeAll 'html', (html) ->
    node = @node || document.createElement 'div'
    node.innerHTML = html

    @set('node', node) if @node isnt node

  @observeAll 'node', (node) ->
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
      , @contexts)

      @_renderer.rendered =>
        @ready node


# DOM Helpers
# -----------

# `Batman.Renderer` will take a node and parse all recognized data attributes out of it and its children.
# It is a continuation style parser, designed not to block for longer than 50ms at a time if the document
# fragment is particularly long.
class Batman.Renderer extends Batman.Object

  constructor: (@node, @callback, contexts = []) ->
    super
    @context = if contexts instanceof RenderContext then contexts else new RenderContext(contexts...)
    setTimeout @start, 0

  start: =>
    @startTime = new Date
    @parseNode @node

  resume: =>
    @startTime = new Date
    @parseNode @resumeNode

  finish: ->
    @startTime = null
    @fire 'parsed'
    @callback?()
    @fire 'rendered'

  forgetAll: ->

  parsed: @eventOneShot ->
  rendered: @eventOneShot ->

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
      setTimeout @resume, 0
      return

    if node.getAttribute
      bindings = for attr in node.attributes
        name = attr.nodeName.match(bindingRegexp)?[1]
        continue if not name
        if ~(varIndex = name.indexOf('-'))
          [name.substr(0, varIndex), name.substr(varIndex + 1), attr.value]
        else
          [name, attr.value]

      for readerArgs in bindings.sort(sortBindings)
        key = readerArgs[1]
        throw "property is a reserved keyword" if key == 'property'
        result = if readerArgs.length == 2
          Batman.DOM.readers[readerArgs[0]]?(node, key, @context, @)
        else
          Batman.DOM.attrReaders[readerArgs[0]]?(node, key, readerArgs[2], @context, @)

        if result is false
          skipChildren = true
          break

    if (nextNode = @nextNode(node, skipChildren)) then @parseNode(nextNode) else @finish()

  nextNode: (node, skipChildren) ->
    if not skipChildren
      children = node.childNodes
      return children[0] if children?.length

    node.onParseExit?()
    return if @node.isSameNode node

    sibling = node.nextSibling
    return sibling if sibling

    nextParent = node
    while nextParent = nextParent.parentNode
      nextParent.onParseExit?()
      return if @node.isSameNode(nextParent)

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
    (?:^|,)           # Match either the start of an arguments list or the start of a space inbetween commas.
    \s*               # Be insensitive to whitespace between the comma and the actual arguments.
    (?!               # Use a lookahead to ensure we aren't matching true or false:
      (?:true|false)  # Match either true or false ...
      \s*             # and make sure that there's nothing else that comes after the true or false ...
      (?:$|,)         # before the end of this argument in the list.
    )
    ([a-zA-Z][\w\.]*) # Now that true and false can't be matched, match a dot delimited list of keys.
    \s*               # Be insensitive to whitespace before the next comma or end of the filter arguments list.
    (?:$|,)           # Match either the next comma or the end of the filter arguments list.
    ///

  # A less beastly pair of regular expressions for pulling out the [] syntax `get`s in a binding string, and
  # dotted names that follow them.
  get_dot_rx = /(?:\]\.)(.+?)(?=[\[\.]|\s*\||$)/
  get_rx = /(?!^\s*)\[(.*?)\]/g

  # The `filteredValue` which calculates the final result by reducing the initial value through all the filters.
  @accessor 'filteredValue', ->
    value = @get('unfilteredValue')
    if @filterFunctions.length > 0
      @filterFunctions.reduce((value, fn, i) =>
        # Get any argument keypaths from the context stored at parse time.
        args = @filterArguments[i].map (argument) ->
          if argument._keypath
            argument.context.get(argument._keypath)
          else
            argument
        # Apply the filter.
        fn(value, args...)
      , value)
    else
      value

  # The `unfilteredValue` is whats evaluated each time any dependents change.
  @accessor 'unfilteredValue', ->
    # If we're working with an `@key` and not an `@value`, find the context the key belongs to so we can
    # hold a reference to it for passing to the `dataChange` and `nodeChange` observers.
    if k = @get('key')
      @get("keyContext.#{k}")
    else
      @get('value')

  # The `keyContext` accessor is
  @accessor 'keyContext', ->
    unless @_keyContext
      [unfilteredValue, @_keyContext] = @renderContext.findKey @key
    @_keyContext

  constructor: ->
    super

    # Pull out the key and filter from the `@keyPath`.
    @parseFilter()

    # Define the default observers.
    @nodeChange ||= (node, context) =>
      if @key
        @get('keyContext').set @key, @node.value
    @dataChange ||= (value, node) ->
      Batman.DOM.valueForNode @node, value

    shouldSet = yes

    # And attach them.
    if @only != 'write' and Batman.DOM.nodeIsEditable(@node)
      Batman.DOM.events.change @node, =>
        shouldSet = no
        @nodeChange(@node, @_keyContext || @value, @)
        shouldSet = yes
    # Observe the value of this binding's `filteredValue` and fire it immediately to update the node.
    @observe 'filteredValue', yes, (value) =>
      if shouldSet and @only != 'read'
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
      throw "Bad binding keypath \"#{orig}\"!"
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
              throw new Error("Bad filter arguments \"#{args}\"!")
          else
            @filterArguments.push []
        else
          throw new Error("Unrecognized filter '#{filterName}' in key \"#{@keyPath}\"!")

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
    JSON.parse( "[" + segment.replace(keypath_rx, "{\"_keypath\": \"$1\"}") + "]" )

# The RenderContext class manages the stack of contexts accessible to a view during rendering.
# Every, and I really mean every method which uses filters has to be defined in terms of a new
# binding, or by using the RenderContext.bind method. This is so that the proper order of objects
# is traversed and any observers are properly attached.
class RenderContext
  constructor: (contexts...) ->
    @contexts = contexts
    @storage = new Batman.Object
    @defaultContexts = [@storage]
    @defaultContexts.push Batman.currentApp if Batman.currentApp

  findKey: (key) ->
    base = key.split('.')[0].split('|')[0].trim()
    for contexts in [@contexts, @defaultContexts]
      i = contexts.length
      while i--
        context = contexts[i]
        if context.get?
          val = context.get(base)
        else
          val = context[base]

        if typeof val isnt 'undefined'
          # we need to pass the check if the basekey exists, even if the intermediary keys do not.
          return [$get(context, key), context]

    return [container.get(key), container]

  set: (args...) ->
    @storage.set(args...)

  push: (x) ->
    @contexts.push(x)

  pop: ->
    @contexts.pop()

  clone: ->
    context = new @constructor(@contexts...)
    newStorage = $mixin {}, @storage
    context.setStorage(newStorage)
    context

  setStorage: (storage) ->
    @defaultContexts[0] = storage

  # `BindingProxy` is a simple class which assists in allowing bound contexts to be popped to the top of
  # the stack. This happens when a `data-context` is descended into, for each iteration in a `data-foreach`,
  # and in other specific HTML bindings like `data-formfor`. `BindingProxy`s use accessors so that if the
  # value of the binding they proxy changes, the changes will be propagated to any thing observing it.
  # This is good because it allows `data-context` to take filtered keys and even filters which take
  # keypath arguments, calculate the context to descend into when any of those keys change, and importantly
  # expose a friendly `Batman.Object` interface for the rest of the `Binding` code to work with.
  class BindingProxy extends Batman.Object
    isBindingProxy: true
    # Take the `binding` which needs to be proxied, and optionally rest it at the `localKey` scope.
    constructor: (@binding, @localKey) ->
      if @localKey
        @accessor @localKey, -> @binding.get('filteredValue')
      else
        @accessor (key) -> @binding.get("filteredValue.#{key}")

  # Below are the two primitives that all the `Batman.DOM` helpers are composed of.
  # `addKeyToScopeForNode` takes a `node`, `key`, and optionally a `localName`. It creates a `Binding` to
  # the key (such that the key can contain filters and many keypaths in arguments), and then pushes the
  # bound value onto the stack of contexts for the given `node`. If `localName` is given, the bound value
  # is available using that identifier in child bindings. Otherwise, the value itself is pushed onto the
  # context stack and member properties can be accessed directly in child bindings.
  addKeyToScopeForNode: (node, key, localName) ->
    @bind(node, key, (value, node, binding) =>
      @push new BindingProxy(binding, localName)
    , ->
      true
    )
    # Pop the `BindingProxy` off the stack once this node has been parsed.
    node.onParseExit = =>
      @pop()

  # `bind` takes a `node`, a `key`, and observers for when the `dataChange`s and the `nodeChange`s. It
  # creates a `Binding` to the key (supporting filters and the context stack), which fires the observers
  # when appropriate. Note that `Binding` has default observers for `dataChange` and `nodeChange` that
  # will set node/object values if these observers aren't passed in here.
  # The optional `only` parameter can be used to create read-only or write-only bindings. If left unset,
  # both read and write events are observed.
  bind: (only, node, key, dataChange, nodeChange) ->
    if !nodeChange and only and typeof only != 'string'
      [node, key, dataChange, nodeChange] = [only, node, key, dataChange]

    return new Binding
      renderContext: @
      keyPath: key
      node: node
      dataChange: dataChange
      nodeChange: nodeChange
      only: only

Batman.DOM = {
  # `Batman.DOM.readers` contains the functions used for binding a node's value or innerHTML, showing/hiding nodes,
  # and any other `data-#{name}=""` style DOM directives.
  readers: {
    read: (node, key, context, renderer) ->
      Batman.DOM.readers.bind(node, key, context, renderer, 'read')

    write: (node, key, context, renderer) ->
      Batman.DOM.readers.bind(node, key, context, renderer, 'write')

    bind: (node, key, context, renderer, only) ->
      if node.nodeName.toLowerCase() == 'input' and node.getAttribute('type') == 'checkbox'
        Batman.DOM.attrReaders.bind(node, 'checked', key, context, only)
      else if node.nodeName.toLowerCase() == 'input' and node.getAttribute('type') == 'radio'
        contextChange = (value) ->
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
        context.bind only, node, key, contextChange, nodeChange
      else if node.nodeName.toLowerCase() == 'select'
        # wait for the select to render before binding to it
        renderer.rendered ->
          Batman.DOM.attrReaders.bind(node, 'value', key, context, only)
      else
        context.bind(only, node, key)

    context: (node, key, context) -> context.addKeyToScopeForNode(node, key)

    mixin: (node, key, context) ->
      context.push(Batman.mixins)
      context.bind(node, key, (mixin) ->
        $mixin node, mixin
      , ->)
      context.pop()

    showif: (node, key, context, renderer, invert) ->
      originalDisplay = node.style.display || ''

      context.bind(node, key, (value) ->
        if !!value is !invert
          node.show?()
          node.style.display = originalDisplay
        else
          if typeof node.hide is 'function' then node.hide() else node.style.display = 'none'
      , -> )

    hideif: (args...) ->
      Batman.DOM.readers.showif args..., yes

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
          name = helpers.underscore(helpers.pluralize(model.constructor.name))
          url = dispatcher.findUrl({resource: name, id: model.get('id'), action: action})
        else if model?.prototype # TODO write test for else case
          name = helpers.underscore(helpers.pluralize(model.name))
          url = dispatcher.findUrl({resource: name, action: 'index'})

      return unless url

      if node.nodeName.toUpperCase() is 'A'
        node.href = Batman.HashHistory::urlFor url

      Batman.DOM.events.click node, (-> $redirect url)

    partial: (node, path, context) ->
      view = new Batman.View
        source: path + '.html'
        contentFor: node
        contexts: Array.prototype.slice.call(context.contexts)

    yield: (node, key) ->
      setTimeout (-> Batman.DOM.yield key, node), 0

    contentfor: (node, key) ->
      setTimeout (-> Batman.DOM.contentFor key, node), 0
  }

  # `Batman.DOM.attrReaders` contains all the DOM directives which take an argument in their name, in the
  # `data-dosomething-argument="keypath"` style. This means things like foreach, binding attributes like
  # disabled or anything arbitrary, descending into a context, binding specific classes, or binding to events.
  attrReaders: {
    _parseAttribute: (value) ->
      if value is 'false' then value = false
      if value is 'true' then value = true
      value

    write: (node, attr, key, context) ->
      Batman.DOM.attrReaders.bind node, attr, key, context, 'write'

    bind: (node, attr, key, context, only) ->
      switch attr
        when 'checked', 'disabled'
          contextChange = (value) -> node[attr] = !!value
          nodeChange = (node, subContext) -> subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node[attr]))
        when 'value'
          contextChange = (value) -> node.value = value
          nodeChange = (node, subContext) -> subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.value))
        else
          contextChange = (value) -> node.setAttribute(attr, value)
          nodeChange = (node, subContext) -> subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.getAttribute(attr)))

      context.bind(only, node, key, contextChange, nodeChange)

    context: (node, contextName, key, context) -> context.addKeyToScopeForNode(node, key, contextName)

    event: (node, eventName, key, context) ->
      if key.substr(0, 1) is '@'
        callback = new Function key.substr(1)
      else
        [callback, subContext] = context.findKey key

      Batman.DOM.events[eventName] node, ->
        confirmText = node.getAttribute('data-confirm')
        if confirmText and not confirm(confirmText)
          return
        x = eventName
        x = key
        callback?.apply subContext, arguments

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

    removeclass: (args...) ->
      Batman.DOM.attrReaders.addclass args..., yes

    foreach: (node, iteratorName, key, context, parentRenderer) ->
      prototype = node.cloneNode true
      prototype.removeAttribute "data-foreach-#{iteratorName}"

      parent = node.parentNode
      sibling = node.nextSibling
      fragment = document.createDocumentFragment()
      numPendingChildren = 0
      parentRenderer.parsed ->
        parent.removeChild node

      nodeMap = new Batman.Hash
      observers = {}
      oldCollection = false
      context.bind(node, key, (collection) ->
        # Track the old collection so that if it changes, we can remove the observers we attached,
        # and only observe the new collection.
        if oldCollection
          return if collection == oldCollection
          nodeMap.forEach (item, node) -> parent.removeChild node
          oldCollection.forget 'itemsWereAdded', observers.add
          oldCollection.forget 'itemsWereRemoved', observers.remove
          oldCollection.forget 'setWasSorted', observers.reorder
        oldCollection = collection

        observers.add = (items...) ->
          numPendingChildren += items.length
          for item in items
            parentRenderer.prevent 'rendered'

            newNode = prototype.cloneNode true
            nodeMap.set item, newNode

            localClone = context.clone()
            iteratorContext = new Batman.Object
            iteratorContext[iteratorName] = item
            localClone.push iteratorContext
            localClone.push item

            new Batman.Renderer newNode, do (newNode) ->
              ->
                if collection.isSorted?()
                  observers.reorder()
                else
                  if typeof newNode.show is 'function'
                    newNode.show before: sibling
                  else
                    fragment.appendChild newNode

                if --numPendingChildren == 0
                  parent.insertBefore fragment, sibling
                  fragment = document.createDocumentFragment()

                parentRenderer.allow 'rendered'
                parentRenderer.fire 'rendered'
            , localClone

        observers.remove = (items...) ->
          for item in items
            oldNode = nodeMap.get item
            nodeMap.unset item
            if typeof oldNode.hide is 'function'
              oldNode.hide yes
            else
              oldNode?.parentNode?.removeChild oldNode
          true

        observers.reorder = ->
          items = collection.toArray()
          for item in items
            thisNode = nodeMap.get(item)
            if typeof thisNode.show is 'function'
              thisNode.show before: sibling
            else
              parent.insertBefore(thisNode, sibling)

        # Observe the collection for events in the future
        if collection?.observe
          collection.observe 'itemsWereAdded', observers.add
          collection.observe 'itemsWereRemoved', observers.remove
          collection.observe 'setWasSorted', observers.reorder

        # Add all the already existing items. For hash-likes, add the key.
        if collection.forEach
          collection.forEach (item) -> observers.add(item)
        else for k, v of collection
          observers.add(k)
      , -> )

      false # Return false so the Renderer doesn't descend into this node's children.

    formfor: (node, localName, key, context) ->
      binding = context.addKeyToScopeForNode(node, key, localName)
      Batman.DOM.events.submit node, (node, e) -> e.preventDefault()
  }

  # `Batman.DOM.events` contains the helpers used for binding to events. These aren't called by
  # DOM directives, but are used to handle specific events by the `data-event-#{name}` helper.
  events: {
    click: (node, callback) ->
      Batman.DOM.addEventListener node, 'click', (args...) ->
        callback node, args...
        args[0].preventDefault()

      if node.nodeName.toUpperCase() is 'A' and not node.href
        node.href = '#'

      node

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
        Batman.DOM.addEventListener node, eventName, (args...) ->
          callback node, args...

    submit: (node, callback) ->
      if Batman.DOM.nodeIsEditable(node)
        Batman.DOM.addEventListener node, 'keyup', (args...) ->
          if args[0].keyCode is 13 || args[0].which is 13 || args[0].keyIdentifier is 'Enter'
            callback node, args...
            args[0].preventDefault()
      else
        Batman.DOM.addEventListener node, 'submit', (args...) ->
          callback node, args...
          args[0].preventDefault()

      node
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
        if isSetting then (node.innerHTML = value) else node.innerHTML
  nodeIsEditable: (node) ->
    node.nodeName.toUpperCase() in ['INPUT', 'TEXTAREA', 'SELECT']

  addEventListener: (node, eventName, callback) ->
    if node.addEventListener
      node.addEventListener eventName, callback, false
    else
      node.attachEvent "on#{eventName}", callback
}

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
    if string.substr(-3) is 'ies'
      string.substr(0, string.length - 3) + 'y'
    else if string.substr(-1) is 's'
      string.substr(0, string.length - 1)
    else
      string

  pluralize: (count, string) ->
    if string
      return string if count is 1
    else
      string = count

    lastLetter = string.substr(-1)
    if lastLetter is 'y'
      "#{string.substr(0,string.length-1)}ies"
    else if lastLetter is 's'
      string
    else
      "#{string}s"

  capitalize: (string) -> string.replace capitalize_rx, (m,p1,p2) -> p1+p2.toUpperCase()
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

for k in ['capitalize', 'singularize', 'underscore', 'camelize']
  filters[k] = buntUndefined helpers[k]

# Mixins
# ------
mixins = Batman.mixins = new Batman.Object


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
  for k in ['mixin', 'unmixin', 'route', 'redirect', 'event', 'eventOneShot', 'typeOf', 'redirect']
    onto["$#{k}"] = Batman[k]
  onto

Batman.exportGlobals = () ->
  Batman.exportHelpers(container)

