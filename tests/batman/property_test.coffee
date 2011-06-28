QUnit.module 'Batman.Property',
  setup: ->
    @resolveArea = createSpy -> @height * @width
    
    @rectangle = Batman
      height: 2
      width: 4
      area: new Batman.Property
        resolve: @resolveArea
    
    @resolveName = createSpy -> @firstName+' '+@lastName
    @assignName = createSpy (value) ->
      names = value.split(' ')
      @firstName = names[0]
      @lastName = names[names.length-1]
      value
    @removeName = createSpy ->
      @unset 'firstName'
      @unset 'lastName'
    
    @james = Batman
      firstName: 'James'
      lastName: 'MacAulay'
      name: new Batman.Property
        resolve: @resolveName
        assign: @assignName
        remove: @removeName

test "initializes with the given resolve and assign functions", ->
  equal @rectangle.area.resolve, @resolveArea
  equal typeof @rectangle.area.assign, 'function'
  
  equal @james.name.resolve, @resolveName
  equal @james.name.assign, @assignName

test "resolveOnObject(obj) calls the property's resolve function with the given object as context", ->
  equal @rectangle.area.resolveOnObject(@rectangle), 8
  equal @resolveArea.lastCallContext, @rectangle

test "assignOnObject(obj) calls the property's assign function with the given object as context", ->
  equal @james.name.assignOnObject(@james, 'Jimmy Redbeard'), 'Jimmy Redbeard'
  equal @assignName.lastCallContext, @james
  equal @james.firstName, 'Jimmy'
  equal @james.lastName, 'Redbeard'

test "removeOnObject(obj) calls the property's assign function with the given object as context", ->
  equal @james.name.removeOnObject(@james)
  equal @removeName.lastCallContext, @james
  equal typeof(@james.firstName), 'undefined'
  equal typeof(@james.lastName), 'undefined'
