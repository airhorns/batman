helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View simple rendering'

hte = (actual, expected) ->
  equal actual.innerHTML, expected

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

asyncTest 'it should allow arbitrary (?!")\s+\|\s+(?!")attributes to be bound', 2, ->
  source = '<div data-bind-foo="one" data-bind-bar="two" foo="before"></div>'
  helpers.render source,
    one: "baz"
    two: "qux"
  , (node) ->
    equal $(node[0]).attr('foo'), "baz"
    equal $(node[0]).attr('bar'), "qux"
    QUnit.start()

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
  context = new Batman.Object
    heros: new Batman.Set('mario', 'crono', 'link')
    selected: new Batman.Object(name: 'crono')
  helpers.render '<select data-bind="selected.name"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event
      equals node[0].value, 'crono'
      context.set 'selected.name', 'link'
      delay =>
        equal node[0].value, 'link'

asyncTest 'it should bind the options of a select box and update when the select\'s value changes', ->
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

asyncTest 'it should bind the value of a multi-select box and update when the selections change', ->
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

asyncTest 'it should bind the options of a multi-select box and update when the select\'s value changes', ->
  context = new Batman.Object
    something: 'crono'
    mario: new Batman.Object(selected: null)
    crono: new Batman.Object(selected: null)
    luigi: new Batman.Object(selected: null)
  helpers.render '<select multiple="multiple" data-bind="something"><option value="mario" data-bind-selected="mario.selected"></option><option value="crono" data-bind-selected="crono.selected"></option><option value="mario" data-bind-selected="luigi.selected"></option></select>', context, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event
      equal node[0].value, 'crono'
      equal context.get('crono.selected'), true
      equal context.get('mario.selected'), false
      equal context.get('luigi.selected'), false

      node[0].value = 'mario'
      helpers.triggerChange node[0]
      delay =>
        equal context.get('mario.selected'), true
        # Luigi's value is 'mario'
        equal context.get('luigi.selected'), true
        equal context.get('crono.selected'), false

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

asyncTest 'it should allow click events to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]


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
    ad: Batman

  helpers.render source, context, (node) ->
    fixed = node[0]
    free = node[1]
    trade = node[2]

    ok (!fixed.checked and !free.checked and trade.checked)
    equal context.get('ad.sale_type'), 'trade', 'checked attribute binds'

    helpers.triggerChange(fixed)
    delay =>
      equal context.get('ad.sale_type'), 'fixed'

QUnit.module 'one-way bindings'

asyncTest 'read should update only the binding value', 3, ->
  source = '<input type="text" data-read="foo" value="start"/>'
  context = Batman foo: null
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.value, 'start'
    node.value = 'bar'
    helpers.triggerChange node
    delay =>
      equal context.get('foo'), 'bar'
      context.set 'foo', 'baz'
      delay =>
        equal node.value, 'bar'

asyncTest 'write should update only the bound node', 3, ->
  source = '<input type="text" data-write="foo" value="start"/>'
  context = Batman foo: 'bar'
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.value, 'bar'
    node.value = 'baz'
    helpers.triggerChange node
    delay =>
      equal context.get('foo'), 'bar'
      context.set 'foo', 'end'
      delay =>
        equal node.value, 'end'

asyncTest 'attribute write should update only the bound attribute', 3, ->
  source = '<input type="text" data-write-width="foo.width" value="start" width="10"/>'
  context = Batman
    foo: Batman
      width: 20
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.getAttribute('width'), '20'
    node.setAttribute 'width', 30
    helpers.triggerChange node
    delay =>
      equal context.get('foo.width'), 20
      context.set 'foo.width', 40
      delay =>
        equal node.getAttribute('width'), '40'

asyncTest 'data-write and data-read work correctly on the same node', ->
  source = '<input type="text" data-read="there" data-write="here" value="start"/>'
  context = Batman here: 'here', there: ''
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.value, 'here'
    equal context.get('there'), ''
    node.value = 'there'
    helpers.triggerChange node
    delay =>
      equal context.get('there'), 'there'
      equal context.get('here'), 'here'

