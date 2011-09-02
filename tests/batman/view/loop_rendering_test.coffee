helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module "Batman.View loop rendering"

asyncTest 'it should allow simple loops', 1, ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  helpers.render source, {objects}, (node, view) ->
    delay => # new renderer's are used for each loop node, must wait longer
      names = $('p', view.get('node')).map -> @innerHTML
      names = names.toArray()
      deepEqual names, ['foo', 'bar', 'baz']

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
  source = '<div><p data-foreach-object="objects" class="present" data-bind="object.name"></p></div>'
  objects = new Batman.SortableSet({id: 1, name: 'foo'}, {id: 2, name: 'bar'})
  objects.sortBy 'id'

  helpers.render source, {objects}, (node, view) ->
    names = ($('p', view.get('node')).map -> @innerHTML).toArray()
    deepEqual names, ['foo', 'bar']
    objects.addIndex('name')
    # multiple reordering all at once should not end up with duplicate DOM nodes
    objects.set 'activeIndex', 'name'
    objects.set 'activeIndex', 'id'
    objects.set 'activeIndex', 'name'
    delay =>
      names = ($('p', view.get('node')).map -> @innerHTML).toArray()
      deepEqual names, ['bar', 'foo']

asyncTest 'it should add items in order', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object.name"></p>'
  objects = new Batman.SortableSet({id: 1, name: 'foo'}, {id: 2, name: 'bar'})
  objects.sortBy 'id'

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


asyncTest 'it should not fail if the collection is cleared', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  context = new Batman.Object
    objects: new Batman.Set('foo', 'bar', 'baz')

  helpers.render source, false, context, (node, view) ->
    delay => # new renderer's are used for each loop node, must wait longer
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
    delay ->
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

QUnit.module "Batman.View rendering nested loops"
  setup: ->
    @context = Batman
      posts: new Batman.Set()
      tagColor: "green"

    @context.posts.add Batman(tags:new Batman.Set("funny", "satire", "nsfw"), name: "post-#{i}") for i in [0..2]

    @source = '''
      <div>
        <div data-foreach-post="posts" class="post">
          <span data-foreach-tag="post.tags" data-bind="tag" class="tag" data-bind-post="post.name" data-bind-color="tagColor"></span>
        </div>
      </div>
    '''

asyncTest 'it should allow nested loops', 2, ->
  helpers.render @source, @context, (node, view) ->
    delay => # extra delay because foreach parsing ignores children
      equal $('.post', node).length, 3
      equal $('.tag', node).length, 9

asyncTest 'it should allow access to variables in higher scopes during loops', 3*3, ->
  helpers.render @source, @context, (node, view) ->
    delay => # extra delay because foreach parsing ignores children
      node = view.get('node')
      for postNode, i in $('.post', node)
        for tagNode, j in $('.tag', postNode)
          equal $(tagNode).attr('color'), "green"

asyncTest 'it should not render past its original node', ->
  @context.class1 = 'foo'
  @context.class2 = 'bar'
  @context.class3 = 'baz'
  source = '''
    <div id='node1' data-bind-class='class1'>
      <div id='node2' data-bind-class='class2'>
        <div>node1 class should not be set</div>
        <div>node2 class should be set</div>
        <div>node3 class should not be set</div>
      </div>
      <div id='node3' data-bind-class='class3'></div>
    </div>
  '''

  node = document.createElement 'div'
  node.innerHTML = source

  node1 = $(node).find('#node1')[0]
  node2 = $(node).find('#node2')[0]
  node3 = $(node).find('#node3')[0]

  view = new Batman.View
    contexts: [@context]
    node: node2
  view.ready ->
    equal node1.className, ''
    equal node2.className, 'bar'
    equal node3.className, ''
    QUnit.start()

  true

QUnit.module 'Batman.View rendering formfor'
  setup: ->
    @User = class User extends MockClass
      name: 'default name'

asyncTest 'it should pull in objects for form rendering', 1, ->
  source = '''
  <form data-formfor-user="instanceOfUser">
    <input type="text" data-bind="user.name">
  </form>
  '''
  context =
    instanceOfUser: new @User

  node = helpers.render source, context, (node) ->
    equals $('input', node).val(), "default name"
    QUnit.start()

asyncTest 'it should update objects when form rendering', 1, ->
  source = '''
  <form data-formfor-user="instanceOfUser">
    <input type="text" data-bind="user.name">
  </form>
  '''
  context =
    instanceOfUser: new @User

  node = helpers.render source, context, (node) =>
    $('input', node).val('new name')
    helpers.triggerChange(node[0].childNodes[1])
    delay =>
      equals @User.lastInstance.name, "new name"


asyncTest 'it should update the context for the form if the context changes', 2, ->
  source = '''
  <form data-formfor-user="instanceOfUser">
    <input type="text" data-bind="user.name">
  </form>
  '''
  context = new Batman.Object
    instanceOfUser: null

  node = helpers.render source, context, (node) =>
    equals $('input', node).val(), ""
    context.set 'instanceOfUser', new @User
    delay =>
      equals $('input', node).val(), "default name"


