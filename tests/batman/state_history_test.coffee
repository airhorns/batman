QUnit.module 'Batman.StateHistory',
  setup: ->
    @app =
      dispatcher:
        dispatch: @dispatchSpy = createSpy()
    @history = new Batman.StateHistory(@app)

test "pathFromLocation(window.location) returns the app-relative path", ->
  location =
    pathname: Batman.Navigation.normalizePath(Batman.pathPrefix, 'foo/bar')
    search: '?page=2'
  equal @history.pathFromLocation(location), '/foo/bar?page=2'
  equal @history.pathFromLocation(pathname: Batman.pathPrefix, search: ''), '/'

if Batman.StateHistory.isSupported()
  test "pushState(stateObject, title, path) prefixes the path with Batman.pathPrefix and delegates to window.history", ->
    @history.pushState(null,'','/foo/bar')
    equal window.location.pathname, "#{Batman.pathPrefix}/foo/bar"

  test "replaceState(stateObject, title, path) replaces the current history entry", ->
    originalHistoryLength = window.history.length
    @history.replaceState(null,'','/foo/bar')
    equal window.location.pathname, "#{Batman.pathPrefix}/foo/bar"
    equal window.history.length, originalHistoryLength

test "handleLocation(window.location) dispatches based on pathFromLocation", ->
  @history.handleLocation
    pathname: Batman.Navigation.normalizePath(Batman.pathPrefix, 'foo/bar')
    search: '?page=2'
    hash: '#!/unused'
  equal @dispatchSpy.callCount, 1
  deepEqual @dispatchSpy.lastCallArguments, ["/foo/bar?page=2"]

test "handleLocation(window.location) uses the hashbang if necessary", ->
  @dispatchSpy.whichReturns("/foo/bar?page=2")
  @history.replaceState = createSpy()
  @history.handleLocation hash: '#!/foo/bar?page=2'
  equal @history.replaceState.callCount, 1
  deepEqual @history.replaceState.lastCallArguments, [null, '', '/foo/bar?page=2']
