QUnit.module 'Batman.HistoryManager',
  setup: ->


test "joinPath(segments...) joins path segments with forward slashes", ->
  equal Batman.HistoryManager::joinPath('foo','bar','baz'), 'foo/bar/baz'

test "joinPath(segments...) squashes segment boundary slashes", ->
  equal Batman.HistoryManager::joinPath('/','/','/','/foo/','/','/bar//baz/','/'), '/foo/bar//baz/'