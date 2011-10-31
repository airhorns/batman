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
      source: "test_path#{++count}"
      prefix: "some_other_prefix"

    Batman.Request = MockRequest
    @view = new Batman.View(@options) # create a view which uses the MockRequest internally
  teardown: ->
    Batman.Request = oldRequest

test 'should pull in the source for a view from a path, prepending the prefix', 1, ->
  equal MockRequest.lastConstructorArguments[0].url, "/some_other_prefix/#{@options.source}.html"

test 'should update its node with the contents of its view', 1, ->
  MockRequest.lastInstance.fireSuccess('view contents')
  equal @view.get('node').innerHTML, 'view contents'

asyncTest 'should fire the ready event once its contents have been loaded', 1, ->
  @view.on 'ready', observer = createSpy()

  MockRequest.lastInstance.fireSuccess('view contents')
  delay =>
    ok observer.called

asyncTest 'should allow prefetching of view sources', 2, ->
  Batman.View.sourceCache.prefetch('a/prefetched/view')
  equal MockRequest.lastConstructorArguments[0].url, "/a/prefetched/view.html"
  delay =>
    MockRequest.lastInstance.fireSuccess('prefetched contents')
    view = new Batman.View({source: 'view', prefix: 'a/prefetched'})
    equal view.get('html'), 'prefetched contents'
