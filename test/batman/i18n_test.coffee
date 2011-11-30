I18N = Batman.I18N
viewHelpers = if !IN_NODE then window.viewHelpers else require './view/view_helper'

oldLocales = Batman.I18N.locales
oldRequest = Batman.Request

reset = ->
  I18N.unset 'locale'
  Batman.I18N.set('locales', oldLocales)
  Batman.Request = oldRequest

class MockRequest extends MockClass
  @chainedCallback 'success'
  @chainedCallback 'error'

suite "Batman", ->
  suite "I18N: locale property", ->
    setup ->
        MockRequest.reset()
        Batman.I18N.set('locales', Batman {en: {grapefruit: true}, fr: {pamplemouse: true}})
        Batman.Request = MockRequest
    teardown reset

    test "the default locale should be returned if no locale has been set", ->
      I18N.unset 'locale'
      assert.equal I18N.get('locale'), I18N.get('defaultLocale')

    test "setting the locale should work", ->
      I18N.set 'locale', 'fr'
      assert.equal I18N.get('locale'), 'fr'

    test "Batman.I18N.translations should reflect the locale", ->
      I18N.set 'locale', 'en'
      assert.ok I18N.get('translations.grapefruit')
      assert.ok !I18N.get('translations.pamplemouse')

      I18N.set 'locale', 'fr'
      assert.ok !I18N.get('translations.grapefruit')
      assert.ok I18N.get('translations.pamplemouse')

  suite "Batman.I18N: locales fetching", ->
    object = false
    setup ->
      MockRequest.reset()
      Batman.Request = MockRequest
      Batman.I18N.set('locales', new Batman.I18N.LocalesStorage)
      object = {a: "b"}

    teardown reset

    test "the locales should be settable", ->
      en = Batman()
      I18N.set('locales.en', en)
      assert.equal I18N.get('locales.en'), en

    test "getting a new locale should trigger a request for that locale", (done) ->
      assert.deepEqual I18N.get('locales.en'), {}, "should return an object for use in the interm"
      delay {done}, =>
        MockRequest.lastInstance.fireSuccess({en: object})
        assert.equal I18N.get('locales.en'), object

    test "getting a new localed should fire observers when the new locale is fetched", (done) ->
      I18N.observe 'locales.en', spy = createSpy()
      assert.deepEqual I18N.get('locales.en'), {}, "should return an object for use in the interm"

      delay {done}, =>
        MockRequest.lastInstance.fireSuccess({en: object})
        assert.equal spy.lastCallArguments[0], object

    test "the locales object should be replaceable", ->
      I18N.set('locales', Batman {en: {a: "c"}})
      assert.deepEqual I18N.get('locales.en'), {a: "c"}

  suite "Batman.I18N: translate filter", ->
    setup ->
        I18N.set 'locales', Batman
          fr:
            grapefruit: 'pamplemouse'
            kind_of_grapefruit: "pamplemouse %{kind}"
            how_many_grapefruits:
              1: "1 pamplemouse"
              other: "%{count} pamplemouses"

        Batman.developer.suppress ->
          I18N.set 'locale', 'fr'
    teardown reset

    test "it should look up keys in the translations under t", (done) ->
      viewHelpers.render '<div data-bind="t.grapefruit | translate"></div>', false, {}, (node) ->
        assert.equal node.childNodes[0].innerHTML, "pamplemouse", 't has been added to the default render stack'
        done()

    test "it should accept string literals", (done) ->
      viewHelpers.render '<div data-bind="\'this kind of defeats the purpose\' | translate"></div>', false, {}, (node) ->
        assert.equal node.childNodes[0].innerHTML, "this kind of defeats the purpose"
        done()

    test "it should accept translations from other keypaths", (done) ->
      viewHelpers.render '<div data-bind="foo.bar | translate"></div>', false, {foo: {bar: "baz"}}, (node) ->
        assert.equal node.childNodes[0].innerHTML, "baz"
        done()
