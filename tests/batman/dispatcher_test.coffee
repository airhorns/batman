return if IN_NODE

QUnit.module 'Batman.Dispatcher defining routes',
  setup: ->
    window.location.hash = ''
    Batman.START = new Date()
    class @App extends Batman.App
      @layout: null
      @test: (url) ->
        @run() if not @hasRun
        [controller, action] = @dispatcher.findRoute(url).get('action')
        controller[action]

    class @App.TestController extends Batman.Controller
      index: ->
      index2: ->

    class @App.Product extends Batman.Model
    class @App.ProductsController extends Batman.Controller
      index: ->
      show: (params) ->
        equal params.id, 1, 'id is correct'
        QUnit.start()
      edit: ->
  teardown: ->
    @App.historyManager?.stop()
    window.location.hash = ''

test 'simple route match', ->
  @App.route 'products', 'test#index'
  @App.route '/products2', 'test#index2'
  @App.route 'products3', 'test'

  equal @App.test('products'), @App.TestController::index
  equal @App.test('/products2'), @App.TestController::index2
  equal @App.test('products3'), @App.TestController::index

test 'simple root match', ->
  @App.root 'test#index'
  equal @App.test('/'), @App.TestController::index

asyncTest 'redirecting', 1, ->
  @App.route 'foo', ->
    ok true, 'route called'
    QUnit.start()
  @App.run()

  $redirect 'foo'

asyncTest 'param matching', ->
  @App.route 'test/:id', 'products#show'
  equal @App.test('test/1'), @App.ProductsController::show

  $redirect 'test/1'

asyncTest 'splat matching', 1, ->
  @App.route '/*first/fixed/:id/*last', (params) ->
    deepEqual params,
      url: url
      first: 'x/y'
      id: '10'
      last: 'foo/bar'
    QUnit.start()
  @App.run()

  $redirect url = '/x/y/fixed/10/foo/bar'

asyncTest 'query params', ->
  @App.root (params) ->
    deepEqual params,
      url: '/'
      foo: 'bar'
      x: 'true'
    QUnit.start()
  @App.run()

  $redirect '/?foo=bar&x=true'

asyncTest 'resources', ->
  @App.resources 'products', ->
    @collection ->
      @route 'testCollection'
    @member ->
      @route 'test', 'testMember'

  @App.ProductsController::testCollection = ->
  @App.ProductsController::testMember = ->

  equal @App.test('products'), @App.ProductsController::index
  equal @App.test('products/1'), @App.ProductsController::show
  equal @App.test('products/1/edit'), @App.ProductsController::edit
  equal @App.test('products/1/destroy'), null

  equal @App.test('products/testCollection'), @App.ProductsController::testCollection
  equal @App.test('products/1/test'), @App.ProductsController::testMember

  $redirect 'products/1'

asyncTest 'hash manager', ->
  @App.route 'test', spy = createSpy()
  @App.route 'test2', spy2 = createSpy()
  @App.run()

  window.location.hash = '#!/test'

  setTimeout(->
    equal spy.callCount, 1
    window.location.hash = "#!/test2"
  , 110)

  setTimeout(->
    equal spy2.callCount, 1
    start()
  , 220)
