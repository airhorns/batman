QUnit.module '$setImmediate helper'

asyncTest "should fire asynchronously", 1, ->
  Batman.setImmediate ->
    ok true
    QUnit.start()

asyncTest "should be clearable", 0, ->
  handle = Batman.setImmediate ->
    ok false

  Batman.clearImmediate handle

  delay ->

asyncTest "clearing one should not clear the other", 1, ->
  handleA = Batman.setImmediate ->
    ok false

  handleB = Batman.setImmediate ->
    ok true

  Batman.clearImmediate handleA

  delay ->

asyncTest "should execute in series", 2, ->
  x = 0

  Batman.setImmediate ->
    equal ++x, 1

  Batman.setImmediate ->
    equal ++x, 2

  delay ->

