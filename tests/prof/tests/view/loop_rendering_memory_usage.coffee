Batman = require './../../../../lib/batman'
Watson = require 'watson'
Random = require '../lib/number_generator'
Clunk = require '../lib/clunk'

# Make Iterator defer DOM touches every 50 ms.
# Needed for the ::deferEvery settings below.
Watson.ensureCommitted '7a418aea67be0b79ce11fd5616bd4627f4e576d9', ->
  microtime = require 'microtime'
  jsdom = require 'jsdom'

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

  node = document.createElement 'div'
  node.innerHTML = loopSource
  objects = new Batman.Set([0...50]...)
  context = Batman({objects})
  generator = new Random(0, 50, 23423423)
  view = new Batman.View
    contexts: [context]
    node: node

  Batman.Renderer::deferEvery = false
  Batman.DOM.IteratorBinding::deferEvery = false

  run = ->
    Watson.trackMemory 'view memory usage: loop rendering', 300, 10, (i) ->
      for i in [0...20]
        objects.remove generator.next()
        objects.add generator.next()

  if view.on?
    view.on 'ready', run
  else
    view.ready run
