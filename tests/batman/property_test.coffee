QUnit.module 'Batman.Property',
  setup: ->
    @findArea = -> @height * @width
    
    @rectangle = Batman
      height: 2
      width: 4
      area: new Batman.Property
        resolve: @findArea
    
    @joinNames = -> @firstName+' '+@lastName
    @splitNames = (value) ->
      names = value.split(' ')
      @firstName = names[0]
      @lastName = names[names.length-1]
    
    @james = Batman
      firstName: 'James'
      lastName: 'MacAulay'
      name: new Batman.Property
        resolve: @joinNames
        assign: @splitNames

test "initializes with the given resolve and assign functions", ->
  equal @rectangle.area.resolve, @findArea
  equal typeof @rectangle.area.assign, 'function'
  
  equal @james.name.resolve, @joinNames
  equal @james.name.assign, @splitNames