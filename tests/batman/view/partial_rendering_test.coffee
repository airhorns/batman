helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

class MockRequest extends MockClass
  @chainedCallback 'success'
  @chainedCallback 'error'
oldRequest = Batman.Request
QUnit.module 'Batman.View partial rendering'
  setup: ->
    MockRequest.reset()
    Batman.Request = MockRequest

  teardown: ->
    Batman.View.viewSources = {}
    Batman.Request = oldRequest

asyncTest "preloaded/already rendered partials should render", ->
  Batman.View.viewSources['test/one.html'] = "<div>Hello from a partial</div>"

  source = '<div data-partial="test/one"></div>'
  node = helpers.render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "<div>Hello from a partial</div>"

asyncTest "unloaded partials should load then render", 2, ->
  source = '<div data-partial="test/one"></div>'


  # Callback below doesn't fire until view's ready event, which waits for the partial to be fetched and rendered.
  node = helpers.render source, {}, (node) ->
    equal node.children(0).html(), "<div>Hello from a partial</div>"
    QUnit.start()

  setTimeout ->
    deepEqual MockRequest.lastInstance.constructorArguments[0].url, "views/test/one.html"
    MockRequest.lastInstance.fireSuccess('<div>Hello from a partial</div>')
  , 25
