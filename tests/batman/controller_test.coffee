class TestController extends Batman.Controller
  _currentAction: "show"
  show: ->

class MockView extends MockClass
  constructor: ->
    @contexts = []
    super

  @chainedCallback 'ready'
  get: createSpy().whichReturns("view contents")


QUnit.module 'Batman.Controller render'
  setup: ->
    @controller = new TestController

test 'it should render views if given in the options', ->
  testView = new MockView
  @controller.render
    view: testView

  spyOnDuring Batman.DOM, 'contentFor', (contentFor) ->
    testView.fireReady()
    deepEqual testView.get.lastCallArguments, ['node']
    deepEqual contentFor.lastCallArguments, ['main', 'view contents']

test 'it should pull in views if not present already', ->
  mockClassDuring Batman ,'View', MockView, (mockClass) =>
    @controller.render()
    view = mockClass.lastInstance
    equal view.constructorArguments[0].source, 'test/show.html'

    spyOnDuring Batman.DOM, 'contentFor', (contentFor) =>
      view.fireReady()
      deepEqual view.get.lastCallArguments, ['node']
      deepEqual contentFor.lastCallArguments, ['main', 'view contents']

test 'dispatching routes without any actions calls render', 1, ->
  @controller.test = ->
  @controller.render = ->
    ok true, 'render called'

  @controller.dispatch 'test'

test '@render false disables implicit render', 1, ->
  @controller.test = ->
    ok true, 'action called'
    @render false

  @controller.dispatch 'test'

test 'redirecting a dispatch prevents implicit render', 2, ->
  Batman.historyManager = new Batman.HashHistory
  Batman.historyManager.redirect = ->
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
