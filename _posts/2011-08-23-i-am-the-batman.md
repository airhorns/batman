---
title: Announcing batman.js
key: community
subkey: blog &mdash; announcing batman.js
layout: default
author: Nick Small
use_wrapper: true
---

It gives us great pleasure to finally announce the release of batman.js to the JavaScript community today. This release represents the first code dump of something we've been working hard on at Shopify for a long time, so we're very excited to get it into your hands and see what you do with it.

What you'll find in this 0.5.0 release is a capable framework that you can use to build dynamic apps without a lot of code. There is plenty of cool stuff here to play around with:

* a robust system of observable properties
* data and event bindings between pure HTML views and the rest of your app
* models with synchronous and asynchronous validations, a state machine for lifecycle events, and arbitrary storage backends
* a flexible route system
* persistent controllers



That being said, there are still a bunch of pain points and other rough edges. For example:

* several APIs are in flux
* server-side batman.js is not yet very useful
* there's no association system in place for models
* we are over our target of 1000 lines of code (right now batman.coffee is almost 1900 lines, without comments)



In other words, this is an alpha release. It should give you a good idea of where we're headed, but beware of missing features and breaking changes before we hit 1.0.

It takes about 10 seconds to get a bare app generated and running on localhost, so it's easy to [start exploring](/download.html). Take a look at the [documentation](/documentation.html) and [examples](/examples.html), build some cool stuff, and [tell us all about it](http://groups.google.com/group/batmanjs) :)

#### &mdash; Nick, James, Harry, and Kamil
