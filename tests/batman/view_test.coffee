$ = window.$ unless $

class MockRequest extends MockClass
  @chainedCallback 'success'
  @chainedCallback 'error'

oldRequest = Batman.Request
triggerChange = (domNode) ->
  evt = document.createEvent("HTMLEvents")
  evt.initEvent("change", true, true)
  domNode.dispatchEvent(evt)

triggerClick = (domNode) ->
  evt = document.createEvent("MouseEvents")
  evt.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null)
  domNode.dispatchEvent(evt)

keyIdentifers =
  13: 'Enter'

window.getKeyEvent = _getKeyEvent = (eventName, keyCode) ->
  evt = document.createEvent("KeyboardEvent")
  if evt.initKeyEvent
    evt.initKeyEvent(eventName, true, true, window, 0, 0, 0, 0, keyCode, keyCode)
  else
    evt.initKeyboardEvent(eventName, true, true, window, keyIdentifers[keyCode], keyIdentifers[keyCode])
  evt.which = evt.keyCode = keyCode
  evt

triggerKey = (domNode, keyCode) ->
  domNode.dispatchEvent(_getKeyEvent("keydown", keyCode))
  domNode.dispatchEvent(_getKeyEvent("keypress", keyCode))
  domNode.dispatchEvent(_getKeyEvent("keyup", keyCode))

count = 0
QUnit.module 'Batman.View'
  setup: ->
    MockRequest.reset()
    @options =
      source: "test_path#{++count}.html"

    Batman.Request = MockRequest
    @view = new Batman.View(@options) # create a view which uses the MockRequest internally

  teardown: ->
    Batman.Request = oldRequest

asyncTest 'should pull in the source for a view from a path, appending the prefix', 1, ->
  delay =>
    deepEqual MockRequest.lastInstance.constructorArguments[0].url, "views/#{@options.source}"

asyncTest 'should update its node with the contents of its view', 1, ->
  delay =>
    MockRequest.lastInstance.fireSuccess('view contents')
    equal @view.get('node').innerHTML, 'view contents'

asyncTest 'should fire the ready event once its contents have been loaded', 1, ->
  @view.ready (observer = createSpy())

  delay =>
    MockRequest.lastInstance.fireSuccess('view contents')
    delay =>
      ok observer.called

QUnit.module 'Batman.View rendering'

# Helper function for making a Batman.Object out of a JS object
obj = (a = {}) ->
  new Batman.Object a

# Helper function for rendering a view given a context. Optionally returns a jQuery of the nodes,
# and calls a callback with the same. Beware of the 50ms timeout when rendering views, tests should
# be async and rely on the view.ready one shot event for running assertions.
render = (source, jqueryize = true, context = {}, callback = ->) ->
  node = document.createElement 'div'
  node.innerHTML = source
  unless !!jqueryize == jqueryize
    [context, callback] = [jqueryize, context]
  else
    if typeof context == 'function'
      callback = context

  context = if context.get && context.set then context else obj context
  view = new Batman.View
    contexts: [obj(), context]
    node: node
  view.ready ->
    node = if jqueryize then $(view.get('node')).children() else view.get('node')
    callback(node, view)
  view.get('node')

# Helper assertion for checking if the innerHTML is what was expected
hte = (actual, expected) ->
  equal actual.innerHTML, expected

test 'it should render simple nodes', ->
  hte render("<div></div>", false), "<div></div>"

test 'it should render many parent nodes', ->
  hte render("<div></div><p></p>", false), "<div></div><p></p>"

QUnit.module 'Batman.View rendering simple bindings'

asyncTest 'it should allow the inner value to be bound', 1, ->
  render '<div data-bind="foo"></div>',
    foo: 'bar'
  , (node) =>
    equals node.html(), "bar"
    QUnit.start()

asyncTest 'it should bind undefined values as empty strings', 1, ->
  render '<div data-bind="foo"></div>',
    foo: undefined
  , (node) =>
    equals node.html(), ""
    QUnit.start()

asyncTest 'it should ignore empty bindings', 1, ->
  render '<div data-bind=""></div>',
    { }
  , (node) =>
    equals node.html(), ""
    QUnit.start()

asyncTest 'it should allow a class to be bound', 6, ->
  source = '<div data-addclass-one="foo" data-removeclass-two="bar" class="zero"></div>'
  render source,
    foo: true
    bar: true
  , (node) ->
    ok node.hasClass('zero')
    ok node.hasClass('one')
    ok !node.hasClass('two')

    render source,
      foo: false
      bar: false
    , (node) ->
      ok node.hasClass('zero')
      ok !node.hasClass('one')
      ok node.hasClass('two')
      QUnit.start()

asyncTest 'it should allow visibility to be bound on block elements', 2, ->
  source = '<div data-showif="foo"></div>'
  render source,
    foo: true
  , (node) ->
    equal node.css('display'), ''

    render source,
      foo: false
    , (node) ->
        equal node.css('display'), 'none'
        QUnit.start()

asyncTest 'it should allow visibility to be bound on inline elements', 2, ->
  source = '<span data-showif="foo"></span>'
  render source,
    foo: true
  , (node) ->
    equal node.css('display'), ''

    render source,
      foo: false
    , (node) ->
        equal node.css('display'), 'none'
        QUnit.start()

asyncTest 'it should allow arbitrary (?!")\s+\|\s+(?!")attributes to be bound', 2, ->
  source = '<div data-bind-foo="one" data-bind-bar="two" foo="before"></div>'
  render source,
    one: "baz"
    two: "qux"
  , (node) ->
    equal $(node[0]).attr('foo'), "baz"
    equal $(node[0]).attr('bar'), "qux"
    QUnit.start()

asyncTest 'it should allow input values to be bound', 1, ->
  render '<input data-bind="one" type="text" />',
    one: "qux"
  , (node) ->
    equal $(node[0]).val(), 'qux'
    QUnit.start()

asyncTest 'it should bind the input value and update the input when it changes', 2, ->
  context = new Batman.Object
    one: "qux"

  render '<input data-bind="one" type="text" />', context, (node) ->
    equal $(node[0]).val(), 'qux'
    context.set('one', "bar")
    delay =>
      equal $(node[0]).val(), 'bar'

asyncTest 'it should bind the input value of checkboxes and update the value when the object changes', 2, ->
  context = new Batman.Object
    one: true

  render '<input type="checkbox" data-bind="one" />', context, (node) ->
    equal node[0].checked, true
    context.set('one', false)
    delay =>
      equal node[0].checked, false

asyncTest 'it should bind the input value of checkboxes and update the object when the value changes', 1, ->
  context = new Batman.Object
    one: true

  render '<input type="checkbox" data-bind="one" />', context, (node) ->
    node[0].checked = false
    triggerChange(node[0])
    delay =>
      equal context.get('one'), false

asyncTest 'it should bind the value of a select box and update when the value changes', 2, ->
  heros = new Batman.Set('mario', 'crono', 'link')
  selected = new Batman.Object(name: 'crono')

  render '<select data-bind="selected.name"><option data-foreach-hero="heros" data-bind-value="hero"></option></select>', {
    heros: heros
    selected: selected
  }, (node) ->
    delay => # wait for select's data-bind listener to receive the rendered event 
      equals node[0].value, 'crono'
      selected.set 'name', 'link'
      delay =>
        equal node[0].value, 'link'

asyncTest 'it should bind the input value and update the object when it changes', 1, ->
  context = new Batman.Object
    one: "qux"

  render '<input data-bind="one" type="text" />', context, (node) ->
    $(node[0]).val('bar')
    # Use DOM level 2 event dispatch, $().trigger doesn't seem to work
    triggerChange(node[0])
    delay =>
      equal context.get('one'), 'bar'

asyncTest 'it should bind the value of textareas', 2, ->
  context = new Batman.Object
    one: "qux"

  render '<textarea data-bind="one"></textarea>', context, (node) ->
    equal node.val(), 'qux'
    context.set('one', "bar")
    delay =>
      equal node.val(), 'bar'

asyncTest 'it should bind the value of textareas and inputs simulatenously', ->
  context = new Batman.Object
    one: "qux"

  render '<textarea data-bind="one"></textarea><input data-bind="one" type="text"/>', context, (node) ->
    f = (v) =>
      equal $(node[0]).val(), v
      equal $(node[1]).val(), v
    f('qux')

    $(node[1]).val('bar')
    triggerChange(node[1])
    delay =>
      f('bar')
      $(node[0]).val('baz')
      triggerChange(node[0])
      delay =>
        f('baz')
        $(node[1]).val('foo')
        triggerChange(node[1])
        delay =>
          f('foo')

asyncTest 'it should allow click events to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  render source, context, (node) ->
    triggerClick(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]


asyncTest 'it should allow change events on checkboxes to be bound', 1, ->
  context = new Batman.Object
    one: true
    doSomething: createSpy()

  render '<input type="checkbox" data-bind="one" data-event-change="doSomething"/>', context, (node) ->
    node[0].checked = false
    triggerChange(node[0])
    delay =>
      ok context.doSomething.called

if typeof IN_NODE == 'undefined' || IN_NODE == false
  # Can't figure out how to trigger key events in jsdom.
  asyncTest 'it should allow submit events on inputs to be bound', 2, ->
    context =
      doSomething: spy = createSpy()

    source = '<form><input data-event-submit="doSomething" /></form>'
    render source, context, (node) ->
      triggerKey(node[0].childNodes[0], 13)
      delay ->
        ok spy.called
        equal spy.lastCallArguments[0], node[0].childNodes[0]

  # Can't figure out a way to get JSDOM to fire the form submit event.
  asyncTest 'it should allow form submit events to be bound', 1, ->
    context =
      doSomething: spy = createSpy()

    source = '<form data-event-submit="doSomething"><input type="submit" id="submit" /></form>'
    render source, context, (node) ->
      triggerClick($("#submit", node)[0])
      delay =>
        ok spy.called

asyncTest 'it should allow mixins to be applied', 1, ->
  Batman.mixins.set 'test',
    foo: 'bar'

  source = '<div data-mixin="test"></div>'
  render source, false, (node) ->
    delay ->
      equals node.firstChild.foo, 'bar'
      delete Batman.mixins.test

asyncTest 'it should allow contexts to be entered', 2, ->
  context = obj
    namespace: obj
      foo: 'bar'
  source = '<div data-context="namespace"><span id="test" data-bind="foo"></span></div>'
  render source, context, (node) ->
    equal $('#test', node).html(), 'bar'
    context.set('namespace', obj(foo: 'baz'))
    delay ->
      equal $("#test", node).html(), 'baz', 'if the context changes the bindings should update'

asyncTest 'it should allow contexts to be specified using filters', 2, ->
  context = obj
    namespace: obj
      foo: obj
        bar: 'baz'
    keyName: 'foo'

  source = '<div data-context="namespace | get keyName"><span id="test" data-bind="bar"></span></div>'
  render source, context, (node) ->
    equal $('#test', node).html(), 'baz'
    context.set('namespace', obj(foo: obj(bar: 'qux')))
    delay ->
      equal $("#test", node).html(), 'qux', 'if the context changes the bindings should update'


QUnit.module "Batman.View rendering loops"

asyncTest 'it should allow simple loops', 1, ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  render source, {objects}, (node, view) ->
    delay => # new renderer's are used for each loop node, must wait longer
      names = $('p', view.get('node')).map -> @innerHTML
      names = names.toArray()
      deepEqual names, ['foo', 'bar', 'baz']

asyncTest 'it should render new items as they are added', ->
  source = '<div><p data-foreach-object="objects" class="present" data-bind="object"></p></div>'
  objects = new Batman.Set('foo', 'bar')

  render source, {objects}, (node, view) ->
    objects.add('foo', 'baz', 'qux')
    delay =>
      names = $('p', view.get('node')).map -> @innerHTML
      names = names.toArray()
      deepEqual names, ['foo', 'bar', 'baz', 'qux']

asyncTest 'it should remove items from the DOM as they are removed from the set', ->
  source = '<div><p data-foreach-object="objects" class="present" data-bind="object"></p></div>'
  objects = new Batman.Set('foo', 'bar')

  render source, {objects}, (node, view) ->
    objects.remove('foo', 'baz', 'qux')
    delay =>
      names = $('p', view.get('node')).map -> @innerHTML
      names = names.toArray()
      deepEqual names, ['bar']

asyncTest 'it should atomically reorder DOM nodes when the set is reordered', ->
  source = '<div><p data-foreach-object="objects" class="present" data-bind="object.name"></p></div>'
  objects = new Batman.SortableSet({id: 1, name: 'foo'}, {id: 2, name: 'bar'})
  objects.sortBy 'id'

  render source, {objects}, (node, view) ->
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

  render source, {objects}, (node, view) ->
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
    contexts: [obj(), obj({objects})]
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

  render source, false, {bar: objects, foo: "qux"}, (node) ->
    equal 'qux', $('span', node).html(), "Node after the loop is also rendered"
    QUnit.start()

asyncTest 'it should update the whole set of nodes if the collection changes', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  context = new Batman.Object
    objects: new Batman.Set('foo', 'bar', 'baz')

  render source, false, context, (node, view) ->
    equal $('.present', node).length, 3
    context.set('objects', new Batman.Set('qux', 'corge'))
    delay =>
      equal $('.present', node).length, 2


asyncTest 'it should not fail if the collection is cleared', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  context = new Batman.Object
    objects: new Batman.Set('foo', 'bar', 'baz')

  render source, false, context, (node, view) ->
    delay => # new renderer's are used for each loop node, must wait longer
      equal $('.present', node).length, 3
      context.get('objects').clear()
      delay =>
        equal $('.present', node).length, 0


asyncTest 'previously observed collections shouldn\'t have any effect if they are replaced', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  oldObjects = new Batman.Set('foo', 'bar', 'baz')
  context = new Batman.Object(objects: oldObjects)

  render source, false, context, (node, view) ->
    context.set('objects', new Batman.Set('qux', 'corge'))
    oldObjects.add('no effect')
    delay =>
      equal $('.present', node).length, 2

asyncTest 'it should order loops among their siblings properly', 5, ->
  source = '<div><span data-bind="baz"></span><p data-foreach-object="bar" class="present" data-bind="object"></p><span data-bind="foo"></span></div>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  render source, false, {baz: "corn", bar: objects, foo: "qux"}, (node) ->
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

  render source, {playerScores}, (node, view) ->
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

  render source, {playerScores}, (node, view) ->
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
  render source, {x}, (node, view) ->
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
    @context = obj
      posts: new Batman.Set()
      tagColor: "green"

    @context.posts.add obj(tags:new Batman.Set("funny", "satire", "nsfw"), name: "post-#{i}") for i in [0..2]

    @source = '''
      <div>
        <div data-foreach-post="posts" class="post">
          <span data-foreach-tag="post.tags" data-bind="tag" class="tag" data-bind-post="post.name" data-bind-color="tagColor"></span>
        </div>
      </div>
    '''

asyncTest 'it should allow nested loops', 2, ->
  render @source, @context, (node, view) ->
    delay => # extra delay because foreach parsing ignores children
      equal $('.post', node).length, 3
      equal $('.tag', node).length, 9

asyncTest 'it should allow access to variables in higher scopes during loops', 3*3, ->
  render @source, @context, (node, view) ->
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

  node = render source, context, (node) ->
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

  node = render source, context, (node) =>
    $('input', node).val('new name')
    triggerChange(node[0].childNodes[1])
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

  node = render source, context, (node) =>
    equals $('input', node).val(), ""
    context.set 'instanceOfUser', new @User
    delay =>
      equals $('input', node).val(), "default name"



QUnit.module 'Batman.View rendering yielding and contentFor'

asyncTest 'it should insert content into yields when the content comes before the yield', 1, ->
  source = '''
  <div data-contentfor="baz">chunky bacon</div>
  <div data-yield="baz" id="test">erased</div>
  '''
  node = render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "chunky bacon"

asyncTest 'it should insert content into yields when the content comes after the yield', 1, ->
  source = '''
  <div data-yield="baz" class="test">erased</div>
  <span data-contentfor="baz">chunky bacon</span>
  '''
  node = render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "chunky bacon"

asyncTest 'it shouldn\'t go nuts if the content is already inside the yield', 1, ->
  source = '<div data-yield="baz" class="test">
              <span data-contentfor="baz">chunky bacon</span>
            </div>'
  node = render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "chunky bacon"

QUnit.module 'Batman.View rendering with bindings'

asyncTest 'it should update simple bindings when they change', 2, ->
  context = obj foo: 'bar'
  node = render '<div data-bind="foo"></div>', context, (node) ->
    equals node.html(), "bar"
    context.set('foo', 'baz')
    equals node.html(), "baz"
    QUnit.start()

asyncTest 'it should allow chained keypaths', 3, ->
  context = obj
    foo: obj
      bar: obj
        baz: 'wallawalladingdong'

  render '<div data-bind="foo.bar.baz"></div>', context, (node) ->

    equals node.html(), "wallawalladingdong"
    context.set('foo.bar.baz', 'kablamo')
    equals node.html(), "kablamo"
    context.set('foo.bar', obj baz: "whammy")
    equals node.html(), "whammy"

    QUnit.start()

QUnit.module 'Batman.View rendering filters'

asyncTest 'should render filters at one key deep keypaths', 1, ->
  node = render '<div data-bind="foo | upcase"></div>',
    foo: 'foo'
  , (node) ->
    equals node.html(), "FOO"
    QUnit.start()

asyncTest 'should render filters at n deep keypaths', 2, ->
  render '<div data-bind="foo.bar | upcase"></div>',
    foo: obj
      bar: 'baz'
  , (node) ->
    equals node.html(), "BAZ"
    render '<div data-bind="foo.bar.baz | upcase "></div>',
      foo: obj
        bar: obj
          baz: "qux"
    , (node) ->
      equals node.html(), "QUX"
      QUnit.start()

asyncTest 'should render chained filters', 1, ->
  node = render '<div data-bind="foo | upcase | downcase"></div>',
    foo: 'foo'
  , (node) ->
    equals node.html(), "foo"
    QUnit.start()

asyncTest 'should update bindings with the filtered value if they change', 1, ->
  context = obj
    foo: 'bar'
  render '<div data-bind="foo | upcase"></div>', context, (node) ->
    context.set('foo', 'baz')
    equals node.html(), 'BAZ'
    QUnit.start()

asyncTest 'should allow filtering on attributes', 2, ->
  render '<div data-addclass-works="bar | first" data-bind-attr="foo | upcase "></div>',
    foo: "bar"
    bar: [true]
  , (node) ->
    ok node.hasClass('works')
    equals node.attr('attr'), 'BAR'
    QUnit.start()

asyncTest 'should allow filtering on simple values', 1, ->
  render '<div data-bind="\'foo\' | upcase"></div>', {}, (node) ->
    equals node.html(), 'FOO'
    QUnit.start()

asyncTest 'should allow filtering on objects and arrays', 2, ->
  render '<div data-bind="[1,2,3] | join \' \'"></div>', {}, (node) ->
    equals node.html(), '1 2 3'

    Batman.Filters.dummyObjectFilter = (value, key) -> value[key]
    render '<div data-bind="{\'foo\': \'bar\', \'baz\': 4} | dummyObjectFilter \'foo\'"></div>', {}, (node) ->
      equals node.html(), 'bar'
      QUnit.start()

asyncTest 'should allow keypaths as arguments to filters', 1, ->
  render '<div data-bind="foo | join bar"></div>',
    foo: [1,2,3]
    bar: ':'
  , (node) ->
    equals node.html(), '1:2:3'
    QUnit.start()

asyncTest 'should update bindings when argument keypaths change', 1, ->
  context = obj
    foo: [1,2,3]
    bar: ''

  render '<div data-bind="foo | join bar"></div>', context, (node) ->
    context.set('bar', "-")
    delay ->
      equals node.html(), '1-2-3'

asyncTest 'should allow filtered keypaths as arguments to context', 1, ->
  context = obj
    foo: obj
      baz: obj
        qux: "filtered!"
    bar: 'baz'

  render '<div data-context-corge="foo | get bar"><div id="test" data-bind="corge.qux"></div></div>', context, (node) ->
    delay ->
      equals $("#test", node).html(), 'filtered!'

asyncTest 'should allow filtered keypaths as arguments to formfor', 1, ->
  class SingletonDooDad extends Batman.Object
    someKey: 'foobar'

    @classAccessor 'instance',
      get: (key) ->
        unless @_instance
          @_instance = new SingletonDooDad
        @_instance

  context = obj
    klass: SingletonDooDad

  source = '<form data-formfor-obj="klass | get \'instance\'"><span id="test" data-bind="obj.someKey"></span></form>'
  render source, context, (node) ->
    delay ->
      equals $("#test", node).html(), 'foobar'

asyncTest 'should allow filtered keypaths as arguments to mixin', 1, ->
  context = obj
    foo: obj
      baz:
        someKey: "foobar"
    bar: 'baz'

  render '<div id="test" data-mixin="foo | get bar"></div>', context, (node) ->
    delay ->
      equals node[0].someKey, 'foobar'

asyncTest 'should allow filtered keypaths as arguments to foreach', 3, ->
  context = obj
    foo: obj
      baz: [obj(key: 1), obj(key: 2), obj(key: 3)]
    bar: 'baz'

  render '<div><span class="tracking" data-foreach-number="foo | get bar" data-bind="number.key"></span></div>', context, (node) ->
    delay ->
      tracker = {'1': false, '2': false, '3': false}
      $(".tracking", node).each (i, x) ->
        tracker[$(x).html()] = true
      ok tracker['1']
      ok tracker['2']
      ok tracker['3']

QUnit.module 'Batman.View rendering filters built in'

asyncTest 'get', 1, ->
  context = obj
    foo: new Batman.Hash({bar: "qux"})

  render '<div data-bind="foo | get \'bar\'"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'get short syntax', 1, ->
  context = obj
    foo: new Batman.Hash({bar: "qux"})

  render '<div data-bind="foo[\'bar\']"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'truncate', 2, ->
  render '<div data-bind="foo | truncate 5"></div>',
    foo: 'your mother was a hampster'
  , (node) ->
    equals node.html(), "yo..."

    render '<div data-bind="foo.bar | truncate 5, \'\'"></div>',
      foo: obj
        bar: 'your mother was a hampster'
    , (node) ->
      equals node.html(), "your "
      QUnit.start()

asyncTest 'prepend', 1, ->
  render '<div data-bind="foo | prepend \'special-\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "special-bar"
    QUnit.start()

asyncTest 'append', 1, ->
  render '<div data-bind="foo | append \'-special\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "bar-special"
    QUnit.start()

asyncTest 'downcase', 1, ->
  render '<div data-bind="foo | downcase"></div>',
    foo: 'BAR'
  , (node) ->
    equals node.html(), "bar"
    QUnit.start()

asyncTest 'upcase', 1, ->
  render '<div data-bind="foo | upcase"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "BAR"
    QUnit.start()

asyncTest 'join', 2, ->
  render '<div data-bind="foo | join"></div>',
    foo: ['a', 'b', 'c']
  , (node) ->
    equals node.html(), "abc"

    render '<div data-bind="foo | join \'|\'"></div>',
      foo: ['a', 'b', 'c']
    , (node) ->
      equals node.html(), "a|b|c"
      QUnit.start()

asyncTest 'sort', 1, ->
  render '<div data-bind="foo | sort | join"></div>',
    foo: ['b', 'c', 'a', '1']
  , (node) ->
    equals node.html(), "1abc"
    QUnit.start()

asyncTest 'not', 1, ->
  render '<div data-showif="foo | not"></div>',
    foo: true
  , (node) ->
    equals node[0].style.display, "none"
    QUnit.start()


asyncTest 'map', 1, ->
  render '<div data-bind="posts | map \'name\' | join \', \'"></div>',
    posts: [
      obj
        name: 'one'
        comments: 10
    , obj
        name: 'two'
        comments: 20
    ]
  , (node) ->
    equals node.html(), "one, two"
    QUnit.start()

asyncTest 'map with a numeric key', 1, ->
  render '<div data-bind="counts | map 1 | join \', \'"></div>',
    counts: [
      [1, 2, 3]
      [4, 5, 6]
    ]
  , (node) ->
    equals node.html(), "2, 5"
    QUnit.start()

asyncTest 'map', 1, ->
  render '<div data-bind="posts | map \'name\' | join \', \'"></div>',
    posts: [
      obj
        name: 'one'
        comments: 10
    , obj
        name: 'two'
        comments: 20
    ]
  , (node) ->
    equals node.html(), "one, two"
    QUnit.start()

QUnit.module "Batman.View rendering filters defined by the user"

asyncTest 'should render a user defined filter', 2, ->
  Batman.Filters['test'] = spy = createSpy().whichReturns("testValue")
  render '<div data-bind="foo | test 1, \'baz\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "testValue"
    deepEqual spy.lastCallArguments, ['bar', 1, 'baz']
    QUnit.start()

QUnit.module 'Batman.View rendering routes'

asyncTest 'should set href for URL fragment', 1, ->
  render '<a data-route="/test">click</a>', {},
  (node) =>
    equal node.attr('href'), '#!/test'
    QUnit.start()

unless IN_NODE
  asyncTest 'should set model instance', 1, ->
    class @App extends Batman.App
      @layout: null
      @route 'tweet/:id', 'tweets#show', resource: 'tweet'
    class @App.Tweet extends Batman.Model
    class @App.TweetsController extends Batman.Controller
      show: (params) ->

    @App.run()

    tweet = new @App.Tweet(id: 1)
    @App.set 'tweet', tweet

    source = '<a data-route="tweet">click</a>'
    node = document.createElement 'div'
    node.innerHTML = source

    view = new Batman.View
      contexts: []
      node: node
    view.ready ->
      node = $(view.get('node').children[0])
      equal node.attr('href'), '#!/tweet/1'
      QUnit.start()
    view.get 'node'
