# generator.js
# Batman
# Copyright Shopify, 2011

# can all be sync since this isn't a server

File = require('fs')
Path = require('path')
Util = require('util')
{Batman} = require('../lib/batman.js')

template = process.argv[3]
name = process.argv[4]

if !template
  return Batman.missingArg('template')

if !name
  return Batman.missingArg('name')

source = Path.join(__dirname, 'templates', template)

if !Path.existsSync(source)
  return console.log('template ' + template + ' not found')

if template == 'app'
  dest = Path.join(process.cwd(), name)
  if Path.existsSync(dest)
    return console.log('destination already exists')

  appName = name
  File.mkdirSync(dest, 0755)
 else
  dest = process.cwd()
  appName = File.readFileSync(Path.join(process.cwd(), '.batman'), 'utf8')


replaceVars = (string) ->
  return string
    .replace(/\$APP\$/g, appName.toUpperCase())
    .replace(/\$App\$/g, Batman.helpers.camelize(appName))
    .replace(/\$app\$/g, appName.toLowerCase())

    .replace(/\$NAME\$/g, name.toUpperCase())
    .replace(/\$Name\$/g, Batman.helpers.camelize(name))
    .replace(/\$name\$/g, name.toLowerCase())


walk = (path) ->
  sourcePath = if path then Path.join(source, path) else source

  File.readdirSync(sourcePath).forEach (file) ->
    if (file == '.gitignore')
      return

    resultName = replaceVars(file)

    # FIXME
    components = file.split('.')
    ext = components[components.length - 1]

    stat = File.statSync(Path.join(sourcePath, file))
    if stat.isDirectory()
      dir = Path.join(dest, path, resultName)
      if !Path.existsSync(dir)
        File.mkdirSync(dir, 0755)
      walk Path.join(path, file)

     else if ext == 'png' || ext == 'jpg' || ext == 'gif'
      reader = File.readFileSync(Path.join(sourcePath, file), 'binary')
      File.writeFileSync(Path.join(dest, path, resultName), reader, 'binary')

     else
      reader = File.readFileSync(Path.join(sourcePath, file), 'utf8')
      writePath = Path.join(dest, path, resultName)

      console.log('creating ' + writePath)
      File.writeFileSync(writePath, replaceVars(reader))


walk()

if template == 'app'
  process.chdir(dest)
  require('./framework.js')
