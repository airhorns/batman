helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module "Batman.View filter value and parameter parsing"
  setup: ->
    Batman.Filters['test'] = @spy = createSpy().whichReturns("testValue")
  teardown: ->
    delete Batman.Filters.test

asyncTest "should parse one segment keypaths as values", ->
  helpers.render '<div data-bind="foo | test"></div>', Batman(foo: "bar"), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, ["bar"]
    QUnit.start()

asyncTest "should parse many segment keypaths as values", ->
  helpers.render '<div data-bind="foo.bar | test"></div>', Batman(foo: Batman(bar: "baz")), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, ["baz"]
    QUnit.start()

asyncTest "should parse one segment keypaths as arguments", ->
  helpers.render '<div data-bind="1 | test foo"></div>', Batman(foo: "bar"), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, "bar"]
    QUnit.start()

asyncTest "should parse one segment keypaths as arguments anywhere in the list of arguments", ->
  helpers.render '<div data-bind="1 | test foo, 2, bar, 3, baz"></div>', Batman(foo: "a", bar: "b", baz: "c"), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, "a", 2, "b", 3, "c"]
    QUnit.start()

asyncTest "should parse one segment keypaths as arguments anywhere in the list of arguments", ->
  helpers.render '<div data-bind="1 | test qux.foo, 2, qux.bar, 3, qux.baz"></div>', Batman(qux: Batman(foo: "a", bar: "b", baz: "c")), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, "a", 2, "b", 3, "c"]
    QUnit.start()

asyncTest "should parse many segment keypaths as arguments", ->
  helpers.render '<div data-bind="1 | test foo.bar"></div>', Batman(foo: Batman(bar: "baz")), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, "baz"]
    QUnit.start()

asyncTest "should parse keypaths containing true as arguments", ->
  helpers.render '<div data-bind="1 | test true.bar"></div>', Batman("true": Batman(bar: "baz")), (node) =>
    deepEqual @spy.lastCallArguments, [1, "baz"]

    helpers.render '<div data-bind="1 | test truesay.bar"></div>', Batman(truesay: Batman(bar: "baz")), (node) =>
      deepEqual @spy.lastCallArguments, [1, "baz"]
      QUnit.start()

asyncTest "should parse keypaths containing false as arguments", ->
  helpers.render '<div data-bind="1 | test false.bar"></div>', Batman("false": Batman(bar: "baz")), (node) =>
    deepEqual @spy.lastCallArguments, [1, "baz"]
    helpers.render '<div data-bind="1 | test falsified.bar"></div>', Batman(falsified: Batman(bar: "baz")), (node) =>
      deepEqual @spy.lastCallArguments, [1, "baz"]
      QUnit.start()

asyncTest "should not parse true or false as a keypath", ->
  helpers.render '<div data-bind="1 | test true"></div>', Batman("true": Batman(bar: "baz")), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, true]
    helpers.render '<div data-bind="1 | test false"></div>', Batman(truesay: Batman(bar: "baz")), (node) =>
      equals node.html(), "testValue"
      deepEqual @spy.lastCallArguments, [1, false]
      QUnit.start()

asyncTest 'should render chained filters', 1, ->
  node = helpers.render '<div data-bind="foo | upcase | downcase"></div>',
    foo: 'foo'
  , (node) ->
    equals node.html(), "foo"
    QUnit.start()

asyncTest 'should update bindings with the filtered value if they change', 1, ->
  context = Batman
    foo: 'bar'
  helpers.render '<div data-bind="foo | upcase"></div>', context, (node) ->
    context.set('foo', 'baz')
    equals node.html(), 'BAZ'
    QUnit.start()

asyncTest 'should allow filtering on attributes', 2, ->
  helpers.render '<div data-addclass-works="bar | first" data-bind-attr="foo | upcase "></div>',
    foo: "bar"
    bar: [true]
  , (node) ->
    ok node.hasClass('works')
    equals node.attr('attr'), 'BAR'
    QUnit.start()

asyncTest 'should allow filtering on simple values', 1, ->
  helpers.render '<div data-bind="\'foo\' | upcase"></div>', {}, (node) ->
    equals node.html(), 'FOO'
    QUnit.start()

asyncTest 'should allow filtering on objects and arrays', 2, ->
  helpers.render '<div data-bind="[1,2,3] | join \' \'"></div>', {}, (node) ->
    equals node.html(), '1 2 3'

    Batman.Filters.dummyObjectFilter = (value, key) -> value[key]
    helpers.render '<div data-bind="{\'foo\': \'bar\', \'baz\': 4} | dummyObjectFilter \'foo\'"></div>', {}, (node) ->
      equals node.html(), 'bar'
      delete Batman.Filters.dummyObjectFilter
      QUnit.start()

asyncTest 'should allow keypaths as arguments to filters', 1, ->
  helpers.render '<div data-bind="foo | join bar"></div>',
    foo: [1,2,3]
    bar: ':'
  , (node) ->
    equals node.html(), '1:2:3'
    QUnit.start()

asyncTest 'should allow many keypaths as arguments to filters', 1, ->
  Batman.Filters.joining = (sep, values...) ->
    values.join(sep)

  helpers.render '<div data-bind="foo | joining bar, baz, qux"></div>',
    foo: ' '
    bar: 'a'
    baz: 'b'
    qux: 'c'
  , (node) ->
    delete Batman.Filters.joining
    equals node.html(), 'a b c'
    QUnit.start()

asyncTest 'should allow a mix of keypaths and simple values as arguments to filters', 2, ->
  Batman.Filters.joining = (sep, values...) ->
    values.join(sep)

  context = Batman
    foo: ' '
    bar: 'a'
    baz: 'b'
    qux: 'c'

  helpers.render '<div data-bind="foo | joining \'a\', baz, \'c\'"></div>', context, (node) ->
    equals node.html(), 'a b c'
    helpers.render '<div data-bind="foo | joining bar, \'b\', qux"></div>', context, (node) ->
      delete Batman.Filters.joining
      equals node.html(), 'a b c'
      QUnit.start()

renderWithoutBatmanizing = (source, context, callback) ->
  node = document.createElement('div')
  node.innerHTML = source

  view = new Batman.View
    node: node
    context: context

  view.on 'ready', callback
  view.get('node')

asyncTest 'should allow argument values which are simple objects', 2, ->
  context =
    foo: 'foo'
    bar:
      baz: "qux"

  Batman.Filters.test = (val, arg) ->
    equal val, 'foo'
    deepEqual arg, {baz: "qux"}

  node = document.createElement('div')
  renderWithoutBatmanizing '<div data-bind="foo | test bar"></div>', context, ->
    delete Batman.Filters.test
    QUnit.start()

asyncTest 'should allow argument values which are in the context of simple objects', 2, ->
  context =
    foo: 'foo'
    bar:
      baz: "qux"

  Batman.Filters.test = (val, arg) ->
    equal val, 'foo'
    equal arg, "qux"

  renderWithoutBatmanizing '<div data-bind="foo | test bar.baz"></div>', context, ->
    delete Batman.Filters.test
    QUnit.start()

asyncTest 'should update bindings when argument keypaths change', 2, ->
  context = Batman
    foo: [1,2,3]
    bar: ''

  helpers.render '<div data-bind="foo | join bar"></div>', context, (node) ->
    equals node.html(), '123'
    context.set('bar', "-")
    delay ->
      equals node.html(), '1-2-3'

asyncTest 'should update bindings when argument keypaths change in the middle of the keypath', 2, ->
  context = Batman
    foo: Batman
      bar: '.'
    array: [1,2,3]

  helpers.render '<div data-bind="array | join foo.bar"></div>', context, (node) ->
    equals node.html(), '1.2.3'
    context.set('foo', Batman(bar: '-'))
    delay ->
      equals node.html(), '1-2-3'

asyncTest 'should update bindings when argument keypaths change context', 2, ->
  context = Batman
    foo: '.'
    array: [1,2,3]

  closer = Batman
    closer: true

  node = document.createElement 'div'
  node.innerHTML = '<div data-bind="array | join foo"></div>'
  context = Batman.RenderContext.start(context).descend(closer)
  view = new Batman.View
    context: context
    node: node.childNodes[0]

  view.on 'ready', ->
    node = view.get('node')
    equals node.innerHTML, '1.2.3'
    closer.set('foo', '-')
    delay ->
      equals node.innerHTML, '1-2-3'

  view.get('node')

asyncTest 'it should update the data object if value bindings aren\'t filtered', 3, ->
  context = new Batman.Object

  # Define an accessor on a normal key
  context.accessor "one"
    get: getSpy = createSpy().whichReturns("abcabcabc")
    set: setSpy = createSpy().whichReturns("defdefdef")

  # Try it without a filter
  helpers.render '<textarea data-bind="one"></textarea>', context, (node) ->
    node.val('defdefdef')
    helpers.triggerChange(node.get(0))
    delay =>
      equal node.val(), 'defdefdef'
      ok getSpy.called
      ok setSpy.called

asyncTest 'it shouldn\'t update the data object if value bindings are filtered', 3, ->
  # Try it with a filter
  context = new Batman.Object
    one: "abcabcabcabcabc"

  context.accessor "one"
    get: getSpy = createSpy().whichReturns("abcabcabc")
    set: setSpy = createSpy().whichReturns("defdefdef")

  context.accessor
    get: defaultGetSpy = createSpy()
    set: defaultSetSpy = createSpy()

  helpers.render '<textarea data-bind="one | truncate 5"></textarea>', context, (node) ->
    node.val('defdefdefdef')
    helpers.triggerChange(node.get(0))
    delay =>
      equal node.val(), 'defdefdefdef'
      ok !setSpy.called
      ok !defaultSetSpy.called

asyncTest 'should allow filtered keypaths as arguments to context', 1, ->
  context = Batman
    foo: Batman
      baz: Batman
        qux: "filtered!"
    bar: 'baz'

  helpers.render '<div data-context-corge="foo | get bar"><div id="test" data-bind="corge.qux"></div></div>', context, (node) ->
    delay ->
      equals $("#test", node).html(), 'filtered!'

asyncTest 'should allow filtered keypaths as arguments to context and filters to be performed in the context', 2, ->
  context = Batman
    foo: Batman
      baz: new Batman.Set({foo: 'bar'}, {foo: 'baz'})
      qux: new Batman.Set({foo: '1'}, {foo: '2'})
    bar: 'baz'

  helpers.render '<div data-context-corge="foo | get bar"><div id="test" data-bind="corge | map \'foo\' | join \', \'"></div></div>', context, (node) ->
    delay ->
      equals $("#test", node).html(), 'bar, baz'
      context.set 'bar', 'qux'
      delay ->
        equals $("#test", node).html(), '1, 2'

asyncTest 'should allow filtered keypaths as arguments to formfor', 1, ->
  class SingletonDooDad extends Batman.Object
    someKey: 'foobar'

    @classAccessor 'instance',
      get: (key) ->
        unless @_instance
          @_instance = new SingletonDooDad
        @_instance

  context = Batman
    klass: SingletonDooDad

  source = '<form data-formfor-obj="klass | get \'instance\'"><span id="test" data-bind="obj.someKey"></span></form>'
  helpers.render source, context, (node) ->
    delay ->
      equals $("#test", node).html(), 'foobar'

asyncTest 'should allow filtered keypaths as arguments to mixin', 1, ->
  context = Batman
    foo: Batman
      baz:
        someKey: "foobar"
    bar: 'baz'

  helpers.render '<div id="test" data-mixin="foo | get bar"></div>', context, (node) ->
    delay ->
      equals Batman.data(node[0], 'someKey'), 'foobar'

asyncTest 'should allow filtered keypaths as arguments to event', 1, ->
  context = Batman
    foo: Batman
      baz: spy = createSpy()
    bar: 'baz'

  helpers.render '<button id="test" data-event-click="foo | get bar"></button>', context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      ok spy.called

asyncTest 'should allow filtered keypaths as arguments to foreach', 3, ->
  context = Batman
    foo: Batman
      baz: [Batman(key: 1), Batman(key: 2), Batman(key: 3)]
    bar: 'baz'

  helpers.render '<div><span class="tracking" data-foreach-number="foo | get bar" data-bind="number.key"></span></div>', context, (node) ->
    delay ->
      tracker = {'1': false, '2': false, '3': false}
      $(".tracking", node).each (i, x) ->
        tracker[$(x).html()] = true
      ok tracker['1']
      ok tracker['2']
      ok tracker['3']

asyncTest 'should bind to things under window only when the keypath specifies it', 2, ->
  Batman.container.foo = "bar"
  helpers.render '<div data-bind="foo"></div>', null, (node) ->
    equal node.html(), ""
    helpers.render '<div data-bind="window.foo"></div>', null, (node) ->
      equal node.html(), "bar"
      QUnit.start()

