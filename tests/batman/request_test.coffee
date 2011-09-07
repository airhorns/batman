oldSend = Batman.Request::send

QUnit.module 'Batman.Request'
  setup: ->
    @send = Batman.Request::send = createSpy()
  teardown: ->
    Batman.Request::send = oldSend

test 'should not fire if not given a url', ->
  new Batman.Request
  ok !@send.called

asyncTest 'should request a url with default get', 2, ->
  new Batman.Request
    url: 'some/test/url.html'

  delay =>
    req = @send.lastCallContext
    equal req.url, 'some/test/url.html'
    equal req.method, 'get'

asyncTest 'should request a url with a different method', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    method: 'post'

  delay =>
    req = @send.lastCallContext
    equal req.method, 'post'

asyncTest 'should request a url with data', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    data:
      a: "b"
      c: 1

  delay =>
    req = @send.lastCallContext
    deepEqual req.data, {a: "b", c: 1}

asyncTest 'should call the success callback if the request was successful', 1, ->
  observer = createSpy()
  req = new Batman.Request
    url: 'some/test/url.html'
  req.success(observer)

  delay =>
    req = @send.lastCallContext
    req.success('some test data')

    delay =>
      deepEqual observer.lastCallArguments, ['some test data']
