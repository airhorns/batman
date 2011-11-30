suite 'Batman', ->
  suite 'Dispatcher defining routes', ->
    TestApp = false
    setup ->
      Batman.START = new Date()
      TestApp = class TestApp extends Batman.App
        @layout: null
        @test: (url) ->
          @run() if not @hasRun
          {controller, action} = @dispatcher.findRoute(url).get('action')
          @controllers.get("#{controller}.#{action}")

      class TestApp.TestController extends Batman.Controller
        index: -> @render false
        index2: -> @render false

      class TestApp.Product extends Batman.Model
      class TestApp.ProductsController extends Batman.Controller
        index: -> @render false
        show: -> @render false
        edit: -> @render false

    teardown ->
      TestApp.stop()

    test 'controller aliases', ->
      TestApp.dispatcher = new Batman.Dispatcher TestApp
      assert.equal TestApp.get('controllers.products'), TestApp.ProductsController.get('sharedController')

    test 'simple route match', ->
      TestApp.route 'products', 'test#index'
      TestApp.route '/products2', 'test#index2'
      TestApp.route 'products3', 'test'

      assert.equal TestApp.test('products'), TestApp.TestController::index
      assert.equal TestApp.test('/products2'), TestApp.TestController::index2
      assert.equal TestApp.test('products3'), TestApp.TestController::index

    test 'simple root match', ->
      TestApp.root 'test#index'
      assert.equal TestApp.test('/'), TestApp.TestController::index

    test 'redirecting', (done) ->
      TestApp.route 'foo', ->
        assert.ok true, 'route called'
        done()
      TestApp.run()

      $redirect '/foo'

    test 'redirecting with params', (done) ->
      TestApp.ProductsController::show = (params) ->
        assert.equal params.id, 1, 'id is correct'
        done()
        @render false

      TestApp.route 'products/:id', 'products#show'
      TestApp.run()

      $redirect controller: 'products', action: 'show', id: '1'

    test 'param matching', (done) ->
      TestApp.ProductsController::show = (params) ->
        assert.equal params.id, 1, 'id is correct'
        done()
        @render false

      TestApp.route 'test/:id', 'products#show'
      assert.equal TestApp.test('test/1'), TestApp.ProductsController::show

      $redirect 'test/1'

    test 'splat matching', (done) ->
      TestApp.route '/*first/fixed/:id/*last', (params) ->
        assert.equal params.url, url
        assert.equal params.first, 'x/y'
        assert.equal params.id, '10'
        assert.equal params.last, 'foo/bar'
        done()
      TestApp.run()

      $redirect url = '/x/y/fixed/10/foo/bar'

    test 'query params', (done) ->
      hasCalledRoute = no
      TestApp.root (params) ->

        assert.equal params.url, '/'
        assert.equal params.foo, 'bar'
        assert.equal params.x, 'true'

        if hasCalledRoute
          assert.equal params.bar, 'baz'
          done()
        else
          hasCalledRoute = yes
          params.bar = 'baz'
          $redirect params

      TestApp.run()

      $redirect '/?foo=bar&x=true'

    test 'route match with default params', (done) ->
      TestApp.ProductsController::show = (params) ->
        assert.equal params.id, 1, 'id is correct'
        done()
        @render false

      TestApp.root controller: 'test', action: 'index'
      TestApp.route 'show', controller: 'products', action: 'show', id: 1

      assert.equal TestApp.test('/'), TestApp.TestController::index
      $redirect '/show'

    test 'resources', (done) ->
      TestApp.ProductsController::show = (params) ->
        assert.equal params.id, 1, 'id is correct'
        done()
        @render false

      class TestApp.ImagesController extends Batman.Controller
        index: (params) ->
          assert.equal params.productId, 1, 'index correct'
          @redirect 'products/1/images/2'
        show: (params) ->
          assert.equal params.productId, 1, 'show product correct'
          assert.equal params.id, 2, 'show image correct'
          @redirect 'products/1'

      TestApp.resources 'products', ->
        @resources 'images'
        @collection ->
          @route 'testCollection'
        @member ->
          @route 'test', 'testMember'

      TestApp.ProductsController::testCollection = -> @render false
      TestApp.ProductsController::testMember = -> @render false

      assert.equal TestApp.test('products'), TestApp.ProductsController::index
      assert.equal TestApp.test('products/new'), null
      assert.equal TestApp.test('products/1'), TestApp.ProductsController::show
      assert.equal TestApp.test('products/1/edit'), TestApp.ProductsController::edit

      assert.equal TestApp.test('products/testCollection'), TestApp.ProductsController::testCollection
      assert.equal TestApp.test('products/1/test'), TestApp.ProductsController::testMember

      $redirect 'products/1/images'

    test 'multiple resources', ->
      tracker =
        products: false
        images: false

      TestApp.resources ['products', 'images'], ->
        tracker[@resource] = true

      assert.ok tracker.products
      assert.ok tracker.images

    test 'hash history', (done) ->
      Batman.config.usePushState = false
      TestApp.route 'test', ->
        window.location.hash = '#!/test2'
      TestApp.route 'test2', ->
        assert.ok true, 'routes called'
        done()
      TestApp.run()

      window.location.hash = '#!/test'

    if Batman.PushStateNavigator.isSupported()
      test 'state history',  (done) ->
        TestApp.route 'test', ->
          Batman.redirect "/test2"
        TestApp.route 'test2', ->
          assert.ok true, 'routes called'
          done()
        TestApp.run()

        Batman.redirect '/test'

    test '404', (done) ->
      TestApp.route '404', ->
        assert.ok true, '404 called'
        done()
      TestApp.run()

      $redirect 'something/random'
