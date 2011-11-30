if window?
  exports = window
  exports.IN_NODE = false
else
  exports = global
  jsdom = require 'jsdom'
  exports.window = w = jsdom.jsdom("<html><head><script></script></head><body></body></html>").createWindow()
  exports.document = w.document
  global.notStrictEqual = (actual, expected, message) -> ok expected != actual, message
  exports.IN_NODE = true

if exports.IN_NODE
  do ->
    hash = ''
    exports.window.location.__defineGetter__ 'hash', -> hash
    exports.window.location.__defineSetter__ 'hash', (value) ->
      hash = value
      evt = exports.window.document.createEvent "HTMLEvents"
      evt.initEvent "hashchange", true, false
      exports.window.dispatchEvent evt

unless exports.localStorage?
  do ->
    storage = {}
    exports.localStorage =
      key: (index) -> (key for key, value of storage when !index--)[0]
      getItem: (key) -> storage["#{key}"]
      setItem: (key, value) -> storage["#{key}"] = value
      removeItem: (key) -> delete storage["#{key}"]
      clear: -> storage = {}

exports.ASYNC_TEST_DELAY = 20

class Spy
  constructor: (original) ->
    @called = false
    @callCount = 0
    @calls = []
    @original = original
    @fixedReturn = false

  whichReturns: (value) ->
    @fixedReturn = true
    @fixedReturnValue = value
    @

# Simple mock function implementation stolen from Jasmine.
# Use `createSpy` to get back a function which tracks if it has been
# called, how many times, with what arguments, and optionally returns
# something specific. Example:
#
#    observer = createSpy()
#
#    object.on('click', observer)
#    object.fire('click', {foo: 'bar'})
#
#    equal observer.called, true
#    equal observer.callCount, 1
#    deepEqual observer.lastCallArguments, [{foo: 'bar'}]
#
createSpy = (original) ->
  spy = new Spy(original)

  f = (args...) ->
    f.called = true
    f.callCount++
    f.lastCall =
      context: this
      arguments: args

    f.lastCallArguments = f.lastCall.arguments
    f.lastCallContext = f.lastCall.context
    f.calls.push f.lastCall

    unless f.fixedReturn
      f.original?.call(this, args...)
    else
      f.fixedReturnValue

  for k, v of spy
    f[k] = v

  f

# `spyOn` can also be used as a shortcut to create or replace a
# method on an existing object with a spy. Example:
#
#    object = new DooHickey
#
#    spyOn(object, 'doStuff')
#
#    equal object.doStuff.callCount, 0
#    object.doStuff()
#    equal object.doStuff.callCount, 1
#
spyOn = (obj, method) ->
  obj[method] = createSpy(obj[method])

# `spyOnDuring` replaces a method on an object with a spy, but
# only for the duration of a passed function, after which it
# restores the original value.
spyOnDuring = (obj, method, fn) ->
  original = obj[method]
  spy = spyOn(obj, method)
  result = fn(spy)
  obj[method] = original
  [spy, result]

# MockClass
# A class suitable for extending to mock a class which some code
# instantiates For example, to test code which creates
# `Batman.Request`s, extend this class:
#
#     class MockRequest extends MockClass
#
# and then make the code use this mock class instead of the real
# thing by setting `Batman.Request` to this mock in the setup
# method and restoring the old one in the teardown method of your
# QUnit module, like this:
#
#     module 'test something using Batman.Request',
#      setup: ->
#        @_oldRequest = Batman.Request
#        Batman.Request = MockRequest
#      teardown: ->
#        Batman.Request = @_oldRequest
#
# Batman.Request now tracks the instances it has created, and
# arguments passed to the constructor.

class MockClass

  # Resets this class into the vanilla state, forgetting any instances
  # created.
  @reset: ->
    # The last instance created from this class
    @lastInstance = false
    # All the instances created from this class, ordered by time of
    # creation
    @instances = []
    # The count of instances created
    @instanceCount = 0
    # The last arguments passed to this class' constructor
    @lastConstructorArguments = false
    # All the sets of arugments passed to this class' constructor
    @constructorArguments = []

  @reset()

  # Class level method to make an instance level method a spy
  @spyOn: (name) ->
    spyOn(@::, name)

  # Class level method to add chained callback style methods.
  # Calling this on a subclass of `MockClass` will add two
  # methods on the instances, one which adds callbacks to a
  # stack, and one which fires the stack. Example:
  #
  #    class MockRequest extends Mock Class
  #      @chainedCallback 'success'
  #
  #    mock = new MockRequest
  #
  # Adding a new callback to the stack:
  #
  #    mock.success (data) -> doWorkWithData(data)
  #    mock.success (data) -> doOtherStuff() if data.special
  #
  # Firing the callbacks:
  #
  #    mock.fireSuccess({special: false})
  #

  @chainedCallback: (name) ->
    @::[name] = (f) ->
      (@callbackStacks[name] ||= []).push f
      @
    @::["fire#{name.charAt(0).toUpperCase() + name.slice(1)}"] = () ->
      f.apply(@, arguments) for f in @callbackStacks[name]

  on: (event, callback) ->
    (@callbackStacks[event] ||= []).push(callback)
    @
  fire: (event) ->
    return unless @callbackStacks[event]
    f.apply(@, arguments) for f in @callbackStacks[event]

  _callbackStacks: {}

  constructor: (options = {}) ->
    @constructorArguments = arguments
    @constructor.lastInstance = this
    @constructor.instances.push this
    @constructor.lastConstructorArguments = arguments
    @constructor.constructorArguments.push arguments
    @constructor.instanceCount++
    @callbackStacks = {}

    for k, v of options
      if @[k]
        @[k](v)
      else
        @[k] = v

# Replaces a class in a namespace with a mock class for
# the duration of a function, and then sets it back to its
# original value. The function is passed the mock class.
mockClassDuring = (namespace, name, mock = MockClass, fn) ->
  original = namespace[name]
  namespace[name] = mock
  result = fn(mock)
  namespace[name] = original
  [mock, result]

## Handy for async tests which usually follow this pattern

delayCount = 0
delay = (options, fn) ->
  if typeof options == 'function'
    fn = options
    options = {}
  options.length ||= ASYNC_TEST_DELAY

  defer = ->
    fn()
    if --delayCount == 0
      options.done?()

  delayCount++
  setTimeout(defer, options.length)

doWhen = (conditionFunction, actionFunction, timeout=2000) ->
  t = new Date
  f = ->
    if conditionFunction() or (new Date) - t > timeout
      try
        actionFunction()
      finally
        clearInterval interval
  interval = setInterval f, 20

for k, v of {Spy, MockClass, createSpy, spyOn, spyOnDuring, mockClassDuring, delay, doWhen}
  exports[k] = v

if exports.IN_NODE
  exports.assert = require 'assert'
  exports.Batman = require '../../src/batman.node.coffee'

## return clean links (e.g. "Rerun" links):
#QUnit.__url = QUnit.url
#QUnit.url = (params) -> QUnit.__url(params).replace(/^[^\?]*\?/, "#{originalPathname}?")

originalPathname = window.location.pathname
originalHref = window.location.href

suite 'Batman', ->
  setup ->
    Batman.config.pathPrefix = originalPathname
    Batman.config.usePushState = true

  teardown ->
    if Batman.currentApp?
      Batman.currentApp.stop()
      Batman.currentApp = null
    window.location.hash = ""
    if window.history?.pushState? and window.location.href isnt originalHref
      window.history.pushState(null, '', originalHref)
