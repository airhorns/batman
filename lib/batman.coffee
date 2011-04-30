`
/*!
  * Reqwest! A x-browser general purpose XHR connection manager
  * copyright Dustin Diaz 2011
  * https://github.com/ded/reqwest
  * license MIT
  */
!function(context){function reqwest(a,b){return new Reqwest(a,b)}function init(o,fn){function error(a){o.error&&o.error(a),complete(a)}function success(resp){o.timeout&&clearTimeout(self.timeout)&&(self.timeout=null);var r=resp.responseText;switch(type){case"json":resp=eval("("+r+")");break;case"js":resp=eval(r);break;case"html":resp=r}fn(resp),o.success&&o.success(resp),complete(resp)}function complete(a){o.complete&&o.complete(a)}this.url=typeof o=="string"?o:o.url,this.timeout=null;var type=o.type||setType(this.url),self=this;fn=fn||function(){},o.timeout&&(this.timeout=setTimeout(function(){self.abort(),error()},o.timeout)),this.request=getRequest(o,success,error)}function setType(a){if(/\.json$/.test(a))return"json";if(/\.js$/.test(a))return"js";if(/\.html?$/.test(a))return"html";if(/\.xml$/.test(a))return"xml";return"js"}function Reqwest(a,b){this.o=a,this.fn=b,init.apply(this,arguments)}function getRequest(a,b,c){var d=xhr();d.open(a.method||"GET",typeof a=="string"?a:a.url,!0),setHeaders(d,a),d.onreadystatechange=readyState(d,b,c),a.before&&a.before(d),d.send(a.data||null);return d}function setHeaders(a,b){var c=b.headers||{};c.Accept="text/javascript, text/html, application/xml, text/xml, */*";if(b.data){c["Content-type"]="application/x-www-form-urlencoded";for(var d in c)c.hasOwnProperty(d)&&a.setRequestHeader(d,c[d],!1)}}function readyState(a,b,c){return function(){a&&a.readyState==4&&(twoHundo.test(a.status)?b(a):c(a))}}var twoHundo=/^20\d$/,xhr="XMLHttpRequest"in window?function(){return new XMLHttpRequest}:function(){return new ActiveXObject("Microsoft.XMLHTTP")};Reqwest.prototype={abort:function(){this.request.abort()},retry:function(){init.call(this,this.o,this.fn)}};var old=context.reqwest;reqwest.noConflict=function(){context.reqwest=old;return this},context.reqwest=reqwest}(this)
`

###
Batman
###

$bind = (me, f) ->
  -> f.apply(me, arguments)

Batman = (objects...) ->
  new Batman.Object objects...

toString = Object.prototype.toString
Batman.typeOf = (obj) ->
  toString.call(obj).slice(8, -1)

Batman.mixin = (to, objects...) ->
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
      observers.push(handler) if observers.indexOf(handler) is -1
      @
    else
      result = original.apply @, arguments
      return false if result is false
      
      observer.apply(@, arguments) for observer in observers
      result
  
  f.isEvent = yes
  f.action = original
  f._observers = []
  f

$event.oneShot = $event

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
    else if typeof value is 'function'
      value.call @
    else
      value
  
  set: (key, value) ->
    if arguments.length > 2
      results = for thisKey in arguments
        thisValue = arguments[++_i]
        @set thisKey, thisValue
      return results
    
    index = key.indexOf '.'
    if index isnt -1
      next = @get(key.substr(0, index))
      return if next and next.set then next.set(key.substr(index + 1), value) else @methodMissing(key.substr(0, key.indexOf('.', index + 1)))
    
    oldValue = @[key]
    
    if oldValue isnt value
      @fire "#{key}:before", value, oldValue
      
      if typeof oldValue is 'undefined'
        @methodMissing key, value
      else if typeof oldValue is 'function'
        oldValue.call @, value
      else
        @[key] = value
      
      @fire key, value, oldValue
    
    value
  
  observe: (key, fireImmediately, callback) ->
    if typeof fireImmediately is 'function'
      callback = fireImmediately
      fireImmediately = no
    
    index = key.indexOf('.')
    if index is -1
      array = @_observers[key] ||= []
      array.push(callback)# if array and array.indexOf(callback) is -1
    else
      thisObject = @
      callback._recursiveObserver = recursiveObserver = =>
        @forget(key, callback)
        @observe(key, yes, callback)
      
      for thisKey in key.split('.')
        break if not thisObject or not thisObject.observe
        thisObject.observe(thisKey, recursiveObserver)
        thisObject = thisObject.get(thisKey)
    
    if fireImmediately
      callback(@get(key))
    
    @
  
  forget: (key, callback) ->
    index = key.indexOf('.')
    if index is -1
      array = @_observers[key]
      array.splice(array.indexOf(callback), 1)# if array and array.indexOf(callback) isnt -1
    else
      thisObject = @
      recursiveObserver = callback._recursiveObserver
      
      for thisKey in key.split('.')
        break if not thisObject or not thisObject.forget
        thisObject.forget(thisKey, recursiveObserver)
        thisObject = thisObject.get(thisKey)
    
    @
  
  fire: (key, value, oldValue) ->
    observers = @_observers[key]
    callback.call(@, value, oldValue) for callback in observers if observers
    @
  
  methodMissing: (key, value) ->
    if arguments.length > 1
      @[key] = value
    
    @[key]
}

class Batman.Object
  @property: (defaultValue) ->
    f = (value) ->
      f.value = value if arguments.length
      f.value
    
    f.isProperty = yes
    f._observers = []
    f.observe = (observer) ->
      observers = f._observers
      observers.push(observer) if observers.indexOf(observer) is -1
      f
    
    f
  
  @global: (isGlobal) ->
    return if isGlobal is no
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

Batman.property = (orig) ->
  orig

class Batman.DataStore extends Batman.Object
  constructor: ->
    super
    @_data = {}
  
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
    if arguments.length > 1
      @_data[key] = value
    
    @_data[key]

# route matching courtesy of Backbone
namedParam = /:([\w\d]+)/g
splatParam = /\*([\w\d]+)/g
namedOrSplat = /[:|\*]([\w\d]+)/g
escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

class Batman.App extends Batman.Object
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
  
  @global: (isGlobal) ->
    return if isGlobal is false
    Batman.Object.global.apply @, arguments
    
    instance = new @
    @sharedApp = instance
    
    global.BATMAN_APP = instance
  
  constructor: ->
    super
    @dataStore = new Batman.DataStore
    
    @startRouting() if @_routes?.length
    
    layout = =>
      new Batman.View context: global, node: document.body
    
    setTimeout layout, 0
  
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
    window.location.hash = @_cachedRoute = @routePrefix + url
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
      controller[actionName](params)
  
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
  BATMAN_APP.redirect url

class Batman.Controller extends Batman.Object
  @match: (url, action) ->
    BATMAN_APP.match url, helpers.camelize(@name.replace('Controller', ''), true) + '.' + action
  
  @beforeFilter: (action, options) ->
    # FIXME
  
  render: (options) ->
    options ||= {}

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

class Batman.Model extends Batman.Object
  @_makeRecords: (ids) ->
    new @({id: id}, record) for id, record of ids
  
  @hasMany: (relation) ->
    model = helpers.camelize(helpers.singularize(relation))
    inverse = helpers.camelize(@name, yes)
    
    @::[relation] = ->
      query = model: model
      query[inverse + 'Id'] = @id
      BATMAN_APP[model]._makeRecords(BATMAN_APP.dataStore.query(query))
  
  @hasOne: (relation) ->
    
  
  @belongsTo: (relation) ->
    model = helpers.camelize(helpers.singularize(relation))
    key = helpers.camelize(model, yes) + 'Id'
    
    @::[relation] = (value) ->
      if arguments.length
        @[key] = if value and value.id then ''+value.id else ''+value
      
      BATMAN_APP[model]._makeRecords(BATMAN_APP.dataStore.query({model: model, id: @[key]}))[0]
  
  @timestamps: (useTimestamps) ->
    return if useTimestamps is off
    @::createdAt = null
    @::updatedAt = null
  
  @all: ->
    @_makeRecords BATMAN_APP.dataStore.query({model: @name})
  
  @one: ->
    @_makeRecords(BATMAN_APP.dataStore.query({model: @name}, {limit: 1}))[0]
  
  @find: (id) ->
    new @(BATMAN_APP.dataStore.get(id))
  
  constructor: ->
    @_data = {}
    super
  
  id: ''
  
  set: (key, value) ->
    if arguments.length > 2
      return super
    
    @_data[key] = super
  
  reload: ->
  
  save: ->
    @id ||= ''+Math.floor(Math.random() * 1000)
    BATMAN_APP.dataStore.set(@id, Batman.mixin(@toJSON(), {id: @id, model: @constructor.name}))
    @
  
  toJSON: ->
    @_data
  
  fromJSON: (data) ->
    Batman.mixin @, data

class Batman.Request extends Batman.Object
  method: 'get'
  data: ''
  
  url: (url) ->
    if url
      @_url = url
      setTimeout($bind(@, @send), 0)
    
    @_url
  
  send: (data) ->
    @_request = reqwest
      url: @get 'url'
      method: @get 'method'
      success: (resp) =>
        @set 'data', resp
        @success resp
      failure: (error) =>
        @set 'data', error
        @error error
    @
  
  success: $event (data) ->
  
  error: $event (error) ->

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
  
  pluralize: (string) ->
    if string.substr(-1) is 'y'
      "#{string.substr(0,string.length-1)}ies"
    else
      "#{string}s"
}

Batman.DOM = {
  attributes: {
    bind: (key, node, context) ->
      context.observe key, yes, (value) -> Batman.DOM.valueForNode(node, value)
      Batman.DOM.events.change node, (value) -> context.set(key, value)
  }
  
  events: {
    change: (node, callback) ->
      nodeName = node.nodeName.toUpperCase()
      nodeType = node.type?.toUpperCase()
      
      eventName = 'change'
      eventName = 'keyup' if (nodeName is 'INPUT' and nodeType is 'TEXT') or nodeName is 'TEXTAREA'
      
      Batman.DOM.addEventListener node, eventName, (e...) ->
        callback Batman.DOM.valueForNode(node), e...
  }
  
  parseNode: (node, context) ->
    return if not node
    
    if typeof node.getAttribute is 'function'
      for attribute in node.attributes # FIXME: get data-attributes only if possible
        key = attribute.nodeName
        continue if key.substr(0,5) isnt 'data-'
        
        key = key.substr(5)
        value = attribute.nodeValue
        
        binding = Batman.DOM.attributes[key]
        binding(value, node, context) if binding
    
    for child in node.childNodes
      Batman.DOM.parseNode(child, context)
    
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

global = exports ? this
global.Batman = Batman
global.$mixin = Batman.mixin
global.$bind = $bind
global.$event = $event
