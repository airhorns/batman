Tiller is a totally read only reporting system for which you write reports in a CoffeeScript a DSL to build nice looking HTML output. Combined with `watson` to generate data about memory usage and performance characteristics, you can generate data and view the reports.

Watson and Tiller both are npm packages which you'll have to install. The flow of things is like this:

 - Aquire tarballs for watson and tiller.
 - Install tiller via `npm install -g && npm link` in the tiller source directory
 - Install watsons dependencies and expose it using `npm link` in the watson source directory
 - Link watson to batman via `npm link watson` in the batman source directory
 - Create a MySQL database and store the connection information in 'batman/tests/prof/watson.json'
 - Run something like 'watson run --files="some/*glob/relative/to/current/path" shaA shaB HEAD master~10 v0.7.5' to generate the data
 - Run 'tiller --config=batman/tests/prof/watson.json' to run the reporting interface server
 - View reports by visiting localhost:4000

Watson works by cloning the whole batman repo to a temporary directory, checking out each SHA, running the tests you specified via 'coffee' sub processes, and then tracking the data. Hopefully the benchmark code should be self explanatory. The reports are all virtually identical, but they all grab different keys corresponding to the coffee file which generated the data pertaining to them.
