QUnit.module "Batman.RenderCache"
  setup: ->
    @cache = new Batman.RenderCache
    class @MockView extends MockClass
    @context = {}
    @exampleOptions = {source: "products/show", viewClass: @MockView, context: @context}

test "cache can have items added", ->
  equal 0, @cache.length()
  viewInstance = @cache.viewForOptions @exampleOptions
  equal 1, @cache.length()

test "cache can retrieve previously added items", ->
  newViewInstance = @cache.viewForOptions @exampleOptions
  nextViewInstance = @cache.viewForOptions @exampleOptions
  equal newViewInstance, nextViewInstance

test "cache won't return items with the same cache key but with different valued options", ->
  optionsA = Batman.mixin {foo: true}, @exampleOptions
  optionsB = Batman.mixin {foo: false}, @exampleOptions

  viewA = @cache.viewForOptions optionsA
  viewB = @cache.viewForOptions optionsB

  notEqual viewA, viewB

test "cache won't return items with the same cache key but with different length options", ->
  optionsA = Batman.mixin {foo: true}, @exampleOptions
  optionsB = @exampleOptions

  viewA = @cache.viewForOptions optionsA
  viewB = @cache.viewForOptions optionsB

  notEqual viewA, viewB

test "cache evicts old items as new items come in past the size limit", ->
  @cache.maximumSize = 2
  editOptions = Batman.mixin {}, @exampleOptions, {source: "products/edit"}
  newOptions = Batman.mixin {}, @exampleOptions, {source: "products/new"}
  showOptions = Batman.mixin {}, @exampleOptions

  editView = @cache.viewForOptions editOptions
  newView = @cache.viewForOptions newOptions
  # This should cycle out the edit view
  showView = @cache.viewForOptions showOptions
  equal @cache.length(), 2

  # This cycles show to the top -> now show, new
  equal @cache.viewForOptions(showOptions), showView, "The newly added view is cached"
  # This cyclew new to the top -> now new, show
  equal @cache.viewForOptions(newOptions), newView, "The unaffected view is still cached"

  equal @cache.length(), 2
  # This should cycle out show, -> now edit, new
  notEqual @cache.viewForOptions(editOptions), editView, "The olded view has been evicted because a new one is returned instead of a cached one"

  equal @cache.length(), 2

test "cache reprioritizes MRU items to not be evicted", ->
  @cache.maximumSize = 3
  editOptions = Batman.mixin {}, @exampleOptions, {source: "products/edit"}
  indexOptions = Batman.mixin {}, @exampleOptions, {source: "products/index"}
  newOptions = Batman.mixin {}, @exampleOptions, {source: "products/new"}
  showOptions = Batman.mixin {}, @exampleOptions

  editView = @cache.viewForOptions editOptions
  newView = @cache.viewForOptions newOptions
  indexView = @cache.viewForOptions indexOptions # Stack is now index, new, edit

  equal editView, @cache.viewForOptions editOptions # Stack is now edit, index, new

  # This should cycle out the new view
  showView = @cache.viewForOptions showOptions

  notEqual newView, @cache.viewForOptions newOptions, "The new view was evicted because it was last on the stack because edit moved to the top"
