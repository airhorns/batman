`if (typeof window !== 'undefined') {
/*!
  * Reqwest! A x-browser general purpose XHR connection manager
  * copyright Dustin Diaz 2011
  * https://github.com/ded/reqwest
  * license MIT
  */
!function(context){function reqwest(a,b){return new Reqwest(a,b)}function init(o,fn){function error(a){o.error&&o.error(a),complete(a)}function success(resp){o.timeout&&clearTimeout(self.timeout)&&(self.timeout=null);var r=resp.responseText;switch(type){case"json":resp=eval("("+r+")");break;case"js":resp=eval(r);break;case"html":resp=r}fn(resp),o.success&&o.success(resp),complete(resp)}function complete(a){o.complete&&o.complete(a)}this.url=typeof o=="string"?o:o.url,this.timeout=null;var type=o.type||setType(this.url),self=this;fn=fn||function(){},o.timeout&&(this.timeout=setTimeout(function(){self.abort(),error()},o.timeout)),this.request=getRequest(o,success,error)}function setType(a){if(/\.json$/.test(a))return"json";if(/\.js$/.test(a))return"js";if(/\.html?$/.test(a))return"html";if(/\.xml$/.test(a))return"xml";return"js"}function Reqwest(a,b){this.o=a,this.fn=b,init.apply(this,arguments)}function getRequest(a,b,c){var d=xhr();d.open(a.method||"GET",typeof a=="string"?a:a.url,!0),setHeaders(d,a),d.onreadystatechange=readyState(d,b,c),a.before&&a.before(d),d.send(a.data||null);return d}function setHeaders(a,b){var c=b.headers||{};c.Accept="text/javascript, text/html, application/xml, text/xml, */*";if(b.data){c["Content-type"]="application/x-www-form-urlencoded";for(var d in c)c.hasOwnProperty(d)&&a.setRequestHeader(d,c[d],!1)}}function readyState(a,b,c){return function(){a&&a.readyState==4&&(twoHundo.test(a.status)?b(a):c(a))}}var twoHundo=/^20\d$/,xhr="XMLHttpRequest"in window?function(){return new XMLHttpRequest}:function(){return new ActiveXObject("Microsoft.XMLHTTP")};Reqwest.prototype={abort:function(){this.request.abort()},retry:function(){init.call(this,this.o,this.fn)}};var old=context.reqwest;reqwest.noConflict=function(){context.reqwest=old;return this},context.reqwest=reqwest}(this)

//Lightweight JSONP fetcher - www.nonobtrusive.com
var JSONP=(function(){var a=0,c,f,b,d=this;function e(j){var i=document.createElement("script"),h=false;i.src=j;i.async=true;i.onload=i.onreadystatechange=function(){if(!h&&(!this.readyState||this.readyState==="loaded"||this.readyState==="complete")){h=true;i.onload=i.onreadystatechange=null;if(i&&i.parentNode){i.parentNode.removeChild(i)}}};if(!c){c=document.getElementsByTagName("head")[0]}c.appendChild(i)}function g(h,j,k){f="?";j=j||{};for(b in j){if(j.hasOwnProperty(b)){f+=encodeURIComponent(b)+"="+encodeURIComponent(j[b])+"&"}}var i="json"+(++a);d[i]=function(l){k(l);d[i]=null;try{delete d[i]}catch(m){}};e(h+f+"callback="+i);return i}return{get:g}}());
}`

###
batman
###

$bind = (me, f) ->
  -> f.apply(me, arguments)

Batman = (objects...) ->
  new Batman.Object objects...

toString = Object.prototype.toString
Batman.typeOf = (obj) ->
  toString.call(obj).slice(8, -1)

$mixin = Batman.mixin = (to, objects...) ->
  set = if to.set then $bind(to, to.set) else null
  for object in objects
    continue if Batman.typeOf(object) isnt 'Object'

    for key, value of object
      if set then set(key, value) else to[key] = value

    if typeof object.initialize is 'function'
      object.initialize.call to

  to

Batman.unmixin = (from, objects...) ->
  for object in objects
    for key of object
      from[key] = null
      delete from[key]

  from

$event = Batman.event = (original) ->
  f = (handler) ->
    observers = f._observers
    if Batman.typeOf(handler) is 'Function'
      if f.oneShot && f.lastFire?
        handler.apply(@, f.lastFire)
      else
        observers.push(handler) if observers.indexOf(handler) is -1
      @
    else
      result = original.apply @, arguments
      f.lastFire = arguments
      return false if result is false

      observer.apply(@, arguments) for observer in observers
      result

  f.isEvent = yes
  f.oneShot = false
  f.action = original
  f._observers = []
  f

$event.oneShot = (x) ->
  e = $event(x)
  e.oneShot = true
  e

Batman.Observable = {
  initialize: ->
    @_observers = {}

  get: (key) ->
    if arguments.length > 1
      results = for thisKey in arguments
        @get thisKey
      return results

    index = key.indexOf '.'
    if index isnt -1
      next = @get(key.substr(0, index))
      nextKey = key.substr(index + 1)
      return if next and next.get then next.get(key.substr(index + 1)) else @methodMissing(key.substr(0, key.indexOf('.', index + 1)))

    value = @[key]
    if typeof value is 'undefined'
      @methodMissing key
    else if value and value.isProperty
      value.call @
    else
      value

  set: (key, value) ->
    if (l = arguments.length) > 2
      results = for i in [0...l] by 2
        @set arguments[i], arguments[i+1]
      return results

    index = key.lastIndexOf '.'
    if index isnt -1
      # next = @get(key.substr(0, index))
      # return if next and next.set then next.set(key.substr(index + 1), value) else @methodMissing(key.substr(0, key.indexOf('.', index + 1)))
      FIXME_firstObject = @get(key.substr(0, index))
      FIXME_lastPath = key.substr(index + 1)
      return FIXME_firstObject.set(FIXME_lastPath, value)

    oldValue = @[key]

    if oldValue isnt value
      @fire "#{key}:before", value, oldValue

      if typeof oldValue is 'undefined'
        @methodMissing key, value
      else if oldValue and oldValue.isProperty
        oldValue.call @, value
      else
        @[key] = value

      @fire(key, value, oldValue)

    value

  unset: (key) ->
    if typeof @[key] is 'undefined'
      @methodMissing('unset:' + key)
    else
      @[key] = null
      delete @[key]

  observe: (key, fireImmediately, callback) ->
    if typeof fireImmediately is 'function'
      callback = fireImmediately
      fireImmediately = no

    if (index = key.lastIndexOf('.')) is -1
      array = @_observers[key] ||= []
      array.push(callback)# if array and array.indexOf(callback) is -1
    else if false
      thisObject = @
      callback._recursiveObserver = recursiveObserver = =>
        @forget(key, callback)
        @observe(key, yes, callback)

      for thisKey in key.split('.')
        break if not thisObject or not thisObject.observe
        thisObject.observe(thisKey, recursiveObserver)
        thisObject = thisObject.get(thisKey)
    else
      FIXME_firstPath = key.substr(0, index)
      FIXME_lastPath = key.substr(index + 1)
      FIXME_object = @get(FIXME_firstPath)
      FIXME_object?.observe(FIXME_lastPath, callback)

    if fireImmediately
      callback(@get(key))

    @

  forget: (key, callback) ->
    index = key.lastIndexOf('.')
    if index is -1
      array = @_observers[key]
      array.splice(array.indexOf(callback), 1)# if array and array.indexOf(callback) isnt -1
    else if false
      thisObject = @
      recursiveObserver = callback._recursiveObserver

      for thisKey in key.split('.')
        break if not thisObject or not thisObject.forget
        thisObject.forget(thisKey, recursiveObserver)
        thisObject = thisObject.get(thisKey)
    else
      FIXME_object = @get(key.substr(0, index))
      FIXME_object.forget(key.substr(index + 1), callback)

    @

  fire: (key, value, oldValue) ->
    observers = @_observers[key]
    (callback.call(@, value, oldValue) if callback) for callback in observers if observers
    @

  methodMissing: (key, value) ->
    if (key.indexOf('unset:') isnt -1)
      key = key.substr(6)
      @[key] = null
      delete @[key]
    else if arguments.length > 1
      @[key] = value

    @[key]
}

class Batman.Object
  @property: (original) ->
    f = (value) ->
      result = original.apply @, arguments if typeof original is 'function'
      f.value = result || value if arguments.length
      result || f.value

    f.value = original if typeof original isnt 'function'

    f.isProperty = yes
    f._observers = []
    f.observe = (observer) ->
      observers = f._observers
      observers.push(observer) if observers.indexOf(observer) is -1
      f

    f

  @global: (isGlobal) ->
    return if isGlobal is no

    Batman.mixin @, Batman.Observable
    @isClass = yes

    global[@name] = @

  constructor: (properties...) ->
    Batman.Observable.initialize.call @

    for key, value of @
      if value and value.isProperty
        observers = value._observers
        @observe(key, observer) for observer in observers
      else if value and value.isEvent
        @[key] = $event value.action

    Batman.mixin @, properties...

  Batman.mixin @::, Batman.Observable

class Batman.DataStore extends Batman.Object
  constructor: ->
    super
    @_data = {}

    now?.receiveSync = (data) =>
      @_data = data
      @_syncing = no

  needsSync: ->
    return if @_syncing
    if @_syncTimeout
      clearTimeout @_syncTimeout

    @_syncTimeout = setTimeout $bind(@, @sync), 1000

  sync: ->
    return if @_syncing
    if @_syncTimeout
      @_syncTimeout = clearTimeout @_syncTimeout

    @_syncing = yes
    now?.sendSync(@_data)

  query: (conditions, options) ->
    conditions ||= {}
    options ||= {}

    limit = options.limit

    results = {}
    numResults = 0

    for id, record of @_data
      match = yes
      for key, value of conditions
        if record[key] isnt value
          match = no
          break

      if match
        results[id] = record
        numResults++

        return results if limit and numResults >= limit

    results

  methodMissing: (key, value) ->
    if key.indexOf('unset:') is 0
      key = key.substr(6)
      @_data[key] = null
      delete @_data[key]
    else if arguments.length > 1
      @_data[key] = value

    @_data[key]

class Batman.App extends Batman.Object
  # route matching courtesy of Backbone
  namedParam = /:([\w\d]+)/g
  splatParam = /\*([\w\d]+)/g
  namedOrSplat = /[:|\*]([\w\d]+)/g
  escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

  @match: (url, action) ->
    routes = @::_routes ||= []
    match = url.replace(escapeRegExp, '\\$&')
    regexp = new RegExp('^' + match.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + '$')
    namedArguments = []

    while (array = namedOrSplat.exec(match))?
      namedArguments.push(array[1]) if array[1]

    routes.push match: match, regexp: regexp, namedArguments: namedArguments, action: action

  @root: (action) ->
    @match '/', action

  @_require: (path, names...) ->
    @global yes
    
    for name in names
      @_notReady()
      new Batman.Request(type: 'html', url: "#{path}/#{name}.coffee").success (coffee) =>
        @_ready()
        CoffeeScript.eval coffee
    @

  @controller: (names...) ->
    @_require 'controllers', names...

  @model: (names...) ->
    @_require 'models', names...

  @_notReady: ->
    @_notReadyCount ||= 0
    @_notReadyCount++

  @_ready: ->
    @_notReadyCount--
    @run() if @_ranBeforeReady

  @run: ->
    if SharedApp?
      throw "An app is already running!"
    
    if @_notReadyCount > 0
      @_ranBeforeReady = yes
      return false
    
    @global yes
    
    app = new @()
    @sharedApp = app
    global.SharedApp = app
    
    app.run()

  run: ->
    new Batman.View context: global, node: document.body

    if @_routes?.length
      # for className, controller of @constructor
        # if controller instanceof Batman.Controller

      @startRouting()

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

    if Batman.typeOf(action) is 'String'
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

    params

  controller: (className) ->
    controllers = @_controllers ||= {}
    controller = controllers[className]

    if not controller
      controllerClass = @constructor[className]
      controller = controllers[className] = new controllerClass
      controllerClass.sharedInstance = controller

    controller

Batman.redirect = (url) ->
  SharedApp.redirect url

class Batman.Controller extends Batman.Object
  @match: (url, action) ->
    SharedApp.match url, controller: @, action: action

  @beforeFilter: (action, options) ->
    # FIXME

  redirect: (url) ->
    @_actedDuringAction = yes
    Batman.redirect url

  render: (options) ->
    @_actedDuringAction = yes
    options ||= {}

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
        if Batman.typeOf(value) is 'Array'
          value.push = push(key, value)

      $mixin global, m
      view.ready ->
        Batman.DOM.contentFor('main', view.get('node'))
        Batman.unmixin(global, m)

class Batman.View extends Batman.Object
  source: @property().observe (path) ->
    if path
      new Batman.Request({url: path}).success (data) =>
        @_cachedSource = data

        node = document.createElement 'div'
        node.innerHTML = data
        @set 'node', node

  node: @property().observe (node) ->
    if node
      Batman.DOM.parseNode(node, @context || @)
      @ready()

  ready: $event.oneShot ->

  methodMissing: (key, value) ->
    return super if not @context
    if arguments.length > 1
      @context.set key, value
    else
      @context.get key

FIXME_id = 0

class Batman.Model extends Batman.Object
  @_makeRecords: (ids) ->
    cached = @_cachedRecords ||= {}
    for id, record of ids
      r = cached[id] || (cached[id] = new @({id: id}))
      $mixin r, record

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

  @validate: (f) ->


  @validatesLengthOf: (key, options) ->
    @validate =>


  @timestamps: (useTimestamps) ->
    return if useTimestamps is off
    @::createdAt = null
    @::updatedAt = null

  @persist: (mixin) ->
    if mixin is Batman
      f = =>
        FIXME_id = (+(@last().get('id')) || 0) + 1
      setTimeout f, 1000

  @all: @property ->
    @_makeRecords App.dataStore.query({model: @name})

  @first: @property ->
    @_makeRecords(App.dataStore.query({model: @name}, {limit: 1}))[0]

  @last: @property ->
    array = @_makeRecords(App.dataStore.query({model: @name}))
    array[array.length - 1]

  @find: (id) ->
    @_makeRecords(App.dataStore.query({model: @name, id: ''+id}))[0]

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

  set: (key, value) ->
    if arguments.length > 2
      return super

    @_data[key] = super

  reload: =>

  save: =>
    if not @id
      @id = ''+(FIXME_id++)
      oldAll = @constructor.get('all')
    else
      @id += ''

    App.dataStore.set(@id, Batman.mixin(@toJSON(), {id: @id, model: @constructor.name}))
    App.dataStore.needsSync()

    @constructor.fire('all', @constructor.get('all'), oldAll) if oldAll
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

class Batman.Request extends Batman.Object
  method: 'get'
  data: ''
  response: ''

  url: @property (url) ->
    if url
      @_url = url
      setTimeout($bind(@, @send), 0)

    @_url

  send: (data) ->
    options = {
      url: @get 'url'
      method: @get 'method'
      success: (resp) =>
        @set 'response', resp
        @success resp
      failure: (error) =>
        @set 'response', error
        @error error
    }

    data ||= @get 'data'
    options.data = data if data

    type = @get 'type'
    options.type = type if type

    @_request = reqwest options
    @

  success: $event (data) ->

  error: $event (error) ->

class Batman.JSONPRequest extends Batman.Request
  send: (data) ->
    JSONP.get @get('url'), @get('data') || {}, (data) =>
      @set 'response', data
      @success data

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

    content = Batman.DOM._yieldContents?[name]
    node.innerHTML = ''
    node.appendChild(content) if content

  contentFor: (name, node) ->
    contents = Batman.DOM._yieldContents ||= {}
    contents[name] = node

    yield = Batman.DOM._yields?[name]
    yield.innerHTML = ''
    yield.appendChild(node) if yield

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
    else
      if isSetting then node.innerHTML = value else node.innerHTML

  addEventListener: (node, eventName, callback) ->
    if node.addEventListener
      node.addEventListener eventName, callback
    else
      node.attachEvent "on#{eventName}", callback

    callback
}

Batman.mixins = {
  animation: {
    initialize: ->
      @style.display = 'block'

    show: (appendTo) ->
      style = @style
      cachedWidth = @scrollWidth
      cachedHeight = @scrollHeight

      style.webkitTransition = ''
      style.width = 0
      style.height = 0
      style.opacity = 0

      style.webkitTransition = 'all 0.5s ease-in-out'
      style.opacity = 1
      style.width = cachedWidth + 'px'
      style.height = cachedHeight + 'px'

      f = =>
        style.webkitTransition = ''
        appendTo.appendChild(@) if appendTo
      setTimeout f, 450

    hide: (remove)->
      style = @style
      style.overflow = 'hidden'
      style.webkitTransition = 'all 0.5s ease-in-out'
      style.opacity = 0
      style.width = 0
      style.height = 0

      f = =>
        style.webkitTransition = ''
        @parentNode.removeChild(@) if remove
      setTimeout f, 450
  }

  editable: {
    initialize: ->
      Batman.DOM.addEventListener @, 'click', $bind(@, @startEditing)

    startEditing: ->
      return if @isEditing
      if not @editor
        editor = @editor = document.createElement 'input'
        editor.type = 'text'
        editor.className = 'editor'

        Batman.DOM.events.submit editor, =>
          @commit()
          @stopEditing()

      @_originalDisplay = @style.display
      @style.display = 'none'

      @isEditing = yes
      @editor.value = Batman.DOM.valueForNode @

      @parentNode.insertBefore @editor, @
      @editor.focus()
      @editor.select()

      @editor

    stopEditing: ->
      return if not @isEditing
      @style.display = @_originalDisplay
      @editor.parentNode.removeChild @editor

      @isEditing = no

    commit: ->
      @_bindingContext?.set?(@_bindingKey, @editor.value)
  }
}

global = exports ? this
global.Batman = Batman
global.$mixin = Batman.mixin
global.$bind = $bind
global.$event = $event

$mixin global, Batman.Observable
