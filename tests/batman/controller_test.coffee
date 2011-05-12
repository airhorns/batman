class TestController extends Batman.Controller
  _currentAction: "show"

QUnit.module 'Batman.Controller redirect'
  setup: ->
    @_oldRedirect = Batman.Redirect
    spyOn(Batman, 'redirect')
  teardown: ->
    Batman.redirect = @_oldRedirect

test 'should redirect', ->
  (new TestController).redirect("/somewhere/else")
  deepEqual Batman.redirect.lastCallArguments, ["/somewhere/else"]

class MockView extends MockClass
  @chainedCallback 'ready'
  get: createSpy().whichReturns("view contents")

QUnit.module 'Batman.Controller render'
  setup: ->
    @_oldView = Batman.View
    @_oldContentFor = Batman.DOM.contentFor
    spyOn(Batman.DOM, "contentFor")
    @controller = new TestController

  teardown: ->
    Batman.View = @_oldView
    Batman.DOM.contentFor = @_oldContentFor

test 'it should render views if given in the options', ->
  testView = new MockView
  @controller.render
    view: testView

  testView.fireReady()
  deepEqual testView.get.lastCallArguments, ['node']
  deepEqual Batman.DOM.contentFor.lastCallArguments, ['main', 'view contents']

test 'it should pull in views if not present already', ->
  Batman.View = MockView
  @controller.render()
  view = MockView.lastInstance
  equal view.constructorArguments[0].source, 'views/test/show.html'

  view.fireReady()
  deepEqual view.get.lastCallArguments, ['node']
  deepEqual Batman.DOM.contentFor.lastCallArguments, ['main', 'view contents']
