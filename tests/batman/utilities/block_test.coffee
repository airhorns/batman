QUnit.module "Batman._block"

test "should allow blockizing of functions with take only a callback", 1, ->
  class Test
    method: Batman._block (callback) ->
      callback()

  (new Test).method()(-> ok true)

test "should allow blockizing of functions which take arguments and a callback", 3, ->
  class Test
    method: Batman._block (arg1, arg2, callback) ->
      equal arg1, "foo"
      equal arg2, 2
      callback()

  (new Test).method("foo", 2)(-> ok true)

test "should preserve the context in which the function is called", 1, ->
  ctx = false

  class Test
    getContext: ->
      @
    method: Batman._block (arg, callback) ->
      equal arg, @

  x = new Test
  ctx = x.getContext()
  x.method(ctx)(->)


test "should allow the callback to be passed as the last argument", 2, ->
  x = ->
  class Test
    method: Batman._block (arg, callback) ->
      equal arg, true
      equal callback, x

  (new Test).method(true, x)

test "should allow the airty to be specified so non function arguments can be passed and still trigger the call", 2, ->
  class Test
    method: Batman._block(2, (arg, anotherArg) ->
      equal arg, true
      equal anotherArg, false
    )

  (new Test).method(true, false)
