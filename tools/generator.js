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
	
	if (!template)
		return Batman.missingArg('template')
	
	if (!name)
		return Batman.missingArg('name')
	
	var dest = Path.join(process.cwd(), name)
	var source = Path.join(__dirname, 'templates', template)
	
	if (!Path.existsSync(source))
		return console.log('template ' + template + ' not found')
	
	if (template === 'app') {
		if (Path.existsSync(dest))
			return console.log('destination already exists')
		
		File.mkdirSync(dest, 0755)
	} else {
		if (!Path.existsSync(dest))
			return console.log('destination already exists')
	}
	
	var replaceVars = function(string) {
		return string
			.replace(/\$APP\$/g, name.toUpperCase())
			.replace(/\$App\$/g, name.substr(0,1).toUpperCase() + name.substr(1))
			.replace(/\$app\$/g, name.toLowerCase())
	}
	
	var walk = function(path) {
		var sourcePath = path ? Path.join(source, path) : source
		
		File.readdirSync(sourcePath).forEach(function(file) {
			if (file.substr(0,1) === '.')
				return;
			
			var resultName = replaceVars(file)
			
			// FIXME
			var components = file.split('.')
			var ext = components[components.length - 1]
			
			var stat = File.statSync(Path.join(sourcePath, file))
			if (stat.isDirectory()) {
				File.mkdirSync(Path.join(dest, path, resultName), 0755)
				walk(Path.join(path, file))
			} else if (ext === 'png' || ext === 'jpg' || ext === 'gif') {
				var reader = File.readFileSync(Path.join(sourcePath, file), 'binary')
				File.writeFileSync(Path.join(dest, path, resultName), reader, 'binary')
			} else {
				var reader = File.readFileSync(Path.join(sourcePath, file), 'utf8')
				File.writeFileSync(Path.join(dest, path, resultName), replaceVars(reader))
			}
		})
	}
	
	walk()
	
})()
