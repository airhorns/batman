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

  QUnit.module "requiring"

  QUnit.module "running"

