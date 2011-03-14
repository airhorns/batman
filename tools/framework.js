/* 
 * framework.js
 * 
 * Batman
 * Copyright Shopify, 2011
 */

var File = require('fs')
var Path = require('path')
var exec = require('child_process').exec

var files = ['batman.js', 'batman.mvc.js', 'batman.dom.js']
var js = files.map(function(file) { return '--js ' + Path.join(__dirname, '..', 'lib', file) }).join(' ')

console.log('compiling batman.js...')

exec('java -jar ' + Path.join(__dirname, 'compiler.jar') + ' ' + js + ' --js_output_file ' + Path.join(process.cwd(), 'lib', 'batman-min.js'), function(err, stdout) {
	if (err)
		return console.log(err.message)
	
	console.log('batman.js compiled into lib/batman-min.js')
})
