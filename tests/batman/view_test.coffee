$ = window.$ unless $
runningInNode = module? && exports?

class MockRequest extends MockClass
  @chainedCallback 'success'
  @chainedCallback 'error'

oldRequest = Batman.Request

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
  
  setTimeout(=>
    MockRequest.lastInstance.fireSuccess('view contents')
  , ASYNC_TEST_DELAY)

  setTimeout(=>
    QUnit.start()
    ok observer.called
  , ASYNC_TEST_DELAY*2)
  
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

asyncTest 'it should allow visibility to be bound', 2, ->
  source = '<div data-showif="foo" style="display: block;"></div>'
  render source,
    foo: true
  , (node) ->
    if runningInNode
      equal node.css('display'), undefined
    else
      equal node.css('display'), 'block'

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

asyncTest 'it should allow events to be bound', 1, ->
  context =
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  render source, context, (node) ->
    if runningInNode
      # Use DOM level 2 event dispatch, which doesn't seem to work with jQuery
      evt = document.createEvent("MouseEvents")
      evt.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null)
      node[0].dispatchEvent(evt)
    else
      node.trigger('click')
    ok spy.called
    QUnit.start()

asyncTest 'it should allow mixins to be applied', 1, ->
  Batman.mixins.set 'test', 
    foo: 'bar'

  source = '<div data-mixin="test"></div>'
  render source, false, (node) ->
    equals node.firstChild.foo, 'bar'
    delete Batman.mixins.test
    QUnit.start()

QUnit.module "Batman.View rendering loops"

asyncTest 'it should allow simple loops', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  render source, {objects}, (node, view) ->
    delay => # new renderer's are used for each loop node, must wait longer
      tracking = {foo: false, bar: false, baz: false}
      node = $(view.get('node')).children()
      for i in [0...node.length]
        # We must track these in a temp object because they are a set => undefined order, can't assume
        tracking[node[i].innerHTML] = true 
        equal node[i].className,  'present'
      
      for k in ['foo', 'bar', 'baz']
        ok tracking[k], "Object #{k} was found in the source"

asyncTest 'it should continue to render nodes after the loop', 1, ->
  source = '<div><p data-foreach-object="bar" class="present" data-bind="object"></p><span data-bind="foo"/></div>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  render source, false, {bar: objects, foo: "qux"}, (node) ->
    delay => equal 'qux', $('span', node).html(), "Node after the loop is also rendered"


asyncTest 'it should order loops among their siblings properly', 5, ->
  source = '<div><span data-bind="baz"></span><p data-foreach-object="bar" class="present" data-bind="object"></p><span data-bind="foo"></span></div>'
  objects = new Batman.Set('foo', 'bar', 'baz')

  render source, false, {baz: "corn", bar: objects, foo: "qux"}, (node) ->
    delay =>
      div = node.childNodes[0]
      equal 'corn', $('span', div).get(0).innerHTML, "Node before the loop is rendered"
      equal 'qux', $('span', div).get(1).innerHTML, "Node before the loop is rendered"
      equal 'p', div.childNodes[1].tagName.toLowerCase(), "Order of nodes is preserved"
      equal 'span', div.childNodes[4].tagName.toLowerCase(), "Order of nodes is preserved"
      equal 'span', div.childNodes[0].tagName.toLowerCase(), "Order of nodes is preserved"

QUnit.module "Batman.View rendering nested loops"
  setup: ->
    @context = obj
      posts: new Batman.Set
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
    delay ->
      equal $('.post', node).length, 3
      equal $('.tag', node).length, 9

asyncTest 'it should allow access to variables in higher scopes during loops', 3*3 + 3, ->
  postCounts = [0,0,0]
  render @source, @context, (node, view) ->
    delay => # new renderers are used for each loop node, must wait longer
      node = view.get('node')
      for postNode, i in $('.post', node)
        for tagNode, j in $('.tag', postNode)
          equal $(tagNode).attr('color'), "green"

          # Each tag node has a "post-#{i}" binding to show it has access to the enclosing scope.
          # Since the order the tags come out is undefined, we increment the ith index in a 
          # tracking array. At the end, each position in the tracking array should read 3, 
          # because each post has three tags.
          postRef = $(tagNode).attr('post')
          postCounts[parseInt(postRef.slice(5,6), 10)]++

      for count, i in postCounts
        equal count, 3, "There are 3 tags referencing post-#{i}"

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
  node = render '<div data-bind="foo | times 2"></div>',
    foo: 2
  , (node) ->
    equals node.html(), "4"
    QUnit.start()

asyncTest 'should render filters at n deep keypaths', 2, ->
  render '<div data-bind="foo.bar | times 2"></div>',
    foo: obj
      bar: 2
  , (node) ->
    equals node.html(), "4"
    render '<div data-bind="foo.bar.baz | times 2"></div>',
      foo: obj
        bar: obj
          baz: 2
    , (node) ->
      equals node.html(), "4"
      QUnit.start()

asyncTest 'should update bindings with the filtered value if they change', 1, ->
  context = obj
    foo: 1
  render '<div data-bind="foo | times 2"></div>', context, (node) ->
    context.set('foo', 2)
    equals node.html(), '4'
    QUnit.start()

asyncTest 'should allow filtering on attributes', 2, ->
  render '<div data-addclass-works="bar | first" data-bind-attr="foo | times 3"></div>',
    foo: 2
    bar: [true]
  , (node) ->
    ok node.hasClass('works')
    equals node.attr('attr'), 6
    QUnit.start()

asyncTest 'should allow filtering on simple values', 1, ->
  render '<div data-bind="1 | times 2"></div>', {}, (node) ->
    equals node.html(), '2'
    QUnit.start()

asyncTest 'should allow filtering on objects and arrays', 2, ->
  render '<div data-bind="[1,2,3] | join \' \'"></div>', {}, (node) ->
    equals node.html(), '1 2 3'

    Batman.Filters.dummyObjectFilter = (value, key) -> value[key]
    render '<div data-bind="{\'foo\': \'bar\', \'baz\': 4} | dummyObjectFilter \'foo\'"></div>', {}, (node) ->
      equals node.html(), 'bar'
      QUnit.start()

asyncTest 'should allow keypaths as arguments to filters', 1, ->
  render '<div data-bind="foo | times bar"></div>', 
    foo: 2
    bar: 2
  , (node) ->
    equals node.html(), '4'
    QUnit.start()

asyncTest 'should update bindings when argument keypaths change', 1, ->
  context = obj
    foo: 2
    bar: 2

  render '<div data-bind="foo | times bar"></div>', context, (node) ->
    context.set('bar', 4)
    delay ->
      equals node.html(), '8'

QUnit.module 'Batman.View rendering filters built in'

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

QUnit.module "Batman.View rendering filters defined by the user"

asyncTest 'should render a user defined filter', 2, ->
  Batman.Filters['test'] = spy = createSpy().whichReturns("testValue")
  render '<div data-bind="foo | test 1, \'baz\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "testValue"
    deepEqual spy.lastCallArguments, ['bar', 1, 'baz']
    QUnit.start()

test 'dumb', ->
  
  class A extends Batman.Object
  a = new A
  a.set 'foo', 10

  class B extends Batman.Object
    @::accessor 'prop'
      get: (key) -> a.get('foo') + @get 'foo'

  b = new B
  b.set 'foo', 20
  b.observe 'prop', spy = createSpy()
  equal b.get('prop'), 30

  a.set('foo', 20)
  ok spy.called

  class Binding extends Batman.Object
    @::accessor 
      get: () -> b.get 'foo'
 
  c = new Binding
  equal c.get(), 20

  c.observe 'whatever', spy = createSpy()
  b.set 'foo', 1000
  ok spy.called


   

