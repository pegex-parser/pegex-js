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

{Parser} = require './Pegex/Parser'

exports.pegex = (grammar, receiver) ->
  throw "Argument 'grammar' required in function 'pegex'" \
    unless grammar?
  if typeof grammar is 'string' or grammar instanceof global.Pegex.Input
    {Grammar} = require './Pegex/Grammar'
    grammar = new Grammar {text: grammar}
  if not receiver?
#     {Receiver} = require './Pegex/Tree/Wrap'
#     receiver = new Receiver
    {Receiver} = require './Pegex/Receiver'
    receiver = new Receiver
    receiver.wrap = on
  else if typeof receiver is String
    receiver = require receiver
    receiver = new receiver
  new Parser
    grammar: grammar
    receiver: receiver
