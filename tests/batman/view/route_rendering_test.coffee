helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'
{TestStorageAdapter} = if typeof require isnt 'undefined' then require '../model/model_helper' else window

oldRedirect = Batman.redirect
QUnit.module 'Batman.View route rendering',
  setup: ->
    class @App extends Batman.App
      @layout: null
      @route '/test', ->
    Batman.redirect = @redirect = createSpy()
  teardown: ->
    Batman.redirect = oldRedirect
    @App.stop()

asyncTest 'should set href for URL fragment', 1, ->
  @App.on 'run', ->
    helpers.render '<a data-route="\'/test\'">click</a>', {}, (node) =>
      equal node.attr('href'), Batman.Navigator.defaultClass()::linkTo("/test")
      QUnit.start()
  @App.run()

asyncTest 'should redirect when clicked', 1, ->
  @App.on 'run', =>
    helpers.render '<a data-route="\'/test\'">click</a>', {}, (node) =>
      helpers.triggerClick(node[0])
      delay =>
        deepEqual @redirect.lastCallArguments['/test']
  @App.run()

asyncTest 'should set "#" href for undefined keypath', 1, ->
  @App.on 'run', ->
    helpers.render '<a data-route="not.defined">click</a>', {}, (node) =>
      equal node.attr('href'), "#"
      QUnit.start()
  @App.run()

asyncTest 'should set hash href for URL fragment when using HashbangNavigator', 1, ->
  Batman.config.usePushState = false
  @App.on 'run', ->
    helpers.render '<a data-route="\'/test\'">click</a>', {}, (node) =>
      equal node.attr('href'), "#!/test"
      QUnit.start()
  @App.run()

asyncTest 'should set corresponding href for model and action', 1, ->
  @App.resources 'tweets', 'users'

  class @App.User extends Batman.Model
    @persist TestStorageAdapter

  app = @App
  class @App.Tweet extends Batman.Model
    @belongsTo 'user', {namespace: app}

  class @App.TweetsController extends Batman.Controller
    show: (params) ->

  @App.on 'run', =>
    user = new @App.User(id: 2)
    user.save (err) =>
      throw err if err

      tweet = new @App.Tweet(id: 1, user_id: user.get('id'))
      tweet.get('user').load (err, user) =>
        throw err if err

        @App.set 'tweet', tweet

        source = '''
          <a data-route="Tweet">index</a>
          <a data-route="Tweet | routeToAction 'new'">new</a>
          <a data-route="tweet">show</a>
          <a data-route="tweet | routeToAction 'edit'">edit</a>
          <a data-route="tweet.user">user</a>
          <a data-route="tweet.user | routeToAction 'edit'">edit user</a>
        '''

        helpers.render source, {}, (node, view) ->
          urls = ($(a).attr('href') for a in $('a', view.get('node')))
          expected = ['/tweets', '/tweets/new', '/tweets/1', '/tweets/1/edit', '/users/2', '/users/2/edit']
          expected = expected.map (path) -> Batman.navigator.linkTo(path)
          deepEqual urls, expected
          QUnit.start()

  @App.run()

asyncTest 'should bind to models when routing to them', 2, ->
  @App.resources 'tweets', ->
    @member 'duplicate'

  class @App.Tweet extends Batman.Model

  class @App.TweetsController extends Batman.Controller
    show: (params) ->
    duplicate: (params) ->

  tweetA = new @App.Tweet(id: 1)
  tweetB = new @App.Tweet(id: 2)

  @App.on 'run', =>
    source = '''
      <a data-route="tweet">index</a>
      <a data-route="tweet | routeToAction 'duplicate'">duplicate</a>
    '''

    context = Batman
      tweet: tweetA


    helpers.render source, context, (node, view) ->
      checkUrls = (expected) ->
        urls = ($(a).attr('href') for a in $('a', view.get('node')))
        expected = expected.map (path) -> Batman.navigator.linkTo(path)
        deepEqual urls, expected

      checkUrls ['/tweets/1', '/tweets/1/duplicate']
      context.set 'tweet', tweetB

      delay ->
        checkUrls ['/tweets/2', '/tweets/2/duplicate']

  @App.run()

asyncTest 'should allow you to use {controller, action} routes, if they are defined', 1, ->
  @App.route 'foo/bar', 'foo#bar'
  class @App.FooController extends Batman.Controller
    bar: ->

  @App.on 'run', ->
    source = '''
      <a data-route="{'controller': 'foo', 'action': 'bar'}">bar</a>
      <a data-route="{'controller': 'foo', 'action': 'baz'}">baz</a>
    '''

    viewHelpers.render source, {}, (node, view) ->
      urls = ($(a).attr('href') for a in $('a', view.get('node')))
      urls[i] = url || '' for url, i in urls
      deepEqual urls, [Batman.navigator.linkTo('/foo/bar'), '#']
      QUnit.start()

  @App.run()

asyncTest 'should allow you to bind to objects in the context stack', 2, ->
  @App.route 'foo/bar', 'foo#bar'
  @App.route 'baz/qux', 'baz#qux'
  class @App.FooController extends Batman.Controller
    bar: ->
  class @App.BazController extends Batman.Controller
    qux: ->

  @App.on 'run', ->
    source = '''
      <a data-route="whereToRedirect">bar</a>
    '''

    context = Batman
      whereToRedirect:
        controller: 'foo'
        action: 'bar'

    viewHelpers.render source, false, context, (node, view) ->
      a = $(node.childNodes[0])
      deepEqual a.attr('href'), Batman.navigator.linkTo('/foo/bar')
      context.set 'whereToRedirect',
        controller: 'baz'
        action: 'qux'
      delay ->
        deepEqual a.attr('href'), Batman.navigator.linkTo('/baz/qux')

  @App.run()

asyncTest 'should allow you to use named route queries', 2, ->
  @App.resources 'products', ->
    @resources 'images', ->
      @member 'duplicate'

  @App.on 'run', ->
    source = '''
      <a data-route="routes.products">products index</a>
      <a data-route="routes.products.new">products new</a>
      <a data-route="routes.products[product]">product show</a>
      <a data-route="routes.products[product].images">images index</a>
      <a data-route="routes.products[product].images[image]">images show</a>
      <a data-route="routes.products[product].images[image].duplicate">image member</a>
    '''

    context = Batman
      product: Batman
        toParam: -> 10
      image: Batman
        toParam: -> 20

    viewHelpers.render source, false, context, (node, view) ->
      checkUrls = (expected) ->
        urls = ($(a).attr('href') for a in $('a', view.get('node')))
        expected = expected.map (path) -> Batman.navigator.linkTo(path)
        deepEqual urls, expected

      expected = ['/products', '/products/new', '/products/10', '/products/10/images', '/products/10/images/20', '/products/10/images/20/duplicate']
      checkUrls(expected)

      context.set 'product', Batman(toParam: -> 30)
      delay ->
        expected = ['/products', '/products/new', '/products/30', '/products/30/images', '/products/30/images/20', '/products/30/images/20/duplicate']
        checkUrls(expected)

  @App.run()

asyncTest 'should redirect to named route queries when clicked', 1, ->
  @App.resources 'products'

  @App.on 'run', =>
    source = '<a data-route="routes.products.new">products new</a>'

    context = Batman
      product: Batman
        toParam: -> 10

    viewHelpers.render source, context, (node, view) =>
      delay =>
        helpers.triggerClick(node[0])
        delay =>
          deepEqual @redirect.lastCallArguments, ['/products/new']

  @App.run()
