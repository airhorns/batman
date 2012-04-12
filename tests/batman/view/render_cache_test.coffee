{putInDOM, removeFromDOM} = do ->
  dom = document.createElement 'div'
  {
    putInDOM:      (view) -> view.isInDOM = -> true
    removeFromDOM: (view) -> view.isInDOM = -> false
  }

equalCacheLength = (cache, length) ->
  QUnit.equal cache.length, length
  QUnit.equal cache.keyQueue.length, length

QUnit.module "Batman.RenderCache"
  setup: ->
    @cache = new Batman.RenderCache
    class @MockView extends MockClass
      get: ->
      set: ->
      isInDOM: -> false
    @context = {}
    @exampleOptions = {source: "products/show", viewClass: @MockView, context: @context}

test "cache can have items added", ->
  equalCacheLength(@cache, 0)
  viewInstance = @cache.viewForOptions @exampleOptions
  equalCacheLength(@cache, 1)

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
  @cache.maximumLength = 2
  editOptions = Batman.mixin {}, @exampleOptions, {source: "products/edit"}
  newOptions = Batman.mixin {}, @exampleOptions, {source: "products/new"}
  showOptions = Batman.mixin {}, @exampleOptions

  editView = @cache.viewForOptions editOptions
  newView = @cache.viewForOptions newOptions
  # This should cycle out the edit view
  showView = @cache.viewForOptions showOptions
  equalCacheLength(@cache, 2)

  # This cycles show to the top -> now show, new
  equal @cache.viewForOptions(showOptions), showView, "The newly added view is cached"
  # This cyclew new to the top -> now new, show
  equal @cache.viewForOptions(newOptions), newView, "The unaffected view is still cached"

  equalCacheLength(@cache, 2)
  # This should cycle out show, -> now edit, new
  notEqual @cache.viewForOptions(editOptions), editView, "The oldest view has been evicted because a new one is returned instead of a cached one"

  equalCacheLength(@cache, 2)

test "cache evicts only old items which are not in the DOM as new items come in past the size limit", ->
  @cache.maximumLength = 2
  editOptions = Batman.mixin {}, @exampleOptions, {source: "products/edit"}
  newOptions = Batman.mixin {}, @exampleOptions, {source: "products/new"}
  indexOptions = Batman.mixin {}, @exampleOptions, {source: "products/index"}
  showOptions = Batman.mixin {}, @exampleOptions

  editView = @cache.viewForOptions editOptions
  putInDOM(editView)
  newView = @cache.viewForOptions newOptions
  putInDOM(newView)
  # This does not cycle out edit or new because it's in use
  showView = @cache.viewForOptions showOptions
  equalCacheLength(@cache, 3)

  # This cycles show to the top -> now show, new, edit
  equal @cache.viewForOptions(showOptions), showView, "The newly added view is cached"
  # This cycles new to the top -> now new, show, edit
  equal @cache.viewForOptions(newOptions), newView, "The unaffected view is still cached"
  # This cycles new to the top -> now edit, new, show
  equal @cache.viewForOptions(editOptions), editView, "The unaffected view is still cached"

  equalCacheLength(@cache, 3)

  removeFromDOM(showView)
  removeFromDOM(newView)
  # This should cycle out show and new because they are no longer in use, -> now index, edit
  index = @cache.viewForOptions(indexOptions)

  equalCacheLength(@cache, 2)

test "cache reprioritizes MRU items to not be evicted", ->
  @cache.maximumLength = 3
  editOptions = Batman.mixin {}, @exampleOptions, {source: "products/edit"}
  newOptions = Batman.mixin {}, @exampleOptions, {source: "products/new"}
  indexOptions = Batman.mixin {}, @exampleOptions, {source: "products/index"}
  showOptions = Batman.mixin {}, @exampleOptions

  editView = @cache.viewForOptions editOptions
  newView = @cache.viewForOptions newOptions
  indexView = @cache.viewForOptions indexOptions # Stack is now index, new, edit

  equal editView, @cache.viewForOptions editOptions # Stack is now edit, index, new

  # This should cycle out the new view
  showView = @cache.viewForOptions showOptions

  notEqual newView, @cache.viewForOptions newOptions, "The new view was evicted because it was last on the stack because edit moved to the top"

test "cache allows keys past the length threshold to be reprioritized", ->
  @cache.maximumLength = 3
  editOptions = Batman.mixin {}, @exampleOptions, {source: "products/edit"}
  newOptions = Batman.mixin {}, @exampleOptions, {source: "products/new"}
  indexOptions = Batman.mixin {}, @exampleOptions, {source: "products/index"}
  showOptions = Batman.mixin {}, @exampleOptions
  duplicateOptions = Batman.mixin {}, @exampleOptions, {source: "products/duplicate"}

  editView = @cache.viewForOptions editOptions
  newView = @cache.viewForOptions newOptions
  indexView = @cache.viewForOptions indexOptions # Stack is now index, new, edit

  equal editView, @cache.viewForOptions editOptions # Stack is now edit, index, new

  putInDOM(newView)
  # This should not cycle out the new view even though it is past the threshold
  # Stack is now show, edit, index, new
  showView = @cache.viewForOptions showOptions

  # Stack is now new, show, edit, index
  equal newView, @cache.viewForOptions newOptions, "The new view was not evicted because it was last on the stack because edit moved to the top"

  # This should cycle out index and edit because they are past the threshold
  duplicateView = @cache.viewForOptions duplicateOptions

  equalCacheLength(@cache, 3)
