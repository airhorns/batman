{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.ModelDraft"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @adapter.storage =
      'products1': {name: "One", cost: 10, id:1}

    @Product.persist @adapter

test "drafts should be creatable from new instances", ->
  product = new @Product()
  draft = product.draft()
  ok draft.isDraft

asyncTest "drafts should be creatable from existing instances", ->
  @Product.find 1, (err, product) =>
    throw err if err
    draft = product.draft()
    ok draft.isDraft
    QUnit.start()

asyncTest "drafts should be creatable from existing drafts", ->
  @Product.find 1, (err, product) =>
    throw err if err
    draft = product.draft().draft()
    ok draft.isDraft
    QUnit.start()

asyncTest "drafts should be discardable", ->
  @Product.find 1, (err, product) =>
    throw err if err
    draft = product.draft()
    equal product.get('drafts.length'), 1
    ok draft.discard()
    equal product.get('drafts.length'), 0
    QUnit.start()

test "drafts should be able to retrieve the record they are a draft of", ->
  product = new @Product()
  draft = product.draft()
  equal draft.record(), product

  deepDraft = draft.draft()
  equal deepDraft.record(), product

test "drafts should reflect their parents attributes if they haven't yet been set on the draft", ->
  @product = new @Product(name: "Snowboard", cost: 10)
  equal @product.get('name'), "Snowboard"
  @draft = @product.draft()

  equal @draft.get('name'), "Snowboard"
  equal @draft.get('cost'), 10
  @product.set 'cost', 20
  equal @product.get('cost'), 20
  equal @draft.get('cost'), 20, "Drafts transparently proxy changes to the underlying attributes"

test "drafts should latch sets upon themselves and not update the parent", ->
  @product = new @Product(name: "Snowboard", cost: 10)
  @draft = @product.draft()

  equal @draft.set('cost', 20), 20, "The set should return the value setted"
  equal @draft.get('cost'), 20
  equal @product.get('cost'), 10

test "drafts should latch sets upon themselves and updates to the parent shouldn't affect them", ->
  @product = new @Product(name: "Snowboard", cost: 10)
  @draft = @product.draft()

  equal @draft.set('cost', 20), 20, "The set should return the value setted"
  @product.set('cost', 30)
  equal @draft.get('cost'), 20, "The set should return the latched value"

test "draft attributes should be accessible under attributes", ->
  @product = new @Product(name: "Snowboard", cost: 10)
  @draft = @product.draft()

  @draft.set('cost', 20)

  equal @draft.get('attributes.cost'), 20

asyncTest "drafts should start in the same state as their parent", ->
  product = new @Product(name: "Snowboard", cost: 10)
  draft = product.draft()
  equal draft.get('lifecycle.state'), product.get('lifecycle.state'), 'same state when dirty'

  @Product.find 1, (err, product) ->
    throw err if err
    draft = product.draft()
    equal draft.get('lifecycle.state'), product.get('lifecycle.state'), 'same state when clean'
    QUnit.start()

asyncTest "setting on drafts should make them dirty but not affect the parent's state", ->
  @Product.find 1, (err, product) ->
    throw err if err
    draft = product.draft()
    equal draft.get('lifecycle.state'), 'clean'
    draft.set('cost', 30)
    equal draft.get('lifecycle.state'), 'dirty'
    equal product.get('lifecycle.state'), 'clean'
    QUnit.start()

test "toJSONing a draft should output the combined attributes of the draft and the parent", ->
  @Product.encode 'math', (x) -> x*10
  product = new @Product(name: "Snowboard", cost: 10, math: 10)
  draft = product.draft()
  draft.set('cost', 30)
  draft.set('math', 30)

  deepEqual draft.toJSON(), {name: "Snowboard", cost: 30, math: 300}

asyncTest "validating a draft should validate using the combined attributes of the draft and the parent", ->
  @Product.validate 'cost', presence: true
  product = new @Product(cost: undefined)
  draft = product.draft()
  draft.set('cost', 10)
  draft.validate (error, errors) ->
    throw error if error
    equal errors.length, 0, 'Draft validates because it has the attributes'
    QUnit.start()

asyncTest "saving a draft should update the record", ->
  @Product.find 1, (err, product) ->
    throw err if err
    draft = product.draft().draft()
    draft.set('cost', 30)
    draft.save (err, savedProduct) ->
      throw err if err
      equal product, savedProduct
      equal savedProduct.get('cost'), 30
      equal draft.get('lifecycle.state'), 'clean', "Draft has the proper state"
      equal product.get('lifecycle.state'), 'clean', "Record has the proper state"
      equal product.get('drafts.length'), 0, "Draft has discarded itself after save"
      QUnit.start()

asyncTest "saving a deep draft should update the record as well as any parents", ->
  @Product.find 1, (err, product) ->
    throw err if err
    parentDraft = product.draft()
    draft = parentDraft.draft()
    draft.set('cost', 30)
    parentDraft.get('lifecycle').onEnter 'saving', parentSpy = createSpy()
    draft.save (err, savedProduct) ->
      throw err if err
      ok parentSpy.called
      equal parentDraft.get('cost'), 30
      equal parentDraft.get('lifecycle.state'), 'clean'
      equal product.get('drafts.length'), 0, "Each draft has discarded itself after save"
      QUnit.start()

asyncTest "loading a draft should update the record", ->
  @Product.find 1, (err, product) =>
    throw err if err
    draft = product.draft()
    @adapter.storage["products1"]["name"] = "Changed"
    draft.load (err, loadedProduct) ->
      throw err if err
      equal loadedProduct, product
      equal loadedProduct.get('name'), "Changed"
      QUnit.start()

asyncTest "loading a draft should not update latched attributes on the draft", ->
  @Product.find 1, (err, product) =>
    throw err if err
    draft = product.draft()
    draft.set 'name', 'draft name'
    @adapter.storage["products1"]["name"] = "storage name"
    draft.load (err, loadedProduct) ->
      throw err if err
      equal draft.get('name'), "draft name"
      QUnit.start()

asyncTest "destroying a draft should destroy the record", ->
  @Product.find 1, (err, product) =>
    throw err if err
    draft = product.draft()
    draft.destroy (err) ->
      throw err if err
      equal draft.get('lifecycle.state'), 'destroyed'
      equal product.get('lifecycle.state'), 'destroyed'
      equal product.get('drafts.length'), 0, "Draft has discarded itself after destroy"
      QUnit.start()

asyncTest "destroying a record should destroy all the drafts", ->
  @Product.find 1, (err, product) =>
    throw err if err
    draft = product.draft()
    otherDraft = product.draft()
    nestedDraft = draft.draft()
    product.destroy (err) ->
      throw err if err
      equal draft.get('lifecycle.state'), 'destroyed'
      equal otherDraft.get('lifecycle.state'), 'destroyed'
      equal product.get('lifecycle.state'), 'destroyed'
      equal product.get('drafts.length'), 0, "Every draft has discarded itself after destroy"
      QUnit.start()
