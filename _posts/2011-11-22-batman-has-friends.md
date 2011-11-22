---
title: "Batman 0.8.0 released: Association support, pagination, and stability."
key: community
subkey: blog &mdash; Batman 0.8.0 released
layout: default
author: Harry Brundage
use_wrapper: true
---

Batman 0.8.0 is available on github and npm now.

The main new features:

### Serious association support

You can now tell your models about their associated records and they will lazily fetch them, reload them, and deserialize them from inline JSON.

{% highlight coffeescript %}
class Store extends Batman.Model
  @hasMany 'products'

class Product extends Batman.Model
  @belongsTo 'store'

store = new Store(id: 1)
store.get('products') # returns a Batman.Set which will be populated with the store's products
{% endhighlight %}

The objects returned by the association getters are smart enough to know if they have already been loaded, and they define a `load` function which you can use to reload them. Association can be loaded via inline JSON (like in the Shopify API) and they save themselves by serializing into their parent's JSON, which means they work out of the box with Rails models which `accept_nested_attributes_for` their children.

### Pagination

Batman can now paginate a large server side set without much work from you. You just have to tell it what parameters to send to the server, and then interpret them on the server side.

{% highlight coffeescript %}
class ProductPaginator extends Batman.ModelPaginator
  model: App.Product
  limit: 25
  totalProducts: 100
  # Optionally override paramsForOffsetAndLimit(offset, limit) to define
  # what params to send to the server

products = new ProductPaginator
products.get('page') #=> 1
products.get('toArray') #=> [Product, Product, Product...]
{% endhighlight %}

### Serious bugfixes

A huge swath of bugs have been squashed, so batman should be even easier build awesome apps with. Batman uses a whole lot less memory now as well, so it should be that much faster. For more information on what bugs have been fixed, see the [changelog](https://github.com/Shopify/batman/blob/master/CHANGELOG.md). As always, if you want to help squash some yourself, you can head over to [Batman on Github](https://github.com/Shopify/batman/) and help us out!


## Thanks

We'd also like to thank all the people on GitHub which have helped us get to this point so far: [Pieter van de Bruggen](https://github.com/pvande), [Damir](https://github.com/sidonath), [Willem van Bergen](https://github.com/wvanbergen), [Marcin Ciunelis](https://github.com/martinciu), [Brian Beck](https://github.com/exogen), [Paul Miller](https://github.com/paulmillr), [David Mosher](https://github.com/davemo), [Tobias Lütke](https://github.com/tobi), [Kyle Finley](https://github.com/kylefinley), [Morita Hajime](https://github.com/omo), [Fernando Correia](https://github.com/fernandoacorreia), [Erik Behrends](https://github.com/behrends), [cj](https://github.com/cj), [Richard Hooker](https://github.com/hookercookerman), [Rasmus Rønn Nielsen](https://github.com/rasmusrn), and [Jonathan Rudenberg](https://github.com/titanous). Air high five!


You can see the full diff for 0.8.0 here [on Github](https://github.com/Shopify/batman/compare/v0.7.5...master). If you have any questions or run into any problems, feel free to post on the [mailing list](http://groups.google.com/group/batmanjs) or come hang out in IRC in #batmanjs on Freenode.

It takes about 10 seconds to get a bare app generated and running on localhost, so it's easy to [start exploring](/download.html). Take a look at the [documentation](/documentation.html) and [examples](/examples.html), build some cool stuff, and [tell us all about it](http://groups.google.com/group/batmanjs) :)

#### &mdash; [Nick](http://twitter.com/nciagra), [James](http://twitter.com/jamesmacaulay), [Harry](http://twitter.com/harrybrundage), and [Kamil](http://twitter.com/ktusznio)


