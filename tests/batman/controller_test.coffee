class TestController extends Batman.Controller
  show: ->

class MockView extends MockClass
  @chainedCallback 'ready'
  get: createSpy().whichReturns("view contents")

QUnit.module 'Batman.Controller render'
  setup: ->
    @controller = new TestController
    Batman.DOM.Yield.clearAll()
  teardown: ->
    delete Batman.currentApp

test 'it should render a Batman.View if `view` isn\'t given in the options to render', ->
  mockClassDuring Batman ,'View', MockView, (mockClass) =>
    @controller.dispatch 'show'
    view = mockClass.lastInstance
    equal view.constructorArguments[0].source, 'test/show'

    spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
      view.fireReady()
      deepEqual view.get.lastCallArguments, ['node']
      deepEqual replace.lastCallArguments, ['view contents']

test 'it should cache the rendered Batman.View if `view` isn\'t given in the options to render', ->
  mockClassDuring Batman ,'View', MockView, (mockClass) =>
    @controller.dispatch 'show'
    view = mockClass.lastInstance

    @controller.dispatch 'show'
    equal mockClass.lastInstance, view, "No new instance has been made"

test 'it should render a Batman.View subclass with the ControllerAction name on the current app if it exists', ->
  Batman.currentApp = mockApp = Batman _renderContext: Batman.RenderContext.base
  mockApp.TestShowView = MockView

  @controller.dispatch 'show'
  view = MockView.lastInstance
  equal view.constructorArguments[0].source, 'test/show'

  spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
    view.fireReady()
    deepEqual view.get.lastCallArguments, ['node']
    deepEqual replace.lastCallArguments, ['view contents']

test 'it should cache the rendered Batman.View subclass with the ControllerAction name on the current app if it exists', ->
  Batman.currentApp = mockApp = Batman _renderContext: Batman.RenderContext.base
  mockApp.TestShowView = MockView

  @controller.dispatch 'show'
  view = MockView.lastInstance

  @controller.dispatch 'show'
  equal MockView.lastInstance, view, "No new instance has been made"

test 'it should render views if given in the options', ->
  testView = new MockView
  @controller.render
    view: testView

  spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
    testView.fireReady()
    deepEqual testView.get.lastCallArguments, ['node']
    deepEqual replace.lastCallArguments, ['view contents']

test 'it should pull in views if not present already', ->
  mockClassDuring Batman ,'View', MockView, (mockClass) =>
    @controller.dispatch 'show'
    view = mockClass.lastInstance
    equal view.constructorArguments[0].source, 'test/show'

    spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
      view.fireReady()
      deepEqual view.get.lastCallArguments, ['node']
      deepEqual replace.lastCallArguments, ['view contents']

test 'dispatching routes without any actions calls render', 1, ->
  @controller.test = ->
  @controller.render = ->
    ok true, 'render called'

  @controller.dispatch 'test'

test '@render false disables implicit render', 2, ->
  @controller.test = ->
    ok true, 'action called'
    @render false

  spyOnDuring Batman.DOM, 'replace', (replace) =>
    @controller.dispatch 'test'
    ok ! replace.called

test 'event handlers can render after an action', 6, ->
  testView = new MockView
  @controller.test = ->
    ok true, 'action called'
    @render view: testView

  testView2 = new MockView
  @controller.handleEvent = ->
    ok true, 'event called'
    @render view: testView2

  testView3 = new MockView
  @controller.handleAnotherEvent = ->
    ok true, 'another event called'
    @render view: testView3

  @controller.dispatch 'test'
  spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
    testView.fire 'ready'
    equal replace.callCount, 1

    @controller.handleEvent()
    testView2.fire 'ready'
    equal replace.callCount, 2

    @controller.handleAnotherEvent()
    testView3.fire 'ready'
    equal replace.callCount, 3

test 'redirecting a dispatch prevents implicit render', 2, ->
  Batman.navigator = new Batman.HashbangNavigator
  Batman.navigator.redirect = ->
    ok true, 'redirecting history manager'
  @controller.render = ->
    ok true, 'redirecting controller'
  @controller.render = ->
    throw "shouldn't be called"

  @controller.test1 = ->
    @redirect 'foo'

  @controller.test2 = ->
    Batman.redirect 'foo2'

  @controller.dispatch 'test1'
  @controller.dispatch 'test2'

test '[before/after]Filter', 3, ->
  class FilterController extends Batman.Controller
    @beforeFilter only: 'withBefore', except: 'withoutBefore', ->
      ok true, 'beforeFilter called'
    @afterFilter 'testAfter'

    withBefore: ->
      @render false
    withoutBefore: ->
      @render false
    testAfter: ->
      ok true, 'afterFilter called'

  controller = new FilterController

  controller.dispatch 'withoutBefore'
  controller.dispatch 'withBefore'
