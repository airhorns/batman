# generator.js
# Batman
# Copyright Shopify, 2011

# can all be sync since this isn't a server

fs = require 'fs'
path = require 'path'
util = require 'util' 
cli  = require 'cli'
Batman = require '../lib/batman.js'

cli.setUsage('batman [OPTIONS] generate app|model|controller|view <name>').parse 
  app: ['-n', "The name of your Batman application (if generating an application component). This can also be stored in a .batman file in the project root.", "string"]

cli.main (args, options) ->
  args.shift() # get rid of the command
  
  options.appName = options.app
  if args.length == 2
    options.template = args[0]
    options.name = args[1]
  else
    @error "Please specify a template and a name for batman generate."
    cli.getUsage()
    process.exit()

  source = path.join(__dirname, 'templates', options.template)

  if !path.existsSync(source)
    @fatal "template #{options.template} not found"

  if options.template == 'app'
    # Allow the app name to be passed with the option flag or as the argument at the end of the command.
    if options.appName?
      options.name = options.appName
    else
      options.appName = options.name

    destinationPath = path.join(process.cwd(), Batman.helpers.underscore(options.appName))
    if path.existsSync(destinationPath)
      @fatal 'Destination already exists!'
  
    # Make the directory and add the .batman
    fs.mkdirSync(destinationPath, 0755)
    fs.writeFileSync(path.join(destinationPath, '.batman'), options.appName)
  else
    destinationPath = process.cwd()
    unless options.appName?
      try
        options.appName = fs.readFileSync(path.join(process.cwd(), '.batman')).toString().trim()
      catch e
        if e.code is 'EBADF'
          @fatal 'Couldn\'t find out the name your project! Either pass it with --name or put it in a .batman file in your project root.'
        else
          throw e
  
  # `replaceVars` is a super simple templating engine.
  # Add a new key to `varMap` right here, and in the templates, the following substitutions will be made:
  # $key$: the lower cased value of the key
  # $Key$: the camel cased value of the key
  # $KEY$: the upper cased value of the key
  varMap = 
    app: options.appName
    name: options.name

  transforms = [((x) -> x.toUpperCase()), ((x) -> Batman.helpers.camelize(x)), ((x) -> x.toLowerCase())]

  replaceVars = (string) ->
    for templateKey, value of varMap
      console.error "template key #{templateKey} not defined!" unless value?
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

        @info "creaitng #{destFile}"
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
