simpleSetup = ->
    @app = Batman()
    @routeMap = Batman
      addRoute: createSpy()
      addRootRoute: createSpy()

    @builder = new Batman.RouteMapBuilder(@app, @routeMap, undefined)

QUnit.module "Batman.RouteMapBuilder defining simple routes"
  setup: simpleSetup

test "can define simple routes to a controller and action", ->
  @builder.route '/foo/bar', {controller: 'foo', action: 'bar'}

  [name, route] = @routeMap.addRoute.lastCallArguments
  ok route instanceof Batman.ControllerActionRoute
  equal route.get('controller'), 'foo'
  equal route.get('action'), 'bar'

test "can define simple routes to a controller and action with extra params", ->
  @builder.route '/foo/bar', {controller: 'foo', action: 'bar', handy: true}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal route.get('controller'), 'foo'
  equal route.get('action'), 'bar'
  deepEqual route.get('baseParams'), {handy: true}

test "can define simple routes to signatures", ->
  @builder.route '/foo/bar', "foo#bar"

  [name, route] = @routeMap.addRoute.lastCallArguments
  ok route instanceof Batman.ControllerActionRoute
  equal route.get('controller'), 'foo'
  equal route.get('action'), 'bar'

test "can define simple routes to signatures with extra options", ->
  @builder.route '/foo/bar', "foo#bar", {handy: true}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal route.get('controller'), 'foo'
  equal route.get('action'), 'bar'
  deepEqual route.get('baseParams'), {handy: true}

test "can define simple routes to callbacks", ->
  @builder.route '/foo/bar', spy = createSpy()
  [name, route] = @routeMap.addRoute.lastCallArguments
  ok route instanceof Batman.CallbackActionRoute
  equal route.get('callback'), spy

test "can define simple routes to callbacks with extra options", ->
  @builder.route '/foo/bar', spy = createSpy(), {handy: true}
  [name, route] = @routeMap.addRoute.lastCallArguments
  equal route.get('callback'), spy
  deepEqual route.get('baseParams'), {handy: true}

test "can name routes", ->
  @builder.route '/foo/bar', {as: 'baz'}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'baz'

test "autogenerates names for routes from the path if not given", ->
  @builder.route 'foo', ->
  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'foo'

  @builder.route '/foo/bar', ->
  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'fooBar'

  @builder.route '/somethings/:id', ->
  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'somethings'

  @builder.route '/somethings/:id/new', ->
  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'somethingsNew'

QUnit.module "Batman.RouteMapBuilder defining resource routes"
  setup: simpleSetup

test "can define resource routes", 13, ->
  @builder.resources 'products'

  expectedActions = {}
  for call in @routeMap.addRoute.calls
    [name, route] = call.arguments

    ok route instanceof Batman.ControllerActionRoute
    equal route.get('controller'), 'products'
    expectedActions[route.get('action')] = route

  ok expectedActions['index'], 'index route is created'
  ok expectedActions['new'], 'new route is created'
  ok expectedActions['show'], 'show route is created'
  ok expectedActions['edit'], 'edit route is created'
  equal Object.keys(expectedActions).length, 4, 'no more than the expected routes are created'

test "can define resource routes to multi word controllers", 10, ->
  @builder.resources 'saved_searches'

  expectedActions = {}
  for call in @routeMap.addRoute.calls
    [name, route] = call.arguments

    ok route instanceof Batman.ControllerActionRoute
    equal route.get('controller'), 'savedSearches'
    expectedActions[route.get('action')] = route

  ok expectedActions['index'].test '/saved_searches'
  ok expectedActions['show'].test '/saved_searches/10'

test "will only define the resource routes specified by the only option", 3, ->
  @builder.resources 'products', {only: ['show', 'new']}

  expectedActions = {}
  for call in @routeMap.addRoute.calls
    [name, route] = call.arguments
    expectedActions[route.get('action')] = route

  ok expectedActions['new'], 'new route is created'
  ok expectedActions['show'], 'show route is created'
  equal Object.keys(expectedActions).length, 2, 'no more than the expected routes are created'

test "will not define the resource routes specified by the except option", 3, ->
  @builder.resources 'products', {except: ['show', 'new']}

  expectedActions = {}
  for call in @routeMap.addRoute.calls
    [name, route] = call.arguments
    expectedActions[route.get('action')] = route

  ok expectedActions['index'], 'index route is created'
  ok expectedActions['edit'], 'edit route is created'
  equal Object.keys(expectedActions).length, 2, 'no more than the expected routes are created'

test "show routes route to the show action", 4, ->
  @builder.resources 'products', {only: ['show']}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'products'
  equal route.get('action'), 'show'
  ok route.get('member')
  equal route.get('templatePath'), '/products/:id'

test "edit routes route to the edit action", 4, ->
  @builder.resources 'products', {only: ['edit']}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'products.edit'
  equal route.get('action'), 'edit'
  ok route.get('member')
  equal route.get('templatePath'), '/products/:id/edit'

test "new routes route to the new action", 4, ->
  @builder.resources 'products', {only: ['new']}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'products.new'
  equal route.get('action'), 'new'
  ok route.get('collection')
  equal route.get('templatePath'), '/products/new'

test "index routes route to the index action", 4, ->
  @builder.resources 'products', {only: ['index']}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'products'
  equal route.get('action'), 'index'
  ok route.get('collection')
  equal route.get('templatePath'), '/products'

test "can define nonstandard member routes", ->
  @builder.resources 'products', {only: ['index']}, ->
    @member 'duplicate', {handy: true}

  equal @routeMap.addRoute.callCount, 2
  [name, route] = @routeMap.addRoute.calls[0].arguments
  equal name, 'products.duplicate'
  equal route.get('action'), 'duplicate'
  equal route.get('controller'), 'products'
  ok route.get('member')
  ok !route.get('collection')
  deepEqual route.get('baseParams'), {handy: true}
  deepEqual route.get('templatePath'), '/products/:id/duplicate'

test "can define nonstandard collection routes", ->
  @builder.resources 'products', {only: ['show']}, ->
    @collection 'filtered', {handy: true}

  equal @routeMap.addRoute.callCount, 2
  [name, route] = @routeMap.addRoute.calls[0].arguments
  equal name, 'products.filtered'
  equal route.get('action'), 'filtered'
  equal route.get('controller'), 'products'
  ok route.get('collection')
  ok !route.get('member')
  deepEqual route.get('baseParams'), {handy: true}
  deepEqual route.get('templatePath'), '/products/filtered'

QUnit.module "Batman.RouteMapBuilder nested resources"
  setup: simpleSetup

test "can define nested resource routes", ->
  @builder.resources 'products', ->
    @resources 'images'

  equal @routeMap.addRoute.callCount, 8

test "can define nested resource routes with options on the outer call", ->
  @builder.resources 'products', {only: []}, ->
    @resources 'images'

  equal @routeMap.addRoute.callCount, 4

test "can define nested resource routes with options on the inner call", ->
  @builder.resources 'products', ->
    @resources 'images', {only: ['index']}

  equal @routeMap.addRoute.callCount, 5

test "can define nested resource routes with multiple outer resources", ->
  @builder.resources 'products', 'collections', ->
    @resources 'images'

  equal @routeMap.addRoute.callCount, 16

test "can define nested resource routes with multiple outer resources and options", ->
  @builder.resources 'products', 'collections', {handy: true}, ->
    @resources 'images'

  equal @routeMap.addRoute.callCount, 16

test "defines the four routes", ->
  @builder.resources 'products', {only: []}, ->
    @resources 'images'

  equal @routeMap.addRoute.callCount, 4

  expectedActions = {}
  for call in @routeMap.addRoute.calls
    [name, route] = call.arguments

    ok route instanceof Batman.ControllerActionRoute
    equal route.get('controller'), 'images'
    expectedActions[route.get('action')] = route

  ok expectedActions['index'], 'index route is created'
  ok expectedActions['new'], 'new route is created'
  ok expectedActions['show'], 'show route is created'
  ok expectedActions['edit'], 'edit route is created'
  equal Object.keys(expectedActions).length, 4, 'no more than the expected routes are created'

test "show routes route to the show action", 4, ->
  @builder.resources 'products', {only: []}, ->
    @resources 'images', {only: ['show']}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'products.images'
  equal route.get('action'), 'show'
  ok route.get('member')
  equal route.get('templatePath'), '/products/:productId/images/:id'

test "edit routes route to the edit action", 4, ->
  @builder.resources 'products', {only: []}, ->
    @resources 'images', {only: ['edit']}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'products.images.edit'
  equal route.get('action'), 'edit'
  ok route.get('member')
  equal route.get('templatePath'), '/products/:productId/images/:id/edit'

test "new routes route to the new action", 4, ->
  @builder.resources 'products', {only: []}, ->
    @resources 'images', {only: ['new']}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'products.images.new'
  equal route.get('action'), 'new'
  ok route.get('collection')
  equal route.get('templatePath'), '/products/:productId/images/new'

test "index routes route to the index action", 4, ->
  @builder.resources 'products', {only: []}, ->
    @resources 'images', {only: ['index']}

  [name, route] = @routeMap.addRoute.lastCallArguments
  equal name, 'products.images'
  equal route.get('action'), 'index'
  ok route.get('collection')
  equal route.get('templatePath'), '/products/:productId/images'

test "can define nonstandard member routes", ->
  @builder.resources 'products', {only: ['show']}, ->
    @resources 'images', {only: ['show']}, ->
      @member 'duplicate', {handy: true}

  equal @routeMap.addRoute.callCount, 3
  [name, route] = @routeMap.addRoute.calls[0].arguments
  equal name, 'products.images.duplicate'
  equal route.get('action'), 'duplicate'
  equal route.get('controller'), 'images'
  equal route.get('templatePath'), '/products/:productId/images/:id/duplicate'
  ok route.get('member')
  ok !route.get('collection')
  deepEqual route.get('baseParams'), {handy: true}

test "can define nonstandard collection routes", ->
  @builder.resources 'products', {only: ['show']}, ->
    @resources 'images', {only: ['show']}, ->
      @collection 'filtered', {handy: true}

  equal @routeMap.addRoute.callCount, 3
  [name, route] = @routeMap.addRoute.calls[0].arguments
  equal name, 'products.images.filtered'
  equal route.get('action'), 'filtered'
  equal route.get('controller'), 'images'
  equal route.get('templatePath'), '/products/:productId/images/filtered'
  ok route.get('collection')
  ok !route.get('member')
  deepEqual route.get('baseParams'), {handy: true}
