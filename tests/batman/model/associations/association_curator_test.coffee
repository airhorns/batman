{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

QUnit.module "Batman.Model AssociationCurator",
  setup: ->
    class @Store extends Batman.Model
    class @Product extends Batman.Model
    class @ShopifyStore extends @Store

test "associations can be added", 2, ->
  collection = new Batman.AssociationCurator(@Store)

  association = {associationType: 'belongsTo', label: 'products', model: @Product}
  collection.add association

  ok collection.getByType('belongsTo').has(association)
  equal collection.getByLabel('products'), association

test "associations are inherited by subclasses", 2, ->
  @Store._batman.check(@Store)
  @Store._batman.associations = parentCollection = new Batman.AssociationCurator(@Store)
  @ShopifyStore._batman.check(@ShopifyStore)
  @ShopifyStore._batman.associations = subClassCollection = new Batman.AssociationCurator(@ShopifyStore)

  association = {associationType: 'belongsTo', label: 'products', model: @Product}
  parentCollection.add association
  subclassCurator = @ShopifyStore._batman.get('associations')

  ok subclassCurator.getByType('belongsTo').has(association)
  equal subclassCurator.getByLabel('products'), association
