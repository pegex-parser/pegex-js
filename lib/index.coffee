exports.pegex = (require('./lib/pegex')).pegex
exports.require = ->
  result = {}
  for name in arguments
    o = require __dirname + '/lib/pegex/' + name
    for k, v of o
      result.k = v
  return result
