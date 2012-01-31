uglify = require 'uglify-js'

MAP = uglify.uglify.MAP
REMOVE_NODE = {remove: true}

exports.removeDevelopment = (ast, DEVELOPER_NAMESPACE = 'developer') ->
  removalWalker = uglify.uglify.ast_walker()
  cleanupWalker = uglify.uglify.ast_walker()

  ast = removalWalker.with_walkers
    # Remove all calls to developer.*
    call: (expr, args) ->
      [op, upon, fn] = expr
      if upon
        [key, objectName] = upon
        if objectName == DEVELOPER_NAMESPACE
          return REMOVE_NODE
      ['call', removalWalker.walk(expr), MAP(args, removalWalker.walk)]

    # Remove all assignments to developer or developer.*
    assign: (_, lvalue, rvalue) ->
      if rvalue.length
        if rvalue[0] is 'name' and rvalue[1] is DEVELOPER_NAMESPACE
          return REMOVE_NODE

      if lvalue.length
        [op, upon] = lvalue
        switch op
          when 'dot', 'sub'
            [op, [key, objectName], fn] = lvalue
            if objectName == DEVELOPER_NAMESPACE
              return REMOVE_NODE
          when 'name'
            if upon == DEVELOPER_NAMESPACE
              return REMOVE_NODE
      ['assign', _, removalWalker.walk(lvalue), removalWalker.walk(rvalue)]

    # Remove all var developer declarations, or assignments of developer to another variable.
    var: (defs) ->
      defs = defs.filter ([name, val]) ->
        # `var developer = ` style
        if name is DEVELOPER_NAMESPACE ||
        # `var x = developer;` style
        (val && val[0] is 'name' && val[1] is DEVELOPER_NAMESPACE) ||
        # `var x = developer...` style
        (val && val[0] in ['dot', 'sub'] && val[1].length && val[1][1] is DEVELOPER_NAMESPACE)
          # Don't allow this statement
          false
        else
          # Otherwise just pass it through
          true

      ["var", defs]
  , ->
    removalWalker.walk ast

  keepNode = (node) ->
      switch node[0]
        # Ensure statements or assignments using developer are removed
        when "stat", "assign"
          node[node.length - 1] != REMOVE_NODE
        # Ensure now-empty sequences of var statements are removed
        when "var"
          node[1].length != 0
        # Ensure returning of developer statements are removed
        when "return"
          node[1] != REMOVE_NODE
        else
          true

  clean = (statements) ->
    return null unless statements?
    statements.filter keepNode

  cleanLambdaBody = (name, args, body) ->
    [this[0], name, args, MAP(clean(body), cleanupWalker.walk)]

  cleanBlock = (statements) ->
    [this[0], MAP(clean(statements), cleanupWalker.walk)]

  cleanupWalker.with_walkers
    toplevel: (body) -> return ["toplevel", MAP(clean(body), cleanupWalker.walk)]
    function: cleanLambdaBody
    defun: cleanLambdaBody
    block: cleanBlock
    splice: cleanBlock
    return: (expr) ->
      if keepNode(@)
        return [@[0], cleanupWalker.walk(expr)]
      else
        return [@[0], null]

    try: (statements, catchBlock, finallyBlock) ->
      [@[0], MAP(clean(statements), cleanupWalker.walk),
        if catchBlock then [catchBlock[0], MAP(clean(catchBlock[1]), cleanupWalker.walk)] else catchBlock,
        if finallyBlock then MAP(clean(finallyBlock), cleanupWalker.walk)]
    switch: (expr, body) ->
      [@[0], cleanupWalker.walk(expr), MAP(clean(body), (branch) ->
        [ (if branch[0] then cleanupWalker.walk(branch[0]) else null), MAP(clean(branch[1]), cleanupWalker.walk) ]
      ) ]
  , ->
    cleanupWalker.walk ast
