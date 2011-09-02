helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View route rendering'

asyncTest 'should set href for URL fragment', 1, ->
  helpers.render '<a data-route="/test">click</a>', {},
  (node) =>
    equal node.attr('href'), '#!/test'
    QUnit.start()

unless IN_NODE
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
      '<a data-route="tweet">show</a>' +
      '<a data-route="tweet/edit">edit</a>' +
      '<a data-route="tweet/destroy">destroy</a>'
    node = document.createElement 'div'
    node.innerHTML = source

    view = new Batman.View
      contexts: []
      node: node
    view.ready ->
      urls = ($(a).attr('href') for a in view.get('node').children)
      deepEqual urls, ['#!/tweets', '#!/tweets/1', '#!/tweets/1/edit', '#!/tweets/1/destroy']
      QUnit.start()
    view.get 'node'

