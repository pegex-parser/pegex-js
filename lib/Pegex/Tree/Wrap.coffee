require '../../Pegex/Tree'

global.Pegex.Tree.Wrap =
class exports.Tree extends Pegex.Receiver

gotrule: (got)->
  if not got?
    ''  #XXX () in Perl
  else
    result = {}
    result[@parser.rule] = got
    result

final: (got)->
  if got?
    got
  else
    result = {}
    result[@parser.rule] = []
    result
