# class Person
#   @accessor 'name', 'momName', 'dadName',
#     get: -> @firstName+' '+@lastName
#     set: (val) -> [@firstName, @lastName] = val.split(' ')
#     unset: ->
#       @firstName = null
#       delete @firstName
#       @lastName = null
#       delete @lastName

#
# class Batman.Object
#   constructor: (obj) ->
#     @[key] = val for own key, val of obj if obj


QUnit.module 'Batman.ObservableProperty',
  setup: ->

test "refreshTriggers() sets this.triggers to all properties that this one is dependent on, and maintains the inverse 'dependents' on other Properties", ->
  fullNameAccessor = get: (key) -> firstNameProp.getValue()+' '+lastNameProp.getValue()
  keyAccessors = new Batman.SimpleHash
  keyAccessors.set('fullName', fullNameAccessor)
  person = Batman
    firstName: 'James'
    lastName: 'MacAulay'
  person._batman.keyAccessors = keyAccessors

  firstNameProp = new Batman.ObservableProperty(person, 'firstName')
  lastNameProp = new Batman.ObservableProperty(person, 'lastName')
  fullNameProp = new Batman.ObservableProperty(person, 'fullName')

  equal fullNameProp.getValue(), 'James MacAulay'

  fullNameProp.refreshTriggers()

  equal fullNameProp.triggers.length, 3
  ok fullNameProp.triggers.has(firstNameProp)
  ok fullNameProp.triggers.has(lastNameProp)
  ok fullNameProp.triggers.has(fullNameProp)

  equal firstNameProp.dependents.length, 1
  ok firstNameProp.dependents.has(fullNameProp)

  equal firstNameProp.dependents.length, 1
  ok firstNameProp.dependents.has(fullNameProp)
  equal lastNameProp.dependents.length, 1
  ok lastNameProp.dependents.has(fullNameProp)
  equal fullNameProp.dependents.length, 1
  ok fullNameProp.dependents.has(fullNameProp)

test "property() works on non Batman objects", ->
  property = new Batman.ObservableProperty(window, 'Array')
  ok ! property.hasObserversToFire()
  property.observe spy = createSpy()
  property.fire()
  ok spy.called

  property = new Batman.ObservableProperty({}, 'foo')
  ok ! property.hasObserversToFire()
  property.observe spy = createSpy()
  property.fire()
  ok spy.called

test "only fires when its prevents and allows are balanced", ->
  property = new Batman.ObservableProperty(window, 'Array')
  property.observe spy = createSpy()

  property.prevent()
  property.fire()
  ok !spy.called

  property.allow()
  property.fire()
  ok spy.called
