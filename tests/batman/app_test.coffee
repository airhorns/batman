do ->
  class TestApp extends Batman.App
    @root 'test.root'
    @match 'products/:id', 'test.show'
    @match '*first/fixed/:id/*last', 'test.complex'

  class TestApp.TestController
    render: -> true
    show: (params) ->
    complex: (params) ->
    root: (params) ->

  QUnit.module "Batman.App routing"
    setup: ->
      @app = new TestApp
      @app.controller("TestController")
      @controller = TestApp.TestController.sharedInstance
    teardown: ->
      @app.stopRouting()

  test "should match simple routes", ->
    spyOn(@controller, "show")
    @app.dispatch(url = "products/2")
    deepEqual @controller.show.lastCallArguments, [{
      url: url
      id: '2'
    }]

  test "should match splat routes", ->
    spyOn(@controller, "complex")
    @app.dispatch(url = "x/y/fixed/10/foo/bar")
    deepEqual @controller.complex.lastCallArguments, [{
      url: url
      first: 'x/y'
      id: '10'
      last: 'foo/bar'
    }]

  test "should match a root route", ->
    spyOn(@controller, "root")
    @app.dispatch("/")
    deepEqual @controller.root.lastCallArguments, [{
      url: '/'
    }]

  asyncTest "should start routing on the root route", 1, ->
    window.location.hash = ""
    spyOn(@app, "dispatch")
    @app.startRouting()
    setTimeout(=>
      deepEqual @app.dispatch.lastCallArguments, ["/"]
      start()
    , 15)

  asyncTest "should start routing for aribtrary routes", 1, ->
    window.location.hash = "#!/products/1"
    spyOn(@app, "dispatch")
    @app.startRouting()
    setTimeout(=>
      deepEqual @app.dispatch.lastCallArguments, ["/products/1"]
      start()
    , 15)

  asyncTest "should listen for hashchange events", 2, ->
    window.location.hash = "#!/products/1"
    spyOn(@app, "dispatch")
    @app.startRouting()
    setTimeout(->
      window.location.hash = "#!/products/2"
    , 15)
    setTimeout(=>
      deepEqual @app.dispatch.calls[0].arguments, ["/products/1"]
      deepEqual @app.dispatch.calls[1].arguments, ["/products/2"]
      start()
    , 115)

  test "should redirect", ->
    spyOn(@app, "dispatch")
    @app.redirect("/somewhere/else")
    deepEqual @app.dispatch.lastCallArguments, ["/somewhere/else"]

  QUnit.module "requiring"


  QUnit.module "running"

