if window?
  window.ASYNC_TEST_DELAY = 120 unless 'onhashchange' of window
  window.location.hash = ""
else
  return

class TestApp extends Batman.App

class TestApp.TestController
  @sharedInstance: -> @instance
  render: -> true
  constructor: ->
    @constructor.instance = @
    for k in ['show', 'complex', 'root'] 
      @[k] = createSpy()


QUnit.module "Batman.App routing"
  setup: ->
    @app = TestApp
    @app.root ->
    @app.route '/404', -> throw new Error("404 route called, shouldn't be during tests!")
    @controller = new TestApp.TestController
    @app.startRouting()
    Batman.currentApp = @app

  teardown: ->
    @app.stopRouting()
    Batman._routes = []

test "should redirect", 1, ->
  @app.redirect url = "/foo/bar/bleh"
  equal window.location.hash, "#!/foo/bar/bleh"

asyncTest "should match simple routes", 1, ->
  @app.route "/products/:id", @controller.show
  @app.redirect url = "/products/2"
  delay =>
    deepEqual @controller.show.lastCallArguments, [{
      url: url
      id: '2'
    }]

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

asyncTest "should match a root route", 1, ->
  Batman._routes = []
  @app.root @controller.root
  @app.redirect "/"
  delay =>
    deepEqual @controller.root.lastCallArguments, [{
      url: '/'
    }]

asyncTest "should match a string route", 1, ->
  @app.route "/orders/:id", "test#complex"
  @app.redirect url = "/orders/1"
  delay =>
    deepEqual @controller.complex.lastCallArguments, [{
      url: url
      id: '1'
    }]

asyncTest "should allow routes to be defined within class definitions", 1, ->
  class TestDefinitionController extends Batman.Controller
    testing: @route('/blech/:id', (params) ->
      # Pass a super simple view mock to the controller so it doesn't try and render a Batman.View.
      @render
        view: 
          ready: ->

      deepEqual params, {url: '/blech/42', id: '42'}
      start()
    )
  @app.redirect "/blech/42"

asyncTest "should start routing for aribtrary routes", 1, ->
  @app.stopRouting()
  window.location.hash = "#!/products/1"
  @app.route "/products/:id", spy = createSpy()
  @app.startRouting()

  delay =>
    ok spy.called

asyncTest "should listen for hashchange events", 2, ->
  @app.route "/orders/:id", spy = createSpy()
  window.location.hash = "#!/orders/1"
  
  setTimeout(->
    equal spy.callCount, 1
    window.location.hash = "#!/orders/2"
  , ASYNC_TEST_DELAY*2)

  setTimeout(->
    equal spy.callCount, 2
    start()
  , ASYNC_TEST_DELAY*4)


QUnit.module "requiring"

QUnit.module "running"
