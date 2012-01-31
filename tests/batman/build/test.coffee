# This file is meant to be run on the command line to test the development transform.
# Its a scratchpad.
# Run using coffee --nodejs --debug-brk tests/batman/build/test.coffee
coffee = require 'coffee-script'
transform = require('../../../tools/build/remove_development_transform').removeDevelopment
fs = require 'fs'
path = require 'path'
utils = require 'util'

logAST = global.logAST = (ast) ->
  console.warn require('util').inspect(ast, false, 100)

jsp = require("uglify-js").parser
pro = require("uglify-js").uglify

# Switch between a test file in the local directory and the unminified batman source.
orig_code = fs.readFileSync(path.resolve(__dirname, '../../../lib/batman.js')).toString()
#orig_code = fs.readFileSync(path.resolve(__dirname, './test_file.js')).toString()

ast = jsp.parse(orig_code)
#logAST ast
debugger
ast = transform(ast)
console.warn "\n\n==========\n\n"
#logAST ast

final_code = pro.gen_code(ast, {beautify: true})
console.log "Code generated."
