suite 'Batman', ->
  suite 'Navigator', ->
    suite 'PushStateNavigator', ->
      app = false
      nav = false
      dispatchSpy = false

      setup ->
        app =
          dispatcher:
            dispatch: dispatchSpy = createSpy()
        nav = new Batman.PushStateNavigator(app)

      test "pathFromLocation(window.location) returns the app-relative path",  ->
        location =
          pathname: nav.normalizePath(Batman.config.pathPrefix, 'foo/bar')
          search: '?page=2'
        assert.equal nav.pathFromLocation(location), '/foo/bar?page=2'
        assert.equal nav.pathFromLocation(pathname: Batman.config.pathPrefix, search: ''), '/'

      if Batman.PushStateNavigator.isSupported()
        test "pushState(stateObject, title, path) prefixes the path with Batman.config.pathPrefix and delegates to window.history",  ->
          nav.pushState(null,'','/foo/bar')
          assert.equal window.location.pathname, "#{Batman.config.pathPrefix}/foo/bar"

        test "replaceState(stateObject, title, path) replaces the current history entry",  ->
          originalHistoryLength = window.history.length
          nav.replaceState(null,'','/foo/bar')
          assert.equal window.location.pathname, "#{Batman.config.pathPrefix}/foo/bar"
          assert.equal window.history.length, originalHistoryLength

      test "handleLocation(window.location) dispatches based on pathFromLocation",  ->
        nav.handleLocation
          pathname: nav.normalizePath(Batman.config.pathPrefix, 'foo/bar')
          search: '?page=2'
          hash: '#!/unused'
        assert.equal dispatchSpy.callCount, 1
        assert.deepEqual dispatchSpy.lastCallArguments, ["/foo/bar?page=2"]

      test "handleLocation(window.location) uses the hashbang if necessary",  ->
        dispatchSpy.whichReturns("/foo/bar?page=2")
        nav.replaceState = createSpy()
        nav.handleLocation hash: '#!/foo/bar?page=2'
        assert.equal nav.replaceState.callCount, 1
        assert.deepEqual nav.replaceState.lastCallArguments, [null, '', '/foo/bar?page=2']
