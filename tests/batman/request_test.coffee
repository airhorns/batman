_send = spyOn(Batman.Request::, '_send')

QUnit.module 'Batman.Request'
test 'should not fire if not given a url', ->
  new Batman.Request
  ok !_send.called

asyncTest 'should request a url with default get', 2, ->
  new Batman.Request
    url: 'some/test/url.html'

  setTimeout(=>
    options = _send.lastCallArguments[0]
    equal options.url, 'some/test/url.html'
    equal options.method, 'get'
    QUnit.start()
  , ASYNC_TEST_DELAY)

asyncTest 'should request a url with a different method', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    method: 'post'

  setTimeout(=>
    options = _send.lastCallArguments[0]
    equal options.method, 'post'
    QUnit.start()
  , ASYNC_TEST_DELAY)

asyncTest 'should request a url with data', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    data:
      a: "b"
      c: 1

  setTimeout(=>
    options = _send.lastCallArguments[0]
    deepEqual options.data, {a: "b", c: 1}
    QUnit.start()
  , ASYNC_TEST_DELAY)

asyncTest 'should call the success callback if the request was successful', 1, ->
  observer = createSpy()
  req = new Batman.Request
    url: 'some/test/url.html'
  req.success(observer)

  setTimeout(=>
    options = _send.lastCallArguments[0]
    options.success('some test data')
  , ASYNC_TEST_DELAY)

  setTimeout(=>
    deepEqual observer.lastCallArguments, ['some test data']
    QUnit.start()
  , ASYNC_TEST_DELAY*2)
