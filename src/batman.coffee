###
# batman.js
# batman.coffee
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
  hasSet = $typeOf(set) is 'Function'
  
  for mixin in mixins
    continue if $typeOf(mixin) isnt 'Object'
    
    for key, value of mixin
      continue if key in ['initialize', 'deinitialize', 'prototype']
      if hasSet then set.call(to, key, value) else to[key] = value
    
    if $typeOf(mixin.initialize) is 'Function'
      mixin.initialize.call to
  
  to

# Batman.unmixin will remove every key from every argument after the first
# from the first argument. If a mixin has a `deinitialize` method, it will be
# called in the context of the `from` object and won't be removed.
Batman.unmixin = $unmixin = (from, mixins...) ->
  for mixin in mixins
    for key of mixin
      continue if key in ['initialize', 'deinitialize']
      
      from[key] = null
      delete from[key]
    
    if $typeOf(mixin.deinitialize) is 'Function'
      mixin.deinitialize.call from
  
  from

Batman._findName = (f, context) ->
  if not f.displayName
    for key, value of context
      if value is f
        f.displayName = key
        break
  
  f.displayName

###
# Batman.Observable
###

# Batman.Observable is a generic mixin that can be applied to any object in
# order to make that object bindable. It is applied by default to every
# instance of Batman.Object and subclasses.
Batman.Observable =
  initialize: ->
    return if @hasOwnProperty '_observers'
    
    o = {}
    if @_observers # prototype observers
      for key, value of @_observers
        continue if key.substr(0,2) is '__'
        o[key] = value.slice(0)
    
    @_observers = o
  
  get: (key) ->
    value = @[key]
    if value and value.get
      value.get key, @
    else
      value
  
  set: (key, value) ->
    oldValue = @[key]
    if oldValue and oldValue.set
      oldValue.set key, value, @
    else
      @[key] = value
      @fire key, value
  
  # The observers hash contains the callbacks for every observable key.
  # _observers: {}
  # Pass a key and a callback. Whenever the value for that key changes, your
  # callback will be called in the context of the original object.
  observe: (key, fireImmediately, callback) ->
    Batman._observerClassHack.call @
    
    if not callback
      callback = fireImmediately
      fireImmediately = no
    
    observers = @_observers[key] ||= []
    observers.push callback if observers.indexOf(callback) is -1
    
    callback.call(@, @get(key)) if fireImmediately
    
    @
  
  # You normally shouldn't call this directly. It will be invoked by `set`
  # to inform all observers for `key` that `value` has changed.
  fire: (key, value) ->
    # Batman._observerClassHack.call @ # allowed will call this already
    return if not @allowed key
    
    if typeof value is 'undefined'
      value = @get key
    
    observers = @_observers[key]
    if observers
      for observer in observers
        observer.call @, value
    
    @
  
  # Prevent allows you to prevent a given binding from firing. You can
  # nest prevent counts, so three calls to prevent means you need to
  # make three calls to allow before you can fire observers again.
  prevent: (key) ->
    Batman._observerClassHack.call @
    
    counts = @_observers.__preventCounts__ ||= {}
    counts[key] ||= 0
    counts[key]++
    @
  
  # Unblocks a property for firing observers. Every call to prevent
  # must have a matching call to allow.
  allow: (key) ->
    Batman._observerClassHack.call @
    
    counts = @_observers.__preventCounts__ ||= {}
    counts[key]-- if counts[key] > 0
    @
  
  # Returns a boolean whether or not the property is currently allowed
  # to fire its observers.
  allowed: (key) ->
    Batman._observerClassHack.call @
    
    !(@_observers.__preventCounts__?[key] > 0)

Batman._observerClassHack = ->
  if @prototype and @_observers?.__initClass__ isnt @
    @_observers = {__initClass__: @}

###
# Batman.Event
###

Batman.Event = {
  isEvent: yes
  
  get: (key, parent) ->
    @.call parent
  
  set: (key, value, parent) ->
    parent.observe key, value
}

Batman.EventEmitter = {
  # An event is a convenient observer wrapper. Wrap any function in an event.
  # Whenever you call that function, it will cause this object to fire all
  # the observers for that event. There is also some syntax sugar so you can
  # register an observer simply by calling the event with a function argument.
  event: (callback) ->
    if not @observe
      throw "EventEmitter needs to be on an object that has Batman.Observable."
    
    f = (observer) ->
      key = Batman._findName(f, @)
      
      if $typeOf(observer) is 'Function'
        @observe key, f.isOneShot and f.fired, observer
      else if @allowed key
        return false if f.isOneShot and f.fired
        
        value = callback.apply @, arguments
        value = arguments[0] if typeof value is 'undefined'
        value = null if typeof value is 'undefined'
        
        @fire key, value
        f.fired = yes if f.isOneShot
        
        value
      else
        false
    
    $mixin f, Batman.Event
  
  # Use a one shot event for something that only fires once. Any observers
  # added after it has already fired will simply be executed immediately.
  eventOneShot: (callback) ->
    f = Batman.EventEmitter.event.apply @, arguments
    f.isOneShot = yes
    
    f
}

###
# Batman.Object
###

class Batman.Object
  # Setting `isGlobal` to true will cause the class name to be defined on the
  # global object. For example, Batman.Model will be aliased to window.Model.
  # You should use this sparingly; it's mostly useful for debugging.
  @global: (isGlobal) ->
    return if isGlobal is false
    global[@name] = @
    
  # Apply mixins to this subclass.
  @mixin: (mixins...) ->
    $mixin @, mixins...
  
  # Apply mixins to instances of this subclass.
  mixin: (mixins...) ->
    $mixin @, mixins...
  
  constructor: (mixins...) ->
    # We mixin Batman.Observable to the prototype in order to construct fewer
    # pointers. However, we're still creating a new object, so we want to make
    # sure we reapply the Batman.Observable initializer.
    Batman.Observable.initialize.call @
    
    @mixin mixins...
  
  # Make every subclass and their instances observable.
  @mixin Batman.Observable, Batman.EventEmitter
  @::mixin Batman.Observable

###
# Batman.App
###

class Batman.App extends Batman.Object
  # Require path tells the require methods which base directory to look in.
  @requirePath: ''
  
  # The require class methods (`controller`, `model`, `view`) simply tells
  # your app where to look for coffeescript source files. This
  # implementation may change in the future.
  @_require: (path, names...) ->
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
          # FIXME
          @get 'run'
  
  @controller: (names...) ->
    @_require 'controllers', names...
  
  @model: (names...) ->
    @_require 'models', names...
    
  @view: (names...) ->
    @_require 'views', names...
  
  # Layout is your base view that other views can be yielded into. The
  # default behavior is that when you call `app.run()`, a new view will
  # be created for the layout using the `document` node as its content.
  # User `MyApp.layout = null` to turn off the default behavior.
  @layout: undefined
  
  # Call `MyApp.run()` to actually start up your app. Batman level
  # initializers will be run to bootstrap your application.
  @run: @eventOneShot ->
    if typeof @layout is 'undefined'
      @set 'layout', new Batman.View node: document
    
    @startRouting()

###
# Routing
###

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
    if $typeOf(callback) is 'Function' then callbackEater(callback) else callbackEater
  
  redirect: (urlOrFunction) ->
    url = if urlOrFunction?.isRoute then urlOrFunction.pattern else urlOrFunction
    window.location.hash = "#{Batman.HASH_PATTERN}#{url}"

Batman.Object.route = $route = Batman.route
Batman.Object.redirect = $redirect = Batman.redirect

$mixin Batman.App,
  startRouting: ->
    return if not Batman._routes.length
    f = ->
      Batman._routes[0]()
    
    addEventListener 'hashchange', f
    if window.location.hash.length <= 1 then $redirect('/') else f()
  
  root: (callback) ->
    $route '/', callback

###
# Batman.Controller
###

class Batman.Controller extends Batman.Object
  @isController: yes
  
  @_sharedInstance: null
  @sharedInstance: ->
    @_sharedInstance = new @ if not @_sharedInstance
    @_sharedInstance
  
  @dispatch: (route, params...) ->
    @actionTaken = no
    
    result = route.action.call @, params...
    key = Batman._findName route, @prototype
    
    if not @actionTaken
      new Batman.View source: ""
    
    delete @actionTaken

###
# Batman.Model
###

class Batman.Model extends Batman.Object
  @persist: (mechanism) ->
    

###
# Batman.View
###

class Batman.View extends Batman.Object
  source: ''
  html: ''
  
  node: null
  contentFor: null
  
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
      
      @node = null # FIXME: is this still necessary?
      @set 'node', node
  
  @::observe 'node', (node) ->
    Batman.DOM.parseNode node

###
# DOM helpers
###

Batman.DOM = {
  parseNode: ->
}

###
# Batman.Request
###

class Batman.Request extends Batman.Object
  url: ''
  data: ''
  method: 'get'
  
  response: null
  
  @::observe 'url', ->
    setTimeout (=> @send()), 0
  
  loading: @event ->
  loaded: @event ->
  
  success: @event ->
  error: @event ->

# Export a few globals.
global = exports ? this
global.Batman = Batman

# Optionally export global sugar. Not sure what to do with this.
Batman.exportGlobals = ->
  global.$typeOf = $typeOf
  global.$mixin = $mixin
  global.$unmixin = $unmixin
  global.$route = $route
  global.$redirect = $redirect
