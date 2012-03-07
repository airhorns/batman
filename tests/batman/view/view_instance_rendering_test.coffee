helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View data-view bindings'
  setup: ->
    @MockViewClass = class MockViewClass extends MockClass
      isView: true
      @chainedCallback 'ready'
      get: (k) -> @[k]
      set: (k,v) -> @[k] = v

    MockViewClass.reset()

asyncTest 'it should instantiate custom view classes with the node and context', 2, ->
  source = '<div data-view="someCustomClass">foo</div>'
  context = Batman({someCustomClass: @MockViewClass})

  delay =>
    equal @MockViewClass.lastConstructorArguments[0].node.innerHTML, 'foo'
    ok @MockViewClass.lastConstructorArguments[0].context instanceof Batman.RenderContext

  helpers.render source, context, ->

asyncTest 'it should wait to fire the parent\'s ready event until the instantiated view has rendered', 1, ->
  source = '<div data-view="someCustomClass"></div>'
  context = Batman({someCustomClass: @MockViewClass})

  shouldBeReady = false
  helpers.render source, context, ->
    ok shouldBeReady, 'The parent ready event fires after the child is ready'
    QUnit.start()

  setTimeout =>
    shouldBeReady = true
    @MockViewClass.lastInstance.fireReady()
  , ASYNC_TEST_DELAY

asyncTest 'it should set the node on already instantiated custom views', 2, ->
  source = '<div data-view="someCustomView">foo</div>'
  view = new @MockViewClass
  context = Batman({someCustomView: view})

  delay =>
    equal view.get('node').innerHTML, 'foo'
    ok view.get('context') instanceof Batman.RenderContext

  helpers.render source, context, ->

asyncTest 'it should wait for already instantiated views to come into existence', 2, ->
  source = '<div data-view="someCustomView">foo</div>'
  view = new @MockViewClass
  context = Batman()

  delay =>
    context.set 'someCustomView', view
    delay =>
      equal view.get('node').innerHTML, 'foo'
      ok view.get('context') instanceof Batman.RenderContext

  helpers.render source, context, ->

asyncTest 'it should wait to fire the parent\'s ready event until the passed view instance has rendered', 1, ->
  source = '<div data-view="someCustomView"></div>'
  view = new @MockViewClass
  context = Batman({someCustomView: view})

  shouldBeReady = false
  helpers.render source, context, ->
    ok shouldBeReady, 'The parent ready event fires after the child is ready'
    QUnit.start()

  setTimeout =>
    shouldBeReady = true
    view.fireReady()
  , ASYNC_TEST_DELAY

asyncTest 'it should not render inner nodes', ->
  source = '<div data-view="someCustomClass"><div data-bind="someProp"></div></div>'
  context = Batman({someCustomClass: @MockViewClass})
  context.accessor 'someProp', {get: spy = createSpy()}

  setTimeout =>
    @MockViewClass.lastInstance.fireReady()
  , ASYNC_TEST_DELAY

  helpers.render source, context, ->
    ok !spy.called
    QUnit.start()

asyncTest 'it should not render bindings on the node', ->
  source = '<div data-view="someCustomClass" data-bind="someProp"></div>'
  context = Batman({someCustomClass: @MockViewClass})
  context.accessor 'someProp', {get: spy = createSpy()}

  setTimeout =>
    @MockViewClass.lastInstance.fireReady()
  , ASYNC_TEST_DELAY

  helpers.render source, context, ->
    ok !spy.called
    QUnit.start()
