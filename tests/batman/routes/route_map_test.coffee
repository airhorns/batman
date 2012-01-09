QUnit.module "Batman.RouteMap"
  setup: ->
    @routeMap = new Batman.RouteMap

test "should error if two routes with the same name are added", 1, ->
  route = {isRoute: true}
  @routeMap.addRoute('foo', route)
  try
    @routeMap.addRoute('foo', route)
  catch e
    ok e

test "routeForParams should return undefined if no route's test passes", 1, ->
  routeA = {isRoute: true, test: -> false}
  routeB = {isRoute: true, test: -> false}
  routeC = {isRoute: true, test: -> false}
  @routeMap.addRoute('A', routeA)
  @routeMap.addRoute('B', routeB)
  @routeMap.addRoute('C', routeC)

  equal typeof @routeMap.routeForParams('/not/matched'), 'undefined'

test "routeForParams should return the route who's test passes", 1, ->
  routeA = {isRoute: true, test: -> false}
  routeB = {isRoute: true, test: -> false}
  routeC = {isRoute: true, test: -> true}
  @routeMap.addRoute('A', routeA)
  @routeMap.addRoute('B', routeB)
  @routeMap.addRoute('C', routeC)

  equal @routeMap.routeForParams('/matched'), routeC

test "routeForParams should return the first route added route who's test passes", 2, ->
  routeB = {isRoute: true, test: -> true}
  routeC = {isRoute: true, test: -> true}
  @routeMap.addRoute('B', routeB)
  @routeMap.addRoute('C', routeC)
  equal @routeMap.routeForParams('/matched'), routeB

  routeA = {isRoute: true, test: -> false}
  @routeMap.addRoute('A', routeA)
  equal @routeMap.routeForParams('/matched'), routeB
