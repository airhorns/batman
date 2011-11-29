QUnit.module 'helpers'

test 'functionName', ->
  class Function
  class ExtendedFunction extends Function
  class Foo_Bar
  class FooBar
  class P
  namespace = P: P
  equal "Function", Batman._functionName(Function)
  equal "ExtendedFunction", Batman._functionName(ExtendedFunction)
  equal "Foo_Bar", Batman._functionName(Foo_Bar)
  equal "FooBar", Batman._functionName(FooBar)
  equal "P", Batman._functionName(namespace.P)
  equal undefined, Batman._functionName ->
  equal undefined, Batman._functionName =>
