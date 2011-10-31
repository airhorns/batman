QUnit.module 'Batman.HashHistory',
  setup: ->
    @app =
      dispatcher:
        dispatch: @dispatchSpy = createSpy()
    @history = new Batman.HashHistory(@app)

test "pathFromLocation(window.location) returns the app-relative path", ->
  location =
    
  equal @history.pathFromLocation(hash: '#!/foo/bar?page=2'), '/foo/bar?page=2'
  equal @history.pathFromLocation(hash: '#/foo/bar?page=2'), '/'
  equal @history.pathFromLocation(hash: '#'), '/'
  equal @history.pathFromLocation(hash: ''), '/'

test "pushState(stateObject, title, path) sets window.location.hash", ->
  @history.pushState(null, '', '/foo/bar')
  equal window.location.hash, "#!/foo/bar"

unless IN_NODE #jsdom doesn't like window.location.replace
  asyncTest "replaceState(stateObject, title, path) replaces the current history entry", ->
    window.location.hash = '#!/one'
    window.location.hash = '#!/two'
    @history.replaceState(null, '', '/three')
    equal window.location.hash, "#!/three"
    window.history.back()
    setTimeout ->
      equal window.location.hash, "#!/one"
      QUnit.start()
    , 500 # window.history.back() takes forever...
    
test "handleLocation(window.location) dispatches based on pathFromLocation", ->
  @history.handleLocation
    pathname: Batman.pathPrefix
    search: ''
    hash: '#!/foo/bar?page=2'
  equal @dispatchSpy.callCount, 1
  deepEqual @dispatchSpy.lastCallArguments, ["/foo/bar?page=2"]
