QUnit.module "Batman.Route"

test "routes should match and dispatch", 3, ->
  @route = new Batman.CallbackActionRoute "/why/where/what", {callback: spy = createSpy()}

  ok @route.test "/why/where/what"
  ok !@route.test "/when/how"

  @route.dispatch path = "/why/where/what"
  deepEqual spy.lastCallArguments, [{path}]

test "routes should test against params hashes", 4, ->
  @route = new Batman.ControllerActionRoute "/products/:id/edit", {controller: 'products', action: 'edit'}

  ok @route.test {path: "/products/10/edit"}
  ok @route.test {controller: 'products', action: 'edit', id: 10}
  ok !@route.test {controller: 'products', action: 'edit'}
  ok !@route.test {controller: 'products', action: 'show', id: 10}

test "routes with extra parameters should match and dispatch", 1, ->
  @route = new Batman.CallbackActionRoute "/why/where/what", {handy: true, callback: spy = createSpy()}

  @route.dispatch path = "/why/where/what"
  deepEqual spy.lastCallArguments, [{path, handy:true}]

test "routes with named parameters should match and dispatch", 5, ->
  @route = new Batman.CallbackActionRoute "/products/:id", {callback: spy = createSpy()}

  ok @route.test "/products/10"
  ok @route.test "/products/20"
  ok !@route.test "/products/"
  ok !@route.test "/products"

  @route.dispatch "/products/10"
  deepEqual spy.lastCallArguments, [{id: '10', path: "/products/10"}]

test "routes with splat parameters should match and dispatch", 9, ->
  @route = new Batman.CallbackActionRoute "/books/*categories/all", {callback: spy = createSpy()}

  ok @route.test "/books/fiction/fantasy/vampires/all"
  ok @route.test "/books/non-fiction/biography/all"
  ok @route.test "/books/non-fiction/all"
  ok @route.test "/books//all"
  ok !@route.test "/books/"
  ok !@route.test "/books/a/b/c"

  @route.dispatch path = "/books/non-fiction/biography/all"
  deepEqual spy.lastCallArguments, [{categories: 'non-fiction/biography', path}]

  @route.dispatch path = "/books/non-fiction/all"
  deepEqual spy.lastCallArguments, [{categories: 'non-fiction', path}]

  @route.dispatch path = "/books//all"
  deepEqual spy.lastCallArguments, [{categories: '', path}]

test "routes should build paths without named parameters", 1, ->
  @route = new Batman.Route "/products", {}
  equal @route.pathFromParams({}), "/products"

test "routes should build paths with named parameters", 3, ->
  @route = new Batman.Route "/products/:id", {}
  equal @route.pathFromParams({id:1}), "/products/1"
  equal @route.pathFromParams({id:10}), "/products/10"

  @route = new Batman.Route "/products/:product_id/images/:id", {}
  equal @route.pathFromParams({product_id: 10, id:20}), "/products/10/images/20"

test "routes should build paths with splat parameters", 2, ->
  @route = new Batman.Route "/books/*categories/all", {}
  equal @route.pathFromParams({categories: ""}), "/books//all"
  equal @route.pathFromParams({categories: "fiction/fantasy"}), "/books/fiction/fantasy/all"

test "routes should build paths with query parameters", 2, ->
  @route = new Batman.Route "/books/:id", {}
  equal @route.pathFromParams({id: 1, page: 3, limit: 10}), "/books/1?page=3&limit=10"

  @route = new Batman.Route "/books/:page", {}
  equal @route.pathFromParams({id: 1, page: 3, limit: 10}), "/books/3?id=1&limit=10"

test "controller action routes should match", ->
  App =  Batman
    dispatcher: Batman
      controllers: Batman
        products: Batman
          dispatch: productSpy = createSpy()

        savedSearches: Batman
          dispatch: searchSpy = createSpy()

  @route = new Batman.ControllerActionRoute "/products/:id/edit",
    controller: 'products'
    action: 'edit'
    app: App

  ok @route.test "/products/10/edit"
  ok !@route.test "/products/10"

  @route = new Batman.ControllerActionRoute "/saved_searches/:id/duplicate",
    controller: 'savedSearches'
    action: 'duplicate'
    app: App

  ok @route.test "/saved_searches/10/duplicate"
  ok !@route.test "/saved_searches/10"

test "controller/action routes should call the controller's dispatch function", ->
  App =  Batman
    dispatcher: Batman
      controllers: Batman
        products: Batman
          dispatch: productSpy = createSpy()

        savedSearches: Batman
          dispatch: searchSpy = createSpy()

  @route = new Batman.ControllerActionRoute "/products/:id/edit",
    controller: 'products'
    action: 'edit'
    app: App

  @route.dispatch "/products/10/edit"
  equal productSpy.lastCallArguments[0], "edit"
  equal productSpy.lastCallArguments[1].id, "10"

  @route = new Batman.ControllerActionRoute "/saved_searches/:id/duplicate",
    controller: 'savedSearches'
    action: 'duplicate'
    app: App

  @route.dispatch "/saved_searches/20/duplicate"
  equal searchSpy.lastCallArguments[0], "duplicate"
  equal searchSpy.lastCallArguments[1].id, "20"
