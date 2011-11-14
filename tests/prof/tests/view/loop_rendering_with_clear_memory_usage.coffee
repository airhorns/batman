Batman = require './../../../../lib/batman'
Watson = require 'watson'
Random = require '../lib/number_generator'
Clunk = require '../lib/clunk'

# Fix deferred loop rendering to actually happen, and always fire the parent's rendered event
# Needed for the ::deferEvery settings below.
Watson.ensureCommitted '6d132e078e3e07473b538ab157635b8664e2077e', ->
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

  Batman.Renderer::deferEvery = false

  node = document.createElement 'div'
  node.innerHTML = loopSource

  objects = new Batman.Set([0...50]...)
  context = Batman({objects})

  view = new Batman.View
    contexts: [context]
    node: node

  run = ->
    Watson.trackMemory 'view memory usage: loop rendering with clear', 1000, 5, (i) ->
      objects.add(i)
      if i % 300 == 0
        objects.clear()

  if view.on?
    view.on 'ready', run
  else
    view.ready run

