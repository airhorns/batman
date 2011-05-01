/* 
 * framework.js
 * 
 * Batman
 * Copyright Shopify, 2011
 */

var File = require('fs')
var Path = require('path')
var exec = require('child_process').exec

File.symlinkSync(Path.join(__dirname, '..', 'lib'), Path.join(process.cwd(), 'lib'))

/*
var files = ['batman.js', 'batman.mvc.js', 'batman.dom.js']
var js = files.map(function(file) { return '--js ' + Path.join(__dirname, '..', 'lib', file) }).join(' ')

var output = Path.join(process.cwd(), 'lib', 'batman-min.js')

console.log('compiling batman.js...')

exec('java -jar ' + Path.join(__dirname, 'compiler.jar') + ' ' + js + ' --js_output_file ' + output, function(err, stdout) {
	if (err)
		return console.log(err.message)
	
	
	var data = File.readFileSync(output, 'utf8')
	File.writeFileSync(output, 'INCLUDED_FILES=[\'' + files.join('\',\'') + '\'];' + data)
	
	console.log('batman.js compiled into lib/batman-min.js')
})
*/