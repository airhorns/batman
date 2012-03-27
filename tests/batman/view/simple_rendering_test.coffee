helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View simple rendering'

hte = (actual, expected) ->
  equal actual.innerHTML.toLowerCase().replace(/\n|\r/g, ""),
    expected.toLowerCase().replace(/\n|\r/g, "")

test "Batman.Renderer::_sortBindings should be consistent", ->
  bindings = [["a"], ["foreach"], ["c"], ["bind"], ["b"], ["context"], ["f"], ["view"], ["g"], ["formfor"], ["d"], ["renderif"], ["e"]]
  expectedSort = [["view"], ["renderif"], ["foreach"], ["formfor"], ["context"], ["bind"], ["a"], ["b"], ["c"], ["d"], ["e"], ["f"], ["g"]]
  deepEqual bindings.sort(Batman.Renderer::_sortBindings), expectedSort

test 'it should render simple nodes', ->
  hte helpers.render("<div></div>", false), "<div></div>"

test 'it should render many parent nodes', ->
  hte helpers.render("<div></div><p></p>", false), "<div></div><p></p>"

asyncTest 'it should allow the inner value to be bound', 1, ->
  helpers.render '<div data-bind="foo"></div>',
    foo: 'bar'
  , (node) =>
    equals node.html(), "bar"
    QUnit.start()

asyncTest 'it should allow the inner value to be bound using content containing html', 1, ->
  helpers.render '<div data-bind="foo"></div>',
    foo: '<p>bar</p>'
  , (node) =>
    equals node.html(), "&lt;p&gt;bar&lt;/p&gt;"
    QUnit.start()

asyncTest 'it should track added bindings', 2, ->
  Batman.DOM.on 'bindingAdded', spy = createSpy()
  helpers.render '<div data-bind="foo"></div>',
    foo: 'bar'
  , (node) =>
    ok spy.called
    ok spy.lastCallArguments[0] instanceof Batman.DOM.AbstractBinding
    Batman.DOM.forget 'bindingAdded', spy
    QUnit.start()

asyncTest 'it should bind undefined values as empty strings', 1, ->
  helpers.render '<div data-bind="foo"></div>',
    foo: undefined
  , (node) =>
    equals node.html(), ""
    QUnit.start()

asyncTest 'it should allow ! and ? at the end of a keypath', 1, ->
  helpers.render '<div data-bind="foo?"></div>',
    'foo?': 'bar'
  , (node) =>
    equals node.html(), "bar"
    QUnit.start()

asyncTest 'it should ignore empty bindings', 1, ->
  helpers.render '<div data-bind=""></div>', Batman(), (node) =>
    equals node.html(), ""
    QUnit.start()

asyncTest 'it should allow bindings to be defined later', 2, ->
  context = Batman()
  helpers.render '<div data-bind="foo.bar"></div>', context, (node) =>
    equals node.html(), ""
    context.set 'foo', Batman(bar: "baz")
    delay ->
      equals node.html(), "baz"

asyncTest 'it should allow commenting of bindings', 1, ->
  helpers.render '<div x-data-bind="foo"></div>',
    foo: 'bar'
  , (node) =>
    equals node.html(), ""
    QUnit.start()

asyncTest 'bindings in lower down scopes should shadow higher ones', 3, ->
  context = Batman
    namespace: Batman
      foo: 'inner'
    foo: 'outer'
  helpers.render '<div data-context="namespace"><div id="inner" data-bind="foo"></div></div>', context, (node) =>
    node = $('#inner', node)
    equals node.html(), "inner"
    context.set 'foo', "outer changed"
    delay ->
      equals node.html(), "inner"
      context.set 'namespace.foo', 'inner changed'
      delay ->
        equals node.html(), "inner changed"

asyncTest 'bindings in lower down scopes should shadow higher ones with shadowing defined as the base of the keypath being defined', 3, ->
  context = Batman
    namespace: Batman
      foo: Batman()
    foo: Batman
      bar: 'outer'

  helpers.render '<div data-context="namespace"><div id="inner" data-bind="foo.bar"></div></div>', context, (node) =>
    node = $('#inner', node)
    equals node.html(), ""
    context.set 'foo', "outer changed"
    delay ->
      equals node.html(), ""
      context.set 'namespace.foo.bar', 'inner'
      delay ->
        equals node.html(), "inner"

QUnit.module 'Batman.View visibility bindings'

asyncTest 'it should allow visibility to be bound on block elements', 2, ->
  testDiv = $('<div/>')
  testDiv.appendTo($('body'))
  blockDefaultDisplay = testDiv.css('display')
  testDiv.remove()
  source = '<div data-showif="foo"></div>'
  helpers.render source,
    foo: true
  , (node) ->
    # Must put the node in the DOM for the style to be calculated properly.
    helpers.withNodeInDom node, ->
      equal node.css('display'), blockDefaultDisplay

    helpers.render source,
      foo: false
    , (node) ->
        helpers.withNodeInDom node, ->
          equal node.css('display'), 'none'
        QUnit.start()

asyncTest 'it should allow visibility to be bound on inline elements', 2, ->
  testSpan = $('<span/>')
  testSpan.appendTo($('body'))
  inlineDefaultDisplay = testSpan.css('display')
  testSpan.remove()
  source = '<span data-showif="foo"></span>'
  helpers.render source,
    foo: true
  , (node) ->
    # Must put the node in the DOM for the style to be calculated properly.
    helpers.withNodeInDom node, ->
      equal node.css('display'), inlineDefaultDisplay

    helpers.render source,
      foo: false
    , (node) ->
        helpers.withNodeInDom node, ->
          equal node.css('display'), 'none'
        QUnit.start()

asyncTest "it should ignore an inline style of 'display:none' on block elements when determining an element's original display setting", 2, ->
  testDiv = $('<div/>')
  testDiv.appendTo($('body'))
  blockDefaultDisplay = testDiv.css('display')
  testDiv.remove()
  source = '<div data-showif="foo" style="display:none"></div>'
  helpers.render source,
    foo: true
  , (node) ->
    # Must put the node in the DOM for the style to be calculated properly.
    helpers.withNodeInDom node, ->
      equal node.css('display'), blockDefaultDisplay

    helpers.render source,
      foo: false
    , (node) ->
        helpers.withNodeInDom node, ->
          equal node.css('display'), 'none'
        QUnit.start()

asyncTest "it should ignore an inline style of 'display:none' on inline elements when determining an element's original display setting", 2, ->
  testSpan = $('<span/>')
  testSpan.appendTo($('body'))
  inlineDefaultDisplay = testSpan.css('display')
  testSpan.remove()
  source = '<span data-showif="foo" style="display:none"></span>'
  helpers.render source,
    foo: true
  , (node) ->
    # Must put the node in the DOM for the style to be calculated properly.
    helpers.withNodeInDom node, ->
      equal node.css('display'), inlineDefaultDisplay

    helpers.render source,
      foo: false
    , (node) ->
        helpers.withNodeInDom node, ->
          equal node.css('display'), 'none'
        QUnit.start()

asyncTest 'it should allow arbitrary attributes to be bound', 2, ->
  source = '<div data-bind-foo="one" data-bind-data-bar="two" foo="before"></div>'
  helpers.render source,
    one: "baz"
    two: "qux"
  , (node) ->
    equal $(node[0]).attr('foo'), "baz"
    equal $(node[0]).attr('data-bar'), "qux"
    QUnit.start()

asyncTest 'it should bind undefined values as empty strings on attributes', 1, ->
  helpers.render '<div data-bind-src="foo"></div>', {}, (node) ->
    equal node[0].src, ""
    QUnit.start()

QUnit.module 'Batman.View value bindings'

asyncTest 'it should allow input values to be bound', 1, ->
  helpers.render '<input data-bind="one" type="text" />',
    one: "qux"
  , (node) ->
    equal $(node[0]).val(), 'qux'
    QUnit.start()

asyncTest 'input value bindings should not escape their value', 1, ->
  helpers.render '<input data-bind="foo"></input>',
    foo: '<script></script>'
  , (node) =>
    equals node.val(), "<script></script>"
    QUnit.start()

asyncTest 'it should bind the input value and update the input when it changes', 2, ->
  context = Batman
    one: "qux"

  helpers.render '<input data-bind="one" type="text" />', context, (node) ->
    equal $(node[0]).val(), 'qux'
    context.set('one', "bar")
    delay =>
      equal $(node[0]).val(), 'bar'

asyncTest 'it should bind the input value but not update the window object if the input changes', 2, ->
  context = Batman({})

  helpers.render '<input data-bind="nonexistantKey" type="text" />', context, (node) ->
    equal node[0].value, ''
    node[0].value = 'foo'
    helpers.triggerChange(node[0])
    delay =>
      equal typeof window.nonexistantKey, 'undefined'

asyncTest 'it should bind the input value but not update the window object if the input changes with a many segment keypath', 2, ->
  context = Batman({})

  helpers.render '<input data-bind="someKey.path" type="text" />', context, (node) ->
    equal node[0].value, ''
    node[0].value = 'foo'
    helpers.triggerChange(node[0])
    delay =>
      equal typeof window.someKey, 'undefined'

asyncTest 'it should bind the input value of checkboxes and update the value when the object changes', 2, ->
  context = Batman
    one: true

  helpers.render '<input type="checkbox" data-bind="one" />', context, (node) ->
    equal node[0].checked, true
    context.set('one', false)
    delay =>
      equal node[0].checked, false

asyncTest 'it should bind the input value of checkboxes and update the object when the value changes', 1, ->
  context = Batman
    one: true

  helpers.render '<input type="checkbox" data-bind="one" />', context, (node) ->
    node[0].checked = false
    helpers.triggerChange(node[0])
    delay =>
      equal context.get('one'), false

asyncTest 'it should bind the input value and update the object when it changes', 1, ->
  context = new Batman.Object
    one: "qux"

  helpers.render '<input data-bind="one" type="text" />', context, (node) ->
    $(node[0]).val('bar')
    # Use DOM level 2 event dispatch, $().trigger doesn't seem to work
    helpers.triggerChange(node[0])
    delay =>
      equal context.get('one'), 'bar'

asyncTest 'it should bind the input value and update the object when it keyups', 1, ->
  context = new Batman.Object
    one: "qux"

  helpers.render '<input data-bind="one" type="text" />', context, (node) ->
    $(node[0]).val('bar')
    # Use DOM level 2 event dispatch, $().trigger doesn't seem to work
    helpers.triggerKey(node[0], 82) # 82 is r from "bar"
    delay =>
      equal context.get('one'), 'bar'

for type in ['text', 'search', 'tel', 'url', 'email', 'password']
  do (type) ->
    asyncTest "it should bind the input value on HTML5 input #{type} and update the object when it keyups", 1, ->
      context = new Batman.Object
        one: "qux"

      helpers.render "<input data-bind=\"one\" type=\"#{type}\"></input>", context, (node) ->
        $(node[0]).val('bar')
        # Use DOM level 2 event dispatch, $().trigger doesn't seem to work
        helpers.triggerKey(node[0], 82) # 82 is r from "bar"
        delay =>
          equal context.get('one'), 'bar'

asyncTest 'it should bind the value of textareas', 2, ->
  context = new Batman.Object
    one: "qux"

  helpers.render '<textarea data-bind="one"></textarea>', context, (node) ->
    equal node.val(), 'qux'
    context.set('one', "bar")
    delay =>
      equal node.val(), 'bar'

asyncTest 'textarea value bindings should not escape their value', 2, ->
  helpers.render '<textarea data-bind="foo"></textarea>',
    foo: '<script></script>'
  , (node) =>
    # jsdom and the browser have different behaviour, so lets just test against a node with the expected contents
    # to see if they are the same
    textarea = $('<textarea>').val("<script></script>")
    equals node.html(), textarea.html()
    equals node.val(), textarea.val()
    QUnit.start()

asyncTest 'it should bind the value of textareas and inputs simulatenously', ->
  context = new Batman.Object
    one: "qux"

  helpers.render '<textarea data-bind="one"></textarea><input data-bind="one" type="text"/>', context, (node) ->
    f = (v) =>
      equal $(node[0]).val(), v
      equal $(node[1]).val(), v
    f('qux')

    $(node[1]).val('bar')
    helpers.triggerChange(node[1])
    delay =>
      f('bar')
      $(node[0]).val('baz')
      helpers.triggerChange(node[0])
      delay =>
        f('baz')
        $(node[1]).val('foo')
        helpers.triggerChange(node[1])
        delay =>
          f('foo')

unless IN_NODE # jsdom doesn't seem to like input type="file"

  getMockModel = ->
    context = Batman
      storageKey: 'one'
      hasStorage: -> true
      fileAttributes: ''

    adapter = new Batman.RestStorage(context)
    context._batman.storage = [adapter]

    [context, adapter]

  asyncTest 'it should bind the value of file type inputs', 2, ->
    [context, adapter] = getMockModel()
    ok !adapter.defaultRequestOptions.formData

    helpers.render '<input type="file" data-bind="fileAttributes"></input>', false, context, (node) ->
      helpers.triggerChange(node.childNodes[0])
      delay ->
        strictEqual context.fileAttributes, undefined

  asyncTest 'it should bind the value of file type inputs with the "multiple" flag', 2, ->
    [context, adapter] = getMockModel()
    ok !adapter.defaultRequestOptions.formData

    helpers.render '<input type="file" data-bind="fileAttributes" multiple="multiple"></input>', false, context, (node) ->
      helpers.triggerChange(node.childNodes[0])
      delay ->
        deepEqual context.fileAttributes, []


  asyncTest 'it should bind the value of file type inputs when they are proxied', 2, ->
    [context, adapter] = getMockModel()
    ok !adapter.defaultRequestOptions.formData

    source = '<form data-formfor-foo="proxied"><input type="file" data-bind="foo.fileAttributes"></input></form>'

    helpers.render source, false, {proxied: context}, (node) ->
      helpers.triggerChange(node.childNodes[0].childNodes[0])
      delay ->
        strictEqual context.fileAttributes, undefined

asyncTest 'should bind radio buttons to a value', ->
  source = '<input id="fixed" type="radio" data-bind="ad.sale_type" name="sale_type" value="fixed"/>
    <input id="free" type="radio" data-bind="ad.sale_type" name="sale_type" value="free"/>
    <input id="trade" type="radio" data-bind="ad.sale_type" name="sale_type" value="trade"/>'
  context = Batman
    ad: Batman
      sale_type: 'free'

  helpers.render source, context, (node) ->
    fixed = node[0]
    free = node[1]
    trade = node[2]

    ok (!fixed.checked and free.checked and !trade.checked)

    context.set 'ad.sale_type', 'trade'
    delay =>
      ok (!fixed.checked and !free.checked and trade.checked)

asyncTest 'should bind to the value of radio buttons', ->
  source = '<input id="fixed" type="radio" data-bind="ad.sale_type" name="sale_type" value="fixed"/>
    <input id="free" type="radio" data-bind="ad.sale_type" name="sale_type" value="free"/>
    <input id="trade" type="radio" data-bind="ad.sale_type" name="sale_type" value="trade" checked/>'
  context = Batman
    ad: Batman()

  helpers.render source, context, (node) ->
    fixed = node[0]
    free = node[1]
    trade = node[2]

    ok (!fixed.checked and !free.checked and trade.checked)
    equal context.get('ad.sale_type'), 'trade', 'checked attribute binds'

    helpers.triggerChange(fixed)
    delay =>
      equal context.get('ad.sale_type'), 'fixed'

QUnit.module "Batman.View: mixin and context bindings"

asyncTest 'it should allow mixins to be applied', 1, ->
  Batman.mixins.set 'test',
    foo: 'bar'

  source = '<div data-mixin="test"></div>'
  helpers.render source, false, (node) ->
    delay ->
      equals Batman.data(node.firstChild, 'foo'), 'bar'
      delete Batman.mixins.test

asyncTest 'it should allow contexts to be entered', 2, ->
  context = Batman
    namespace: Batman
      foo: 'bar'
  source = '<div data-context="namespace"><span id="test" data-bind="foo"></span></div>'
  helpers.render source, context, (node) ->
    equal $('#test', node).html(), 'bar'
    context.set('namespace', Batman(foo: 'baz'))
    delay ->
      equal $("#test", node).html(), 'baz', 'if the context changes the bindings should update'

asyncTest 'contexts should only be available inside the node with the context directive', 2, ->
  context = Batman
    namespace: Batman
      foo: 'bar'
  source = '<div data-context="namespace"></div><span id="test" data-bind="foo"></span>'

  helpers.render source, context, (node) ->
    equal node[1].innerHTML, ""
    context.set('namespace', Batman(foo: 'baz'))
    delay ->
      equal node[1].innerHTML, ""

asyncTest 'contexts should be available on the node with the context directive', 2, ->
  context = Batman
    namespace: Batman
      foo: 'bar'
  source = '<div data-context="namespace" data-bind="foo"></div>'

  helpers.render source, context, (node) ->
    equal node[0].innerHTML, "bar"
    context.set('namespace', Batman(foo: 'baz'))
    delay ->
      equal node[0].innerHTML, "baz"

asyncTest 'it should allow context names to be specified', 2, ->
  context = Batman
    namespace: 'foo'
  source = '<div data-context-identifier="namespace"><span id="test" data-bind="identifier"></span></div>'
  helpers.render source, context, (node) ->
    equal $('#test', node).html(), 'foo'
    context.set('namespace', 'bar')
    delay ->
      equal $("#test", node).html(), 'bar', 'if the context changes the bindings should update'

asyncTest 'it should allow contexts to be specified using filters', 2, ->
  context = Batman
    namespace: Batman
      foo: Batman
        bar: 'baz'
    keyName: 'foo'

  source = '<div data-context="namespace | get keyName"><span id="test" data-bind="bar"></span></div>'
  helpers.render source, context, (node) ->
    equal $('#test', node).html(), 'baz'
    context.set('namespace', Batman(foo: Batman(bar: 'qux')))
    delay ->
      equal $("#test", node).html(), 'qux', 'if the context changes the bindings should update'

QUnit.module "Batman.View: data-render-if bindings"

asyncTest 'it should not render the inner nodes until the keypath is truthy', 4, ->
  context = Batman
    proceed: false
  context.accessor 'deferred', spy = createSpy().whichReturns('inner value')

  source = '<div data-renderif="proceed"><span data-bind="deferred">unrendered</span></div>'

  helpers.render source, context, (node) ->
    ok !spy.called
    context.set('proceed', true)
    equal $('span', node).html(), 'unrendered'
    delay ->
      ok spy.called
      equal $('span', node).html(), 'inner value'

asyncTest 'it should render the inner nodes in the same context as the node was in when it deferred rendering', 2, ->
  context = Batman
    proceed: false
    foo: Batman
      foo: "bar"

  source = '<div data-context-alias="foo"><div data-renderif="proceed"><span data-bind="alias.foo">unrendered</span></div></div>'

  helpers.render source, context, (node) ->
    equal $('span', node).html(), 'unrendered'
    context.set('proceed', true)
    delay ->
      equal $('span', node).html(), 'bar'

asyncTest 'it should continue rendering on the node it stopped rendering', 2, ->
  context = Batman
    proceed: false
    foo: "bar"

  source = '<div data-bind="foo" data-renderif="proceed" >unrendered</div>'

  helpers.render source, context, (node) ->
    equal node.html(), 'unrendered'
    context.set('proceed', true)
    delay ->
      equal node.html(), 'bar'

asyncTest 'it should only render the inner nodes once', 3, ->
  context = Batman
    proceed: false
  context.accessor 'deferred', spy = createSpy().whichReturns('inner value')

  source = '<div data-renderif="proceed"><span data-bind="deferred">unrendered</span></div>'
  class InstrumentedRenderer extends Batman.Renderer
    @instanceCount: 0
    constructor: ->
      InstrumentedRenderer.instanceCount++
      super

  oldRenderer = Batman.Renderer
  Batman.Renderer = InstrumentedRenderer

  helpers.render source, context, (node) ->
    equal InstrumentedRenderer.instanceCount, 1
    context.set('proceed', true)
    delay ->
      equal InstrumentedRenderer.instanceCount, 2
      context.set('proceed', false)
      context.set('proceed', true)
      delay ->
        equal InstrumentedRenderer.instanceCount, 2
        Batman.Renderer = oldRenderer
