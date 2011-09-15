helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

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
    equal $('.post', node).length, 3
    equal $('.tag', node).length, 9
    QUnit.start()

asyncTest 'it should allow access to variables in higher scopes during loops', 3*3, ->
  helpers.render @source, @context, (node, view) ->
    node = view.get('node')
    for postNode, i in $('.post', node)
      for tagNode, j in $('.tag', postNode)
        equal $(tagNode).attr('color'), "green"
    QUnit.start()

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
