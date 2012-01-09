QUnit.module 'Batman.PushStateNavigator',
  setup: ->
    @app = Batman
      dispatcher:
        dispatch: @dispatchSpy = createSpy()
    @nav = new Batman.PushStateNavigator(@app)

test "pathFromLocation(window.location) returns the app-relative path", ->
  location =
    pathname: @nav.normalizePath(Batman.config.pathPrefix, 'foo/bar')
    search: '?page=2'
  equal @nav.pathFromLocation(location), '/foo/bar?page=2'
  equal @nav.pathFromLocation(pathname: Batman.config.pathPrefix, search: ''), '/'

if Batman.PushStateNavigator.isSupported()
  test "pushState(stateObject, title, path) prefixes the path with Batman.config.pathPrefix and delegates to window.history", ->
    @nav.pushState(null,'','/foo/bar')
    equal window.location.pathname, "#{Batman.config.pathPrefix}/foo/bar"

  test "replaceState(stateObject, title, path) replaces the current history entry", ->
    originalHistoryLength = window.history.length
    @nav.replaceState(null,'','/foo/bar')
    equal window.location.pathname, "#{Batman.config.pathPrefix}/foo/bar"
    equal window.history.length, originalHistoryLength

test "handleLocation(window.location) dispatches based on pathFromLocation", ->
  @nav.handleLocation
    pathname: @nav.normalizePath(Batman.config.pathPrefix, 'foo/bar')
    search: '?page=2'
    hash: '#!/unused'
  equal @dispatchSpy.callCount, 1
  deepEqual @dispatchSpy.lastCallArguments, ["/foo/bar?page=2"]

test "handleLocation(window.location) uses the hashbang if necessary", ->
  @dispatchSpy.whichReturns("/foo/bar?page=2")
  @nav.replaceState = createSpy()
  @nav.handleLocation hash: '#!/foo/bar?page=2'
  equal @nav.replaceState.callCount, 1
  deepEqual @nav.replaceState.lastCallArguments, [null, '', '/foo/bar?page=2']
