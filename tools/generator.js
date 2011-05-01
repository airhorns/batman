/* 
 * generator.js
 * 
 * Batman
 * Copyright Shopify, 2011
 */

// can all be sync since this isn't a server

var File = require('fs')
var Path = require('path')
var Util = require('util')

var f = (function() {
	
	var template = process.argv[3]
	var name = process.argv[4]
	var appName;
	
	if (!template)
		return Batman.missingArg('template')
	
	if (!name)
		return Batman.missingArg('name')
	
	var dest;
	var source = Path.join(__dirname, 'templates', template)
	
	if (!Path.existsSync(source))
		return console.log('template ' + template + ' not found')
	
	if (template === 'app') {
	  dest = Path.join(process.cwd(), name);
		if (Path.existsSync(dest))
			return console.log('destination already exists')
		
		appName = name;
		File.mkdirSync(dest, 0755)
	} else {
	  dest = process.cwd();
	  appName = File.readFileSync(Path.join(process.cwd(), '.batman'), 'utf8')
	}
	
	var replaceVars = function(string) {
		return string
			.replace(/\$APP\$/g, appName.toUpperCase())
			.replace(/\$App\$/g, Batman.helpers.camelize(appName))
			.replace(/\$app\$/g, appName.toLowerCase())
			
			.replace(/\$NAME\$/g, name.toUpperCase())
			.replace(/\$Name\$/g, Batman.helpers.camelize(name))
			.replace(/\$name\$/g, name.toLowerCase())
	}
	
	var walk = function(path) {
		var sourcePath = path ? Path.join(source, path) : source
		
		File.readdirSync(sourcePath).forEach(function(file) {
			if (file === '.gitignore')
				return;
			
			var resultName = replaceVars(file)
			
			// FIXME
			var components = file.split('.')
			var ext = components[components.length - 1]
			
			var stat = File.statSync(Path.join(sourcePath, file))
			if (stat.isDirectory()) {
			  var dir = Path.join(dest, path, resultName);
			  if (!Path.existsSync(dir))
				  File.mkdirSync(dir, 0755)
				walk(Path.join(path, file))
			} else if (ext === 'png' || ext === 'jpg' || ext === 'gif') {
				var reader = File.readFileSync(Path.join(sourcePath, file), 'binary')
				File.writeFileSync(Path.join(dest, path, resultName), reader, 'binary')
			} else {
				var reader = File.readFileSync(Path.join(sourcePath, file), 'utf8')
				var writePath = Path.join(dest, path, resultName)
				
				console.log('creating ' + writePath)
				File.writeFileSync(writePath, replaceVars(reader))
			}
		})
	}
	
	walk()
	
	if (template === 'app') {
	  process.chdir(dest)
	  require('./framework.js')
  }
	
})()
