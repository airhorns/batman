QUnit.module 'Batman.Dispatcher defining routes',
  setup: ->
    window.location.hash = ''
    Batman.START = new Date()
    class @App extends Batman.App
      @layout: null
      @test: (url) ->
        @run() if not @hasRun
        {controller, action} = @dispatcher.findRoute(url).get('action')
        @dispatcher.get controller + '.' + action

    class @App.TestController extends Batman.Controller
      index: -> @render false
      index2: -> @render false

    class @App.Product extends Batman.Model
    class @App.ProductsController extends Batman.Controller
      index: -> @render false
      show: (params) ->
        equal params.id, 1, 'id is correct'
        QUnit.start()
        @render false
      edit: -> @render false
  teardown: ->
    @App.stop()
    window.location.hash = ''

test 'controller aliases', ->
  @App.dispatcher = new Batman.Dispatcher @App
  equal @App.dispatcher.get('products'), @App.ProductsController.get('sharedController')
  equal @App.get('controllers.products'), @App.ProductsController.get('sharedController')

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

  $redirect '/foo'

asyncTest 'redirecting with params', ->
  @App.route 'products/:id', 'products#show'
  @App.run()
  $redirect controller: 'products', action: 'show', id: '1'

asyncTest 'param matching', ->
  @App.route 'test/:id', 'products#show'
  equal @App.test('test/1'), @App.ProductsController::show

  $redirect 'test/1'

asyncTest 'splat matching', ->
  @App.route '/*first/fixed/:id/*last', (params) ->
    equal params.url, url
    equal params.first, 'x/y'
    equal params.id, '10'
    equal params.last, 'foo/bar'
    QUnit.start()
  @App.run()

  $redirect url = '/x/y/fixed/10/foo/bar'

asyncTest 'query params', ->
  @App.root (params) ->
    equal params.url, '/'
    equal params.foo, 'bar'
    equal params.x, 'true'
    QUnit.start()
  @App.run()

  $redirect '/?foo=bar&x=true'

asyncTest 'route match with default params', 2, ->
  @App.root controller: 'test', action: 'index'
  @App.route 'show', controller: 'products', action: 'show', id: 1

  equal @App.test('/'), @App.TestController::index
  $redirect '/show'

asyncTest 'resources', ->
  @App.resources 'products', ->
    @collection ->
      @route 'testCollection'
    @member ->
      @route 'test', 'testMember'

  @App.ProductsController::testCollection = -> @render false
  @App.ProductsController::testMember = -> @render false

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
    QUnit.start()
  , 220)

asyncTest '404', 1, ->
  @App.route '404', ->
    ok true, '404 called'
    QUnit.start()
  @App.run()

  $redirect 'something/random'
