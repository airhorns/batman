Batman = require '../../../../lib/batman'
Watson = require 'watson'
jsdom = require 'jsdom'

# Addition of ViewSourceCache
Watson.ensureCommitted "326f4a52d83b3871ff79a8b6fff4c51f24771fd6", ->
  global.window = jsdom.jsdom("<html><head><script></script></head><body></body></html>").createWindow()
  global.document = window.document

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

  Watson.trackMemory 'view memory usage: source cache', 20, {step: 1, async: true}, (i, next) ->
    context = Batman(objects: new Batman.Set([0...50]...))

    view = new Batman.View
      contexts: [context]
      source: 'a/test/path'

    finish = ->
      Batman.DOM.removeNode(view.get('node'))
      next()

    if view.on?
      view.on 'ready', finish
    else
      view.ready finish

