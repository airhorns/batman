helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View &lt;select&gt; rendering'

asyncTest 'it should bind the value of a select box and update when the javascript land value changes', 2, ->
  context = Batman
    heros: new Batman.Set('mario', 'crono', 'link')
    selected: new Batman.Object(name: 'crono')
  helpers.render '<select data-bind="selected.name"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event
      equals node[0].value, 'crono'
      context.set 'selected.name', 'link'
      delay =>
        equal node[0].value, 'link'

asyncTest 'it should bind the value of a select box and update the javascript land value with the selected option', 3, ->
  context = Batman
    heros: new Batman.SimpleSet('mario', 'crono', 'link')
    selected: 'crono'
  helpers.render '<select data-bind="selected"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', context, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event
      equals node[0].value, 'crono'
      context.set 'selected', 'link'
      delay =>
        equal node[0].value, 'link'
        context.set 'selected', 'mario'
        delay =>
          equal node[0].value, 'mario'

asyncTest 'it binds the options of a select box and updates when the select\'s value changes', ->
  context = Batman
    something: 'crono'
    mario: Batman(selected: null)
    crono: Batman(selected: null)

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
      selections = (c.selected for c in node[0].children when c.nodeType is 1)
      deepEqual selections, [no, yes, yes, no]
      context.set 'selected.name', ['mario', 'kirby']
      delay =>
        selections = (c.selected for c in node[0].children when c.nodeType is 1)
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

asyncTest 'should be able to remove bound select nodes', 2, ->
  context = new Batman.Object selected: "foo"
  helpers.render '<select data-bind="selected"><option value="foo">foo</option></select>', context, (node) ->
    Batman.DOM.removeNode(node[0])
    deepEqual Batman.data(node[0]), {}
    deepEqual Batman._data(node[0]), {}
    QUnit.start()
