helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View data-view bindings'
  setup: ->
    @MockViewClass = class MockViewClass extends MockClass
      @chainedCallback 'ready'
    MockViewClass.reset()

asyncTest 'it should instantiate custom view classes with the node and context', ->
  source = '<div data-view="someCustomClass"></div>'
  context = Batman({someCustomClass: @MockViewClass})

  delay =>
    ok @MockViewClass.lastConstructorArguments[0].node.nodeName
    ok @MockViewClass.lastConstructorArguments[0].context instanceof Batman.RenderContext

  helpers.render source, context, ->

asyncTest 'it should wait to fire the parent\'s ready event until the instantiated view has rendered', ->
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
