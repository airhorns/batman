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
    if not @hasOwnProperty '_observers'
      @_observers = {}
  
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
      @fire key, value, oldValue
  
  unset: (key) ->
    oldValue = @[key]
    if oldValue and oldValue.unset
      oldValue.unset key, @
    else
      @[key] = null
      delete @[key]
      
      @fire key, oldValue
  
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
  fire: (key, value, oldValue) ->
    # Batman._observerClassHack.call @ # allowed will call this already
    return if not @allowed key
    
    if typeof value is 'undefined'
      value = @get key
    
    for observers in [@_observers[key], @constructor::_observers?[key]]
      (callback.call(@, value, oldValue) if callback) for callback in observers if observers
    
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
# Batman.Deferred
# Test Code - what is it useful for?
###

class Batman.Deferred extends Batman.Object
  @::mixin Batman.EventEmitter
  
  constructor: (original = ->) ->
    @success = $event.oneShot(original)
    @failure = $event.oneShot(original)
    @all     = $event.oneShot(original)

    @resolved = false
    @rejected = false
  
  then: (f) ->
    @all f 
    @
  always: () ->
    @then(arguments...)
  done: (f) ->
    @success f
    @
  fail: (f) ->
    @failure f
    @
  
  resolve: (resolution) ->
    @resolved = true
    @rejected = false
    @success resolution
    @all resolution
    @
  
  reject: (failResolution) ->
    @resolved = true
    @rejected = true
    @failure failResolution
    @all failResolution
    @

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
    return if not Batman._routes.length
    f = ->
      Batman._routes[0]()
    
    addEventListener 'hashchange', f
    if window.location.hash.length <= 1 then $redirect('/') else f()
  
  root: (callback) ->
    $route '/', callback

###
  @match: (url, action) ->
    routes = @::_routes ||= []
    match = url.replace(escapeRegExp, '\\$&')
    regexp = new RegExp('^' + match.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + '$')
    namedArguments = []

    while (array = namedOrSplat.exec(match))?
      namedArguments.push(array[1]) if array[1]

    routes.push match: match, regexp: regexp, namedArguments: namedArguments, action: action
  
  startRouting: ->
    return if typeof window is 'undefined'

    parseUrl = =>
      hash = window.location.hash.replace(@routePrefix, '')
      return if hash is @_cachedRoute

      @_cachedRoute = hash
      @dispatch hash

    window.location.hash = @routePrefix + '/' if not window.location.hash
    setTimeout(parseUrl, 0)

    if 'onhashchange' of window
      @_routeHandler = parseUrl
      window.addEventListener 'hashchange', parseUrl
    else
      @_routeHandler = setInterval(parseUrl, 100)

  stopRouting: ->
    if 'onhashchange' of window
      window.removeEventListener 'hashchange', @_routeHandler
      @_routeHandler = null
    else
      @_routeHandler = clearInterval @_routeHandler

  match: (url, action) ->
    Batman.App.match.apply @constructor, arguments

  routePrefix: '#!'
  redirect: (url) ->
    @_cachedRoute = url
    window.location.hash = @routePrefix + url
    @dispatch url

  dispatch: (url) ->
    route = @_matchRoute url
    if not route
      @redirect '/404' unless url is '/404'
      return

    params = @_extractParams url, route
    action = route.action
    return unless action

    if typeOf(action) is 'String'
      components = action.split '.'
      controllerName = helpers.camelize(components[0] + 'Controller')
      actionName = helpers.camelize(components[1], true)

      controller = @controller controllerName
    else if typeof action is 'object'
      controller = @controller action.controller?.name || action.controller
      actionName = action.action

    controller._actedDuringAction = no
    controller._currentAction = actionName

    controller[actionName](params)
    controller.render() if not controller._actedDuringAction

    delete controller._actedDuringAction
    delete controller._currentAction

  _matchRoute: (url) ->
    routes = @_routes
    for route in routes
      return route if route.regexp.test(url)

    null

  _extractParams: (url, route) ->
    array = route.regexp.exec(url).slice(1)
    params = url: url

    for param in array
      params[route.namedArguments[_i]] = param
###


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
# DOM Helpers
###

Batman.DOM = {
  attributes: {
    bind: (string, node, context, observer) ->
      observer ||= (value) -> Batman.DOM.valueForNode(node, value)

      if (index = string.lastIndexOf('.')) isnt -1
        FIXME_firstPath = string.substr(0, index)
        FIXME_lastPath = string.substr(index + 1)
        FIXME_firstObject = context.get(FIXME_firstPath)

        FIXME_firstObject?.observe FIXME_lastPath, yes, observer
        Batman.DOM.events.change node, (value) -> FIXME_firstObject.set(FIXME_lastPath, value)

        node._bindingContext = FIXME_firstObject
        node._bindingKey = FIXME_lastPath
        node._bindingObserver = observer
      else
        context.observe string, yes, observer
        Batman.DOM.events.change node, (value) -> context.set(key, value)

        node._bindingContext = context
        node._bindingKey = string
        node._bindingObserver = observer

      return

    visible: (string, node, context) ->
      original = node.style.display
      Batman.DOM.attributes.bind string, node, context, (value) ->
        node.style.display = if !!value then original else 'none'

    mixin: (string, node, context) ->
      mixin = Batman.mixins[string]
      $mixin(node, mixin) if mixin

    yield: (string, node, context) ->
      Batman.DOM.yield string, node

    contentfor: (string, node, context) ->
      Batman.DOM.contentFor string, node
  }

  keyBindings: {
    bind: (key, string, node, context) ->
      Batman.DOM.attributes.bind string, node, context, (value) ->
        node[key] = value

    foreach: (key, string, node, context) ->
      prototype = node.cloneNode true
      prototype.removeAttribute "data-foreach-#{key}"

      placeholder = document.createElement 'span'
      placeholder.style.display = 'none'
      node.parentNode.replaceChild placeholder, node

      nodes = []
      context.observe string, true, (array) ->
        nodesToRemove = []
        for node in nodes
          nodesToRemove.push(node) if array.indexOf(node._eachItem) is -1

        for node in nodesToRemove
          nodes.splice(nodes.indexOf(node), 1)
          Batman.DOM.forgetNode(node)

          if typeof node.hide is 'function' then node.hide(true) else node.parentNode.removeChild(node)

        for object in array
          continue if not object

          node = nodes[_k]
          continue if node and node._eachItem is object

          context[key] = object

          node = prototype.cloneNode true
          node._eachItem = object

          node.style.opacity = 0
          Batman.DOM.parseNode(node, context)

          placeholder.parentNode.insertBefore(node, placeholder)
          nodes.push(node)

          if node.show
            f = ->
              node.show()
            setTimeout f, 0
          else
            node.style.opacity = 1

          context[key] = null
          delete context[key]

        @

      false

    event: (key, string, node, context) ->
      if key is 'click' and node.nodeName.toUpperCase() is 'A'
        node.href = '#'

      if handler = Batman.DOM.events[key]
        callback = context.get(string)
        if typeof callback is 'function'
          handler node, (e...) ->
            callback(e...)

      return

    class: (key, string, node, context) ->
      context.observe string, true, (value) ->
        className = node.className
        node.className = if !!value then "#{className} #{key}" else className.replace(key, '')
      return

    formfor: (key, string, node, context) ->
      context.set(key, context.get(string))

      Batman.DOM.addEventListener node, 'submit', (e) ->
        Batman.DOM.forgetNode(node)
        context.unset(key)

        Batman.DOM.parseNode(node, context)

        e.preventDefault()

      return ->
        context.unset(key)
  }

  events: {
    change: (node, callback) ->
      nodeName = node.nodeName.toUpperCase()
      nodeType = node.type?.toUpperCase()

      eventName = 'change'
      eventName = 'keyup' if (nodeName is 'INPUT' and nodeType is 'TEXT') or nodeName is 'TEXTAREA'

      Batman.DOM.addEventListener node, eventName, (e...) ->
        callback Batman.DOM.valueForNode(node), e...

    click: (node, callback) ->
      Batman.DOM.addEventListener node, 'click', (e) ->
        callback.apply @, arguments
        e.preventDefault()

    submit: (node, callback) ->
      nodeName = node.nodeName.toUpperCase()
      if nodeName is 'FORM'
        Batman.DOM.addEventListener node, 'submit', (e) ->
          callback.apply @, arguments
          e.preventDefault()
      else if nodeName is 'INPUT'
        Batman.DOM.addEventListener node, 'keyup', (e) ->
          if e.keyCode is 13
            callback.apply @, arguments
            e.preventDefault()
  }

  yield: (name, node) ->
    yields = Batman.DOM._yields ||= {}
    yields[name] = node

    if content = Batman.DOM._yieldContents?[name]
      node.innerHTML = ''
      node.appendChild(content)

  contentFor: (name, node) ->
    contents = Batman.DOM._yieldContents ||= {}
    contents[name] = node

    if yield = Batman.DOM._yields?[name]
      yield.innerHTML = ''
      yield.appendChild(node)

  parseNode: (node, context) ->
    return if not node
    continuations = null

    if typeof node.getAttribute is 'function'
      for attribute in node.attributes # FIXME: get data-attributes only if possible
        key = attribute.nodeName
        continue if key.substr(0,5) isnt 'data-'

        key = key.substr(5)
        value = attribute.nodeValue

        result = if (index = key.indexOf('-')) isnt -1 and (binding = Batman.DOM.keyBindings[key.substr(0, index)])
          binding key.substr(index + 1), value, node, context
        else if binding = Batman.DOM.attributes[key]
          binding(value, node, context)

        if result is false
          return
        else if typeof result is 'function'
          continuations ||= []
          continuations.push(result)

    for child in node.childNodes
      Batman.DOM.parseNode(child, context)

    if continuations
      c() for c in continuations

    return

  forgetNode: (node) ->
    return
    return if not node
    if node._bindingContext and node._bindingObserver
      node._bindingContext.forget?(node._bindingKey, node._bindingObserver)

    for child in node.childNodes
      Batman.DOM.forgetNode(child)

  valueForNode: (node, value) ->
    nodeName = node.nodeName.toUpperCase()
    nodeType = node.type?.toUpperCase()
    isSetting = arguments.length > 1
    value ||= '' if isSetting

    return if isSetting and value is Batman.DOM.valueForNode(node)

    if nodeName in ['INPUT', 'TEXTAREA', 'SELECT']
      if nodeType is 'CHECKBOX'
        if isSetting then node.checked = !!value else !!node.checked
      else
        if isSetting then node.value = value else node.value
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
