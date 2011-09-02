helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

oldRequest = Batman.Request
class MockRequest extends MockClass
  @chainedCallback 'success'
  @chainedCallback 'error'
count = 0

QUnit.module 'Batman.View'
  setup: ->
    MockRequest.reset()
    @options =
      source: "test_path#{++count}.html"

    Batman.Request = MockRequest
    @view = new Batman.View(@options) # create a view which uses the MockRequest internally
  teardown: ->
    Batman.Request = oldRequest

asyncTest 'should pull in the source for a view from a path, appending the prefix', 1, ->
  delay =>
    deepEqual MockRequest.lastInstance.constructorArguments[0].url, "views/#{@options.source}"

asyncTest 'should update its node with the contents of its view', 1, ->
  delay =>
    MockRequest.lastInstance.fireSuccess('view contents')
    equal @view.get('node').innerHTML, 'view contents'

asyncTest 'should fire the ready event once its contents have been loaded', 1, ->
  @view.ready (observer = createSpy())

  delay =>
    MockRequest.lastInstance.fireSuccess('view contents')
    delay =>
      ok observer.called
