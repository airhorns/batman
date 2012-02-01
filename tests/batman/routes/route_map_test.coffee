QUnit.module "Batman.RouteMap"
  setup: ->
    @routeMap = new Batman.RouteMap

mockRoute = (props) ->
  return Batman(props)

test "should error if two routes with the same name are added", 2, ->
  route = mockRoute {isRoute: true}
  @routeMap.addRoute('foo', route)
  raises (-> @routeMap.addRoute('foo', route)), (message) -> ok message; true

test "routeForParams should return undefined if no route's test passes", 1, ->
  routeA = mockRoute {isRoute: true, test: -> false}
  routeB = mockRoute {isRoute: true, test: -> false}
  routeC = mockRoute {isRoute: true, test: -> false}
  @routeMap.addRoute('A', routeA)
  @routeMap.addRoute('B', routeB)
  @routeMap.addRoute('C', routeC)

  equal typeof @routeMap.routeForParams('/not/matched'), 'undefined'

test "routeForParams should return the route who's test passes", 1, ->
  routeA = mockRoute {isRoute: true, test: -> false}
  routeB = mockRoute {isRoute: true, test: -> false}
  routeC = mockRoute {isRoute: true, test: -> true}
  @routeMap.addRoute('A', routeA)
  @routeMap.addRoute('B', routeB)
  @routeMap.addRoute('C', routeC)

  equal @routeMap.routeForParams('/matched'), routeC

test "routeForParams should return the first route added route who's test passes", 2, ->
  routeB = mockRoute {isRoute: true, test: -> true}
  routeC = mockRoute {isRoute: true, test: -> true}
  @routeMap.addRoute('B', routeB)
  @routeMap.addRoute('C', routeC)
  equal @routeMap.routeForParams('/matched'), routeB

  routeA = mockRoute {isRoute: true, test: -> false}
  @routeMap.addRoute('A', routeA)
  equal @routeMap.routeForParams('/matched'), routeB
