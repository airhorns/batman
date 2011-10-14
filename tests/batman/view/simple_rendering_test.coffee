helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View simple rendering'

hte = (actual, expected) ->
  equal actual.innerHTML.toLowerCase().replace(/\n|\r/g, ""),
    expected.toLowerCase().replace(/\n|\r/g, "")

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

asyncTest 'it should bind undefined values as empty strings', 1, ->
  helpers.render '<div data-bind="foo"></div>',
    foo: undefined
  , (node) =>
    equals node.html(), ""
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


asyncTest 'it should allow a class to be bound', 6, ->
  source = '<div data-addclass-one="foo" data-removeclass-two="bar" class="zero"></div>'
  helpers.render source,
    foo: true
    bar: true
  , (node) ->
    ok node.hasClass('zero')
    ok node.hasClass('one')
    ok !node.hasClass('two')

    helpers.render source,
      foo: false
      bar: false
    , (node) ->
      ok node.hasClass('zero')
      ok !node.hasClass('one')
      ok node.hasClass('two')
      QUnit.start()

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

asyncTest 'it should allow arbitrary attributes to be bound', 2, ->
  source = '<div data-bind-foo="one" data-bind-bar="two" foo="before"></div>'
  helpers.render source,
    one: "baz"
    two: "qux"
  , (node) ->
    equal $(node[0]).attr('foo'), "baz"
    equal $(node[0]).attr('bar'), "qux"
    QUnit.start()

asyncTest 'it should allow multiple class names to be bound and updated', ->
  source = '<div data-bind-class="classes"></div>'
  context = new Batman.Object classes: 'foo bar'
  helpers.render source, context, (node) ->
    equal node[0].className, 'foo bar'
    context.set 'classes', 'bar baz'
    delay =>
      equal node[0].className, 'bar baz'

asyncTest 'it should allow input values to be bound', 1, ->
  helpers.render '<input data-bind="one" type="text" />',
    one: "qux"
  , (node) ->
    equal $(node[0]).val(), 'qux'
    QUnit.start()

asyncTest 'it should bind the input value and update the input when it changes', 2, ->
  context = new Batman.Object
    one: "qux"

  helpers.render '<input data-bind="one" type="text" />', context, (node) ->
    equal $(node[0]).val(), 'qux'
    context.set('one', "bar")
    delay =>
      equal $(node[0]).val(), 'bar'

asyncTest 'it should bind the input value of checkboxes and update the value when the object changes', 2, ->
  context = new Batman.Object
    one: true

  helpers.render '<input type="checkbox" data-bind="one" />', context, (node) ->
    equal node[0].checked, true
    context.set('one', false)
    delay =>
      equal node[0].checked, false

asyncTest 'it should bind the input value of checkboxes and update the object when the value changes', 1, ->
  context = new Batman.Object
    one: true

  helpers.render '<input type="checkbox" data-bind="one" />', context, (node) ->
    node[0].checked = false
    helpers.triggerChange(node[0])
    delay =>
      equal context.get('one'), false

asyncTest 'it should bind the value of a select box and update when the value changes', 2, ->
  window.currentContext = context = new Batman.Object
    heros: new Batman.Set('mario', 'crono', 'link')
    selected: new Batman.Object(name: 'crono')
  helpers.render '<select data-bind="selected.name"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event
      equals node[0].value, 'crono'
      context.set 'selected.name', 'link'
      delay =>
        equal node[0].value, 'link'

asyncTest 'it binds the options of a select box and updates when the select\'s value changes', ->
  context = new Batman.Object
    something: 'crono'
    mario: new Batman.Object(selected: null)
    crono: new Batman.Object(selected: null)
  helpers.render '<select data-bind="something"><option value="mario" data-bind-selected="mario.selected"></option><option value="crono" data-bind-selected="crono.selected"></option></select>', context, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event
      equal node[0].value, 'crono'
      equal context.get('crono.selected'), true
      equal context.get('mario.selected'), false

      node[0].value = 'mario'
      helpers.triggerChange node[0]
      delay =>
        equal context.get('mario.selected'), true
        equal context.get('crono.selected'), false

asyncTest 'it binds the value of a multi-select box and updates the options when the bound value changes', ->
  context = new Batman.Object
    heros: new Batman.Set('mario', 'crono', 'link', 'kirby')
    selected: new Batman.Object(name: ['crono', 'link'])
  helpers.render '<select multiple="multiple" size="2" data-bind="selected.name"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event
      selections = (c.selected for c in node[0].children)
      deepEqual selections, [no, yes, yes, no]
      context.set 'selected.name', ['mario', 'kirby']
      delay =>
        selections = (c.selected for c in node[0].children)
        deepEqual selections, [yes, no, no, yes]

asyncTest 'it binds the value of a multi-select box and updates the value when the selected options change', ->
  context = new Batman.Object
    selected: 'crono'
    mario: new Batman.Object(selected: null)
    crono: new Batman.Object(selected: null)
  helpers.render '<select multiple="multiple" data-bind="selected"><option value="mario" data-bind-selected="mario.selected"></option><option value="crono" data-bind-selected="crono.selected"></option></select>', context, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event
      equal node[0].value, 'crono', 'node value is crono'
      equal context.get('selected'), 'crono', 'selected is crono'
      equal context.get('crono.selected'), true, 'crono is selected'
      equal context.get('mario.selected'), false, 'mario is not selected'

      context.set 'mario.selected', true
      delay =>
        equal context.get('mario.selected'), true, 'mario is selected'
        equal context.get('crono.selected'), true, 'crono is still selected'
        deepEqual context.get('selected'), ['mario', 'crono'], 'mario and crono are selected in binding'
        for opt in node[0].children
          ok opt.selected, "#{opt.value} option is selected"

asyncTest 'it should bind the input value and update the object when it changes', 1, ->
  context = new Batman.Object
    one: "qux"

  helpers.render '<input data-bind="one" type="text" />', context, (node) ->
    $(node[0]).val('bar')
    # Use DOM level 2 event dispatch, $().trigger doesn't seem to work
    helpers.triggerChange(node[0])
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

asyncTest 'it should allow events to be bound and execute them in the context as specified on a multi key keypath', 1, ->
  context = Batman
    foo: Batman
      bar: Batman
        doSomething: spy = createSpy()

  source = '<button data-event-click="foo.bar.doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      equal spy.lastCallContext, context.get('foo.bar')


asyncTest 'it should allow events to be bound and execute them in the context as specified on terminal keypath', 1, ->
  context = Batman
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      equal spy.lastCallContext, context

asyncTest 'it should allow click events to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]

asyncTest 'it should allow double click events to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<button data-event-doubleclick="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerDoubleClick(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]

asyncTest 'it should allow event handlers to update', 2, ->
  context = Batman
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      ok spy.called
      context.set('doSomething', newSpy = createSpy())
      helpers.triggerClick(node[0])
      delay ->
        ok newSpy.called

asyncTest 'it should allow change events on checkboxes to be bound', 1, ->
  context = new Batman.Object
    one: true
    doSomething: createSpy()

  helpers.render '<input type="checkbox" data-bind="one" data-event-change="doSomething"/>', context, (node) ->
    node[0].checked = false
    helpers.triggerChange(node[0])
    delay =>
      ok context.doSomething.called

asyncTest 'it should allow submit events on inputs to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<form><input data-event-submit="doSomething" /></form>'
  helpers.render source, context, (node) ->
    helpers.triggerKey(node[0].childNodes[0], 13)
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0].childNodes[0]

asyncTest 'it should allow form submit events to be bound', 1, ->
  context =
    doSomething: spy = createSpy()

  source = '<form data-event-submit="doSomething"><input type="submit" id="submit" /></form>'
  helpers.render source, context, (node) ->
    helpers.triggerSubmit(node[0])
    delay =>
      ok spy.called

asyncTest 'allows data-event-click attributes to reference native model properties directly', ->
  spy = createSpy()
  class Foo extends Batman.Model
    handleClick: spy

  source = '<button data-event-click="foo.handleClick"></button>'

  helpers.render source, {foo: new Foo()}, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]

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

asyncTest 'data-bind-style should bind to a string', 4, ->
  source = '<input type="text" data-bind-style="string"></input>'
  context = Batman
    string: 'background-color:blue; color:green;'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['background-color'], 'blue'
    equal node.style['color'], 'green'

    context.set 'string', 'color: green'
    delay =>
      equal node.style['background-color'], ''
      equal node.style['color'], 'green'

asyncTest 'data-bind-style should bind to a vanilla object', 4, ->
  source = '<input type="text" data-bind-style="object"></input>'
  context = Batman
    object: 
      'background-color': 'blue'
      color: 'green'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['background-color'], 'blue'
    equal node.style['color'], 'green'
    context.set 'object', {color: 'red'}
    delay =>
      equal node.style['background-color'], ''
      equal node.style['color'], 'red'

asyncTest 'data-bind-style should bind to a Batman object', 8, ->
  source = '<input type="text" data-bind-style="object"></input>'
  context = Batman
    object: new Batman.Hash
      'background-color': 'blue'
      color: 'green'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['background-color'], 'blue'
    equal node.style['color'], 'green'
    context.set 'object.color', 'blue'
    delay =>
      equal node.style['color'], 'blue'
      equal node.style['background-color'], 'blue'
      context.unset 'object.color'
      delay =>
        equal node.style['color'], ''
        equal node.style['background-color'], 'blue'
        context.set 'object', new Batman.Hash color: 'yellow'
        delay =>
          equal node.style['color'], 'yellow'
          equal node.style['background-color'], 'blue'

asyncTest 'data-bind-style should forget previously bound hashes', 6, ->
  source = '<div data-bind-style="hash"></div>'
  hash = new Batman.Hash
    'background-color': 'blue'
    color: 'green'
  context = Batman hash: hash
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['background-color'], 'blue'
    equal node.style['color'], 'green'

    context.set 'hash', new Batman.Hash color: 'red'
    delay =>
      equal node.style['background-color'], 'blue'
      equal node.style['color'], 'red'

      hash.set 'color', 'green'
      delay =>
        equal node.style['background-color'], 'blue'
        equal node.style['color'], 'red'

asyncTest 'data-bind-style should bind to a vanilla object of attr/keypath pairs', 4, ->
  source = '<input type="text" data-bind-style="styles"></input>'
  context = Batman
    color: 'blue'
    backgroundColor: 'green'
    styles:
      color: 'color'
      'background-color': 'backgroundColor'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style.color, 'blue'
    equal node.style['background-color'], 'green'
    context.set 'color', 'green'
    delay =>
      equal node.style.color, 'green'
      equal node.style['background-color'], 'green'

QUnit.module "Memory safety"

test "addEventListener and removeEventListener store and remove callbacks using Batman.data", ->
  div = document.createElement 'div'
  f = ->

  Batman.DOM.addEventListener div, 'click', f
  listeners = Batman.data div, 'listeners'
  ok listeners.click.has f

  Batman.DOM.removeEventListener div, 'click', f
  listeners = Batman.data div, 'listeners'
  ok !listeners.click.has f

asyncTest "bindings are kept in Batman.data and destroyed when the node is removed", 8, ->
  context = new Batman.Object bar: true
  context.accessor 'foo', (spy = createSpy -> @get('bar'))
  helpers.render '<div data-addclass-foo="foo"><div data-addclass-foo="foo"></div></div>', context, (node) ->
    equal spy.callCount, 1  # Cached, so only called once

    parent = node[0]
    child = parent.childNodes[0]
    for n in [child, parent]
      bindings = Batman.data n, 'bindings'
      ok bindings instanceof Batman.Set
      ok !bindings.isEmpty()

      Batman.DOM.removeNode n
      deepEqual Batman.data(n), {}

    context.set('bar', false)
    equal spy.callCount, 1
    QUnit.start()

asyncTest "listeners are kept in Batman.data and destroyed when the node is removed", 10, ->
  context = new Batman.Object foo: ->

  helpers.render '<div data-event-click="foo"><div data-event-click="foo"></div></div>', context, (node) ->
    parent = node[0]
    child = parent.childNodes[0]
    for n in [child, parent]
      listeners = Batman.data n, 'listeners'
      ok listeners and listeners.click
      ok listeners.click instanceof Batman.Set
      ok !listeners.click.isEmpty()

      if Batman.DOM.hasAddEventListener
        spy = spyOn n, 'removeEventListener'
      else
        # Spoof detachEvent because typeof detachEvent is 'object' in IE8, and
        # spies break because detachEvent.call blows up
        n.detachEvent = ->
        spy = spyOn n, 'detachEvent'

      Batman.DOM.removeNode n

      ok spy.called
      deepEqual Batman.data(n), {}

    QUnit.start()

