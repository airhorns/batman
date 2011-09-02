helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View filter execution'

asyncTest 'get', 1, ->
  context = Batman
    foo: new Batman.Hash({bar: "qux"})

  helpers.render '<div data-bind="foo | get \'bar\'"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'get short syntax', 1, ->
  context = Batman
    foo: new Batman.Hash({bar: "qux"})

  helpers.render '<div data-bind="foo[\'bar\']"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'truncate', 2, ->
  helpers.render '<div data-bind="foo | truncate 5"></div>',
    foo: 'your mother was a hampster'
  , (node) ->
    equals node.html(), "yo..."

    helpers.render '<div data-bind="foo.bar | truncate 5, \'\'"></div>',
      foo: Batman
        bar: 'your mother was a hampster'
    , (node) ->
      equals node.html(), "your "
      QUnit.start()

asyncTest 'prepend', 1, ->
  helpers.render '<div data-bind="foo | prepend \'special-\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "special-bar"
    QUnit.start()

asyncTest 'append', 1, ->
  helpers.render '<div data-bind="foo | append \'-special\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "bar-special"
    QUnit.start()

asyncTest 'downcase', 1, ->
  helpers.render '<div data-bind="foo | downcase"></div>',
    foo: 'BAR'
  , (node) ->
    equals node.html(), "bar"
    QUnit.start()

asyncTest 'upcase', 1, ->
  helpers.render '<div data-bind="foo | upcase"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "BAR"
    QUnit.start()

asyncTest 'join', 2, ->
  helpers.render '<div data-bind="foo | join"></div>',
    foo: ['a', 'b', 'c']
  , (node) ->
    equals node.html(), "abc"

    helpers.render '<div data-bind="foo | join \'|\'"></div>',
      foo: ['a', 'b', 'c']
    , (node) ->
      equals node.html(), "a|b|c"
      QUnit.start()

asyncTest 'sort', 1, ->
  helpers.render '<div data-bind="foo | sort | join"></div>',
    foo: ['b', 'c', 'a', '1']
  , (node) ->
    equals node.html(), "1abc"
    QUnit.start()

asyncTest 'not', 1, ->
  helpers.render '<div data-showif="foo | not"></div>',
    foo: true
  , (node) ->
    equals node[0].style.display, "none"
    QUnit.start()


asyncTest 'map', 1, ->
  helpers.render '<div data-bind="posts | map \'name\' | join \', \'"></div>',
    posts: [
      Batman
        name: 'one'
        comments: 10
    , Batman
        name: 'two'
        comments: 20
    ]
  , (node) ->
    equals node.html(), "one, two"
    QUnit.start()

asyncTest 'map with a numeric key', 1, ->
  helpers.render '<div data-bind="counts | map 1 | join \', \'"></div>',
    counts: [
      [1, 2, 3]
      [4, 5, 6]
    ]
  , (node) ->
    equals node.html(), "2, 5"
    QUnit.start()

asyncTest 'map', 1, ->
  helpers.render '<div data-bind="posts | map \'name\' | join \', \'"></div>',
    posts: [
      Batman
        name: 'one'
        comments: 10
    , Batman
        name: 'two'
        comments: 20
    ]
  , (node) ->
    equals node.html(), "one, two"
    QUnit.start()

QUnit.module "Batman.View user defined filter execution"

asyncTest 'should render a user defined filter', 2, ->
  Batman.Filters['test'] = spy = createSpy().whichReturns("testValue")
  helpers.render '<div data-bind="foo | test 1, \'baz\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "testValue"
    deepEqual spy.lastCallArguments, ['bar', 1, 'baz']
    QUnit.start()

