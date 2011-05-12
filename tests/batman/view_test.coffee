class MockRequest extends MockClass
  @chainedCallback 'success'

QUnit.module 'Batman.View'
  setup: ->
    @_oldRequest = Batman.Request
    Batman.Request = MockRequest
    @options =
      source: 'test_path.html'
    @view = new Batman.View(@options)

  teardown: ->
    Batman.Request = @_oldRequest

test 'should pull in the source for a view from a path', ->
  deepEqual MockRequest.lastInstance.constructorArguments[0].url, 'test_path.html'

asyncTest 'should update its node with the contents of its view', 1, ->
  setTimeout(=>
    MockRequest.lastInstance.fireSuccess('view contents')
    equal @view.get('node').innerHTML, 'view contents'
    start()
  , 15)

asyncTest 'should fire the ready event once its contents have been loaded', 1, ->
  @view.ready (observer = createSpy())
  setTimeout(=>
    MockRequest.lastInstance.fireSuccess('view contents')
    ok observer.called
    start()
  , 15)
