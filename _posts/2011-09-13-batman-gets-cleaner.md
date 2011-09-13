---
title: "Batman 0.6.0 released: Batman grows stronger, the streets get cleaner"
key: community
subkey: blog &mdash; Batman 0.6.0 released
layout: default
author: Harry Brundage
use_wrapper: true
---

Batman 0.6.0 is available on github and npm now. We've fixed many, many bugs, added a few new features, and made it easier for you to get going with Batman.

Some of the main changes and fixes:

 - Introduction of `Batman.SetSort` and `Batman.SetIndex` for observed, propagated sorting and filtering of sets.
 - A more stable `RestStorage` adapter for hitting your API
 - A streamlined `Renderer` with proper `parsed` and `ready` event emission
 - Chained gets mixed with dot access in filters, ie "Alfred.Todos.all.indexedBy\[currentIndex\].sortedBy\['id'\]"
 - `Batman.data` for attaching data to nodes ala `jQuery.data`
 - new `data-read` and `data-write` one way (asymetric) bindings
 - vastly improved Rails compatability
 - an inordinate amount of bug fixes (thanks especially to [Pieter](http://twitter.com/#!/pvande) from Puppet Labs)

See the diff here [on Github](https://github.com/Shopify/batman/compare/v0.5.1...v0.6.0) or look at more details in the [changelog](https://github.com/Shopify/batman/blob/master/CHANGELOG.md).

It takes about 10 seconds to get a bare app generated and running on localhost, so it's easy to [start exploring](/download.html). Take a look at the [documentation](/documentation.html) and [examples](/examples.html), build some cool stuff, and [tell us all about it](http://groups.google.com/group/batmanjs) :)

#### &mdash; [Nick](http://twitter.com/nciagra), [James](http://twitter.com/jamesmacaulay), [Harry](http://twitter.com/harrybrundage), and [Kamil](http://twitter.com/ktusznio)

