## 0.6.0 (September 13, 2011)

Major Maintenance Release

  - added `Batman.Accessible`, a simple object wrapper around an accessor
  - added `Batman.SetSort` for getting a sorted version of a set which automatically watches the source set and propagates changes
  - added `Batman.SetIndex` for getting a filtered version of a set which automatically watches the source set and propagates changes
  - added after filters to `Batman.Controller`
  - moved `Batman.Model` attributes into an attributes hash to avoid namespace collisions with model state.
  - added `Batman.data` for safely attaching JS objects to DOM nodes
  - added support for many `[]` style gets in filters
  - added asymmetric bindings (`data-read` and `data-write`)
  - ensured Batman objects are instantiated using `new` (#65)
  - added support for radio button `value` bindings (#81)
  - added `Batman.Encoders` to store built in encoders, and added `Batman.Encoders.RailsDate`
  - added `status` to `Batman.Request`, normalizing XHR object's `status`/`statusCode`
  - added proper parameter serialization to the `batman.solo` platform adapter

Bugfixes:

  - fixed `batman server` options (`batman -b server` works as expected)
  - fixed binding to `submit` events on forms (#6)
  - fixed Renderer's ready events to fire when all child renderers have returned (#13)
  - fixed textarea value bindings to work as expected (#20)
  - made bindings to undefined populate their nodes with an empty string instead of "undefined" (#21)
  - made `data-foreach`, `data-formfor`, `data-context`, and `data-mixin` all work as expected when the collection/object being bound changes (#22)
  - fixed `LocalStorage`'s primaryKey generation (#27)
  - made `Request` send the proper content type (#35)
  - made the current application always appear on the context stack (#46, #48)
  - made `@render false` prevent render on a controller action (#50)
  - made `data-foreach` work with cleared sets and many additions/removals (#52, #56, #67)
  - made empty bindings work (#54)
  - made `Set`s not leak attributes when given items to add in the constructor (#66)
  - prevented `@redirect` from entering a redirect loop when using `hashchange` events (#70)
  - made `showif` and `hideif` bindings play nice with inline elements (#71)
  - made jQuery record serialization work with `RestStorage` (#80)
  - made `Model.get('all')` implicitly load (#85)
  - fixed binding to `state` on models (#95)
  - made `Hash` accept keys containing "." (#98)

## 0.5.1 (August 25, 2011)

Maintenance Release

  - `batman server` is now `batman serve` (or still `batman s`)
  - Configure the hostname for the server with -h
  - CI support with [Travis](http://travis-ci.org/#!/Shopify/batman)

Bugfixes:

  - RestStorage uses correct HTTP methods and contentType
  - Some improvements for `batman new`, more coming in 0.5.2
  - DOM manipulation performance improvement

Known issues:

  - Apps generated with `batman new` are somewhat broken
  - Generators allow too many non-alphanumeric characters

## 0.5.0 (August 23, 2011)

Initial Release

Known issues:

  - Inflector support is naive
  - Code is too big
  - Performance hasn't been investigated
  - Filters don't support async results
  - Model error handling is callback based

Missing features:

  - Model assosciations
  - Model scopes
  - Model pagination
  - Push server
  - Documentation
