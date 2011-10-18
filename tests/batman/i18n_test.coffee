I18N = Batman.I18N
viewHelpers = if typeof require is 'undefined' then window.viewHelpers else require './view/view_helper'

oldLocales = Batman.I18N.locales
oldRequest = Batman.Request

reset = ->
  I18N.unset 'locale'
  Batman.I18N.set('locales', oldLocales)
  Batman.Request = oldRequest

class MockRequest extends MockClass
  @chainedCallback 'success'
  @chainedCallback 'error'

QUnit.module "Batman.I18N: locale property"
  setup: ->
    MockRequest.reset()
    Batman.I18N.set('locales', Batman {en: {grapefruit: true}, fr: {pamplemouse: true}})
    Batman.Request = MockRequest
  teardown: reset

test "the default locale should be returned if no locale has been set", ->
  I18N.unset 'locale'
  equal I18N.get('locale'), I18N.get('defaultLocale')

test "setting the locale should work", ->
  I18N.set 'locale', 'fr'
  equal I18N.get('locale'), 'fr'

test "Batman.I18N.translations should reflect the locale", ->
  I18N.set 'locale', 'en'
  ok I18N.get('translations.grapefruit')
  ok !I18N.get('translations.pamplemouse')

  I18N.set 'locale', 'fr'
  ok !I18N.get('translations.grapefruit')
  ok I18N.get('translations.pamplemouse')

QUnit.module "Batman.I18N: locales fetching"
  setup: ->
    MockRequest.reset()
    Batman.Request = MockRequest
    Batman.I18N.set('locales', new Batman.I18N.LocalesStorage)
    @object = {a: "b"}

  teardown: reset

test "the locales should be settable", ->
  en = Batman()
  I18N.set('locales.en', en)
  equal I18N.get('locales.en'), en

asyncTest "getting a new locale should trigger a request for that locale", ->
  deepEqual I18N.get('locales.en'), {}, "should return an object for use in the interm"

  delay =>
    MockRequest.lastInstance.fireSuccess({en: @object})
    equal I18N.get('locales.en'), @object

asyncTest "getting a new localed should fire observers when the new locale is fetched", ->
  I18N.observe 'locales.en', spy = createSpy()
  deepEqual I18N.get('locales.en'), {}, "should return an object for use in the interm"

  delay =>
    MockRequest.lastInstance.fireSuccess({en: @object})
    equal spy.lastCallArguments[0], @object

test "the locales object should be replaceable", ->
  I18N.set('locales', Batman {en: {a: "c"}})
  deepEqual I18N.get('locales.en'), {a: "c"}

QUnit.module "Batman.I18N: translate filter"
  setup: ->
    I18N.set 'locales', Batman
      fr:
        grapefruit: 'pamplemouse'
        kind_of_grapefruit: "pamplemouse %{kind}"
        how_many_grapefruits:
          1: "1 pamplemouse"
          other: "%{count} pamplemouses"

    Batman.developer.suppress ->
      I18N.set 'locale', 'fr'
  teardown: reset

asyncTest "it should look up keys in the translations under t", ->
  viewHelpers.render '<div data-bind="t.grapefruit | translate"></div>', false, {}, (node) ->
    equal node.childNodes[0].innerHTML, "pamplemouse", 't has been added to the default render stack'
    QUnit.start()

asyncTest "it should accept string literals", ->
  viewHelpers.render '<div data-bind="\'this kind of defeats the purpose\' | translate"></div>', false, {}, (node) ->
    equal node.childNodes[0].innerHTML, "this kind of defeats the purpose"
    QUnit.start()

asyncTest "it should accept translations from other keypaths", ->
  viewHelpers.render '<div data-bind="foo.bar | translate"></div>', false, {foo: {bar: "baz"}}, (node) ->
    equal node.childNodes[0].innerHTML, "baz"
    QUnit.start()
