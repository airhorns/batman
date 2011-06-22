$ = window.$ unless $
runningInNode = module? && exports?

class MockRequest extends MockClass
  @chainedCallback 'success'
  @chainedCallback 'error'

oldRequest = Batman.Request

QUnit.module 'Batman.View'
  setup: ->
    MockRequest.reset()
    @options =
      source: 'test_path.html'
    
    Batman.Request = MockRequest
    @view = new Batman.View(@options) # create a view which uses the MockRequest internally
  
  teardown: ->
    Batman.Request = oldRequest

asyncTest 'should pull in the source for a view from a path, appending the prefix', 1, ->
  delay =>
    deepEqual MockRequest.lastInstance.constructorArguments[0].url, 'views/test_path.html'

asyncTest 'should update its node with the contents of its view', 1, ->
  delay =>
    MockRequest.lastInstance.fireSuccess('view contents')
    equal @view.get('node').innerHTML, 'view contents'

asyncTest 'should fire the ready event once its contents have been loaded', 1, ->
  @view.ready (observer = createSpy())
  
  delay =>
    MockRequest.lastInstance.fireSuccess('view contents')
    ok observer.called
    QUnit.start()

QUnit.module 'Batman.View rendering'

obj = (a = {}) -> new Batman.Object a
render = (source, jqueryize = true, context = {}) ->
  node = document.createElement 'div'
  node.innerHTML = source
  context = jqueryize unless !!jqueryize == jqueryize
  context = if context.get && context.set then context else obj context
  new Batman.View
    context: context
    node: node
  if jqueryize then $(node).children() else node

hte = (actual, expected) ->
  equal actual.innerHTML, expected

test 'it should render simple nodes', ->
  hte render("<div></div>", false), "<div></div>"

test 'it should render many parent nodes', ->
  hte render("<div></div><p></p>", false), "<div></div><p></p>"

QUnit.module 'Batman.View rendering simple bindings'

test 'it should allow the inner value to be bound', ->
  node = render '<div data-bind="foo"></div>',
    foo: 'bar'

  equals node.html(), "bar"

test 'it should allow a class to be bound', ->
  source = '<div data-class-one="foo" data-class-two="bar" class="zero"></div>'
  node = render source,
    foo: true
    bar: false

  ok node.hasClass('one')
  ok !node.hasClass('two')

  node = render source,
    foo: false
    bar: true

  ok !node.hasClass('one')
  ok node.hasClass('two')

test 'it should allow visibility to be bound', ->
  source = '<div data-visible="foo" style="display: block;"></div>'
  node = render source,
    foo: true

  if runningInNode
    equal node.css('display'), undefined
  else
    equal node.css('display'), 'block'

  node = render source,
    foo: false

  equal node.css('display'), 'none'

test 'it should allow arbitrary attributes to be bound', ->
  source = '<div data-bind-foo="one" data-bind-bar="two" foo="before"></div>'
  node = render source,
    one: "baz"
    two: "qux"
  equal node[0]['foo'], "baz"
  equal node[0]['bar'], "qux"

test 'it should allow events to be bound', ->
  context =
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  node = render source, context
  if runningInNode
    # Use DOM level 2 event dispatch, which doesn't seem to work with jQuery
    evt = document.createEvent("MouseEvents")
    evt.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null)
    node[0].dispatchEvent(evt)
  else
    node.trigger('click')
  ok spy.called

test 'it should allow mixins to be applied', ->
  Batman.mixins.test =
    initialize: spy = createSpy()
    foo: 'bar'

  source = '<div data-mixin="test"></div>'
  node = render source, false

  ok spy.called
  equals node.firstChild.foo, 'bar'
  delete Batman.mixins.test

QUnit.module "Batman.View rendering loops"

test 'it should allow simple loops', ->
  source = '<p data-foreach-object="objects" class="present" data-bind="object"></p>'
  objects = ['foo', 'bar', 'baz']
  node = render source, {objects}
  for i in [0..2]
    equal node[i].innerHTML, objects[i]
    equal node[i].className,  'present'

QUnit.module "Batman.View rendering nested loops"
  setup: ->
    @context = obj
      posts: []
      tagColor: "green"
    @context.posts.push obj(tags:["funny", "satire", "nsfw"], name: "post-#{i}") for i in [0..2]
    @source = '''
      <div>
        <div data-foreach-post="posts" class="post">
          <span data-foreach-tag="post.tags" data-bind="tag" class="tag" data-bind-post="post.name" data-bind-color="tagColor"></span>
        </div>
      </div>
    '''
    @node = render @source, @context

test 'it should allow nested loops', ->
  equal $('.post', @node).length, 3
  equal $('.tag', @node).length, 9

test 'it should allow access to variables in higher scopes during loops', ->
  for postNode, i in $('.post', @node)
    for tagNode, j in $('.tag', postNode)
      equal tagNode.post, "post-#{i}"
      equal tagNode.color, "green"

QUnit.module 'Batman.View rendering yielding and contentFor'

test 'it should insert content into yields when the content comes before the yield', ->
  source = '''
  <div data-contentfor="baz">chunky bacon</div>
  <div data-yield="baz" id="test">erased</div>
  '''
  node = render source
  equals node.children(0).html(), "chunky bacon"

test 'it should insert content into yields when the content comes after the yield', ->
  source = '''
  <div data-yield="baz" class="test">erased</div>
  <span data-contentfor="baz">chunky bacon</span>
  '''
  node = render source
  equals node.children(0).html(), "chunky bacon"

test 'it shouldn\'t go nuts if the content is already inside the yield', ->
  source = '<div data-yield="baz" class="test">
              <span data-contentfor="baz">chunky bacon</span>
            </div>'
  node = render source
  equals node.children(0).html(), "chunky bacon"

QUnit.module 'Batman.View rendering with bindings'

test 'it should update simple bindings when they change', ->
  context = obj foo: 'bar'
  node = render '<div data-bind="foo"></div>', context

  equals node.html(), "bar"
  context.set('foo', 'baz')
  equals node.html(), "baz"

test 'it should allow chained keypaths', ->
  context = obj
    foo: obj
      bar: obj
        baz: 'wallawalladingdong'
  node = render '<div data-bind="foo.bar.baz"></div>', context

  equals node.html(), "wallawalladingdong"
  context.set('foo.bar.baz', 'kablamo')
  equals node.html(), "kablamo"
  # FIXME: the recursive observers aren't in place
  #context.set('foo.bar', obj baz: "whammy")
  #equals node.html(), "whammy"

