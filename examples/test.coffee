ITERATONS = 3000

class window.MyApp extends Batman.App
  @aSet: new Batman.Set
  @index: @aSet.indexedBy('foo')
  @test: ->
    clunks = (new MyApp.Product() for i in [0..ITERATONS])

    for i in [0..ITERATONS]
      @aSet.add clunks[i]
      if i % 500 == 0
        @aSet.clear()

    array = @index.get('toArray')
    console.log "Run."

class MyApp.Product extends Batman.Model
  constructor: ->
    super
    @set 'name', "Cool Snowboard"
    @set 'cost', (Math.random() * 100).toFixed(2)

  @encode 'name', 'cost'

MyApp.run()
