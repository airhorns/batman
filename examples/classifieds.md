# Another Example: Batman Classifieds

Find the source here: http://github.com/Shopify/batman-classifieds

Find the demo here: http://batman-classifieds.heroku.com

# Running the demo yourself

This is a elementary but not trivial Rails 3.1 app. To run it locally, you need a Ruby installation and the bundler gem installed. To install:

    git clone https://github.com/Shopify/batman-classifieds.git
    cd batman-classifieds
    bundle install
    bundle exec rake db:setup
    bundle exec rails server

And the app should be available at http://localhost:3000/.

# About the app

Batman Classifieds is a good example of a simple Batman application and how to best integrate batman with Rails. It uses the `batman-rails` gem
to source batman's javascripts, and Sprockets to package it all up. There's two major resources: Ads, and Users, which are exposed via JSON endpoints
and accessed using a `Batman.RailsStorage` adapter. Ads are a typical CRUD resource, whereas Users are session based and exposed via the
`ApplicationController` talking to OmniAuth.
