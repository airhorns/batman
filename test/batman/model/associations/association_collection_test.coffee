{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if IN_NODE then require '../model_helper' else window
helpers = if !IN_NODE then window.viewHelpers else require '../../view/view_helper'

suite "Batman", ->
  suite "Model", ->
    suite "Associations", ->
      suite "AssociationCollection", ->
        Store = false
        Product = false
        ShopifyStore = false
        setup ->
            class Store extends Batman.Model
            class Product extends Batman.Model
            class ShopifyStore extends Store

        test "associations can be added", ->
          collection = new Batman.AssociationCollection(Store)

          association = {associationType: 'belongsTo', label: 'products', model: Product}
          collection.add association

          associationsObject = collection.getAllByType()

          assert.equal associationsObject.get('belongsTo').get(association), 'products'
          assert.equal collection.getByLabel('products'), association

        test "associations are inherited by subclasses", ->
          Store._batman.check(Store)
          Store._batman.associations = parentCollection = new Batman.AssociationCollection(Store)
          subClassCollection = new Batman.AssociationCollection(ShopifyStore)

          association = {associationType: 'belongsTo', label: 'products', model: Product}
          parentCollection.add association

          associationsObject = subClassCollection.getAllByType()

          assert.equal associationsObject.get('belongsTo').get(association), 'products'
