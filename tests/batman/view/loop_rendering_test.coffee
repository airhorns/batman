helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module "Batman.View loop rendering"

asyncTest 'it should allow simple loops', 1, ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  helpers.render source, {objects}, (node, view) ->
    names = $('p', view.get('node')).map -> @innerHTML
    names = names.toArray()
    deepEqual names, ['foo', 'bar', 'baz']
    QUnit.start()

asyncTest 'it should render new items as they are added', ->
  source = '<div><p data-foreach-object="objects" class="present" data-bind="object"></p></div>'
  objects = new Batman.Set('foo', 'bar')

  helpers.render source, {objects}, (node, view) ->
    objects.add('foo', 'baz', 'qux')
    delay =>
      names = $('p', view.get('node')).map -> @innerHTML
      names = names.toArray()
      deepEqual names, ['foo', 'bar', 'baz', 'qux']

asyncTest 'it should remove items from the DOM as they are removed from the set', ->
  source = '<div><p data-foreach-object="objects" class="present" data-bind="object"></p></div>'
  objects = new Batman.Set('foo', 'bar')

  helpers.render source, {objects}, (node, view) ->
    objects.remove('foo', 'baz', 'qux')
    delay =>
      names = $('p', view.get('node')).map -> @innerHTML
      names = names.toArray()
      deepEqual names, ['bar']

asyncTest 'it should atomically reorder DOM nodes when the set is reordered', ->
  source = '<div><p data-foreach-object="objects.sortedBy[currentSort]" class="present" data-bind="object.name"></p></div>'
  objects = new Batman.Set({id: 1, name: 'foo'}, {id: 2, name: 'bar'})
  context = Batman({objects, currentSort: 'id'})

  helpers.render source, context, (node, view) ->
    names = ($('p', view.get('node')).map -> @innerHTML).toArray()
    deepEqual names, ['foo', 'bar']
    # multiple reordering all at once should not end up with duplicate DOM nodes
    context.set 'currentSort', 'name'
    delay =>
      context.set 'currentSort', 'id'
      delay =>
        context.set 'currentSort', 'name'
        delay =>
          names = ($('p', view.get('node')).map -> @innerHTML).toArray()
          deepEqual names, ['bar', 'foo']

asyncTest 'it should add items in order', ->
  source = '<p data-foreach-object="objects.sortedBy.id" class="present" data-bind="object.name"></p>'
  objects = new Batman.Set({id: 1, name: 'foo'}, {id: 2, name: 'bar'})
  helpers.render source, {objects}, (node, view) ->
    objects.add({id: 0, name: 'zero'})
    delay =>
      names = $('p', view.get('node')).map -> @innerHTML
      names = names.toArray()
      deepEqual names, ['zero', 'foo', 'bar']

asyncTest 'the ready event should wait for all children to be rendered', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  objects = new Batman.Set('foo', 'bar', 'baz')
  node = document.createElement 'div'
  node.innerHTML = source
  view = new Batman.View
    contexts: [Batman(), Batman({objects})]
    node: node
  ok !view.oneShotFired 'ready', 'make sure views render async'
  view._renderer.parsed =>
    ok !view.oneShotFired 'ready', 'make sure parsed fires before rendered'
  view.ready =>
    tracking = {foo: false, bar: false, baz: false}
    node = $(view.get('node')).children()
    for i in [0...node.length]
      tracking[node[i].innerHTML] = true
      equal node[i].className,  'present'
    for k in ['foo', 'bar', 'baz']
      ok tracking[k], "Object #{k} was found in the source"
    QUnit.start()

asyncTest 'it should continue to render nodes after the loop', 1, ->
  source = '<p data-foreach-object="bar" class="present" data-bind="object"></p><span data-bind="foo"/>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  helpers.render source, false, {bar: objects, foo: "qux"}, (node) ->
    equal 'qux', $('span', node).html(), "Node after the loop is also rendered"
    QUnit.start()

asyncTest 'it should update the whole set of nodes if the collection changes', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  context = new Batman.Object
    objects: new Batman.Set('foo', 'bar', 'baz')

  helpers.render source, false, context, (node, view) ->
    equal $('.present', node).length, 3
    context.set('objects', new Batman.Set('qux', 'corge'))
    delay =>
      equal $('.present', node).length, 2
      context.set('objects', null)
      delay =>
        equal $('.present', node).length, 0
        context.set('objects', new Batman.Set('mario'))
        delay =>
          equal $('.present', node).length, 1

asyncTest 'it should not fail if the collection is cleared', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  context = new Batman.Object
    objects: new Batman.Set('foo', 'bar', 'baz')

  helpers.render source, false, context, (node, view) ->
    equal $('.present', node).length, 3
    context.get('objects').clear()
    delay =>
      equal $('.present', node).length, 0


asyncTest 'previously observed collections shouldn\'t have any effect if they are replaced', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  oldObjects = new Batman.Set('foo', 'bar', 'baz')
  context = new Batman.Object(objects: oldObjects)

  helpers.render source, false, context, (node, view) ->
    context.set('objects', new Batman.Set('qux', 'corge'))
    oldObjects.add('no effect')
    delay =>
      equal $('.present', node).length, 2

asyncTest 'it should order loops among their siblings properly', 5, ->
  source = '<div><span data-bind="baz"></span><p data-foreach-object="bar" class="present" data-bind="object"></p><span data-bind="foo"></span></div>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  helpers.render source, false, {baz: "corn", bar: objects, foo: "qux"}, (node) ->
    div = node.childNodes[0]
    equal 'corn', $('span', div).get(0).innerHTML, "Node before the loop is rendered"
    equal 'qux', $('span', div).get(1).innerHTML, "Node before the loop is rendered"
    equal 'p', div.childNodes[1].tagName.toLowerCase(), "Order of nodes is preserved"
    equal 'span', div.childNodes[4].tagName.toLowerCase(), "Order of nodes is preserved"
    equal 'span', div.childNodes[0].tagName.toLowerCase(), "Order of nodes is preserved"
    QUnit.start()

asyncTest 'it should loop over hashes', ->
  source = '<p data-foreach-player="playerScores" class="present" data-bind-id="player" data-bind="playerScores[player]"></p>'
  playerScores = new Batman.Hash(
    mario: 5
    link: 5
    crono: 10
  )

  helpers.render source, {playerScores}, (node, view) ->
    tracking = {mario: false, link: false, crono: false}
    nodes = $(view.get('node')).children()
    for i in [0...nodes.length]
      node = nodes[i]
      id = node.id
      tracking[id] = (parseInt(node.innerHTML, 10) == playerScores.get(id))
      equal node.className,  'present'
    for k in ['mario', 'link', 'crono']
      ok tracking[k], "Object #{k} should be in the source"
    QUnit.start()

asyncTest 'it should loop over js objects', ->
  source = '<p data-foreach-player="playerScores" class="present" data-bind-id="player" data-bind="playerScores[player]"></p>'
  playerScores =
    mario: 5
    link: 5
    crono: 10

  helpers.render source, {playerScores}, (node, view) ->
    tracking = {mario: false, link: false, crono: false}
    nodes = $(view.get('node')).children()
    for i in [0...nodes.length]
      node = nodes[i]
      id = node.id
      tracking[id] = (parseInt(node.innerHTML, 10) == playerScores[id])
      equal node.className,  'present'
    for k in ['mario', 'link', 'crono']
      ok tracking[k], "Object #{k} should be in the source"
    QUnit.start()

asyncTest 'it shouldn\'t become desynchronized if the foreach collection observer fires with the same collection', ->
  x = Batman(all: new Batman.Set("a", "b", "c", "d", "e"))
  x.accessor 'filtered',
    get: ->
      unless @filtered?
        @filtered = new Batman.SortableSet()
        @filtered.add @get('all').toArray()...
      @filtered
    set: (k,v) ->
      set = @get('filtered')
      @get('all').forEach (e) ->
        if v is '' or e == v then set.add(e) else set.remove(e)
      set

  source = '<p data-foreach-obj="x.filtered" data-bind="obj"></p>'
  helpers.render source, {x}, (node, view) ->
    names = $('p', view.get('node')).map(-> @innerHTML).toArray()
    deepEqual names, ['a', 'b', 'c', 'd', 'e']
    x.set 'filtered', 'a'
    delay ->
      names = $('p', view.get('node')).map(-> @innerHTML).toArray()
      deepEqual names, ['a']
      x.set 'filtered', ''
      delay ->
        names = $('p', view.get('node')).map(-> @innerHTML).toArray()
        deepEqual names, ['a', 'b', 'c', 'd', 'e']
