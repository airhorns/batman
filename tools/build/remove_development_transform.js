(function() {
  var MAP, REMOVE_NODE, uglify;

  uglify = require('uglify-js');

  MAP = uglify.uglify.MAP;

  REMOVE_NODE = {};

  exports.removeDevelopment = function(ast, DEVELOPER_NAMESPACE) {
    var clean, cleanBlock, cleanLambdaBody, cleanupWalker, removalWalker;
    if (DEVELOPER_NAMESPACE == null) DEVELOPER_NAMESPACE = 'developer';
    removalWalker = uglify.uglify.ast_walker();
    cleanupWalker = uglify.uglify.ast_walker();
    ast = removalWalker.with_walkers({
      call: function(expr, args) {
        var fn, key, objectName, op, upon;
        op = expr[0], upon = expr[1], fn = expr[2];
        if (upon) {
          key = upon[0], objectName = upon[1];
          if (objectName === DEVELOPER_NAMESPACE) return REMOVE_NODE;
        }
        return ['call', removalWalker.walk(expr), MAP(args, removalWalker.walk)];
      },
      assign: function(_, lvalue, rvalue) {
        var fn, key, objectName, op, upon, _ref;
        if (rvalue.length) {
          if (rvalue[0] === 'name' && rvalue[1] === DEVELOPER_NAMESPACE) {
            return REMOVE_NODE;
          }
        }
        if (lvalue.length) {
          op = lvalue[0], upon = lvalue[1];
          switch (op) {
            case 'dot':
            case 'sub':
              op = lvalue[0], (_ref = lvalue[1], key = _ref[0], objectName = _ref[1]), fn = lvalue[2];
              if (objectName === DEVELOPER_NAMESPACE) return REMOVE_NODE;
              break;
            case 'name':
              if (upon === DEVELOPER_NAMESPACE) return REMOVE_NODE;
          }
        }
        return ['assign', _, removalWalker.walk(lvalue), removalWalker.walk(rvalue)];
      },
      "var": function(defs) {
        defs = defs.filter(function(_arg) {
          var name, val, _ref;
          name = _arg[0], val = _arg[1];
          if (name === DEVELOPER_NAMESPACE || (val && val[0] === 'name' && val[1] === DEVELOPER_NAMESPACE) || (val && ((_ref = val[0]) === 'dot' || _ref === 'sub') && val[1].length && val[1][1] === DEVELOPER_NAMESPACE)) {
            return false;
          } else {
            return true;
          }
        });
        return ["var", defs];
      }
    }, function() {
      return removalWalker.walk(ast);
    });
    clean = function(statements) {
      if (statements == null) return null;
      return statements.filter(function(node) {
        switch (node[0]) {
          case "stat":
          case "assign":
            return node[node.length - 1] !== REMOVE_NODE;
          case "var":
            return node[1].length !== 0;
          case "return":
            return node[1] !== REMOVE_NODE;
          default:
            return true;
        }
      });
    };
    cleanLambdaBody = function(name, args, body) {
      return [this[0], name, args, MAP(clean(body), cleanupWalker.walk)];
    };
    cleanBlock = function(statements) {
      return [this[0], MAP(clean(statements), cleanupWalker.walk)];
    };
    return cleanupWalker.with_walkers({
      toplevel: function(body) {
        return ["toplevel", MAP(clean(body), cleanupWalker.walk)];
      },
      "function": cleanLambdaBody,
      defun: cleanLambdaBody,
      block: cleanBlock,
      splice: cleanBlock,
      "try": function(statements, catchBlock, finallyBlock) {
        return [this[0], MAP(clean(statements), cleanupWalker.walk), catchBlock ? [catchBlock[0], MAP(clean(catchBlock[1]), cleanupWalker.walk)] : catchBlock, finallyBlock ? MAP(clean(finallyBlock), cleanupWalker.walk) : void 0];
      },
      "switch": function(expr, body) {
        return [
          this[0], cleanupWalker.walk(expr), MAP(clean(body), function(branch) {
            return [(branch[0] ? cleanupWalker.walk(branch[0]) : null), MAP(clean(branch[1]), cleanupWalker.walk)];
          })
        ];
      }
    }, function() {
      return cleanupWalker.walk(ast);
    });
  };

}).call(this);
