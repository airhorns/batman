helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View route rendering',
  setup: ->
    @defaultHistoryManagerClass = Batman.HistoryManager.defaultClass
  teardown: ->
    Batman.HistoryManager.defaultClass = @defaultHistoryManagerClass

asyncTest 'should set href for URL fragment', 1, ->
  helpers.render '<a data-route="/test">click</a>', {},
  (node) =>
    equal node.attr('href'), Batman.HistoryManager.defaultClass::urlFor("/test")
    QUnit.start()

asyncTest 'should set hash href for URL fragment when using HashHistory', 1, ->
  Batman.HistoryManager.defaultClass = Batman.HashHistory
  helpers.render '<a data-route="/test">click</a>', {},
  (node) =>
    equal node.attr('href'), "#!/test"
    QUnit.start()

asyncTest 'should set corresponding href for model and action', 1, ->
  class @App extends Batman.App
    @layout: null
    @resources 'tweets'
  class @App.Tweet extends Batman.Model
  class @App.TweetsController extends Batman.Controller
    show: (params) ->

  @App.run()

  tweet = new @App.Tweet(id: 1)
  @App.set 'tweet', tweet

  source = '<a data-route="Tweet">index</a>' +
    '<a data-route="Tweet/new">new</a>' +
    '<a data-route="tweet">show</a>' +
    '<a data-route="tweet/edit">edit</a>'

  node = document.createElement 'div'
  node.innerHTML = source

  view = new Batman.View
    contexts: []
    node: node
  view.on 'ready', ->
    urls = ($(a).attr('href') for a in view.get('node').children)
    expected = ['/tweets', '/tweets/new', '/tweets/1', '/tweets/1/edit'].map (path) ->
      Batman.HistoryManager.defaultClass::urlFor(path)
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
    deepEqual urls, [Batman.HistoryManager.defaultClass::urlFor('/foo/bar'), '']
    QUnit.start()
  view.get 'node'
