window.location.hash = ""

return if  IN_NODE

class TestApp extends Batman.App

class TestApp.TestController
  @sharedInstance: -> @instance
  render: -> true
  constructor: ->
    @constructor.instance = @
    for k in ['show', 'complex', 'root']
      @[k] = createSpy()





asyncTest "should match splat routes", 1, ->
  @app.route "/*first/fixed/:id/*last", @controller.complex
  @app.redirect url = "/x/y/fixed/10/foo/bar"
  delay =>
    deepEqual @controller.complex.lastCallArguments, [{
      url: url
      first: 'x/y'
      id: '10'
      last: 'foo/bar'
    }]

asyncTest "should match routes even if query parameters are passed", 1, ->
  @app.route "/orders/:id", @controller.complex
  @app.redirect url = "/orders/1?bar=foo&x=true"
  delay =>
    deepEqual @controller.complex.lastCallArguments, [{
      url: "/orders/1"
      id: '1'
      bar: 'foo'
      x: 'true'
    }]

asyncTest "should start routing for aribtrary routes", 1, ->
  @app.stopRouting()
  window.location.hash = "#!/products/1"
  @app.route "/products/:id", spy = createSpy()
  @app.startRouting()

  delay =>
    ok spy.called


QUnit.module "requiring"

QUnit.module "running"
