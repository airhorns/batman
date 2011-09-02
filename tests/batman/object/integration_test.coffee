test 'Batman: runtime integration test', ->
  class A extends Batman.Object
  a = new A
  a.set 'foo', 10

  class B extends Batman.Object
    @accessor 'prop'
      get: (key) -> a.get('foo') + @get 'foo'

  b = new B
  b.set 'foo', 20
  b.observe 'prop', spy = createSpy()
  equal b.get('prop'), 30

  a.set('foo', 20)
  ok spy.called

  class Binding extends Batman.Object
    @accessor
      get: () -> b.get 'foo'

  c = new Binding
  equal c.get('anything'), 20

  c.observe 'whatever', spy = createSpy()
  b.set 'foo', 1000
  ok spy.called
