#
# generator.coffee
# batman.js
#
# Created by Nick Small
# Copyright 2011, Shopify
#

fs = require 'fs'
path = require 'path'
util = require 'util'
cli  = require './cli'
utils = require './utils'
{spawn, exec} = require 'child_process'
Batman = require '../lib/batman.js'

cli.setUsage('batman [OPTIONS] generate app|model|controller|view <name>\n  batman [OPTIONS] new <app_name>')
cli.parse
  app: ['-n', "The name of your Batman application (if generating an application component). This can also be stored in a .batman file in the project root.", "string"]


cli.main (args, options) ->
  # Argument Fandangling
  # --------------------

  # `generate` can get called in a few different ways:
  #  - batman gen <template> name   # standard
  #  - batman gen app name          # different because the `appName` and `name` options should have the same value
  #  - batman -n <name> gen app     # support passing the `appName` to the app generator using the flag
  #  - batman new <name>            # alias `new` to `generate app`
  # Here we support all those options.

  # We use the 'app' identifier for the flag cause appName looks silly.
  options.appName = options.app
  # Get rid of the command and check to see if it's `new`, and if it is do the short cut for `generate app`
  command = args.shift()
  if command == 'new'
    options.template = 'app'
    unless args[0]?
      @error "Please provide a name for the application."
      cli.getUsage()
    options.name = args[0]
  # Otherwise grab the template and name of the thing to generate
  else if args.length == 2
    options.template = args[0]
    options.name = args[1]
  else
    @error "Please specify a template and a name for batman generate."
    cli.getUsage()

  # Grab a reference to the batman template directory
  source = path.join(__dirname, 'templates', options.template)

  if !path.existsSync(source)
    @fatal "template #{options.template} not found"

  # Start the goodness. Define a place to put variables available in the template
  TemplateVars = {}

  if options.template == 'app'
    # Allow the app name to be passed with the option flag or as the argument at the end of the command.
    if options.appName?
      options.name = options.appName
    else
      options.appName = options.name

    # Make the project directory in the current directory.
    destinationPath = path.join(process.cwd(), options.appName)
    if path.existsSync(destinationPath)
      @fatal 'Destination already exists!'
    else
      fs.mkdirSync(destinationPath, 0755)
  else
    # Assume we are in the project directory
    destinationPath = process.cwd()
    # Get the config from the package.json
    Batman.mixin options, utils.getConfig()

  # All the paths have been figured out above, so `appName` can be modified
  # Ensure that the app name is always camel cased
  options.appName = Batman.helpers.camelize(options.appName)

  # `replaceVars` is a super simple templating engine.
  # Add a new key to `varMap` right here, and in the templates, the following substitutions will be made:
  # $key$: the lower-case-underscored value of the key
  # $Key$: the camel cased value of the key
  # $KEY$: the upper cased value of the key
  # $_key$: the original value of the key
  Batman.mixin TemplateVars,
    app: options.appName
    name: options.name

  transforms = [((x) -> x.toUpperCase()), ((x) -> Batman.helpers.camelize(x)), ((x) -> Batman.helpers.underscore(x).toLowerCase())]

  replaceVars = (string) ->
    for templateKey, value of TemplateVars
      console.error "template key #{templateKey} not defined!" unless value?
      # Do vanilla key replacement
      string = string.replace(new RegExp("\\$_#{templateKey}\\$", 'g'), value)
      # Do transformed key replacement
      for f in transforms
        string = string.replace(new RegExp("\\$#{f(templateKey)}\\$", 'g'), f(value))
    string

  # `walk` is the recursive function which will traverse a template's directory structure and copy the files within
  # it to the destination after running the substitutions on their contents and names. `walk` takes in an absolute
  # file path pointing to part or all of the template directory.
  count = 0
  walk = (aPath = "/") =>
    sourcePath = path.join(source, aPath)
    # Examine each file at the path.
    fs.readdirSync(sourcePath).forEach (file) =>
      if file == '.gitignore'
        return

      # Get an absolute path to this file in the template directory
      resultName = replaceVars(file)
      sourceFile = path.join(sourcePath, file)
      destFile = path.join(destinationPath, aPath, resultName)

      ext = path.extname(file).toLowerCase().slice(1)
      stat = fs.statSync(sourceFile)

      # If the file is a directory, create it in the destination, and then walk it in the template.
      if stat.isDirectory()
        dir = path.join(destinationPath, aPath, resultName)
        if !path.existsSync(dir)
          fs.mkdirSync(dir, 0755)
        # Descend into this sub dir in the template directory.
        walk path.join(aPath, file)

      # If the file is a binary blog like an image, copy it to the destination.
      else if ext == 'png' || ext == 'jpg' || ext == 'gif'
        newFile = fs.createWriteStream destFile
        oldFile = fs.createReadStream sourceFile

        @info "creating #{destFile}"
        util.pump oldFile, newFile, (err) ->
          throw err if err?

      # Otherwise, do the substitutions on the raw text of the template file and write it in the destination.
      else
        return if file.charAt(0) == '.' # Skip hidden files like .swp's
        count++
        fs.readFile sourceFile, 'utf8', (err, fileContents) =>
          throw err if err?
          @info "creating #{destFile}"

          fs.writeFile destFile, replaceVars(fileContents), (err) =>
            throw err if err?
            if(--count == 0)
              @ok "#{options.name} generated successfully."

  # Start the walk.
  walk()
