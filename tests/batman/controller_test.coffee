class TestController extends Batman.Controller
  _currentAction: "show"

class MockView extends MockClass
  @chainedCallback 'ready'
  get: createSpy().whichReturns("view contents")

QUnit.module 'Batman.Controller redirect'

test 'should redirect', ->
  spyOnDuring Batman, 'redirect', (spy)->
    (new TestController).redirect("/somewhere/else")
    deepEqual spy.lastCallArguments, ["/somewhere/else"]

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
    equal view.constructorArguments[0].source, 'views/test/show.html'

    spyOnDuring Batman.DOM, 'contentFor', (contentFor) =>
      view.fireReady()
      deepEqual view.get.lastCallArguments, ['node']
      deepEqual contentFor.lastCallArguments, ['main', 'view contents']
