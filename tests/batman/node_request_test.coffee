return unless IN_NODE

oldGetModule = Batman.Request::getModule

QUnit.module 'Batman.Request'
  setup: ->
    @requestSpy = createSpy().whichReturns
      on: ->
      end: ->
    Batman.Request::getModule = =>
      request: @requestSpy
  teardown: ->
    Batman.Request::getModule = oldGetModule
    @request?.cancel()

asyncTest 'should request a url with standard options', 1, ->
  opts =
    url: 'http://www.myserver.local:9339/some/test/url.html'
    method: 'GET'
  expected =
    path: '/some/test/url.html'
    method: 'GET'
    port: '9339'
    host: 'www.myserver.local'
  @request = new Batman.Request opts
  delay =>
    req = @requestSpy.lastCallArguments.shift()
    delete req['headers'] # these make deepEqual sad
    deepEqual req, expected

asyncTest 'accepts GET data as object', 1, ->
  @request = new Batman.Request
    url: '/some/test/url.html'
    data: foo: "bar"
  delay =>
    req = @requestSpy.lastCallArguments.shift()
    equal req.path, '/some/test/url.html?foo=bar'

asyncTest 'accepts GET data as string', 1, ->
  @request = new Batman.Request
    url: '/some/test/url.html'
    data: 'foo=bar'
  delay =>
    req = @requestSpy.lastCallArguments.shift()
    equal req.path, '/some/test/url.html?foo=bar'
