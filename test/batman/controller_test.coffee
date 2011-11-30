class TestController extends Batman.Controller
  show: ->

class MockView extends MockClass

  @chainedCallback 'ready'
  get: createSpy().whichReturns("view contents")

suite 'Batman', ->
  suite 'Controller', ->
    controller = false

    setup ->
      controller = new TestController

    suite 'rendering', ->
      test 'it should render views if given in the options', ->
        testView = new MockView
        controller.render
          view: testView

        spyOnDuring Batman.DOM, 'replace', (replace) ->
          testView.fireReady()
          assert.deepEqual testView.get.lastCallArguments, ['node']
          assert.deepEqual replace.lastCallArguments, ['main', 'view contents']

      test 'it should pull in views if not present already', ->
        mockClassDuring Batman ,'View', MockView, (mockClass) =>
          controller.dispatch 'show'
          view = mockClass.lastInstance
          assert.equal view.constructorArguments[0].source, 'test/show'

          spyOnDuring Batman.DOM, 'replace', (replace) =>
            view.fireReady()
            assert.deepEqual view.get.lastCallArguments, ['node']
            assert.deepEqual replace.lastCallArguments, ['main', 'view contents']

      test 'dispatching routes without any actions calls render', ->
        called = false
        controller.test = ->
        controller.render = ->
          called = true

        controller.dispatch 'test'
        assert.ok called, 'render called'

      test '@render false disables implicit render', ->
        controller.test = ->
          assert.ok true, 'action called'
          @render false

        spyOnDuring Batman.DOM, 'replace', (replace) =>
          controller.dispatch 'test'
          assert.ok ! replace.called

      test 'event handlers can render after an action', ->
        testView = new MockView
        controller.test = ->
          assert.ok true, 'action called'
          @render view: testView

        testView2 = new MockView
        controller.handleEvent = ->
          assert.ok true, 'event called'
          @render view: testView2

        testView3 = new MockView
        controller.handleAnotherEvent = ->
          assert.ok true, 'another event called'
          @render view: testView3

        spyOnDuring Batman.DOM, 'replace', (replace) =>
          controller.dispatch 'test'
          testView.fire 'ready'
          assert.equal replace.callCount, 1

          controller.handleEvent()
          testView2.fire 'ready'
          assert.equal replace.callCount, 2

          controller.handleAnotherEvent()
          testView3.fire 'ready'
          assert.equal replace.callCount, 3

      suite 'redirecting', ->
        test 'redirecting a dispatch prevents implicit render', ->
          Batman.navigator = new Batman.HashbangNavigator
          Batman.navigator.redirect = ->
            assert.ok true, 'redirecting history manager'
          controller.render = ->
            assert.ok true, 'redirecting controller'
          controller.render = ->
            throw "shouldn't be called"

          controller.test1 = ->
            @redirect 'foo'

          controller.test2 = ->
            Batman.redirect 'foo2'

          controller.dispatch 'test1'
          controller.dispatch 'test2'
