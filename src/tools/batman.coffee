#
# batman.coffee
# batman.js
#
# Created by Nick Small
# Copyright 2011, Shopify
#

(->
  cli = require './cli'
  Batman = require '../lib/batman.js'
  global.RUNNING_IN_BATMAN = true
  # List of commands for use in the multiple `cli.parse` calls below.
  Commands = ['server', 'generate', 'new']

  # Yeah, this is happening. Sorry everyone.
  # cli needs to be headlocked into not fatal erroring if no command is given when
  # help is disabled. We need to disable help so the second parse (the one
  # in the command file) can spit out its own command specific usage stuff if the
  # help flag is given with a command. So, we disable the help module here, and
  # catch the `process.exit` call by overriding `cli.fatal`. The effect is this:
  # when run with just '--help', the new `cli.fatal` implementation will spit out
  # the global usage. When run with 'generate --help' for example, the usage from
  # the generate file will be shown. Nice.

  # Disable the help and grab a pointer to the old `fatal` function.
  cli.disable 'help'
  oldFatal = cli.fatal
  noCommandGiven = false
  # Provide a `fatal` which behaves.
  cli.fatal = (str) ->
    if str.match 'command is required'
      noCommandGiven = true
      cli.enable('help').parse(null, Commands)
      process.exit()
    else
      oldFatal(str)

  # Run the parse and then revert this dirty, dirty hack.
  cli.parse null, Commands
  cli.fatal = oldFatal
  cli.enable 'help'

  # File Breakout
  # -------------

  # Effectively reset cli's parsing.
  cli.setArgv(process.argv)

  # Finally, we can actually start doing some work.
  switch cli.command
    when 'serve', 'server'
      require('./server')
    when 'generate', 'new'
      require('./generator')
)()
