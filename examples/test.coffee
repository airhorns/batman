ITERATONS = 3000

loopSource = '''
<div data-foreach-obj="objects">
  <span data-bind="obj"></span>
  <span data-bind="obj"></span>
  <span data-bind="obj"></span>
  <span data-bind="obj"></span>
  <span data-bind="obj"></span>
  <span data-bind="obj"></span>
</div>
'''
Batman.View.sourceCache.set '/views/a/test/path', loopSource

Batman.Renderer::deferEvery = false if Batman.Renderer::deferEvery

class window.MyApp extends Batman.App
  @aSet: new Batman.Set
  @index: @aSet.indexedBy('foo')
  @test: ->
    next = (i) ->
      if i == 0
        console.log "Run"
        return

      context = Batman(objects: new Batman.Set([0...50]...))

      view = new Batman.View
        contexts: [context]
        source: 'a/test/path'

      view.on 'ready', ->
        Batman.DOM.removeNode(view.get('node'))
        next(i-1)

    next(10)

MyApp.run()
