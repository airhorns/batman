helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View route rendering',
  setup: ->

asyncTest 'should set href for URL fragment', 1, ->
  helpers.render '<a data-route="/test">click</a>', {},
  (node) =>
    equal node.attr('href'), Batman.Navigator.defaultClass()::linkTo("/test")
    QUnit.start()

asyncTest 'should set hash href for URL fragment when using HashbangNavigator', 1, ->
  Batman.config.usePushState = false
  helpers.render '<a data-route="/test">click</a>', {},
  (node) =>
    equal node.attr('href'), "#!/test"
    QUnit.start()

asyncTest 'should set corresponding href for model and action', 1, ->
  app = class @App extends Batman.App
    @layout: null
    @resources ['tweets', 'users']

  class @App.User extends Batman.Model
  class @App.Tweet extends Batman.Model
    @belongsTo 'user', {namespace: app}

  class @App.TweetsController extends Batman.Controller
    show: (params) ->

  @App.run()

  user = new @App.User(id: 2)
  @App.User._mapIdentity(user)
  tweet = new @App.Tweet(id: 1, user_id: user.get('id'))
  @App.set 'tweet', tweet

  source = '<a data-route="Tweet">index</a>' +
    '<a data-route="Tweet/new">new</a>' +
    '<a data-route="tweet">show</a>' +
    '<a data-route="tweet/edit">edit</a>' +
    '<a data-route="tweet.user">user</a>' +
    '<a data-route="tweet.user/edit">edit user</a>'

  node = document.createElement 'div'
  node.innerHTML = source

  view = new Batman.View
    contexts: []
    node: node

  view.on 'ready', ->
    urls = ($(a).attr('href') for a in view.get('node').childNodes)
    expected = ['/tweets', '/tweets/new', '/tweets/1', '/tweets/1/edit', '/users/2', '/users/2/edit'].map (path) -> Batman.Navigator.defaultClass()::linkTo(path)
    deepEqual urls, expected
    QUnit.start()

  view.get 'node'

asyncTest 'should allow you to use controller#action routes, if they are defined', 1, ->
  class @App extends Batman.App
    @layout: null
    @route 'foo/bar', 'foo#bar'
  class @App.FooController extends Batman.Controller
    bar: ->

  @App.run()

  source = '<a data-route="foo#bar">bar</a><a data-route="foo#baz">baz</a>'
  node = document.createElement 'div'
  node.innerHTML = source

  view = new Batman.View
    contexts: []
    node: node
  view.on 'ready', ->
    urls = ($(a).attr('href') for a in view.get('node').children)
    urls[i] = url || '' for url, i in urls
    deepEqual urls, [Batman.Navigator.defaultClass()::linkTo('/foo/bar'), '']
    QUnit.start()
  view.get 'node'
