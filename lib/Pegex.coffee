###
name:      Pegex
abstract:  Acmeist PEG Parsing Framework
author:    Ingy döt Net <ingy@ingy.net>
license:   MIT
copyright: 2010-2015
###

global.Pegex =
class Pegex
  VERSION: '0.0.3'

require './Pegex/Parser'

exports.pegex = (grammar, receiver) ->
  throw "Argument 'grammar' required in function 'pegex'" \
    unless grammar?
  if typeof grammar is 'string' or grammar instanceof Pegex.Input
    require './Pegex/Grammar'
    grammar = new Pegex.Grammar {text: grammar}
  if not receiver?
#     {Tree} = require './Pegex/Tree/Wrap'
#     receiver = new Tree
    require './Pegex/Receiver'
    receiver = new Pegex.Receiver
    receiver.wrap = on
  else if typeof receiver is String
    receiver = require receiver
    receiver = new receiver
  new Pegex.Parser
    grammar: grammar
    receiver: receiver
