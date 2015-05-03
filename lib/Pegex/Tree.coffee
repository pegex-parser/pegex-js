require '../Pegex/Receiver'

global.Pegex.Tree =
class exports.Tree extends Pegex.Receiver

  gotrule: (got)->
    if not got?
      ''  #XXX () in Perl
    else if @parser.parent['-wrap']
      result = {}
      result[@parser.rule] = got
      result
    else
      got

  final: (got)->
    if got?
      got
    else
      []
