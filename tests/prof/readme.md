Tiller is a totally read only reporting system where you write reports in Coffeescript and use a DSL to build nice looking HTML output. Combined with watson to generate data by logging memory usage over time and using benchmark.js, you can generate data and view the reports.

Watson and Tiller both are npm packages which you'll have to install. The flow of things is like this:

 - Aquire tarballs for watson and tiller.
 - Install tiller via `npm install -g . && npm link` in the tiller source directory
 - Link tiller to watson's node_modules in the watson source directory via `npm link tiller`
 - Install watsons dependencies via `npm link` in the watson source directory
 - `git checkout` the `hornairs/prof` branch of batman
 - Link watson to batman via `npm link watson` in the batman source directory
 - Create a MySQL database and store the connection information in 'batman/tests/prof/watson.json'
 - Run something like 'watson run --files="some/*glob/relative/to/current/path" shaA shaB HEAD master~10 v0.7.5' to generate the data
 - Run 'tiller --config=batman/tests/prof/watson.json' to run the reporting interface server
 - View reports by visiting localhost:4000

Watson works by cloning the whole batman repo to a temporary directory, checking out each SHA, running the tests you specified via 'coffee' sub processes, and then tracking the data. Hopefully the benchmark code should be self explanatory. The reports are all virtually identical, but they all grab different keys corresponding to the coffee file which generated the data pertaining to them.
