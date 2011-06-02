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

Batman._initializeObject = (object) ->
  if object.prototype and object._batman?.__initClass__ isnt @
    object._batman = {__initClass__: @}
  else if not object.hasOwnProperty '_batman'
    o = {}
    
    if object._batman
      for key, value of object._batman
        value = Array.prototype.slice.call(value) if $typeOf(value) is 'Array'
        o[key] = value
    
    object._batman = o

Batman._findName = (f, context) ->
  if not f.displayName
    for key, value of context
      if value is f
        f.displayName = key
        break
  
  f.displayName

###
# Batman.Keypath
###

# Batman.Keypath represents a keypath on a particular Batman object.
class Batman.Keypath
  constructor: (base, string) ->
    @base = base
    @string = string
    
  eachPartition: (f) ->
    segments = @segments()
    for index in [0...segments.length]
      f(segments.slice(0,index).join('.'), segments.slice(index).join('.'))
  
  eachKeypath: (f) ->
    for index in [0...@segments().length]
      keypath = @keypathAt(index)
      break unless keypath
      f(keypath, index)
  
  eachValue: (f) ->
    for index in [0...@segments().length]
      f(@valueAt(index), index)
      
  keypathAt: (index) ->
    segments = @segments()
    return if index >= segments.length or index < 0 or not @base.get
    return @ if index == 0
    obj = @base.get(segments.slice(0, index).join('.'))
    return unless obj and obj.get
    remainingKeypath = segments.slice(index).join('.')
    new Batman.Keypath obj, remainingKeypath
  
  valueAt: (index) ->
    segments = @segments()
    return if index >= segments.length or index < 0 or not @base.get
    @base.get(segments.slice(0, index+1).join('.'))
    
  segments: ->
    @string.split('.')
  
  get: ->
    @base.get(@string)

###
# Batman.Observable
###

# Batman.Observable is a generic mixin that can be applied to any object in
# order to make that object bindable. It is applied by default to every
# instance of Batman.Object and subclasses.
Batman.Observable = {
  keypath: (string) ->
    new Batman.Keypath(@, string)
  
  get: (key) ->
    value = @[key]
  
  set: (key, value) ->
    oldValue = @get key
    newValue = @[key] = value
    
    @fire key, newValue, oldValue unless newValue is oldValue
  
  unset: (key) ->
    oldValue = @[key]
    @[key] = null
    delete @[key]
    
    @fire key, oldValue
  
  # Pass a key and a callback. Whenever the value for that key changes, your
  # callback will be called in the context of the original object.
  observe: (wholeKeypathString, fireImmediately, callback) ->
    Batman._initializeObject @
    @_batman.observers ||= {}
    
    if not callback
      callback = fireImmediately
      fireImmediately = no
    
    wholeKeypath = @keypath(wholeKeypathString)
    
    keyObservers = @_batman.observers[wholeKeypathString] ||= []
    keyObservers.push(callback)
    
    self = @
    if wholeKeypath.segments().length > 1
      callback._triggers = []
      callback._refresh_triggers = ->
        wholeKeypath.eachKeypath (keypath, index) ->
          segments = keypath.segments()
          if trigger = callback._triggers[index]
            keypath.base.forget(segments[0], trigger)
          trigger = (value, oldValue) ->
            if segments.length > 1 and oldKeypath = oldValue.keypath?(segments.slice(1).join('.'))
              oldKeypath.eachKeypath (k, i) ->
                absoluteIndex = index + i
                console.log "forgetting trigger at '"+k.segments()[0]+"' for '"+wholeKeypathString+"'"
                k.base.forget(k.segments()[0], callback._triggers[index + i])
              callback._refresh_triggers(index)
              oldValue = oldKeypath.get()
            callback.call self, self.get(wholeKeypathString), oldValue
          console.log "adding trigger to '"+segments[0]+"' for '"+wholeKeypathString+"'"
          callback._triggers[index] = trigger
          keypath.base.observe?(segments[0], trigger)
      
      callback._refresh_triggers()
      callback._forgotten = =>
        wholeKeypath.eachKeypath (keypath, index) =>
          if trigger = callback._triggers[index]
            console.log "forgetting trigger at '"+keypath.segments()[0]+"' for '"+wholeKeypathString+"'"
            keypath.base.forget(keypath.segments()[0], trigger)
            callback._triggers[index] = null
      
    if fireImmediately
      value = @get wholeKeypathString
      callback value, value
    @
  
  # You normally shouldn't call this directly. It will be invoked by `set`
  # to inform all observers for `key` that `value` has changed.
  fire: (key, value, oldValue) ->
    # Batman._initializeObject @ # allowed will call this already
    return if not @allowed key
    
    if typeof value is 'undefined'
      value = @get key
    
    observers = @_batman.observers?[key]
    #for observers in [@_batman.observers?[key], @constructor::_batman?.observers?[key]]
    (callback.call(@, value, oldValue) if callback) for callback in observers if observers
    
    @
  
  # Forget removes an observer from an object. If the callback is passed in, 
  # its removed. If no callback but a key is passed in, all the observers on
  # that key are removed. If no key is passed in, all observers are removed.
  forget: (key, callback) ->
    Batman._initializeObject @
    @_batman.observers ||= {}
    
    if key
      if callback
        array = @_batman.observers[key]
        if array
          callbackIndex = array.indexOf(callback)
          array.splice(callbackIndex, 1) if array and callbackIndex isnt -1
          callback._forgotten?()
      else
        for o in @_batman.observers[key]
          o._forgotten?()
        @_batman.observers[key] = []
    else
      for k, ary of @_batman.observers
        for o in ary
          o._forgotten?()
      @_batman.observers = {}
    @
  
  # Prevent allows you to prevent a given binding from firing. You can
  # nest prevent counts, so three calls to prevent means you need to
  # make three calls to allow before you can fire observers again.
  prevent: (key) ->
    Batman._initializeObject @
    
    counts = @_batman.preventCounts ||= {}
    counts[key] ||= 0
    counts[key]++
    @
  
  # Unblocks a property for firing observers. Every call to prevent
  # must have a matching call to allow.
  allow: (key) ->
    Batman._initializeObject @
    
    counts = @_batman.preventCounts ||= {}
    counts[key]-- if counts[key] > 0
    @
  
  # Returns a boolean whether or not the property is currently allowed
  # to fire its observers.
  allowed: (key) ->
    Batman._initializeObject @
    
    !(@_batman.preventCounts?[key] > 0)
}

###
# Batman.Event
###

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
    
    $mixin f,
      isEvent: yes
  
  # Use a one shot event for something that only fires once. Any observers
  # added after it has already fired will simply be executed immediately.
  eventOneShot: (callback) ->
    $mixin Batman.EventEmitter.event.apply(@, arguments),
      isOneShot: yes
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
  
  @property: (foo) ->
    {}
  
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
          @run()
  
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
    
    #@startRouting()

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
    if $typeOf(callback) is 'Function' then callbackEater(callback) else callbackEater
  
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
###

class Batman.View extends Batman.Object
  source: ''
  html: ''
  
  node: null
  contentFor: null
  
  ready: @event ->
  
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
    new Batman.Renderer node, => @ready()

###
# Helpers
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

###
# DOM Helpers
###

class Batman.Renderer extends Batman.Object
  constructor: (@node, @callback) ->
    super
    setTimeout @start, 0
  
  start: =>
    @tree = {}
    @startTime = new Date
    @parseNode @node
  
  resume: =>
    console.log('resume')
    @startTime = new Date
    @parseNode @resumeNode
  
  finish: ->
    console.log('done')
    @startTime = null
    @callback()
  
  regexp = /data\-(.*)/
  
  parseNode: (node) ->
    if (new Date) - @startTime > 50
      console.log('stopping')
      @resumeNode = node
      setTimeout @resume, 0
      return
    
    if node.getAttribute
      for attr in node.attributes
        name = attr.nodeName
        console.log(node.nodeName, name, name.match(regexp))
    
    if (nextNode = @nextNode(node)) then @parseNode(nextNode) else @finish
  
  nextNode: (node) ->
    children = node.childNodes
    return children[0] if children?.length
    
    sibling = node.nextSibling
    return sibling if sibling
    
    nextParent = node
    while nextParent = nextParent.parentNode
      parentSibling = nextParent.nextSibling
      return parentSibling if parentSibling
    
    return
    

Batman.DOM = {
  readers: {
    
  }
  
  keyReaders: {
    
  }
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
