helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

oldDeferEvery = Batman.DOM.IteratorBinding::deferEvery

QUnit.module 'Batman.View select bindings'
  setup: ->
    Batman.DOM.IteratorBinding.deferEvery = false
  teardown: ->
    Batman.DOM.IteratorBinding::deferEvery = oldDeferEvery

asyncTest 'it should still render the select boxes properly even after the binded data has been reset', 3, ->
  leo = new Batman.Object ({name: 'leo', id: 1})
  mikey = new Batman.Object ({name: 'mikey', id: 2})

  context = Batman
    heroes: new Batman.Set(leo, mikey)
    selected: mikey
    showBox: false

  helpers.render  '<select data-bind="selected.id">' +
                    '<option data-foreach-hero="heroes" data-bind-value="hero.id" data-bind="hero.name" />' +
                  '</selected>', context, (node) ->
    equal node[0].childNodes[0].innerHTML, 'leo'
    equal node[0].childNodes[1].innerHTML, 'mikey'
    context.set 'heroes', new Batman.Set(leo, mikey)
    try
      equal node[0].childNodes[1].innerHTML, 'mikey'
    catch error
      ok false, "Unable to test value of option because HTML was not formed as expected"

    QUnit.start()

asyncTest 'it should bind the value of a select box and update when the javascript land value changes', 2, ->
  context = Batman
    heros: new Batman.Set('mario', 'crono', 'link')
    selected: new Batman.Object(name: 'crono')
  helpers.render '<select data-bind="selected.name"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    equal node[0].value, 'crono'
    context.set 'selected.name', 'link'
    equal node[0].value, 'link'
    QUnit.start()

asyncTest 'it should bind the value of a select box and update when options change', 5, ->
  context = Batman
    heros: new Batman.Set()
    selected: new Batman.Object(name: 'crono')
  helpers.render '<select data-bind="selected.name"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    equal node[0].value, ''
    equal context.get('selected.name'), 'crono'
    context.get('heros').add('mario', 'link', 'crono')
    delay ->
      equal node[0].value, 'crono'
      equal context.get('selected.name'), 'crono'
      context.set('selected.name', 'mario')
      equal node[0].value, 'mario'

asyncTest 'it should bind the value of a select box and update the javascript land value with the selected option', 3, ->
  context = Batman
    heros: new Batman.SimpleSet('mario', 'crono', 'link')
    selected: 'crono'
  helpers.render '<select data-bind="selected"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    equal node[0].value, 'crono'
    context.set 'selected', 'link'
    equal node[0].value, 'link'
    context.set 'selected', 'mario'
    equal node[0].value, 'mario'
    QUnit.start()

asyncTest 'it binds the options of a select box and updates when the select\'s value changes', ->
  context = Batman
    something: 'crono'
    mario: Batman(selected: null)
    crono: Batman(selected: null)

  helpers.render '<select data-bind="something"><option value="mario" data-bind-selected="mario.selected"></option><option value="crono" data-bind-selected="crono.selected"></option></select>', context, (node) ->
    equal node[0].value, 'crono'
    equal context.get('crono.selected'), true
    equal context.get('mario.selected'), false

    node[0].value = 'mario'
    helpers.triggerChange node[0]
    equal context.get('mario.selected'), true
    equal context.get('crono.selected'), false
    QUnit.start()

asyncTest 'it binds the value of a multi-select box and updates the options when the bound value changes', ->
  context = new Batman.Object
    heros: new Batman.Set('mario', 'crono', 'link', 'kirby')
    selected: new Batman.Object(name: ['crono', 'link'])
  helpers.render '<select multiple="multiple" size="2" data-bind="selected.name"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    selections = (c.selected for c in node[0].children when c.nodeType is window.Node.ELEMENT_NODE)
    deepEqual selections, [no, yes, yes, no]
    context.set 'selected.name', ['mario', 'kirby']
    selections = (c.selected for c in node[0].children when c.nodeType is window.Node.ELEMENT_NODE)
    deepEqual selections, [yes, no, no, yes]
    QUnit.start()

asyncTest 'it binds the value of a multi-select box and updates the options when the options changes', ->
  context = new Batman.Object
    heros: new Batman.Set()
    selected: new Batman.Object(names: ['crono', 'link'])

  source = '''
    <select multiple="multiple" size="2" data-bind="selected.names">
      <option data-foreach-hero="heros" data-bind-value="hero"></option>
    </select>
  '''

  helpers.render source, context, (node) ->
    getSelections = -> (c.selected for c in node[0].children when c.nodeType is window.Node.ELEMENT_NODE)

    deepEqual context.get('selected.names'), ['crono', 'link']
    deepEqual getSelections(), []
    context.get('heros').add 'mario', 'crono', 'link', 'kirby'
    delay ->
      deepEqual getSelections(), [no, yes, yes, no]
      context.set 'selected.names', ['mario', 'kirby']
      deepEqual getSelections(), [yes, no, no, yes]
      context.get('heros').clear()
      delay ->
        deepEqual context.get('selected.names'), ['mario', 'kirby']

asyncTest 'it binds the value of a multi-select box and updates the value when the selected options change', ->
  context = new Batman.Object
    selected: 'crono'
    mario: new Batman.Object(selected: null)
    crono: new Batman.Object(selected: null)
  helpers.render '<select multiple="multiple" data-bind="selected"><option value="mario" data-bind-selected="mario.selected"></option><option value="crono" data-bind-selected="crono.selected"></option></select>', context, (node) ->
    equal node[0].value, 'crono', 'node value is crono'
    equal context.get('selected'), 'crono', 'selected is crono'
    equal context.get('crono.selected'), true, 'crono is selected'
    equal context.get('mario.selected'), false, 'mario is not selected'

    context.set 'mario.selected', true
    equal context.get('mario.selected'), true, 'mario is selected'
    equal context.get('crono.selected'), true, 'crono is still selected'
    deepEqual context.get('selected'), ['mario', 'crono'], 'mario and crono are selected in binding'
    for opt in node[0].children
      ok opt.selected, "#{opt.value} option is selected"
    QUnit.start()

asyncTest 'should be able to remove bound select nodes', 2, ->
  context = new Batman.Object selected: "foo"
  helpers.render '<select data-bind="selected"><option value="foo">foo</option></select>', context, (node) ->
    Batman.DOM.removeNode(node[0])
    deepEqual Batman.data(node[0]), {}
    deepEqual Batman._data(node[0]), {}
    QUnit.start()

asyncTest "should select an option with value='' when the data is undefined", ->
  context = Batman
    current: 'foo'

  source = '''
    <select data-bind="current">
      <option value="">none</option>
      <option value="foo">foo</option>
    </select>
  '''

  helpers.render source, context, (node) ->
    equal node[0].value, 'foo'
    context.unset 'current'
    equal typeof context.get('current'), 'undefined'
    equal node[0].value, ''
    delay ->
      equal typeof context.get('current'), 'undefined'
      equal node[0].value, ''


asyncTest "should select an option with value='' when the data is ''", ->
  context = Batman
    current: 'foo'

  source = '''
    <select data-bind="current">
      <option value="">none</option>
      <option value="foo">foo</option>
    </select>
  '''

  helpers.render source, context, (node) ->
  helpers.render source, context, (node) ->
    equal node[0].value, 'foo'
    context.set 'current', ''
    equal context.get('current'), ''
    equal node[0].value, ''
    delay ->
      equal context.get('current'), ''
      equal node[0].value, ''

