class MockRequest extends MockClass
  @chainedCallback 'success'

QUnit.module 'Batman.View'
  setup: ->
    @options =
      source: 'test_path.html'
    MockRequest.reset()
    mockClassDuring Batman, 'Request', MockRequest, (mockClass) =>
      @view = new Batman.View(@options)
      @instance = mockClass.lastInstance
  
test 'should pull in the source for a view from a path', 1, ->
    deepEqual @instance.constructorArguments[0].url, 'test_path.html'

test 'should update its node with the contents of its view', 1, ->
   MockRequest.lastInstance.fireSuccess('view contents')
   equal @view.get('node').innerHTML, 'view contents'

asyncTest 'should fire the ready event once its contents have been loaded', 1, ->
  @view.ready (observer = createSpy())

  setTimeout(=>
    @instance.fireSuccess('view contents')
    ok observer.called
    QUnit.start()
  , ASYNC_TEST_DELAY)

