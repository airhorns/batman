FIXME
# Batman

Batman is a full-stack Javascript framework that helps you build rich, single-page, Javascript applications. It (will) include:

* A tiny Javascript framework for managing your app at runtime
* An optional DOM plugin to bind nodes to pieces of your app
* Tools to bootstrap your Javascript development
* Tools to tightly integrate your front-end and back-end
* A robust toolchain for working with your Javascript app

## Javascript Framework

The core of the framework clocks in at <9kb when compressed. It takes a powerful alternative to classical inheritance and a robust system of data bindings, and builds a thin MVC layer on top that favors convention over configuration. This allows you to quickly write apps without having to worry about browser and framework quirks. Let's look at the two key concepts.

### Mixins

Batman features a more fully-realized mixin system in favor of classical inheritance, though at times it may still feel like you're creating classes.

** Batman.mixin()**:

	Batman.mixin(destinationObject, sourceObject1, sourceObject2...)

A basic mixin function. It will simply take all the properties from the source objects and apply them to destinationObject. Because all Javascript objects act like dictionaries or hashes, you can simply pass in a hash and it will be mixed into the destination object. **Returns destinationObject.**

**Batman() constructor**:

	Batman(sourceObject...)

Creates a new object and mixes in all the keys of the source objects to that new object. **Returns the new object.**

*Note: Source objects are applied in order; if a key already exists on an object, it will be overwritten.*

**Batman.Mixin**:

	MyMixin = Batman.Mixin({
		isMyMixin: true
	})

You can think of a Mixin as a predefined bucket of properties, or almost as a class. All of the source objects passed to the Batman.Mixin constructor will be applied to the Mixin's *prototype*. You can now use MyMixin in a variety of ways:

* **applyTo**: Apply it to an object
		
		MyMixin.applyTo(someObject) => someObject.isMyMixin == true
		Batman.mixin(someObject, MyMixin) => someObject.isMyMixin == true
		Batman(MyMixin) => {isMyMixin: true}
* **create**: Instantiate a new object
		
		MyMixin.create() => {isMyMixin: true}
		MyMixin() => {isMyMixin: true}
		MyMixin({foo: 'bar'}) => {isMyMixin: true, foo: 'bar'}
* **removeFrom**: Remove it from an object
		
		MyMixin.removeFrom(someObject) => someObject.isMyMixin == undefined
		Batman.unmixin(someObject, MyMixin) => someObject.isMyMixin == undefined
* **enhance**: Mixin more properties to the *prototype*
		
		MyMixin.enhance({isEnhanced: true})
		MyMixin() => {isMyMixin: true, isEnhanced: true}
* **mixin**: Mixin properties to the mixin object itself
		
		MyMixin.mixin({foo: 'bar'}) => MyMixin.foo == 'bar'
* **inherit**: Returns a hash of functions proxied to this Mixin's prototype
		
		MyMixin.enhance({foo: function() { console.log(this) }})
		AnotherMixin = Batman.Mixin({isAnotherMixin: true}, MyMixin.inherit('foo'))
		AnotherMixin().foo() => logs {isAnotherMixin: true, foo: function}
Batman includes a number of predefined Mixins, and indeed uses these instead of classes. You'll see how this helps you write powerful code more simply.

**Dependency Injection**: You can use inline permanent observers as a basic system of dependency injection. A future update may make this more automatic.

	Batman.View = Batman.Mixin({
		isView: true,
		node: $binding().observeForever(function(node) {
			if (node)
				Batman.require('batman.dom', function() {
					Batman.DOM.applyToNode(node)
				})
		})
	})

Batman.require caches already loaded files.

### Bindings

Bindings let you register any arbitrary key on any arbitrary object as observable. You can then add listeners to that property, so whenever its value changes, you can notify something in a completely different place in your app.

	var obj = Batman({
		foo: $binding('bar')
	})
	
	obj.foo() => 'bar'
	
	obj.foo('pew pew')
	obj.foo() => 'pew pew'

* **observe**: Register a function to be notified when the value changes
		
		obj.foo.observe(function(newValue) {
			console.log(newValue)
		})
		// observe is aliased to obj.foo.on() or obj.foo.when()
		// you can pass true as a second parameter to observe, and the observer will be called immediately, without firing the binding
		
		obj.foo('foobaar') => logs 'foobar'
* **forget**: Stop notifying a particular observer
		
		var f = function() {
			// do something
		}
		
		obj.foo.observe(f)
		obj.foo.forget(f)
		
		obj.foo('foobar') => nothing happens
* **fire**: Manually fire all observers, even if the value hasn't changed
		
		obj.foo.fire() => logs 'foobar', the last value set
* **prevent**: Lock a binding to prevent it from firing
		
		obj.foo.prevent()
		obj.foo.allowed() => false
		
		obj.foo.fire() => false, does nothing
		
		obj.foo.allow()
		obj.foo.fire() => logs 'foobar', the last value set
		
		// every call to prevent() increments a counter; you can nest prevents, but each must have a matching allow() before the binding will fire again
* **copy**: Copies the binding to a new binding
		
		var obj2 = Batman({
			bar: obj.foo.copy()
		})
		
		obj2.bar() => 'foobar'
		
		obj2.bar('qux')
		obj2.bar() => 'qux'
		obj.foo() => 'foobar'
* **observeForever**: Registers an observer that persists through copies
		
		Batman.Request = Batman.Mixin({
			url: $binding('').observeForever(function(url) {
				if (url)
					this.send()
			})
		})
* **validate**: Functionality may change

**Array bindings**: Any binding with an array value will inherit the methods from the Array prototype, but toll-free bridge them to the binding.

	var user = Batman({
		friends: $binding(['nick'])
	})
	
	user.friends() => ['nick']
	
	user.friends.observe(function(friends) {
		console.log(friends)
	})
	
	user.friends.push('tobi') => logs ['nick', 'tobi']
	user.friends.removeObject('tobi') => logs ['nick']
	user.friends.unshift('chris') => logs ['chris', 'nick']
	user.friends.join(',') => 'chris, nick'

**Computed bindings**: You can also have computed bindings. These are bindings which you create with a function instead of a value; whenever the value is requested, the function will be executed and the result will be returned. If a computed binding uses any other bindings in its implementation, it will automatically observe those sub-bindings; when one of the dependent bindings changes, the computed binding will be recalculated, and thus re-fire its observers.

	var person = Batman({
		firstName: $binding("bruce"),
		lastName: $binding("wayne"),
		
		fullName: $binding(function() {
			return this.firstName() + ' ' + this.lastName()
		})
	})
	
	person.fullName() => 'bruce wayne'
	
	person.fullName.observe(function(newValue) {
		console.log(newValue)
	})
	
	person.firstName('thomas') => logs 'thomas wayne', from the observer on fullName

**Transactions**: If you are going to set a number of bindings on the same object, you can coalesce them into one transaction.

	var t = Batman.transaction(person)
	t.isTransaction => true
	
	t.firstName = 'alfred'
	t.lastName = 'pennyworth'
	t.commit() => logs 'alfred pennyworth' a single time, from the observer on fullName

**Events**: Batman builds its event system on top of bindings.

	var button = Batman({
		title: $binding('Click Me'),
		click: $event(function() {
			this.title('Clicked!')
		})
	})
	
	// register an observer
	// this is a shortcut to button.click.observe, so it has the normal aliases
	button.click(function() {
		console.log('pressed')
	})
	
	// when you receive a mouse event...
	button.click() => logs 'pressed'
	// equivalent to button.click.dispatch()
	// if you need to pass a function as an argument, use .dispatch
	
	button.title() => 'Clicked!'

**One Shot Events**: Can only fire a single time, any observers added after that will simply be called immediately

	Batman.ready = $event(function() { /* do something */ }, true)
	Batman.ready.isEvent => true
	Batman.ready.isOneShot => true
	Batman.ready.hasFired => false
	
	Batman.ready()
	Batman.ready.hasFired => true
	
	Batman.ready(function() { console.log('ready') }) => logs 'ready' immediately

**Ajax Requests**: XHR built on bindings

	var request = Batman.Request('foo.json')
		.success(function(request) {
			// do something
		})
		.error(function(error) {
			// handle error
		})
		// other events: .send, .complete, .done, .fail, .then
	
	request.method() => 'get'
	
	request.body({foo: 'bar'})
	request.method() => 'post'
	request.contentType() => 'application/json'
	
	// request will be sent automatically, a short time after the url changes
	// use request.cancel() to stop this behavior or request.send() to send immediately

### MVC

The Javascript framework also includes a very thin layer of MVC. More documentation coming. Short version is everything is a Mixin and aliased to moneyhat functions.

	User = Batman.Model({
		name: $binding('')
	}, $M.timestamps())
	
	User.isModel => true
	User.name => undefined
	
	var me = User({name: 'bruce wayne'})
	me.name() => 'bruce wayne'

### DOM

This optional plugin will be automatically included if you create a Batman.View with the *node* property defined. It allows you to access your app data inside your normal HTML **without using templates**.

*Why templates are bad: they take too long to render; they delay the initial display of the page; the generated DOM nodes are not isolated--any Javascript, like jQuery, may manipulate DOM nodes; if a single piece of data changes, all the existing DOM nodes are blown away.*

Instead of templates, you simply write normal HTML. You can then use data- attributes to bind different properties of the node to your data.

	<body>
		<div data-bind="person.fullName"></div> => <div>bruce wayne</div>
	</body>

No rendering is required, the browser's much faster rendering simply renders the HTML. Batman.DOM simply observes the binding you pass in and updates the *existing* node's innerHTML when the binding changes.

**each**: Iterate over a collection binding using a prototype node

	<ul>
		<li data-each-friend="user.friends"><span data-bind="friend.name"></span></li>
		<li><span data-bind="user.friends.length"></span> friends</li>
	</ul>

The li that has the data-each binding will be used as a prototype; replicated for ever item in the friends array. This allows you to also use arbitrary non-collection elements, like the count li at the bottom of the list.

**visible**: Shows or hides the node based on whether the value of the binding is truthy or falsy.

	<ul data-visible="user.hasFriends"></ul>

**Binding expressions**: The string you pass to the attribute is a full expression. This makes complex bindings possible

	<ul data-visible="user.friends().length > 0"></ul>

**classes**: Add or remove CSS class names based on a hash of bindings

	<div data-classes="modified: user.isModified, has_friends: user.hasFriends">

**Arbitrary HTML attributes**: You can bind the value of any HTML attribute to a binding

	<div data-bind-class="user.cssClasses"><input data-bind-placeholder="user.fullName" /></div>

**events**: A more robust list of events than the DOM provides by default

	<input data-events="submit: controller.takeNameFrom" />
	
	controller = Batman({
		takeNameFromNode: function(value, node) {
			user.firstName(value)
		}
	})

The full list of supported events can be found in Batman.DOM.events

**mixin**: You can mixin an object of properties to a node

	<div data-mixin="animation"></div> => divNode.show(), divNode.hide()

**yield and contentFor**: Place different blocks of HTML in different places (this is subject to the why templates are bad rule above)

	<div id="content" data-yield="main"></div>
	
	<div data-content-for="main">Foo</div> => <div id="content">Foo</div>

More documentation coming soon.
