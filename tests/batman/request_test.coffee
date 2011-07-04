oldSend = Batman.Request::send
send = Batman.Request::send = createSpy()

QUnit.module 'Batman.Request'
test 'should not fire if not given a url', ->
  new Batman.Request
  ok !send.called

asyncTest 'should request a url with default get', 2, ->
  new Batman.Request
    url: 'some/test/url.html'

  setTimeout(=>
    req = send.lastCallContext
    equal req.url, 'some/test/url.html'
    equal req.method, 'get'
    QUnit.start()
  , ASYNC_TEST_DELAY)

asyncTest 'should request a url with a different method', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    method: 'post'

  setTimeout(=>
    req = send.lastCallContext
    equal req.method, 'post'
    QUnit.start()
  , ASYNC_TEST_DELAY)

asyncTest 'should request a url with data', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    data:
      a: "b"
      c: 1

  setTimeout(=>
    req = send.lastCallContext
    deepEqual req.data, {a: "b", c: 1}
    QUnit.start()
  , ASYNC_TEST_DELAY)

asyncTest 'should call the success callback if the request was successful', 1, ->
  observer = createSpy()
  req = new Batman.Request
    url: 'some/test/url.html'
  req.success(observer)

  setTimeout(=>
    req = send.lastCallContext
    req.success('some test data')
  , ASYNC_TEST_DELAY)

  setTimeout(=>
    deepEqual observer.lastCallArguments, ['some test data']
    QUnit.start()
  , ASYNC_TEST_DELAY*2)
