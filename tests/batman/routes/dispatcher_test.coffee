QUnit.module 'Batman.Dispatcher: getting controller instances'
  setup: ->
    @App = Batman()
    @dispatcher = new Batman.Dispatcher(@App, {})

test "can get defined controller's shared instance", ->
  @App.ProductsController = new Batman.Object({sharedController: @instance = {}})
  equal @dispatcher.get('controllers.products'), @instance

test "safely gets controllers named app", ->
  @App.AppController = new Batman.Object({sharedController: @instance = {}})
  equal @dispatcher.get('controllers.app'), @instance

test "safely gets nonexistant controllers", ->
  equal typeof @dispatcher.get('controllers.orders'), 'undefined'

test "safely gets multiword controllers", ->
  @App.SavedSearchesController = new Batman.Object({sharedController: @instance = {}})
  equal @dispatcher.get('controllers.savedSearches'), @instance

QUnit.module 'Batman.Dispatcher: inferring paths'
  setup: ->
    class @App extends Batman.App
    class @App.Product extends Batman.Model
    class @App.SavedSearch extends Batman.Model

    @routeMap = Batman()
    @dispatcher = new Batman.Dispatcher(@App, @routeMap)

test "paramsFromArgument gets record params", ->
  deepEqual Batman.Dispatcher.paramsFromArgument(new @App.Product(id: 1)), {controller: 'products', action: 'show', id: 1}

test "paramsFromArgument gets model params", ->
  deepEqual Batman.Dispatcher.paramsFromArgument(@App.Product), {controller: 'products', action: 'index'}

test "paramsFromArgument gets multiword record params", ->
  deepEqual Batman.Dispatcher.paramsFromArgument(new @App.SavedSearch(id: 1)), {controller: 'savedSearches', action: 'show', id: 1}

test "paramsFromArgument gets multiword model params", ->
  deepEqual Batman.Dispatcher.paramsFromArgument(@App.SavedSearch), {controller: 'savedSearches', action: 'index'}

test "paramsFromArgument gets record proxy params", ->
  proxy = new Batman.AssociationProxy({}, @App.Product)
  proxy.accessor 'target', => new @App.Product(id: 2)
  proxy.set 'loaded', true
  deepEqual Batman.Dispatcher.paramsFromArgument(proxy), {controller: 'products', action: 'show', id: 2}

test "paramsFromArgument leaves strings alone", ->
  deepEqual Batman.Dispatcher.paramsFromArgument("/products/1"), "/products/1"

test "paramsFromArgument leaves objects alone", ->
  deepEqual Batman.Dispatcher.paramsFromArgument({controller: "products", action: "new"}), {controller: "products", action: "new"}

test "routeForParams infers arguments before asking for a route", ->
  @routeMap.routeForParams = createSpy().whichReturns(undefined)
  route = @dispatcher.routeForParams(@App.Product)
  deepEqual @routeMap.routeForParams.lastCallArguments,  [{controller: 'products', action: 'index'}]

test "pathFromParams leaves strings alone", ->
  @routeMap.routeForParams = createSpy().whichReturns(undefined)
  path = @dispatcher.pathFromParams(@App.Product)
  deepEqual @routeMap.routeForParams.lastCallArguments,  [{controller: 'products', action: 'index'}]

test "pathFromParams infers arguments before asking for a route", ->
  @routeMap.routeForParams = createSpy().whichReturns(undefined)
  path = @dispatcher.pathFromParams(@App.Product)
  deepEqual @routeMap.routeForParams.lastCallArguments,  [{controller: 'products', action: 'index'}]

test "pathFromParams infers arguments before passing to the route to construct a path", ->
  equal @dispatcher.pathFromParams('/test?filter=true'), '/test?filter=true'

mockRoute = ->
  return Batman
    dispatch: createSpy((path) -> return path)
    pathFromParams: createSpy()
    paramsFromPath: createSpy()

oldRedirect = Batman.redirect

QUnit.module 'Batman.Dispatcher: dispatching routes'
  setup: ->
    @App = Batman
      currentParams: Batman
        clear: @clearSpy = createSpy()
        replace: @replaceSpy = createSpy()
      currentRoute: null
      currentURL: null

    @routeMap = Batman
      routeForParams: ->

    @dispatcher = new Batman.Dispatcher(@App, @routeMap)

  teardown: ->
    Batman.redirect = oldRedirect

test "dispatch dispatches a matched route", ->
  route = mockRoute()
  @routeMap.routeForParams = -> route

  @dispatcher.dispatch('/matched/route')

  ok route.dispatch.called

test "dispatch updates the currentRoute on the app", ->
  route = mockRoute()
  @routeMap.routeForParams = -> route

  @dispatcher.dispatch('/matched/route')
  equal @App.get('currentRoute'), route

test "dispatch updates the currentURL on the app", ->
  route = mockRoute()
  @routeMap.routeForParams = -> route

  @dispatcher.dispatch('/matched/route')
  equal @App.get('currentURL'), '/matched/route'

test "dispatch redirects to 404 if no route is found", ->
  Batman.redirect = createSpy()
  @routeMap.routeForParams = -> undefined
  @dispatcher.dispatch('/not/matched')

  deepEqual Batman.redirect.lastCallArguments, ['/404']

test "dispatch doesn't re-redirect to 404 if already there", ->
  Batman.redirect = createSpy()
  @routeMap.routeForParams = -> undefined
  @dispatcher.dispatch('/not/matched')
  @dispatcher.dispatch('/404')

  deepEqual Batman.redirect.lastCallArguments, ['/404']
  equal Batman.redirect.callCount, 1

test "dispatch replaces app.currentParams when given a vanilla object", ->
  @routeMap.routeForParams = -> undefined
  @dispatcher.dispatch({foo: 'bar'})

  deepEqual @App.currentParams.replace.lastCallArguments, [{foo: 'bar'}]

test "dispatch clears app.currentParams when no route is found", ->
  @routeMap.routeForParams = -> undefined
  @dispatcher.dispatch('/not/matched')

  ok @App.currentParams.clear.called

test "dispatch clears app.currentParams when a route can't be inferred from the given argument", ->
  @routeMap.routeForParams = -> undefined
  @dispatcher.dispatch(new Batman.Model)

  ok @App.currentParams.clear.called
