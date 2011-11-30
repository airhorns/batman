suite 'Batman', ->
  suite 'Navigator', ->
    suite 'HashbangNavigator', ->
      app = false
      nav = false
      dispatchSpy = false

      setup ->
        app =
          dispatcher:
            dispatch: dispatchSpy = createSpy()
        nav = new Batman.HashbangNavigator(app)

      test "pathFromLocation(window.location) returns the app-relative path",  ->
        assert.equal nav.pathFromLocation(hash: '#!/foo/bar?page=2'), '/foo/bar?page=2'
        assert.equal nav.pathFromLocation(hash: '#/foo/bar?page=2'), '/'
        assert.equal nav.pathFromLocation(hash: '#'), '/'
        assert.equal nav.pathFromLocation(hash: ''), '/'

      test "pushState(stateObject, title, path) sets window.location.hash",  ->
        nav.pushState(null, '', '/foo/bar')
        assert.equal window.location.hash, "#!/foo/bar"

      unless IN_NODE #jsdom doesn't like window.location.replace
        test "replaceState(stateObject, title, path) replaces the current history entry", (done) ->
          window.location.hash = '#!/one'
          window.location.hash = '#!/two'
          nav.replaceState(null, '', '/three')
          assert.equal window.location.hash, "#!/three"

          window.history.back()

          doWhen (-> window.location.hash is "#!/one"), ->
            assert.equal window.location.hash, "#!/one"
            done()

      test "handleLocation(window.location) dispatches based on pathFromLocation",  ->
        nav.handleLocation
          pathname: Batman.config.pathPrefix
          search: ''
          hash: '#!/foo/bar?page=2'
        assert.equal dispatchSpy.callCount, 1
        assert.deepEqual dispatchSpy.lastCallArguments, ["/foo/bar?page=2"]

      test "handleLocation(window.location) handles the real non-hashbang path if present, but only if Batman.config.usePushState is true",  ->
        location =
          pathname: nav.normalizePath(Batman.config.pathPrefix, '/baz')
          search: '?q=buzz'
          hash: '#!/foo/bar?page=2'
          replace: createSpy()
        nav.handleLocation(location)
        assert.equal location.replace.callCount, 1
        assert.deepEqual location.replace.lastCallArguments, ["#{Batman.config.pathPrefix}#!/baz?q=buzz"]

        Batman.config.usePushState = no
        nav.handleLocation(location)
        assert.equal location.replace.callCount, 1
