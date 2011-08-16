# Batman

Batman is a framework for building rich single-page browser applications. It is written in [CoffeeScript](http://jashkenas.github.com/coffee-script/) and its API is developed with CoffeeScript in mind, but of course you can use plain old JavaScript too.

It's got:

* a stateful MVC architecture
* a powerful binding system
* routable controller actions
* pure HTML views
* toolchain support built on [node.js](http://nodejs.org) and [cake](http://jashkenas.github.com/coffee-script/#cake)


# Installation

If you haven't already, you'll need to install [node.js](http://nodejs.org) and [npm](http://npmjs.org/). Then:

    npm install -g batman

Generate a new Batman app somewhere, called bat_belt:

    cd ~/code
    batman new bat_belt

Fire it up:

    cd bat_belt
    batman server #(or just "batman s")

Now visit [http://localhost:8124](http://localhost:8124) and start playing around!

## Architecture

Batman's MVC architecture fits together like this:

* Controllers are persistent objects which render the views and give them mediated access to the model layer.
* Views are written in pure HTML, and use `data-*` attributes to create bindings with model data and event handlers exposed by the controllers.
* Models have validations, lifecycle events, a built-in identity map, and can use arbitrary storage mechanisms (`Batman.LocalStorage` and `Batman.RestStorage` are included).

A Batman application is served up in one page load, followed by asynchronous requests for various resources as the user interacts with the app. Navigation within the app is handled via [hash-bang fragment identifers](http://www.w3.org/QA/2011/05/hash_uris.html), with [pushState](https://developer.mozilla.org/en/DOM/Manipulating_the_browser_history#Adding_and_modifying_history_entries) support forthcoming.


### Controllers

Batman controllers are singleton classes with one or more instance methods that can serve as routable actions. Because they're singletons, instance variables persist as long as the app is running. You normally define your routes along with your actions, like so:

    class MyApp.UsersController extends Batman.Controller
      index: @route('/users') ->
        @users ||= MyApp.User.get('all')

Now when you navigate to `/#!/users`, the dispatcher run this `index` action with an implicit call to `@render`, which by default will look for a view at `/views/users/index.html`. The view is rendered within the main content container of the page, which is designated by setting `data-yield="main"` on some tag in the layout's HTML.

Controllers are also a fine place to put event handlers used by your views. Here's one that uses [jQuery](http://jquery.com/) to toggle a CSS class on a button:

    class MyApp.BigRedButtonController extends Batman.Controller
      index: @route('/button') ->
      
      buttonWasClicked: (node, event) ->
        $(node).toggleClass('activated')


### Views

You write views in plain HTML. These aren't templates in the usual sense: the HTML is rendered in the page as-is, and you use `data-*` attributes to specify how different parts of the view bind to your app's data. Here's a very small view which displays a user's name and avatar:

    <div class="user">
      <img data-bind-src="user.avatarURL" />
      <p data-bind="user.name"></p>
    </div>

The `data-bind` attribute on the `<p>` tag sets up a binding between the user's `name` property and the content of the tag. The `data-bind-src` attribute on the `<img>` tag binds the user's `avatarURL` property to the `src` attribute of the tag. You can do the same thing for arbitrary attribute names, so for example `data-bind-href` would bind to the `href` attribute.


### Models



## Observable Properties

Most of the classes you work with in your app code will descend from `Batman.Object`. One thing you get from `Batman.Object` is a powerful system of observable properties which forms the basis of the binding system. Here's a very simple example:

    gadget = new Batman.Object
    gadget.observe 'name', (newVal, oldVal) ->
      console.log "name changed from #{oldVal} to #{newVal}!"
    gadget.get 'name'
    # returns undefined
    gadget.set 'name', 'Batarang'
    # console output: "name changed from undefined to Batarang!"
    gadget.unset 'name'
    # console output: "name changed from Batarang to undefined!"

By default, these properties are stored like plain old JavaScript properties: that is, `gadget.name` would return "Batarang" just like you'd expect. But if you set the gadget's name with `gadget.name = 'Shark Spray'`, then the observer function you set on `gadget` will not fire.

### Custom Accessors

So, what's the point of using `gadget.get 'name'` instead of just `gadget.name`? Well, Batman properties don't need to be backed by JavaScript properties. Let's write a `Box` class with a custom getter for its volume:

    class Box extends Batman.Object
      constructor: (@length, @width, @height) ->
      @accessor 'volume',
        get: (key) -> @get('length') * @get('width') * @get('height')
    
    box = new Box(16,16,12)
    box.get 'volume'
    # returns 3072

The really cool thing about this is that, because we used `@get` to access the component properties of `volume`, Batman can keep track of those dependencies and let us observe the `volume` directly:
    
    box.observe 'volume', (newVal, oldVal) ->
      console.log "volume changed from #{oldVal} to #{newVal}!"
    box.set 'height', 6
    # console output: "volume changed from 3072 to 1536!"

The `Box`'s `volume` is a read-only attribute here, because we only provided a getter in the accessor we defined. Here's a `Person` class with a (rather naive) read-write accessor for their name:

    class Person extends Batman.Object
      constructor: (name) -> @set 'name', name
      @accessor 'name',
        get: (key) -> [@get('firstName'), @get('lastName')].join(' ')
        set: (key, val) ->
          [first, last] = val.split(' ')
          @set 'firstName', first
          @set 'lastName', last
        unset: (key) ->
          @unset 'firstName'
          @unset 'lastName'
          
          
### Keypaths

If you want to get at properties of properties, use keypaths:

    employee.get 'team.manager.name'

This does what you expect and is pretty much the same as `employee.get('team').get('manager').get('name')`. If you want to observe a deep keypath for changes, go ahead:
    
    employee.observe 'team.manager.name', (newVal, oldVal) ->
      console.log "you now answer to #{newVal || 'nobody'}!"
    manager = employee.get 'team.manager'
    manager.set 'name', 'Bill'
    # console output: "you now answer to Bill!"

If any component of the keypath is set to something that would change the overall value, then observers will fire:
    
    employee.set 'team', randomTeam()
    # console output: "you now answer to Larry!"
    employee.team.unset 'manager'
    # console output: "you now answer to nobody!"
    

## A tour through the project folder

Here's what you get with your freshly generated project:

    .
    ├── README
    ├── controllers
    │   └── app_controller.coffee
    ├── index.html
    ├── models
    ├── bat_belt.coffee
    ├── package.json
    ├── resources
    │   └── batman.png
    └── views
        └── app
            └── index.html


The root directory has two application code files which together form the entry point to your Batman application:

* `index.html` is the only page load in your app. It loads the Batman library along with your app code, then calls `run()` on your application.
* `bat_belt.coffee` (named however you named your app in the generator) contains a [coffeescript class](http://jashkenas.github.com/coffee-script/#classes) which represents your application as a whole. Among other things, it specifies the controllers and models to be loaded as part of your app.

When `index.html` is rendered, it loads `bat_belt.js`, which gets compiled on-the-fly by the `batman server` process from `bat_belt.coffee`. Before the closing `</body>` tag, there's a `<script>` tag which just calls `BatBelt.run()`. Because the `BatBelt` app class has defined the `@root` route to point to the `index` action of `BatBelt.AppController`, this is the action that is loaded when you have a bare path.



# Testing

You can test batman.js locally either on the command line or in the browser and both should work. Tests are written in Coffeescript using [QUnit](http://docs.jquery.com/QUnit#API_documentation).

To run on the command line, install batman.js and its development dependencies using `npm link` or similar, and then run the following command from the project root:

    cake test

To run in the browser (so you can interactively debug perhaps), start a web server to serve up the specs by running this in the project root

    batman server

and then visit `http://localhost:8124/test/batman/test.html` in your browser. Please report any failing tests using Github Issues, and patches are always welcome!
