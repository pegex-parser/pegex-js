###
name:      Pegex
abstract:  Acmeist PEG Parsing Framework
author:    Ingy döt Net <ingy@ingy.net>
license:   MIT
copyright: 2010-2018
###

class global.Pegex
  version: '0.1.4'

exports.pegex = (grammar, receiver)->
  throw "Argument 'grammar' required in function 'pegex'" \
    unless grammar?

  if typeof grammar is 'string' or grammar instanceof Pegex.Input
    require '../pegex/grammar'
    grammar = new Pegex.Grammar text: grammar

  if not receiver?
    require '../pegex/tree/wrap'
    receiver = new Pegex.Tree.Wrap
  else if typeof receiver is String
    receiver = require receiver
    receiver = new receiver

  require '../pegex/parser'
  new Pegex.Parser
    grammar: grammar
    receiver: receiver

exports.require = (name)->
  require require('path').join __dirname, name
