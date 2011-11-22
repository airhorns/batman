## 0.8.0 (November 22, 2011)

Major Release

 - Add `Batman.StateHistory` for pushState navigation support
 - View source html can be prefetched via `View.viewSourceCache.prefetch`
 - Major refactoring of view bindings into class based heirarchy
 - Add `data-defineview` to allow view sources to be declared inline
 - Add Association support to Model via `Model.hasOne`, `Model.hasMany`, `Model.belongsTo`
 - Add smart AssociationProxy objects which support reloading
 - Add support for loading associations with inline JSON
 - Add support for `?` and `!` in property names and keypaths
 - Store the current `params` on the `Batman.currentApp` for introspection.
 - Add `ParamsReplacer` and `ParamsPusher` as smart objects which when set, update the global params, pushState or replaceState, and redirect.
 - Add `Hash::update`, `Hash::replace`, and `Set::update`
 - Add `Set::indexedByUnique`
 - Add `Batman.contains` for membership testing and accompanying `has` filter
 - Add support for JSONP requests in `batman.solo`
 - Add `final` property support to optimize observing properties which will never change
 - Add `Batman.version`
 - Add support for customizable render targets in `Controller::render`

Bugfixes:

 - `Hash::clear` now fires observers for cleared keys
 - Properties are no longer retained if they aren't being observed for mega memory usage efficency
 - `IteratorBinding` can have it's sibling node changed without erroring
 - Filter arguments can be keypaths which start on or descend through POJOs
 - `data-context` now correctly only takes effect for its child nodes
 - `data-event-*` has a catchall to attach event listeners for any event
 - Made `Batman.data` work in IE7
 - Made `Batman.Model` properly inherit storage adapters
 - Made `data-bind-style` bindings camelize keys
 - Fixed major memory leaks around Bindings never being garbage collected via Batman.data
 - Made `Renderer::stop` work if called before the renderer started
 - Stop mixing `Observable` into `window` to error earlier when accidental sets and gets are done on `window`
 - Fix memory leaks around View instances never being garbage collected
 - Fix memory leaks around IteratorBinding instances growing with time
 - Fix memory leaks around SetIndex observing all items forever
 - Fix sets on POJOs from keypaths
 - Fix `batman.solo` to properly encode GET params
 - Fix `Model::toJSON` and `Model::fromJSON` to deal with falsey values like any other
 - Remove ability for `View` instances to have either `context` or `contexts`, and unify on `context`.
 - Fix error thrown if the `main` yield didn't exist
 - Made the extras files requirable in node
 - Fix an invalid data bug when receiving large responses using `batman.node`
 - Fix JSON de-serialization when receiving collection responses using `batman.node`
 - Fix support for non numeric model IDs
 - Fix `data-partial` and `data-yield` to stop introducing superfluous divs.

## 0.7.5 (October 25, 2011)

Major Maintenance Release

  - pagination through `Batman.Paginator` and `Batman.ModelPaginator`
  - nested resources routes
  - unknown params passed to `urlFor` will be appended to the query string
  - `App.layout` accepts a class name which will automatically instantiate that class upon load
  - `Controller::render` accepts an `into` option, which lets you render into a yield other than `main`
  - `yield/contentFor/replace` are now animatable through `show/hide`
  - `interpolate` filter
  - pleasant reminders if you seem to have forgotten some encoders
  - removing nodes will destroy all their bindings
  - `Batman.setImmediate` for fast stack popping

Bugfixes:

  - `App.ready` is now a oneShot event
  - `App.controller/model/view` are now only available in development
  - `data-foreach` (through Iterator) is now entirely deferred
  - better support for `input type='file'`
  - sets within gets don't register sources
  - fixes several memory leaks
  - better view html caching

## 0.7.0 (October 12, 2011)

Major Maintenance Release

  - added extras folder
  - start of i18n features
  - overhauled event system, which properties are now clients of (requires code changes)
  - `Property::isolate` and `Property::expose` will prevent a property from firing dependent observers
  - `data-contentFor` will now append its content to its `data-yield`
  - `data-replace` will replace the content of its `data-yield`
  - descending SetSorts
  - `Batman.App` fires a `loaded` event when all dependencies are loaded
  - `Batman.App.currentRoute` property for observing
  - allow `controller#action` syntax in `data-route`

Bugfixes:

  - use persistent tree structure for RenderContext
  - keep track of bindings and listeners with Batman.data
  - correctly free bindings and listeners
  - coerce string IDs into integers when possible in models
  - accessors are memoized
  - suppress developer warnings in tests
  - don't match non `data-*` attributes
  - fix `data-bind-style`

## 0.6.1 (September 27, 2011)

Maintenance Release

  - added `Batman.Enumerable`
  - added support for multi-select boxes
  - added batman.rails.coffee, a new adapter for use within Rails
  - added developer namespace for easy debugging (it gets stripped out in building)
  - one way bindings have been changed to `data-source` and `data-target` to avoid ambiguity
  - added `data-bind` support for `input type='file'`
  - added `data-event-doubleclick`
  - added `length` filter
  - added `trim` helper
  - `Controller.resources` creates a `new` route instead of `destroy`
  - `Model.find` will always return the shared record instance. you can then bind to this and when the data comes in from the storage adapter, your instance will be updated
  - added `Model::findOrCreate`
  - added `Model::updateAttributes`
  - allow storage adapters to specific their namespace with `storageKey`
  - storage adapter filter callbacks take errors
  - added `App.ready` event that fires once the layout is ready in the DOM
  - normalize `status`/`statusCode` in `Batman.Request`
  - hashes now have meta objects to non-obtrusively bind metadata like `length`
  - the `property` keyword is no longer reserved

Bugfixes:

  - `Controller.afterFilter` was missing
  - hash history uses `Batman.DOM.addEventListener`
  - routes such as `data-route="Model/new"` will route correctly
  - fix `Batman.DOM.removeEventListener` so it doesn't depend on document
  - fire `rendered` event after all children have been rendered
  - model methods can be used as event handlers
  - animation methods called with node as context
  - `data-event` works within the binding system
  - simpler model identity mapper
  - `SortableSet::clear` invalidates sort indices
  - IE: doesn't have Function.prototype.name (move things into $functionName)
  - IE: doesn't support `isSameNode`
  - IE: doesn't support `removeEventListener` (use `detachEvent` instead)
  - IE: fix $typeOf for undefined objects
  - IE: event dispatching fixes
  - IE: include json2.js in the tests

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
