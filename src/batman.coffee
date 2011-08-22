#
# batman.js
#
# Created by Nicholas Small
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
    if @base._batman?
      @base._batman.ancestors().some((ancestor) => ancestor.property?(@key)?.observers?.length > 0)
    else
      false
  prevent: -> @_preventCount++
  allow: -> @_preventCount-- if @_preventCount > 0
  isAllowedToFire: -> @_preventCount <= 0
  fire: (args...) ->
    return unless @hasObserversToFire()
    key = @key
    base = @base
    observers = [@observers].concat(@base._batman.ancestors((ancestor) -> ancestor.property?(key).observers)).reduce((a, b) -> a.merge(b))
    observers.each (callback) ->
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
    delete Batman.Property.triggerTracker
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
    return undefined if typeof key is 'undefined'
    @property(key).getValue()
  set: (key, val) ->
    return undefined if typeof key is 'undefined'
    @property(key).setValue(val)
  unset: (key) ->
    return undefined if typeof key is 'undefined'
    @property(key).unsetValue()

  # `forget` removes an observer from an object. If the callback is passed in,
  # its removed. If no callback but a key is passed in, all the observers on
  # that key are removed. If no key is passed in, all observers are removed.
  forget: (key, observer) ->
    if key
      @property(key).forget(observer)
    else
      @_batman.properties.each (key, property) -> property.forget()
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
      if (cons = @object.constructor):: == @object
        cons.__super__
      else
        cons::

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
class Batman.Object
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
  # this feat by tracking `get` calls, so be sure to use `get` to retrieve properties inside accessors.
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
    return undefined if typeof key is 'undefined'
    if matches = @_storage[key]
      for [obj,v] in matches
        return v if @equality(obj, key)
  set: (key, val) ->
    return undefined if typeof key is 'undefined'
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
  equality: (lhs, rhs) ->
    return false if typeof lhs is 'undefined' or typeof rhs is 'undefined'
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
    @_storage = {}
    @length = 0
  isEmpty: ->
    @length is 0
  merge: (others...) ->
    merged = new @constructor
    others.unshift(@)
    for hash in others
      hash.each (obj, value) ->
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

  for k in ['hasKey', 'equality', 'each', 'keys', 'isEmpty', 'merge', 'clear']
    @::[k] = Batman.SimpleHash::[k]

class Batman.SimpleSet
  constructor: ->
    @_storage = new Batman.SimpleHash
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
  each: (iterator) ->
    @_storage.each (key, value) -> iterator(key)
  isEmpty: -> @length is 0
  clear: ->
    items = @toArray()
    @_storage = new Batman.SimpleHash
    @length = 0
    @itemsWereRemoved(items)
    items
  toArray: ->
    @_storage.keys()

  merge: (others...) ->
    merged = new @constructor
    others.unshift(@)
    for set in others
      set.each (v) -> merged.add v
    merged
  itemsWereAdded: ->
  itemsWereRemoved: ->

class Batman.Set extends Batman.Object
  constructor: Batman.SimpleSet
  itemsWereAdded: @event ->
  itemsWereRemoved: @event ->

  for k in ['has', 'each', 'isEmpty', 'toArray']
    @::[k] = Batman.SimpleSet::[k]

  for k in ['add', 'remove', 'clear', 'merge']
    do (k) =>
      @::[k] = ->
        oldLength = @length
        results = Batman.SimpleSet::[k].apply(@, arguments)
        @property('length').fireDependents()
        results

  @accessor 'isEmpty', -> @isEmpty()
  @accessor 'length', -> @length

class Batman.SortableSet extends Batman.Set
  constructor: ->
    super
    @_indexes = {}
    @observe 'activeIndex', =>
      @setWasSorted(@)
  setWasSorted: @event ->
    return false if @length is 0
  add: ->
    results = Batman.SimpleSet::add.apply @, arguments
    @_reIndex()
    results
  remove: ->
    results = Batman.SimpleSet::remove.apply @, arguments
    @_reIndex()
    results
  addIndex: (index) ->
    @_reIndex(index)
  removeIndex: (index) ->
    @_indexes[index] = null
    delete @_indexes[index]
    @unset('activeIndex') if @activeIndex is index
    index
  each: (iterator) ->
    iterator(el) for el in @toArray()
  sortBy: (index) ->
    @addIndex(index) unless @_indexes[index]
    @set('activeIndex', index) unless @activeIndex is index
    @
  isSorted: ->
    @_indexes[@get('activeIndex')]?
  toArray: ->
    @_indexes[@get('activeIndex')] || super
  _reIndex: (index) ->
    if index
      [keypath, ordering] = index.split ' '
      ary = Batman.Set.prototype.toArray.call @
      @_indexes[index] = ary.sort (a,b) ->
        valueA = (Batman.Observable.property.call(a, keypath)).getValue()?.valueOf()
        valueB = (Batman.Observable.property.call(b, keypath)).getValue()?.valueOf()
        [valueA, valueB] = [valueB, valueA] if ordering?.toLowerCase() is 'desc'
        if valueA < valueB then -1 else if valueA > valueB then 1 else 0
      @setWasSorted(@) if @activeIndex is index
    else
      @_reIndex(index) for index of @_indexes
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
    return false if @hasRun
    Batman.currentApp = @

    if typeof @layout is 'undefined'
      @set 'layout', new Batman.View
        node: document
        contexts: [@]

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
  route: $block(2, (pattern, callback) ->
    f = (params) ->
      if $typeOf(f.action) is 'String'
        components = f.action.split '#'
        controller = Batman.currentApp[helpers.camelize(components[0])+'Controller']
        if controller
          f.context = controller
          f.action = controller::[components[1]]

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
  )
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

    if not @_actedDuringAction and result isnt false
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

  # ## Model API
  # Pick one or many mechanisms with which this model should be persisted. The mechanisms
  # can be already instantiated or just the class defining them.
  @persist: (mechanisms...) ->
    Batman.initializeObject @prototype
    storage = @::_batman.storage ||= []
    for mechanism in mechanisms
      storage.push if mechanism.isStorageAdapter then mechanism else new mechanism(@)
    @

  # ### Query methods
  @classAccessor 'all',
    get: ->
      @load() if not @all
      @all

  @classAccessor 'first', {get: -> @first = @get('all')[0]}
  @classAccessor 'last', {get: -> @last = @get('all')[@all.length - 1]}

  @find: (id) ->
    id = "#{id}"
    for record in @get('all').toArray()
      return record if record._id() is id

    record = new @(id)
    setTimeout (-> record.load()), 0
    record

  # Override this property if your model is indexed by a key other than `id`
  @id: 'id'
  _id: (id) ->
    model = @constructor
    key = model.id?() || model.id || 'id'

    if arguments.length > 0
      id = @[key] = "#{id}" # normalize to a string

      Batman.initializeObject model
      records = model._batman.records ||= {}
      record = records[id]

      all = model.get 'all'
      all.remove(record) if record

      records[id] = @
      all.add(@)

    @[key]

  # ### Transport methods

  # Create a before load event. Clear the `all` set.
  @beforeLoad: @event -> @get('all').clear()
  # Create an after load event.
  @afterLoad: @event ->

  # `load` fetches the record from all sources possible
  @load: (callback) ->
    @all ||= new Batman.Set
    do @beforeLoad

    afterLoad = =>
      callback?.call @
      do @afterLoad

    allMechanisms = @::_batman.getAll 'storage'
    fireImmediately = !allMechanisms.length
    for mechanisms in allMechanisms
      fireImmediately = fireImmediately || !mechanisms.length
      for m in mechanisms
        m.readAllFromStorage @, afterLoad

    do afterLoad if fireImmediately

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
      @::_batman.encoders.set key, (encoder || @defaultEncoder)
      @::_batman.decoders.set key, (decoder || @defaultDecoder)

  # Set up the unit functions as the default for both
  @defaultEncoder = @defaultDecoder = (x) -> (x)

  # Validations allow a model to be marked as 'valid' or 'invalid' based on a set of programmatic rules.
  # By validating our data before it gets to the server we can provide immediate feedback to the user about
  # what they have entered and forgo waiting on a round trip to the server.
  # `validate` allows the attachment of validations to the model on particular keys, where the validation is
  # either a built in one (by use of options to pass to them) or a cusom one (by use of a custom function as
  # the second argument).
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

  # Each model instance (each record) can be in one of many states throughout its lifetime. Since various
  # operations on the model are asynchronous, these states are used to indicate exactly what point the
  # record is at in it's lifetime, which can often be during a save or load operation.
  @mixin Batman.StateMachine

  # Add the various states to the model.
  for k in ['empty', 'dirty', 'loading', 'loaded', 'saving']
    @::state k
  @::state 'saved', -> @dirtyKeys.clear()

  # ### Record API

  # New records can be constructed by passing either an ID or a hash of attributes (potentially
  # containing an ID) to the Model constructor. By not passing an ID, the model is marked as new.
  constructor: (idOrAttributes = {}) ->
    # We have to do this ahead of super, because mixins will call set which calls things on dirtyKeys.
    @dirtyKeys = new Batman.Hash
    @errors = new Batman.Set

    super
    @empty() if not @state()

    # Find the ID from either the first argument or the attributes.
    id = if $typeOf(idOrAttributes) is 'Object' then idOrAttributes.id else idOrAttributes
    @_id id if id?

  # Override the `Batman.Observable` implementation of `set` to implement dirty tracking.
  set: (key, value) ->
    # Optimize setting where the value is the same as what's already been set.
    oldValue = @[key]
    return if oldValue is value

    # Actually set the value and note what the old value was in the tracking array.
    super
    @dirtyKeys.set(key, oldValue)

    # Mark the model as dirty if isn't already.
    @dirty() if @state() isnt 'dirty'

  # FIXME: Is this really needed?
  @accessor 'dirtyKeys', -> @dirtyKeys

  toString: ->
    "#{@constructor.name}: #{@_id()}"

  # `toJSON` uses the various encoders for each key to grab a storable representation of the record.
  toJSON: ->
    obj = {}
    # Encode each key into a new object
    encoders = @_batman.get('encoders')
    unless !encoders or encoders.isEmpty()
      encoders.each (key, encoder) =>
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
        obj[helpers.camelize(key, yes)] = value
    else
      # If we do have decoders, use them to get the data.
      decoders.each (key, decoder) ->
        obj[key] = decoder(data[key])

    # Mixin the buffer object to use optimized and event-preventing sets used by `mixin`.
    @mixin obj

  # Set up the lifecycle events for a record.
  beforeLoad: @event -> @loading(); true
  afterLoad: @event -> @loaded(); true
  beforeCreate: @event ->
  afterCreate: @event ->
  beforeSave: @event -> @saving(); true
  afterSave: @event -> @saved(); true
  beforeValidation: @event ->
  afterValidation: @event ->

  # `load` fetches the record from all sources possible
  load: (callback) ->
    do @beforeLoad

    afterLoad = =>
      callback?.call @
      do @afterLoad

    allMechanisms = @_batman.getAll 'storage'
    fireImmediately = !allMechanisms.length
    for mechanisms in allMechanisms
      fireImmediately = fireImmediately || !mechanisms.length
      for m in mechanisms
        m.readFromStorage @, afterLoad

    do afterLoad if fireImmediately

  # `save` persists a record to all the storage mechanisms added using `@persist`. `save` will only save
  # a model if it is valid.
  save: (callback) =>
    return if not @isValid()
    do @beforeSave

    creating = @isNew()
    do @beforeCreate if creating

    afterSave = =>
      @dirtyKeys.clear()
      if callback? && callback.call?
        callback?.call @
      do @afterCreate if creating
      do @afterSave

    allMechanisms = @_batman.getAll 'storage'
    fireImmediately = !allMechanisms.length
    for mechanisms in allMechanisms
      fireImmediately = fireImmediately || !mechanisms.length
      for m in mechanisms
        m.writeToStorage @, afterSave

    do afterSave if fireImmediately

  # `validate` performs the record level validations determining the record's validity. These may be asynchronous,
  # in which case `validate` has no useful return value. Results from asynchronous validations can be received by
  # listening to the `afterValidation` lifecycle callback.
  validate: ->
    do @beforeValidation

    # Start off assuming the validation is synchronous, and as they are each run, ensure each in fact is.
    async = no

    for validator in @_batman.get('validators') || []
      v = validator.validator

      # Run the validator `v` or the custom callback on each key it validates by instantiating a new promise
      # and passing it to the appropriate function along with the key and the value to be validated.
      for key in validator.keys
        promise = new Batman.ValidatorPromise @
        if v
          v.validateEach promise, @, key, @get key
        else
          validator.callback promise, @, key, @get key

        # In the event the validation is async (marked this way because the promise is paused), then
        # prevent the after callback from running, and run it only after all the promises have resolved.
        if promise.paused
          @prevent 'afterValidation'
          promise.resume => @allow('afterValidation'); @afterValidation()
          async = yes
        else
          promise.success() if promise.canSucceed

    # Return the result of the validation if synchronous, otherwise call the validation callback.
    # FIXME: Is this really right?
    if async then return no else do @afterValidation

  isNew: -> !@_id()

  isValid: ->
    @errors.clear()
    return no if @validate() is no
    @errors.isEmpty()


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
    throw "You must override validate in Batman.Validator subclasses."

  @kind: -> helpers.underscore(@name).replace('_validator', '')
  kind: -> @constructor.kind()

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
  isStorageAdapter: true

class Batman.LocalStorage extends Batman.StorageMechanism
  constructor: ->
    return null if not 'localStorage' in window
    @id = 0
    super

  writeToStorage: (record, callback) ->
    key = @modelKey
    id = record._id() || record._id(++@id)
    localStorage[key + id] = JSON.stringify(record) if key and id
    callback()

  readFromStorage: (record, callback) ->
    key = @modelKey
    id = record._id()
    json = localStorage[key + id] if key and id
    record.fromJSON JSON.parse json
    callback()

  readAllFromStorage: (model, callback) ->
    re = new RegExp("$#{@modelKey}")
    for k, v of localStorage
      if re.test(k)
        data = JSON.parse(v)
        record = new model(data)

    callback()
    return

class Batman.RestStorage extends Batman.StorageMechanism
  optionsForRecord: (record) ->
    options =
      type: 'json'

    options.url = record?.url?() || record?.url || @model.url?() || @model.url || @modelKey
    options.url += "/#{record._id()}" if record and not record.url

    options

  writeToStorage: (record, callback) ->
    options = $mixin @optionsForRecord(record),
      method: if record._id() then 'put' else 'post'
      data: JSON.stringify record
      success: ->
        callback()
      error: (error) ->
        callback(error)

    new Batman.Request(options)

  readFromStorage: (record, callback) ->
    options = $mixin @optionsForRecord(record),
      success: (data) ->
        data = JSON.parse(data) if typeof data is 'string'
        for key of data
          data = data[key]
          break

        record.fromJSON data
        callback()

    new Batman.Request(options)

  readAllFromStorage: (model, callback) ->
    options = $mixin @optionsForRecord(),
      success: (data) ->
        data = JSON.parse(data) if typeof data is 'string'
        if !Array.isArray(data)
          for key of data
            data = data[key]
            break

        for obj in data
          record = new model ''+obj[model.id]
          record.fromJSON obj

        callback()
        return

    new Batman.Request options

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

        @ready node
      , @contexts)

      # Ensure any context object explicitly given for use in rendering the view (in `@context`) gets passed to the renderer
      @_renderer.context.push(@context) if @context
      @_renderer.context.set 'view', @

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
    @callback?()

  forgetAll: ->

  regexp = /data\-(.*)/

  parseNode: (node) ->
    if new Date - @startTime > 50
      @resumeNode = node
      setTimeout @resume, 0
      return

    if node.getAttribute
      @context.set 'node', node

      for attr in node.attributes
        name = attr.nodeName.match(regexp)?[1]
        continue if not name

        result = if (index = name.indexOf('-')) is -1
          Batman.DOM.readers[name]?(node, attr.value, @context, @)
        else
          Batman.DOM.attrReaders[name.substr(0, index)]?(node, name.substr(index + 1), attr.value, @context, @)

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

  # A less beastly regular expression for pulling out the [] syntax `get`s in a binding string.
  get_rx = /(\w)\[(.+?)\]/

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
      if @get('key')
        @get("keyContext.#{@get('key')}")
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
    if Batman.DOM.nodeIsEditable(@node)
      Batman.DOM.events.change @node, =>
        shouldSet = no
        @nodeChange(@node, @_keyContext || @value, @)
        shouldSet = yes
    # Observe the value of this binding's `filteredValue` and fire it immediately to update the node.
    @observe 'filteredValue', yes, (value) =>
      if shouldSet
        @dataChange(value, @node, @)
    @

  parseFilter: ->
    # Store the function which does the filtering and the arguments (all except the actual value to apply the
    # filter to) in these arrays.
    @filterFunctions = []
    @filterArguments = []

    # Rewrite [] style gets, replace quotes to be JSON friendly, and split the string by pipes to see if there are any filters.
    filters = @keyPath.replace(get_rx, "$1 | get $2 ").replace(/'/g, '"').split(/(?!")\s+\|\s+(?!")/)

    # The key will is always the first token before the pipe.
    try
      key = @parseSegment(orig = filters.shift())[0]
    catch e
      throw "Bad binding keypath \"#{orig}\"!"
    if key._keypath
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
          throw new Error("Unrecognized filter #{filter} in key \"#{@keyPath}\"!")

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


# The Render context class manages the stack of contexts accessible to a view during rendering.
# Every, and I really mean every method which uses filters has to be defined in terms of a new
# binding, or by using the RenderContext.bind method. This is so that the proper order of objects
# is traversed and any observers are properly attached.
class RenderContext
  constructor: (contexts...) ->
    @contexts = contexts
    @storage = new Batman.Object
    @contexts.push @storage

  findKey: (key) ->
    base = key.split('.')[0].split('|')[0].trim()
    i = @contexts.length
    while i--
      context = @contexts[i]
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
    context.setStorage(@storage)
    context

  setStorage: (storage) ->
    @contexts.splice(@contexts.indexOf(@storage), 1)
    @push(storage)
    storage

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
  bind: (node, key, dataChange, nodeChange) ->
    return new Binding
      renderContext: @
      keyPath: key
      node: node
      dataChange: dataChange
      nodeChange: nodeChange

Batman.DOM = {
  # `Batman.DOM.readers` contains the functions used for binding a node's value or innerHTML, showing/hiding nodes,
  # and any other `data-#{name}=""` style DOM directives.
  readers: {
    bind: (node, key, context) ->
      if node.nodeName.toLowerCase() == 'input' and node.getAttribute('type') == 'checkbox'
        Batman.DOM.attrReaders.bind(node, 'checked', key, context)
      else
        context.bind(node, key)

    context: (node, key, context) -> context.addKeyToScopeForNode(node, key)

    mixin: (node, key, context) ->
      context.push(Batman.mixins)
      context.bind(node, key, (mixin) ->
        $mixin node, mixin
      , ->)
      context.pop()

    showif: (node, key, context, renderer, invert) ->
      originalDisplay = node.style.display
      originalDisplay = 'block' if !originalDisplay or originalDisplay is 'none'

      context.bind(node, key, (value) ->
        if !!value is !invert
          if typeof node.show is 'function' then node.show() else node.style.display = originalDisplay
        else
          if typeof node.hide is 'function' then node.hide() else node.style.display = 'none'
      , -> )

    hideif: (args...) ->
      Batman.DOM.readers.showif args..., yes

    route: (node, key, context) ->
      if key.substr(0, 1) is '/'
        route = Batman.redirect.bind Batman, key
        routeName = key
      else if (index = key.indexOf('#')) isnt -1
        controllerName = helpers.camelize(key.substr(0, index)) + 'Controller'
        controller = context.get controllerName

        route = controller?.sharedInstance()[key.substr(index + 1)]
        routeName = route?.pattern
      else
        route = context.get key

        if route instanceof Batman.Model
          controllerName = helpers.camelize(helpers.pluralize(key)) + 'Controller'
          controller = context.get(controllerName).sharedInstance()

          id = route._id()
          route = controller.show?.bind(controller, {id: id})
          routeName = '/' + helpers.pluralize(key) + '/' + id
        else
          routeName = route.pattern

      if node.nodeName.toUpperCase() is 'A'
        node.href = Batman.HASH_PATTERN + (routeName || '')

      Batman.DOM.events.click node, (-> route?())

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

    bind: (node, attr, key, context) ->
      switch attr
        when 'checked'
          contextChange = (value) -> node.checked = !!value
          nodeChange = (node, subContext) -> subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.checked))
        when 'value'
          contextChange = (value) -> node.value = value
          nodeChange = (node, subContext) -> subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.value))
        else
          contextChange = (value) -> node.setAttribute(attr, value)
          nodeChange = (node, subContext) -> subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.getAttribute(attr)))

      context.bind(node, key, contextChange, nodeChange)

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
      node.onParseExit = ->
        setTimeout (-> parent.removeChild node), 0

      nodeMap = new Batman.Hash
      observers = {}
      oldCollection = false
      context.bind(node, key, (collection) ->
        # Track the old collection so that if it changes, we can remove the observers we attached,
        # and only observe the new collection.
        if oldCollection
          nodeMap.each (item, node) -> parent.removeChild node
          oldCollection.forget 'itemsWereAdded', observers.add
          oldCollection.forget 'itemsWereRemoved', observers.remove
          oldCollection.forget 'setWasSorted', observers.reorder
        oldCollection = collection

        observers.add = (items...) ->
          for item in items
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
                  parent.insertBefore newNode, sibling
                parentRenderer.allow 'ready'
            , localClone

        observers.remove = (items...) ->
          for item in items
            oldNode = nodeMap.get item
            nodeMap.unset item
            oldNode?.parentNode?.removeChild oldNode

        observers.reorder = ->
          items = collection.toArray()
          for item in items
            parent.insertBefore(nodeMap.get(item), sibling)

        # Observe the collection for events in the future
        if collection?.observe
          collection.observe 'itemsWereAdded', observers.add
          collection.observe 'itemsWereRemoved', observers.remove
          collection.observe 'setWasSorted', observers.reorder

        # Add all the already existing items.
        # Fandangle with the iterator so that we always add the last argument of whatever calls this function.
        # This is useful for iterating over hashes or other things that pass (key, value) instead of (value)
        if collection.each
          collection.each (korv, v) -> observers.add(korv)
        else if collection.forEach
          collection.forEach (x) -> observers.add(x)
        else for k, v of collection
          observers.add(v)
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
      Batman.DOM.addEventListener node, 'click', (e) ->
        callback node, e
        e.preventDefault()

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
        Batman.DOM.addEventListener node, eventName, (e) ->
          callback node, e

      node

    submit: (node, callback) ->
      if Batman.DOM.nodeIsEditable(node)
        Batman.DOM.addEventListener node, 'keyup', (e) ->
          if e.keyCode is 13
            callback node, e
            e.preventDefault()
      else
        Batman.DOM.addEventListener node, 'submit', (e) ->
          callback node, e
          e.preventDefault()

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
      else
        if isSetting then (node.innerHTML = value) else node.innerHTML
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
  animation:
    initialize: () ->
      @style['MoxTransition'] = @style['WebkitTransition'] = @style['OTransition'] = @style['transition'] = "opacity .25s linear"
    show: ->
      @style.visibility = 'visible'
      @style.opacity = 1
    hide: ->
      @style.opacity = 0
      setTimeout =>
        @style.visibility = 'hidden'
      , 26


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
  for k in ['mixin', 'unmixin', 'route', 'redirect', 'event', 'eventOneShot', 'typeOf']
    onto["$#{k}"] = Batman[k]
  onto

Batman.exportGlobals = () ->
  Batman.exportHelpers(container)
